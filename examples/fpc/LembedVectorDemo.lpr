program LembedVectorDemo;

{$I ../../lib-source/mORMot2/src/mormot.defines.inc}

uses
  {$I ../../lib-source/mORMot2/src/mormot.uses.inc}
  {$ifdef UNIX}
  cwstring,
  {$endif UNIX}
  SysUtils,
  mormot.core.base,
  mormot.core.os,
  mormot.core.text,
  mormot.core.unicode,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static;

type
  TSemanticDocumentSearch = class
  private
    FDatabase: TSqlDataBase;
    FRepoRoot: TFileName;
    FModelName: string;
    FModelPath: TFileName;
    FEmbeddingDimensions: Integer;
    FInitialized: Boolean;
    procedure EnableExtensionLoading;
    procedure LoadExtension(const AFileName: TFileName);
    procedure LoadExtensions;
    procedure RegisterModel;
  public
    constructor Create(const ADBPath, ARepoRoot: TFileName);
    destructor Destroy; override;
    procedure Initialize(const AModelPath: TFileName; const AModelName: string;
      AEmbeddingDimensions: Integer);
    function AddDocument(const ATitle, AContent: string): Int64;
    function Search(const AQuery: string; ALimit: Integer): TRawUtf8DynArray;
    function FindSimilar(ADocumentId: Int64; ALimit: Integer): TRawUtf8DynArray;
    procedure DeleteDocument(ADocumentId: Int64);
    function GetLembedVersion: string;
    function GetStats: string;
  end;

function PathJoin(const A, B: TFileName): TFileName;
begin
  Result := IncludeTrailingPathDelimiter(A) + B;
end;

function FindRepoRoot: TFileName;
var
  Dir: TFileName;
  I: Integer;
begin
  Dir := ExpandFileName(ExtractFilePath(ParamStr(0)));
  for I := 0 to 8 do
  begin
    if DirectoryExists(PathJoin(Dir, 'lib')) and
       DirectoryExists(PathJoin(Dir, 'lib-source')) then
      Exit(ExcludeTrailingPathDelimiter(Dir));
    Dir := ExpandFileName(PathJoin(Dir, '..'));
  end;
  Result := GetCurrentDir;
end;

function RequireFile(const AFileName: TFileName): TFileName;
begin
  Result := ExpandFileName(AFileName);
  if not FileExists(Result) then
    raise Exception.CreateFmt('Datei nicht gefunden: %s', [Result]);
end;

{ TSemanticDocumentSearch }

constructor TSemanticDocumentSearch.Create(const ADBPath, ARepoRoot: TFileName);
begin
  inherited Create;
  FRepoRoot := ARepoRoot;
  FDatabase := TSqlDataBase.Create(ADBPath, '');
  FEmbeddingDimensions := 1024;
end;

destructor TSemanticDocumentSearch.Destroy;
begin
  FDatabase.Free;
  inherited Destroy;
end;

procedure TSemanticDocumentSearch.EnableExtensionLoading;
var
  ResultCode: Integer;
  Enabled: Integer;
begin
  if not Assigned(sqlite3.db_config) then
    raise Exception.Create('sqlite3_db_config ist nicht verfuegbar.');

  Enabled := 0;
  ResultCode := sqlite3.db_config(
    FDatabase.DB,
    SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION,
    1,
    @Enabled);

  if ResultCode <> SQLITE_OK then
    raise Exception.CreateFmt('Extension loading konnte nicht aktiviert werden: %s',
      [Utf8ToString(sqlite3.errmsg(FDatabase.DB))]);
end;

procedure TSemanticDocumentSearch.LoadExtension(const AFileName: TFileName);
var
  Msg: PUtf8Char;
  ErrorText: string;
  ResultCode: Integer;
  Utf8FileName: RawUtf8;
begin
  Msg := nil;
  Utf8FileName := StringToUtf8(AFileName);
  ResultCode := sqlite3.load_extension(
    FDatabase.DB,
    PUtf8Char(pointer(Utf8FileName)),
    nil,
    Msg);

  if ResultCode = SQLITE_OK then
    Exit;

  if Msg <> nil then
  begin
    ErrorText := Utf8ToString(Msg);
    sqlite3.free_(Msg);
  end
  else
    ErrorText := Utf8ToString(sqlite3.errmsg(FDatabase.DB));

  raise Exception.CreateFmt('Fehler beim Laden von %s: %s',
    [AFileName, ErrorText]);
