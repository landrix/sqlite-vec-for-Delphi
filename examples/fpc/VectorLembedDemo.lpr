program VectorLembedDemo;

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
  TProductSemanticSearch = class
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
    function AddProduct(const AName, ADescription, ACategory: string;
      APrice: Currency): Int64;
    function SearchProducts(const AQuery: string; ALimit: Integer): TRawUtf8DynArray;
    function FindSimilarProducts(AProductId: Int64; ALimit: Integer): TRawUtf8DynArray;
    function SearchByCategory(const ACategory, AQuery: string;
      ALimit: Integer): TRawUtf8DynArray;
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

function SqlQuote(const S: string): RawUtf8;
begin
  Result := StringToUtf8(StringReplace(S, '''', '''''', [rfReplaceAll]));
end;

{ TProductSemanticSearch }

constructor TProductSemanticSearch.Create(const ADBPath, ARepoRoot: TFileName);
begin
  inherited Create;
  FRepoRoot := ARepoRoot;
  FDatabase := TSqlDataBase.Create(ADBPath, '');
  FEmbeddingDimensions := 384;
end;

destructor TProductSemanticSearch.Destroy;
begin
  FDatabase.Free;
  inherited Destroy;
end;

procedure TProductSemanticSearch.EnableExtensionLoading;
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

procedure TProductSemanticSearch.LoadExtension(const AFileName: TFileName);
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

procedure TProductSemanticSearch.LoadExtensions;
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

procedure TProductSemanticSearch.RegisterModel;
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

procedure TProductSemanticSearch.Initialize(const AModelPath: TFileName;
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
    'CREATE TABLE IF NOT EXISTS products(' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  description TEXT NOT NULL,' +
    '  category TEXT NOT NULL,' +
    '  price REAL NOT NULL,' +
    '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
    ');');

  FDatabase.Execute(
    'CREATE VIRTUAL TABLE IF NOT EXISTS vec_products USING vec0(' +
    '  embedding float[' + IntToStr(FEmbeddingDimensions) + ']' +
    ');');

  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_prod_category ON products(category);');
  FDatabase.Execute('CREATE INDEX IF NOT EXISTS idx_prod_price ON products(price);');

  FInitialized := True;
end;

function TProductSemanticSearch.AddProduct(const AName, ADescription,
  ACategory: string; APrice: Currency): Int64;
var
  Stmt: TSqlRequest;
  FullText: RawUtf8;
begin
  if not FInitialized then
    raise Exception.Create('Datenbank nicht initialisiert.');

  Stmt.Prepare(FDatabase.DB,
    'INSERT INTO products(name, description, category, price) VALUES (?, ?, ?, ?);');
  try
    Stmt.Bind(1, StringToUtf8(AName));
    Stmt.Bind(2, StringToUtf8(ADescription));
    Stmt.Bind(3, StringToUtf8(ACategory));
    Stmt.Bind(4, Double(APrice));
    Stmt.Step;
  finally
    Stmt.Close;
  end;

  Result := FDatabase.LastInsertRowID;
  FullText := StringToUtf8(Format('%s. %s. Category: %s',
    [AName, ADescription, ACategory]));

  Stmt.Prepare(FDatabase.DB,
    'INSERT INTO vec_products(rowid, embedding) SELECT ?, lembed(?, ?);');
  try
    Stmt.Bind(1, Result);
    Stmt.Bind(2, StringToUtf8(FModelName));
    Stmt.Bind(3, FullText);
    Stmt.Step;
  finally
    Stmt.Close;
  end;
end;

function TProductSemanticSearch.SearchProducts(const AQuery: string;
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
    '  FROM vec_products ' +
    '  WHERE embedding MATCH lembed(?, ?) ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT p.id, p.name, p.category, p.price, m.distance ' +
    'FROM matches m JOIN products p ON p.id = m.rowid ' +
    'ORDER BY m.distance;');
  try
    Stmt.Bind(1, StringToUtf8(FModelName));
    Stmt.Bind(2, StringToUtf8(AQuery));
    Stmt.Bind(3, ALimit);
    while Stmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, Index + 1);
      Result[Index] := FormatUtf8(
        'ID: % | Name: % | Category: % | Price: %.2f EUR | Distance: %',
        [Stmt.FieldInt(0), Stmt.FieldS(1), Stmt.FieldS(2),
         Stmt.FieldDouble(3), Stmt.FieldS(4)]);
      Inc(Index);
    end;
  finally
    Stmt.Close;
  end;
end;

function TProductSemanticSearch.FindSimilarProducts(AProductId: Int64;
  ALimit: Integer): TRawUtf8DynArray;
var
  Stmt: TSqlRequest;
  Index: Integer;
begin
  SetLength(Result, 0);
  Index := 0;

  Stmt.Prepare(FDatabase.DB,
    'WITH source_embedding AS ( ' +
    '  SELECT embedding AS query_embedding FROM vec_products WHERE rowid = ? ' +
    '), matches AS ( ' +
    '  SELECT vec_products.rowid, distance ' +
    '  FROM vec_products, source_embedding ' +
    '  WHERE vec_products.rowid != ? ' +
    '    AND embedding MATCH source_embedding.query_embedding ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT p.id, p.name, p.category, p.price, m.distance ' +
    'FROM matches m JOIN products p ON p.id = m.rowid;');
  try
    Stmt.Bind(1, AProductId);
    Stmt.Bind(2, AProductId);
    Stmt.Bind(3, ALimit);
    while Stmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, Index + 1);
      Result[Index] := FormatUtf8(
        'ID: % | Name: % | Category: % | Price: %.2f EUR | Distance: %',
        [Stmt.FieldInt(0), Stmt.FieldS(1), Stmt.FieldS(2),
         Stmt.FieldDouble(3), Stmt.FieldS(4)]);
      Inc(Index);
    end;
  finally
    Stmt.Close;
  end;
end;

function TProductSemanticSearch.SearchByCategory(const ACategory, AQuery: string;
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
    '  FROM vec_products ' +
    '  WHERE embedding MATCH lembed(?, ?) ' +
    '    AND k = ? ' +
    '  ORDER BY distance ' +
    ') ' +
    'SELECT p.id, p.name, p.price, m.distance ' +
    'FROM matches m JOIN products p ON p.id = m.rowid ' +
    'WHERE p.category = ? ' +
    'ORDER BY m.distance ' +
    'LIMIT ?;');
  try
    Stmt.Bind(1, StringToUtf8(FModelName));
    Stmt.Bind(2, StringToUtf8(AQuery));
    Stmt.Bind(3, ALimit * 3);
    Stmt.Bind(4, StringToUtf8(ACategory));
    Stmt.Bind(5, ALimit);
    while Stmt.Step = SQLITE_ROW do
    begin
      SetLength(Result, Index + 1);
      Result[Index] := FormatUtf8(
        'ID: % | Name: % | Price: %.2f EUR | Distance: %',
        [Stmt.FieldInt(0), Stmt.FieldS(1), Stmt.FieldDouble(2), Stmt.FieldS(3)]);
      Inc(Index);
    end;
  finally
    Stmt.Close;
  end;
end;

function TProductSemanticSearch.GetStats: string;
var
  Stmt: TSqlRequest;
  ProductCount: Int64;
  EmbeddingCount: Int64;
  CategoryCount: Int64;
begin
  ProductCount := 0;
  EmbeddingCount := 0;
  CategoryCount := 0;

  Stmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM products;');
  try
    if Stmt.Step = SQLITE_ROW then
      ProductCount := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  Stmt.Prepare(FDatabase.DB, 'SELECT COUNT(*) FROM vec_products;');
  try
    if Stmt.Step = SQLITE_ROW then
      EmbeddingCount := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  Stmt.Prepare(FDatabase.DB, 'SELECT COUNT(DISTINCT category) FROM products;');
  try
    if Stmt.Step = SQLITE_ROW then
      CategoryCount := Stmt.FieldInt(0);
  finally
    Stmt.Close;
  end;

  Result := Format(
    'Produkte: %d' + LineEnding +
    'Embeddings: %d' + LineEnding +
    'Kategorien: %d' + LineEnding +
    'Modell: %s' + LineEnding +
    'Dimensionen: %d',
    [ProductCount, EmbeddingCount, CategoryCount, FModelName, FEmbeddingDimensions]);
end;

procedure PrintResults(const AResults: TRawUtf8DynArray);
var
  I: Integer;
begin
  for I := 0 to High(AResults) do
    WriteLn('    ', I + 1, '. ', Utf8ToString(AResults[I]));
end;

procedure AddDemoProducts(ASearch: TProductSemanticSearch; out AMouseId: Int64);
begin
  ASearch.AddProduct('MacBook Pro 16"',
    'Powerful laptop with M3 chip, 32GB RAM, perfect for development and video editing',
    'Electronics', 2499.00);
  ASearch.AddProduct('Dell XPS 15',
    'High-performance laptop with Intel Core i9, ideal for programming and creative work',
    'Electronics', 1899.00);
  ASearch.AddProduct('iPad Pro 12.9"',
    'Tablet with Apple M2 chip, great for drawing, note-taking and media consumption',
    'Electronics', 1299.00);
  ASearch.AddProduct('Sony WH-1000XM5',
    'Premium noise-cancelling wireless headphones with excellent sound quality',
    'Electronics', 399.00);
  AMouseId := ASearch.AddProduct('Logitech MX Master 3S',
    'Ergonomic wireless mouse for professionals, precise tracking and programmable buttons',
    'Electronics', 109.00);
  ASearch.AddProduct('ErgoChair Pro',
    'Ergonomic office chair with lumbar support, breathable mesh and adjustable armrests',
    'Furniture', 549.00);
  ASearch.AddProduct('Standing Desk Pro',
    'Electric height-adjustable desk for healthier working, memory presets included',
    'Furniture', 799.00);
  ASearch.AddProduct('LED Desk Lamp',
    'Modern desk lamp with adjustable brightness and color temperature, USB charging port',
    'Furniture', 79.00);
  ASearch.AddProduct('Clean Code',
    'Essential book about software craftsmanship and writing maintainable code',
    'Books', 44.00);
  ASearch.AddProduct('Design Patterns',
    'Classic book about reusable object-oriented software design patterns',
    'Books', 54.00);
end;

procedure RunDemo;
const
  CModelFile = 'all-MiniLM-L6-v2.e4ce9877.q8_0.gguf';
  CModelName = 'miniLM';
  CModelDimensions = 384;
var
  RepoRoot: TFileName;
  DBPath: TFileName;
  ModelPath: TFileName;
  Search: TProductSemanticSearch;
  MouseId: Int64;
  Results: TRawUtf8DynArray;
begin
  RepoRoot := FindRepoRoot;
  DBPath := PathJoin(RepoRoot, 'examples/fpc/demo_product_search.db');
  ModelPath := PathJoin(RepoRoot, 'examples/fpc/' + CModelFile);
  if not FileExists(ModelPath) then
    ModelPath := PathJoin(RepoRoot, CModelFile);

  WriteLn('SQLite vec0 + lembed FPC Demo - Produktsuche');
  WriteLn('Repo: ', RepoRoot);
  WriteLn;

  DeleteFile(DBPath);
  Search := TProductSemanticSearch.Create(DBPath, RepoRoot);
  try
    WriteLn('[1/6] Initialisiere Datenbank und Modell...');
    Search.Initialize(ModelPath, CModelName, CModelDimensions);
    WriteLn('      Extensions geladen: lembed0.so + vec0.so');
    WriteLn;

    WriteLn('[2/6] Fuege Beispiel-Produkte hinzu...');
    AddDemoProducts(Search, MouseId);
    WriteLn('      10 Produkte hinzugefuegt');
    WriteLn;

    WriteLn('[3/6] Statistiken:');
    WriteLn(Search.GetStats);
    WriteLn;

    WriteLn('[4/6] Semantische Produktsuche');
    WriteLn('Suche: "laptop for software development"');
    Results := Search.SearchProducts('laptop for software development', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('Suche: "audio device for music listening"');
    Results := Search.SearchProducts('audio device for music listening', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('Suche: "ergonomic office equipment for healthy work"');
    Results := Search.SearchProducts('ergonomic office equipment for healthy work', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('Suche: "learning resources about programming"');
    Results := Search.SearchProducts('learning resources about programming', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('[5/6] Aehnliche Produkte zu "Logitech MX Master 3S"');
    Results := Search.FindSimilarProducts(MouseId, 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('[6/6] Kategorie "Electronics": "portable device"');
    Results := Search.SearchByCategory('Electronics', 'portable device', 3);
    PrintResults(Results);
    WriteLn;

    WriteLn('Finale Statistiken:');
    WriteLn(Search.GetStats);
  finally
    Search.Free;
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
      WriteLn('  1. Modell-Datei nach examples/fpc oder ins Repo-Root kopieren:');
      WriteLn('     all-MiniLM-L6-v2.e4ce9877.q8_0.gguf');
      WriteLn('  2. Linux-Binaries bauen:');
      WriteLn('     powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed-wsl.ps1');
      WriteLn('     powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec-wsl.ps1');
      WriteLn('  3. Demo ueber examples/fpc/run-vector-lembed-demo.sh starten.');
      Halt(1);
    end;
  end;
end.
