unit VectorLembedExample;

interface

uses
  System.SysUtils, System.Classes,
  mormot.db.sql, mormot.db.raw.sqlite3, mormot.db.raw.sqlite3.static,
  mormot.core.base, mormot.core.unicode, mormot.core.text;

type
  /// <summary>
  /// Beispiel-Klasse für semantische Produktsuche mit lembed + sqlite-vector
  /// Nutzt Quantisierung für 4-5x schnellere Suche bei großen Datenmengen
  /// </summary>
  TProductSemanticSearch = class
  private
    FDatabase: TSQLDatabase;
    FModelName: string;
    FModelPath: string;
    FInitialized: Boolean;
    FQuantized: Boolean;
    procedure LoadExtensions;
    procedure RegisterModel;
  public
    constructor Create(const ADBPath: string);
    destructor Destroy; override;
    
    /// <summary>
    /// Initialisiert die Datenbank mit Tabellen und Modell
    /// </summary>
    procedure Initialize(const AModelPath: string; const AModelName: string = 'embedder');
    
    /// <summary>
    /// Fügt ein Produkt hinzu und generiert automatisch das Embedding
    /// </summary>
    function AddProduct(const AName, ADescription, ACategory: string; APrice: Currency): Int64;
    
    /// <summary>
    /// Quantisiert alle Embeddings für 4-5x schnellere Suche
    /// Sollte nach dem Hinzufügen vieler Produkte aufgerufen werden
    /// </summary>
    procedure QuantizeEmbeddings;
    
    /// <summary>
    /// Lädt quantisierte Embeddings in den Speicher für maximale Geschwindigkeit
    /// </summary>
    procedure PreloadQuantized;
    
    /// <summary>
    /// Führt eine semantische Produktsuche durch
    /// AUseQuantized: True = 4-5x schneller, leicht reduzierte Genauigkeit
    /// </summary>
    function SearchProducts(const AQuery: string; ALimit: Integer = 10; 
                           AUseQuantized: Boolean = True): TRawUtf8DynArray;
    
    /// <summary>
    /// Findet ähnliche Produkte zu einem gegebenen Produkt
    /// </summary>
    function FindSimilarProducts(AProductId: Int64; ALimit: Integer = 5;
                                AUseQuantized: Boolean = True): TRawUtf8DynArray;
    
    /// <summary>
    /// Sucht Produkte nach Kategorie mit semantischer Sortierung
    /// </summary>
    function SearchByCategory(const ACategory, AQuery: string; 
                             ALimit: Integer = 10): TRawUtf8DynArray;
    
    /// <summary>
    /// Löscht ein Produkt
    /// </summary>
    procedure DeleteProduct(AProductId: Int64);
    
    /// <summary>
    /// Gibt Statistiken über die Datenbank zurück
    /// </summary>
    function GetStats: string;
    
    property Quantized: Boolean read FQuantized;
  end;

implementation

uses
  sqliteVecForDelphi;

{ TProductSemanticSearch }

constructor TProductSemanticSearch.Create(const ADBPath: string);
begin
  inherited Create;
  FDatabase := TSQLDatabase.Create(ADBPath, '');
  FInitialized := False;
  FQuantized := False;
end;

destructor TProductSemanticSearch.Destroy;
begin
  FDatabase.Free;
  inherited;
end;

procedure TProductSemanticSearch.LoadExtensions;
begin
  // Extensions aus Ressourcen extrahieren
  TSQLDatabaseVectorHelper.ExtractLembed0Dll;
  TSQLDatabaseVectorHelper.ExtractVectorDll;
  
  // Extension loading aktivieren
  TSQLDatabaseVectorHelper.EnableExtensionLoading(FDatabase.DB);
  
  // lembed0.dll laden
  TSQLDatabaseVectorHelper.LoadExtension(FDatabase.DB, 'lembed0.dll');
    
  // vector.dll laden (sqlite-vector, nicht vec0!)
  TSQLDatabaseVectorHelper.LoadExtension(FDatabase.DB, 'vector.dll');