end;

procedure TSemanticDocumentSearch.LoadExtensions;
var
  LembedPath: TFileName;
  VecPath: TFileName;
begin
  LembedPath := RequireFile(PathJoin(FRepoRoot,
    'lib/sqlite-lembed/aarch64-linux/lembed0.so'));
  VecPath := RequireFile(PathJoin(FRepoRoot,
    'lib/sqlite-vec/aarch64-linux/vec0.so'));

  EnableExtensionLoading;
  LoadExtension(LembedPath);
  LoadExtension(VecPath);
end;

procedure TSemanticDocumentSearch.RegisterModel;
var
  Count: Int64;
  Stmt: TSqlRequest;
begin
  Stmt.Prepare(FDatabase.DB,
    'INSERT INTO temp.lembed_models(name, model) ' +
    'VALUES (?, lembed_model_from_file(?));');
  try
    Stmt.Bind(1, StringToUtf8(FModelName));
    Stmt.Bind(2, StringToUtf8(FModelPath));
    Stmt.Step;
  finally
    Stmt.Close;
  end;

  Count := 0;
  Stmt.Prepare(FDatabase.DB,
    'SELECT COUNT(*) FROM temp.lembed_models WHERE name = ?;');
  try
    Stmt.Bind(1, StringToUtf8(FModelName));
    if Stmt.Step = SQLITE_ROW then
      Count := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  if Count <> 1 then
    raise Exception.CreateFmt('Modell "%s" wurde nicht registriert.',
      [FModelName]);
end;

procedure TSemanticDocumentSearch.Initialize(const AModelPath: TFileName;
  const AModelName: string; AEmbeddingDimensions: Integer);
begin
  if FInitialized then
    Exit;

  FModelPath := RequireFile(AModelPath);
  FModelName := AModelName;
  FEmbeddingDimensions := AEmbeddingDimensions;

  if FEmbeddingDimensions <= 0 then
    raise Exception.CreateFmt('Ungueltige Embedding-Dimension: %d',
      [FEmbeddingDimensions]);

  LoadExtensions;
  RegisterModel;

  FDatabase.Execute(
    'CREATE TABLE IF NOT EXISTS documents(' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  title TEXT NOT NULL,' +
    '  content TEXT NOT NULL,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ');');

  FDatabase.Execute(
    'CREATE VIRTUAL TABLE IF NOT EXISTS vec_documents USING vec0(' +
    '  embedding float[' + IntToStr(FEmbeddingDimensions) + ']' +
    ');');

  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_doc_created ON documents(created_at);');
  FInitialized := True;
end;

function TSemanticDocumentSearch.AddDocument(const ATitle, AContent: string): Int64;
var
  Stmt: TSqlRequest;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');

  Stmt.Prepare(FDatabase.DB,
    'INSERT INTO documents(title, content) VALUES (?, ?);');
  try
    Stmt.Bind(1, StringToUtf8(ATitle));
    Stmt.Bind(2, StringToUtf8(AContent));
    Stmt.Step;
  finally
    Stmt.Close;
  end;

  Result := FDatabase.LastInsertRowID;

  Stmt.Prepare(FDatabase.DB,
    'INSERT INTO vec_documents(rowid, embedding) ' +
    'SELECT ?, lembed(?, ? || '' '' || ?);');
  try
    Stmt.Bind(1, Result);
    Stmt.Bind(2, StringToUtf8(FModelName));
    Stmt.Bind(3, StringToUtf8(ATitle));
    Stmt.Bind(4, StringToUtf8(AContent));
    Stmt.Step;
  finally
    Stmt.Close;
  end;
end;

function TSemanticDocumentSearch.Search(const AQuery: string;
  ALimit: Integer): TRawUtf8DynArray;
var
  Stmt: TSqlRequest;
  Index: Integer;
