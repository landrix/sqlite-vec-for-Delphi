unit LembedVectorExample;

interface

uses
  System.SysUtils, System.Classes,
  mormot.db.sql, mormot.db.raw.sqlite3, mormot.db.raw.sqlite3.static,
  mormot.core.base, mormot.core.unicode, mormot.core.text;

type
  /// <summary>
  /// Beispiel-Klasse für semantische Dokumentensuche mit lembed + sqlite-vec
  /// </summary>
  TSemanticDocumentSearch = class
  private
    FDatabase: TSQLDatabase;
    FModelName: string;
    FModelPath: string;
    FEmbeddingDimensions: Integer;
    FInitialized: Boolean;
    procedure LoadExtensions;
    procedure RegisterModel;
  public
    constructor Create(const ADBPath: string);
    destructor Destroy; override;
    
    /// <summary>
    /// Initialisiert die Datenbank mit Tabellen und Modell
    /// </summary>
    procedure Initialize(const AModelPath: string; const AModelName: string = 'embedder';
      AEmbeddingDimensions: Integer = 384);
    
    /// <summary>
    /// Fügt ein Dokument hinzu und generiert automatisch das Embedding
    /// </summary>
    function AddDocument(const ATitle, AContent: string): Int64;
    
    /// <summary>
    /// Führt eine semantische Suche durch
    /// </summary>
    function Search(const AQuery: string; ALimit: Integer = 10): TRawUtf8DynArray;
    
    /// <summary>
    /// Findet ähnliche Dokumente zu einem gegebenen Dokument
    /// </summary>
    function FindSimilar(ADocumentId: Int64; ALimit: Integer = 5): TRawUtf8DynArray;
    
    /// <summary>
    /// Löscht ein Dokument und sein Embedding
    /// </summary>
    procedure DeleteDocument(ADocumentId: Int64);
    
    /// <summary>
    /// Gibt Statistiken über die Datenbank zurück
    /// </summary>
    function GetStats: string;
  end;

implementation

uses
  sqliteVecForDelphi;

{ TSemanticDocumentSearch }

constructor TSemanticDocumentSearch.Create(const ADBPath: string);
begin
  inherited Create;
  FDatabase := TSQLDatabase.Create(ADBPath, '');
  FEmbeddingDimensions := 384;
  FInitialized := False;
end;

destructor TSemanticDocumentSearch.Destroy;
begin
  FDatabase.Free;
  inherited;
end;

procedure TSemanticDocumentSearch.LoadExtensions;
begin
  // Extensions aus Ressourcen extrahieren
  TSQLDatabaseVectorHelper.ExtractLembed0Dll;
  TSQLDatabaseVectorHelper.ExtractVec0Dll;
  
  // Extension loading aktivieren
  TSQLDatabaseVectorHelper.EnableExtensionLoading(FDatabase.DB);
  
  // lembed0.dll laden
  TSQLDatabaseVectorHelper.LoadExtension(FDatabase.DB, 'lembed0.dll');
    
  // vec0.dll laden
  TSQLDatabaseVectorHelper.LoadExtension(FDatabase.DB, 'vec0.dll');
end;

procedure TSemanticDocumentSearch.RegisterModel;
var
  lCount: Int64;
  lStmt: TSQLRequest;
begin
  // Modell registrieren
  lStmt.Prepare(FDatabase.DB,
    'INSERT INTO temp.lembed_models(name, model) ' +
    'VALUES (?, lembed_model_from_file(?));'
  );
  try
    lStmt.Bind(1, StringToUtf8(FModelName));
    lStmt.Bind(2, StringToUtf8(FModelPath));
    try
      lStmt.Step;
    except
      on E: Exception do
        raise Exception.CreateFmt(
          'Modell konnte nicht registriert werden (%s, Datei: %s): %s',
          [FModelName, FModelPath, E.Message]
        );
    end;
  finally
    lStmt.Close;
  end;

  lStmt.Prepare(FDatabase.DB,
    'SELECT COUNT(*) FROM temp.lembed_models WHERE name = ?;'
  );
  try
    lStmt.Bind(1, StringToUtf8(FModelName));
    if lStmt.Step = SQLITE_ROW then
      lCount := lStmt.FieldInt(0)
    else
      lCount := 0;
  finally
    lStmt.Close;
  end;

  if lCount <> 1 then
    raise Exception.CreateFmt(
      'Modell "%s" wurde nicht in temp.lembed_models registriert.',
      [FModelName]
    );