end;

procedure TProductSemanticSearch.RegisterModel;
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
    lStmt.Step;
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

procedure TProductSemanticSearch.Initialize(const AModelPath, AModelName: string);
begin
  if FInitialized then
    Exit;
    
  FModelPath := AModelPath;
  FModelName := AModelName;

  if not FileExists(FModelPath) then
    raise Exception.CreateFmt('Modelldatei nicht gefunden: %s', [FModelPath]);
  
  // Extensions laden
  LoadExtensions;
  
  // Modell registrieren
  RegisterModel;
  
  // Produkte-Tabelle erstellen (normale SQLite-Tabelle)
  FDatabase.Execute(
    'CREATE TABLE IF NOT EXISTS products(' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  description TEXT NOT NULL,' +
    '  category TEXT NOT NULL,' +
    '  price REAL NOT NULL,' +
    '  embedding BLOB,' +  // BLOB für vector.dll (statt virtuelle Tabelle)
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ');'
  );
  
  // Indizes für bessere Performance
  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_prod_category ON products(category);');
  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_prod_price ON products(price);');
  
  // Vector initialisieren (all-MiniLM-L6-v2 = 384 Dimensionen, FLOAT32)
  // Distance-Metriken: L2 (default), L1, COSINE, DOT, SQUARED_L2
  FDatabase.Execute(
    'SELECT vector_init(''products'', ''embedding'', ''type=FLOAT32,dimension=384,distance=L2'');'
  );
  
  FInitialized := True;
end;

function TProductSemanticSearch.AddProduct(const AName, ADescription, 
  ACategory: string; APrice: Currency): Int64;
var
  lStmt: TSQLRequest;
  lFullText: RawUtf8;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert. Rufe Initialize() auf.');
    
  // Kombiniere alle Textfelder für besseres Embedding
  lFullText := StringToUtf8(Format('%s. %s. Category: %s', [AName, ADescription, ACategory]));
  
  // Produkt mit Embedding einfügen
  lStmt.Prepare(FDatabase.DB,
    'INSERT INTO products(name, description, category, price, embedding) ' +
    'VALUES (?, ?, ?, ?, lembed(?, ?));'
  );
  
  try
    lStmt.Bind(1, StringToUtf8(AName));
    lStmt.Bind(2, StringToUtf8(ADescription));
    lStmt.Bind(3, StringToUtf8(ACategory));
    lStmt.Bind(4, APrice);
    lStmt.Bind(5, StringToUtf8(FModelName));
    lStmt.Bind(6, lFullText);
    
    lStmt.Step;
  finally
    lStmt.Close;
  end;
  
  // ID des eingefügten Produkts
  Result := FDatabase.LastInsertRowID;
  
  // Nach jedem Insert: Quantisierung wird ungültig
  FQuantized := False;
end;

procedure TProductSemanticSearch.QuantizeEmbeddings;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  // Quantisierung durchführen (reduziert Speicher und erhöht Geschwindigkeit)
  // Konvertiert FLOAT32 → INT8 mit minimaler Genauigkeitseinbuße
  FDatabase.Execute('SELECT vector_quantize(''products'', ''embedding'');');
  
  FQuantized := True;
end;

procedure TProductSemanticSearch.PreloadQuantized;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  if not FQuantized then
    raise Exception.Create('Embeddings müssen zuerst quantisiert werden (QuantizeEmbeddings).');
    
  // Lädt quantisierte Version in den Speicher für 4-5x Geschwindigkeitssteigerung
  FDatabase.Execute('SELECT vector_quantize_preload(''products'', ''embedding'');');
end;

function TProductSemanticSearch.SearchProducts(const AQuery: string; 
  ALimit: Integer; AUseQuantized: Boolean): TRawUtf8DynArray;