begin
  SetLength(Result, 0);
  Index := 0;

  Stmt.Prepare(FDatabase.DB,
    'WITH matches AS ( ' +
    '  SELECT rowid, distance ' +
    '  FROM vec_documents ' +
    '  WHERE embedding MATCH lembed(?, ?) ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT d.id, d.title, m.distance, d.created_at ' +
    'FROM matches m JOIN documents d ON d.id = m.rowid ' +
    'ORDER BY m.distance;');
  try
    Stmt.Bind(1, StringToUtf8(FModelName));
    Stmt.Bind(2, StringToUtf8(AQuery));
    Stmt.Bind(3, ALimit);
    while Stmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, Index + 1);
      Result[Index] := FormatUtf8(
        'ID: % | Title: % | Distance: % | Date: %',
        [Stmt.FieldInt(0), Stmt.FieldS(1), Stmt.FieldS(2), Stmt.FieldS(3)]);
      Inc(Index);
    end;
  finally
    Stmt.Close;
  end;
end;

function TSemanticDocumentSearch.FindSimilar(ADocumentId: Int64;
  ALimit: Integer): TRawUtf8DynArray;
var
  Stmt: TSqlRequest;
  Index: Integer;
begin
  SetLength(Result, 0);
  Index := 0;

  Stmt.Prepare(FDatabase.DB,
    'WITH source_embedding AS ( ' +
    '  SELECT embedding AS query_embedding FROM vec_documents WHERE rowid = ? ' +
    '), matches AS ( ' +
    '  SELECT vec_documents.rowid, distance ' +
    '  FROM vec_documents, source_embedding ' +
    '  WHERE vec_documents.rowid != ? ' +
    '    AND embedding MATCH source_embedding.query_embedding ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT d.id, d.title, m.distance ' +
    'FROM matches m JOIN documents d ON d.id = m.rowid;');
  try
    Stmt.Bind(1, ADocumentId);
    Stmt.Bind(2, ADocumentId);
    Stmt.Bind(3, ALimit);
    while Stmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, Index + 1);
      Result[Index] := FormatUtf8(
        'ID: % | Title: % | Distance: %',
        [Stmt.FieldInt(0), Stmt.FieldS(1), Stmt.FieldS(2)]);
      Inc(Index);
    end;
  finally
    Stmt.Close;
  end;
end;

procedure TSemanticDocumentSearch.DeleteDocument(ADocumentId: Int64);
var
  Stmt: TSqlRequest;
begin
  Stmt.Prepare(FDatabase.DB, 'DELETE FROM vec_documents WHERE rowid = ?;');
  try
    Stmt.Bind(1, ADocumentId);
    Stmt.Step;
  finally
    Stmt.Close;
  end;

  Stmt.Prepare(FDatabase.DB, 'DELETE FROM documents WHERE id = ?;');
  try
    Stmt.Bind(1, ADocumentId);
    Stmt.Step;
  finally
    Stmt.Close;
  end;
end;

function TSemanticDocumentSearch.GetLembedVersion: string;
var
  Stmt: TSqlRequest;
begin
  Result := '';
  Stmt.Prepare(FDatabase.DB, 'SELECT lembed_version();');
  try
    if Stmt.Step = SQLITE_ROW then
      Result := Utf8ToString(Stmt.FieldS(0));
  finally
    Stmt.Close;
  end;
end;

function TSemanticDocumentSearch.GetStats: string;
var
  Stmt: TSqlRequest;
  DocCount: Int64;
  VecCount: Int64;
begin
  DocCount := 0;
  VecCount := 0;

  Stmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM documents;');
  try
    if Stmt.Step = SQLITE_ROW then
      DocCount := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  Stmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM vec_documents;');
  try
    if Stmt.Step = SQLITE_ROW then
      VecCount := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  Result := Format(
    'Dokumente: %d' + LineEnding +
    'Embeddings: %d' + LineEnding +
    'Modell: %s' + LineEnding +
    'Dimensionen: %d',
    [DocCount, VecCount, FModelName, FEmbeddingDimensions]);
end;

procedure PrintResults(const AResults: TRawUtf8DynArray);
var
  I: Integer;
begin
  for I := 0 to High(AResults) do
    WriteLn('  ', Utf8ToString(AResults[I]));
end;

