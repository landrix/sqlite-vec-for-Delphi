program LembedVectorDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  LembedVectorExample in 'LembedVectorExample.pas',
  sqliteVecForDelphi in '..\..\sqliteVecForDelphi.pas',
  mormot.core.base,
  mormot.core.unicode,
  mormot.db.sql,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static;

procedure RunDemo;
const
  // Zum Testen mit BGE-M3 die nächste Zeile aktivieren.
  // Hinweis: Die mitgelieferte sqlite-lembed v0.0.1-alpha.8 DLL kann
  // bge-m3-q8_0.gguf je nach GGUF/llama.cpp-Version nicht laden.
  {.$DEFINE USE_BGE_M3}

  {$IFDEF USE_BGE_M3}
  CModelFile = 'bge-m3-q8_0.gguf';
  CModelName = 'bge-m3';
  CModelDimensions = 1024;
  {$ELSE}
  // all-MiniLM-L6-v2: schnell, klein, 384 Dimensionen
  CModelFile = 'all-MiniLM-L6-v2.e4ce9877.q8_0.gguf';
  CModelName = 'miniLM';
  CModelDimensions = 384;
  {$ENDIF}
var
  lSearch: TSemanticDocumentSearch;
  lResults: TRawUtf8DynArray;
  i: Integer;
  lDBPath: string;
  lDocId: Int64;
begin
  WriteLn('=== SQLite Lembed + Vec Demo ===');
  WriteLn;
  
  lDBPath := ExtractFilePath(ParamStr(0)) + 'demo_semantic_search.db';

  // Beim Wechsel des Modells ändern sich ggf. die Vektor-Dimensionen.
  // Für die Demo wird die Datenbank deshalb frisch aufgebaut.
  DeleteFile(lDBPath);

  // Datenbank erstellen
  lSearch := TSemanticDocumentSearch.Create(lDBPath);
  try
    WriteLn('Initialisiere Datenbank und lade Modell...');
    
    // WICHTIG: CModelFile muss im Programmverzeichnis liegen.
    lSearch.Initialize(
      ExtractFilePath(ParamStr(0)) + CModelFile,
      CModelName,
      CModelDimensions
    );

    WriteLn('✓ Initialisierung abgeschlossen');
    WriteLn;
    
    // Beispiel-Dokumente hinzufügen
    WriteLn('Füge Beispiel-Dokumente hinzu...');
    
    lSearch.AddDocument(
      'Introduction to Machine Learning',
      'Machine learning is a subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed.'
    );
    
    lSearch.AddDocument(
      'Python Programming Basics',
      'Python is a high-level programming language known for its simplicity and readability. It is widely used in web development, data science, and automation.'
    );
    
    lSearch.AddDocument(
      'Database Management Systems',
      'A database management system (DBMS) is software that interacts with end users, applications, and the database itself to capture and analyze data.'
    );
    
    lSearch.AddDocument(
      'Neural Networks Explained',
      'Neural networks are computing systems inspired by biological neural networks. They are used in deep learning and can recognize patterns in data.'
    );
    
    lDocId := lSearch.AddDocument(
      'Web Development with JavaScript',
      'JavaScript is a versatile programming language essential for creating interactive web pages. It runs in the browser and enables dynamic content.'
    );
    
    lSearch.AddDocument(
      'Cloud Computing Overview',
      'Cloud computing delivers computing services over the internet, including storage, processing power, and software applications on demand.'
    );
    
    WriteLn('✓ 6 Dokumente hinzugefügt');
    WriteLn;
    
    // Statistiken anzeigen
    WriteLn(lSearch.GetStats);
    WriteLn;
    
    // Semantische Suche durchführen
    WriteLn('=== Suche 1: "artificial intelligence and neural networks" ===');
    lResults := lSearch.Search('artificial intelligence and neural networks', 3);
    for i := 0 to High(lResults) do
      WriteLn('  ', Utf8ToString(lResults[i]));
    WriteLn;
    
    WriteLn('=== Suche 2: "programming languages for beginners" ===');
    lResults := lSearch.Search('programming languages for beginners', 3);
    for i := 0 to High(lResults) do
      WriteLn('  ', Utf8ToString(lResults[i]));
    WriteLn;
    
    WriteLn('=== Suche 3: "data storage solutions" ===');
    lResults := lSearch.Search('data storage solutions', 3);
    for i := 0 to High(lResults) do
      WriteLn('  ', Utf8ToString(lResults[i]));
    WriteLn;
    
    // Ähnliche Dokumente finden
    WriteLn(Format('=== Ähnliche Dokumente zu "Web Development with JavaScript" (ID: %d) ===', [lDocId]));
    lResults := lSearch.FindSimilar(lDocId, 3);
    for i := 0 to High(lResults) do
      WriteLn('  ', Utf8ToString(lResults[i]));
    WriteLn;
    
    // Dokument löschen
    WriteLn('Lösche Dokument mit ID 3...');
    lSearch.DeleteDocument(3);
    WriteLn('✓ Dokument gelöscht');
    WriteLn;
    
    WriteLn(lSearch.GetStats);
    
  finally
    lSearch.Free;
  end;
  
  WriteLn;
  WriteLn('Demo abgeschlossen. Drücke Enter zum Beenden...');
  ReadLn;
end;

begin
  try
    RunDemo;
  except
    on E: Exception do
    begin
      WriteLn('FEHLER: ', E.Message);
      ReadLn;
    end;
  end;
end.