var
  lStmt: TSQLRequest;
  lIndex: Integer;
  lSQL: RawUtf8;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  SetLength(Result, 0);
  lIndex := 0;
  
  if AUseQuantized and FQuantized then
  begin
    // Quantisierte Suche (4-5x schneller)
    lSQL := 
      'SELECT ' +
      '  p.id, ' +
      '  p.name, ' +
      '  p.description, ' +
      '  p.category, ' +
      '  p.price, ' +
      '  v.distance ' +
      'FROM products AS p ' +
      'JOIN vector_quantize_scan(''products'', ''embedding'', lembed(?, ?), ?) AS v ' +
      '  ON p.id = v.rowid ' +
      'ORDER BY v.distance;';
      
    lStmt.Prepare(FDatabase.DB, lSQL);
    lStmt.Bind(1, StringToUtf8(FModelName));
    lStmt.Bind(2, StringToUtf8(AQuery));
    lStmt.Bind(3, ALimit);
  end
  else
  begin
    // Normale Suche (präziser, aber langsamer)
    lSQL :=
      'SELECT ' +
      '  p.id, ' +
      '  p.name, ' +
      '  p.description, ' +
      '  p.category, ' +
      '  p.price, ' +
      '  vector_distance(p.embedding, lembed(?, ?)) as distance ' +
      'FROM products AS p ' +
      'WHERE p.embedding IS NOT NULL ' +
      'ORDER BY distance ' +
      'LIMIT ?;';
      
    lStmt.Prepare(FDatabase.DB, lSQL);
    lStmt.Bind(1, StringToUtf8(FModelName));
    lStmt.Bind(2, StringToUtf8(AQuery));
    lStmt.Bind(3, ALimit);
  end;
  
  try
    while lStmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, lIndex + 1);
      Result[lIndex] := FormatUtf8(
        'ID: % | Name: % | Category: % | Price: %.2f € | Distance: %',
        [lStmt.FieldInt(0), lStmt.FieldS(1), lStmt.FieldS(3), 
         lStmt.FieldDouble(4), lStmt.FieldS(5)]
      );
      Inc(lIndex);
    end;
  finally
    lStmt.Close;
  end;
end;

function TProductSemanticSearch.FindSimilarProducts(AProductId: Int64; 
  ALimit: Integer; AUseQuantized: Boolean): TRawUtf8DynArray;
var
  lStmt: TSQLRequest;
  lIndex: Integer;
  lSQL: RawUtf8;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  SetLength(Result, 0);
  lIndex := 0;
  
  if AUseQuantized and FQuantized then
  begin
    // Quantisierte Ähnlichkeitssuche
    lSQL :=
      'WITH source_product AS ( ' +
      '  SELECT embedding FROM products WHERE id = ? ' +
      ') ' +
      'SELECT ' +
      '  p.id, ' +
      '  p.name, ' +
      '  p.category, ' +
      '  p.price, ' +
      '  v.distance ' +
      'FROM products AS p ' +
      'JOIN source_product AS s ' +
      'JOIN vector_quantize_scan(''products'', ''embedding'', s.embedding, ? + 1) AS v ' +
      '  ON p.id = v.rowid ' +
      'WHERE p.id != ? ' +
      'ORDER BY v.distance ' +
      'LIMIT ?;';
      
    lStmt.Prepare(FDatabase.DB, lSQL);
    lStmt.Bind(1, AProductId);
    lStmt.Bind(2, ALimit);
    lStmt.Bind(3, AProductId);
    lStmt.Bind(4, ALimit);
  end
  else
  begin
    // Normale Ähnlichkeitssuche
    lSQL :=
      'WITH source_product AS ( ' +
      '  SELECT embedding FROM products WHERE id = ? ' +
      ') ' +
      'SELECT ' +
      '  p.id, ' +
      '  p.name, ' +
      '  p.category, ' +
      '  p.price, ' +
      '  vector_distance(p.embedding, s.embedding) as distance ' +
      'FROM products AS p, source_product AS s ' +
      'WHERE p.id != ? ' +
      '  AND p.embedding IS NOT NULL ' +
      'ORDER BY distance ' +
      'LIMIT ?;';
      
    lStmt.Prepare(FDatabase.DB, lSQL);
    lStmt.Bind(1, AProductId);
    lStmt.Bind(2, AProductId);
    lStmt.Bind(3, ALimit);
  end;
  
  try
    while lStmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, lIndex + 1);
      Result[lIndex] := FormatUtf8(
        'ID: % | Name: % | Category: % | Price: %.2f € | Distance: %',
        [lStmt.FieldInt(0), lStmt.FieldS(1), lStmt.FieldS(2), 
         lStmt.FieldDouble(3), lStmt.FieldS(4)]
      );
      Inc(lIndex);
    end;
  finally
    lStmt.Close;
  end;