end;

procedure TSemanticDocumentSearch.Initialize(const AModelPath, AModelName: string;
  AEmbeddingDimensions: Integer);
begin
  if FInitialized then
    Exit;
    
  FModelPath := AModelPath;
  FModelName := AModelName;
  FEmbeddingDimensions := AEmbeddingDimensions;

  if not FileExists(FModelPath) then
    raise Exception.CreateFmt('Modelldatei nicht gefunden: %s', [FModelPath]);

  if FEmbeddingDimensions <= 0 then
    raise Exception.CreateFmt('Ungültige Embedding-Dimension: %d', [FEmbeddingDimensions]);
  
  // Extensions laden
  LoadExtensions;
  
  // Modell registrieren
  RegisterModel;
  
  // Dokumenten-Tabelle erstellen (falls nicht vorhanden)
  FDatabase.Execute(
    'CREATE TABLE IF NOT EXISTS documents(' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  title TEXT NOT NULL,' +
    '  content TEXT NOT NULL,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ');'
  );
  
  // Vector-Tabelle erstellen (falls nicht vorhanden)
  FDatabase.Execute(
    'CREATE VIRTUAL TABLE IF NOT EXISTS vec_documents USING vec0(' +
    '  embedding float[' + IntToStr(FEmbeddingDimensions) + ']' +
    ');'
  );
  
  // Index für bessere Performance
  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_doc_created ON documents(created_at);');
  
  FInitialized := True;
end;

function TSemanticDocumentSearch.AddDocument(const ATitle, AContent: string): Int64;
var
  lStmt: TSQLRequest;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert. Rufe Initialize() auf.');
    
  // Dokument einfügen
  lStmt.Prepare(FDatabase.DB,
    'INSERT INTO documents(title, content) VALUES (?, ?);'
  );
  try
    lStmt.Bind(1, StringToUtf8(ATitle));
    lStmt.Bind(2, StringToUtf8(AContent));
    lStmt.Step;
  finally
    lStmt.Close;
  end;
  
  // ID des eingefügten Dokuments holen
  Result := FDatabase.LastInsertRowID;
  
  // Embedding generieren und speichern
  // Kombiniere Title + Content für bessere semantische Erfassung
  lStmt.Prepare(FDatabase.DB,
    'INSERT INTO vec_documents(rowid, embedding) ' +
    'SELECT ?, lembed(?, ? || '' '' || ?);'
  );
  try
    lStmt.Bind(1, Result);
    lStmt.Bind(2, StringToUtf8(FModelName));
    lStmt.Bind(3, StringToUtf8(ATitle));
    lStmt.Bind(4, StringToUtf8(AContent));
    try
      lStmt.Step;
    except
      on E: Exception do
        raise Exception.CreateFmt(
          'Embedding konnte nicht erzeugt/gespeichert werden (Modell: %s, Dimensionen: %d): %s',
          [FModelName, FEmbeddingDimensions, E.Message]
        );
    end;
  finally
    lStmt.Close;
  end;
end;

function TSemanticDocumentSearch.Search(const AQuery: string; ALimit: Integer): TRawUtf8DynArray;
var
  lStmt: TSQLRequest;
  lIndex: Integer;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  SetLength(Result, 0);
  lIndex := 0;
  
  lStmt.Prepare(FDatabase.DB,
    'WITH matches AS ( ' +
    '  SELECT rowid, distance ' +
    '  FROM vec_documents ' +
    '  WHERE embedding MATCH lembed(?, ?) ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT ' +
    '  d.id, ' +
    '  d.title, ' +
    '  d.content, ' +
    '  m.distance, ' +
    '  d.created_at ' +
    'FROM matches m ' +
    'JOIN documents d ON d.id = m.rowid ' +
    'ORDER BY m.distance;'
  );
  
  try
    lStmt.Bind(1, StringToUtf8(FModelName));
    lStmt.Bind(2, StringToUtf8(AQuery));
    lStmt.Bind(3, ALimit);
    
    try
      while lStmt.Step = SQLITE_ROW do
      begin
        SetLength(Result, lIndex + 1);
        Result[lIndex] := FormatUtf8(
          'ID: % | Title: % | Distance: % | Date: %',
          [lStmt.FieldInt(0), lStmt.FieldS(1), lStmt.FieldS(3), lStmt.FieldS(4)]
        );
        Inc(lIndex);
      end;
    except
      on E: Exception do
        raise Exception.CreateFmt(
          'Semantische Suche fehlgeschlagen (Modell: %s, Dimensionen: %d, Limit: %d): %s',
          [FModelName, FEmbeddingDimensions, ALimit, E.Message]
        );
    end;
  finally
    lStmt.Close;
  end;