procedure AddDemoDocuments(ASearch: TSemanticDocumentSearch; out AWebDocId: Int64);
begin
  ASearch.AddDocument('Introduction to Machine Learning',
    'Machine learning is a subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed.');
  ASearch.AddDocument('Python Programming Basics',
    'Python is a high-level programming language known for its simplicity and readability. It is widely used in web development, data science, and automation.');
  ASearch.AddDocument('Database Management Systems',
    'A database management system is software that interacts with users, applications, and the database itself to capture and analyze data.');
  ASearch.AddDocument('Neural Networks Explained',
    'Neural networks are computing systems inspired by biological neural networks. They are used in deep learning and can recognize patterns in data.');
  AWebDocId := ASearch.AddDocument('Web Development with JavaScript',
    'JavaScript is a versatile programming language essential for creating interactive web pages. It runs in the browser and enables dynamic content.');
  ASearch.AddDocument('Cloud Computing Overview',
    'Cloud computing delivers computing services over the internet, including storage, processing power, and software applications on demand.');
end;

procedure RunDemo;
const
  CModelFile = 'bge-m3-q8_0.gguf';
  CModelName = 'bge-m3';
  CModelDimensions = 1024;
var
  RepoRoot: TFileName;
  DBPath: TFileName;
  ModelPath: TFileName;
  Searcher: TSemanticDocumentSearch;
  WebDocId: Int64;
  Results: TRawUtf8DynArray;
begin
  RepoRoot := FindRepoRoot;
  DBPath := PathJoin(RepoRoot, 'examples/fpc/demo_semantic_search.db');
  ModelPath := PathJoin(RepoRoot, 'examples/fpc/' + CModelFile);
  if not FileExists(ModelPath) then
    ModelPath := PathJoin(RepoRoot, CModelFile);

  WriteLn('SQLite lembed + vec0 FPC Demo - Dokumentensuche');
  WriteLn('Modell: ', CModelName, ' (', CModelDimensions, ' Dimensionen)');
  WriteLn('Repo: ', RepoRoot);
  WriteLn;

  DeleteFile(DBPath);
  Searcher := TSemanticDocumentSearch.Create(DBPath, RepoRoot);
  try
    WriteLn('[1/5] Initialisiere Datenbank und lade BGE-M3...');
    Searcher.Initialize(ModelPath, CModelName, CModelDimensions);
    WriteLn('      Initialisierung abgeschlossen');
    WriteLn('      sqlite-lembed Version: ', Searcher.GetLembedVersion);
    WriteLn;

    WriteLn('[2/5] Fuege Beispiel-Dokumente hinzu...');
    AddDemoDocuments(Searcher, WebDocId);
    WriteLn('      6 Dokumente hinzugefuegt');
    WriteLn;

    WriteLn('[3/5] Statistiken:');
    WriteLn(Searcher.GetStats);
    WriteLn;

    WriteLn('[4/5] Semantische Suche');
    WriteLn('=== Suche 1: "artificial intelligence and neural networks" ===');
    Results := Searcher.Search('artificial intelligence and neural networks', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('=== Suche 2: "programming languages for beginners" ===');
    Results := Searcher.Search('programming languages for beginners', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('=== Suche 3: "data storage solutions" ===');
    Results := Searcher.Search('data storage solutions', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('[5/5] Aehnliche Dokumente zu "Web Development with JavaScript"');
    Results := Searcher.FindSimilar(WebDocId, 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('Loesche Dokument mit ID 3...');
    Searcher.DeleteDocument(3);
    WriteLn(Searcher.GetStats);
  finally
    WriteLn;
    WriteLn('Raeume Modell und Datenbank auf...');
    Searcher.Free;
    WriteLn('Aufraeumen abgeschlossen');
  end;

  WriteLn;
  WriteLn('Demo abgeschlossen. Datenbank: ', DBPath);
end;

begin
  try
    RunDemo;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('FEHLER: ', E.Message);
      WriteLn;
      WriteLn('Hinweise:');
      WriteLn('  1. BGE-M3-Modell nach examples/fpc oder ins Repo-Root kopieren:');
      WriteLn('     bge-m3-q8_0.gguf');
      WriteLn('  2. Linux-Binaries bauen:');
      WriteLn('     powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed-wsl.ps1');
      WriteLn('     powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec-wsl.ps1');
      WriteLn('  3. Demo ueber examples/fpc/run-lembed-vector-demo.sh starten.');
      Halt(1);
    end;
  end;
end.