end;

function TProductSemanticSearch.SearchByCategory(const ACategory, AQuery: string; 
  ALimit: Integer): TRawUtf8DynArray;
var
  lStmt: TSQLRequest;
  lIndex: Integer;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  SetLength(Result, 0);
  lIndex := 0;
  
  // Kombiniere Kategorie-Filter mit semantischer Suche
  lStmt.Prepare(FDatabase.DB,
    'SELECT ' +
    '  p.id, ' +
    '  p.name, ' +
    '  p.description, ' +
    '  p.price, ' +
    '  vector_distance(p.embedding, lembed(?, ?)) as distance ' +
    'FROM products AS p ' +
    'WHERE p.category = ? ' +
    '  AND p.embedding IS NOT NULL ' +
    'ORDER BY distance ' +
    'LIMIT ?;'
  );
  
  try
    lStmt.Bind(1, StringToUtf8(FModelName));
    lStmt.Bind(2, StringToUtf8(AQuery));
    lStmt.Bind(3, StringToUtf8(ACategory));
    lStmt.Bind(4, ALimit);
    
    while lStmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, lIndex + 1);
      Result[lIndex] := FormatUtf8(
        'ID: % | Name: % | Price: %.2f € | Distance: %',
        [lStmt.FieldInt(0), lStmt.FieldS(1), lStmt.FieldDouble(3), lStmt.FieldS(4)]
      );
      Inc(lIndex);
    end;
  finally
    lStmt.Close;
  end;
end;

procedure TProductSemanticSearch.DeleteProduct(AProductId: Int64);
var
  lStmt: TSQLRequest;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  lStmt.Prepare(FDatabase.DB, 'DELETE FROM products WHERE id = ?;');
  try
    lStmt.Bind(1, AProductId);
    lStmt.Step;
  finally
    lStmt.Close;
  end;
  
  // Quantisierung muss neu gemacht werden
  FQuantized := False;
end;

function TProductSemanticSearch.GetStats: string;
var
  lStmt: TSQLRequest;
  lProdCount: Int64;
  lCategories: Integer;
  lAvgPrice: Double;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');
    
  // Produkte zählen
  lStmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM products;');
  try
    if lStmt.Step = SQLITE_ROW then
      lProdCount := lStmt.FieldInt(0);
  finally
    lStmt.Close;
  end;
  
  // Kategorien zählen
  lStmt.Prepare(FDatabase.DB, 'SELECT COUNT(DISTINCT category) FROM products;');
  try
    if lStmt.Step = SQLITE_ROW then
      lCategories := lStmt.FieldInt(0);
  finally
    lStmt.Close;
  end;
  
  // Durchschnittspreis
  lStmt.Prepare(FDatabase.DB, 'SELECT AVG(price) FROM products;');
  try
    if lStmt.Step = SQLITE_ROW then
      lAvgPrice := lStmt.FieldDouble(0);
  finally
    lStmt.Close;
  end;
  
  Result := Format(
    'Statistiken:' + sLineBreak +
    '  Produkte: %d' + sLineBreak +
    '  Kategorien: %d' + sLineBreak +
    '  Durchschnittspreis: %.2f €' + sLineBreak +
    '  Modell: %s' + sLineBreak +
    '  Quantisiert: %s',
    [lProdCount, lCategories, lAvgPrice, FModelName, 
     BoolToStr(FQuantized, True)]
  );
end;

end.