end;

function TSemanticDocumentSearch.FindSimilar(ADocumentId: Int64; ALimit: Integer): TRawUtf8DynArray;
var
  lStmt: TSQLRequest;
  lIndex: Integer;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  SetLength(Result, 0);
  lIndex := 0;
  
  // Finde Dokumente mit ähnlichen Embeddings
  lStmt.Prepare(FDatabase.DB,
    'WITH source_embedding AS ( ' +
    '  SELECT embedding AS query_embedding FROM vec_documents WHERE rowid = ? ' +
    '), ' +
    'matches AS ( ' +
    '  SELECT vec_documents.rowid, distance ' +
    '  FROM vec_documents, source_embedding ' +
    '  WHERE vec_documents.rowid != ? ' +
    '    AND embedding MATCH source_embedding.query_embedding ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT d.id, d.title, m.distance ' +
    'FROM matches m ' +
    'JOIN documents d ON d.id = m.rowid;'
  );
  
  try
    lStmt.Bind(1, ADocumentId);
    lStmt.Bind(2, ADocumentId);
    lStmt.Bind(3, ALimit);
    
    try
      while lStmt.Step = SQLITE_ROW do
      begin
        SetLength(Result, lIndex + 1);
        Result[lIndex] := FormatUtf8(
          'ID: % | Title: % | Distance: %',
          [lStmt.FieldInt(0), lStmt.FieldS(1), lStmt.FieldS(2)]
        );
        Inc(lIndex);
      end;
    except
      on E: Exception do
        raise Exception.CreateFmt(
          'Aehnlichkeitssuche fehlgeschlagen (Dokument-ID: %d, Limit: %d): %s',
          [ADocumentId, ALimit, E.Message]
        );
    end;
  finally
    lStmt.Close;
  end;
end;

procedure TSemanticDocumentSearch.DeleteDocument(ADocumentId: Int64);
var
  lStmt: TSQLRequest;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  // Embedding löschen
  lStmt.Prepare(FDatabase.DB, 'DELETE FROM vec_documents WHERE rowid = ?;');
  try
    lStmt.Bind(1, ADocumentId);
    lStmt.Step;
  finally
    lStmt.Close;
  end;
  
  // Dokument löschen
  lStmt.Prepare(FDatabase.DB, 'DELETE FROM documents WHERE id = ?;');
  try
    lStmt.Bind(1, ADocumentId);
    lStmt.Step;
  finally
    lStmt.Close;
  end;
end;

function TSemanticDocumentSearch.GetStats: string;
var
  lStmt: TSQLRequest;
  lDocCount, lVecCount: Int64;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  // Dokumente zählen
  lStmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM documents;');
  try
    if lStmt.Step = SQLITE_ROW then
      lDocCount := lStmt.FieldInt(0);
  finally
    lStmt.Close;
  end;
  
  // Embeddings zählen
  lStmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM vec_documents;');
  try
    if lStmt.Step = SQLITE_ROW then
      lVecCount := lStmt.FieldInt(0);
  finally
    lStmt.Close;
  end;
  
  Result := Format(
    'Statistiken:' + sLineBreak +
    '  Dokumente: %d' + sLineBreak +
    '  Embeddings: %d' + sLineBreak +
    '  Modell: %s' + sLineBreak +
    '  Dimensionen: %d',
    [lDocCount, lVecCount, FModelName, FEmbeddingDimensions]
  );
end;

end.
