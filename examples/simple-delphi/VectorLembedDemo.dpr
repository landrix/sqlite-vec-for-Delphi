program VectorLembedDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  VectorLembedExample in 'VectorLembedExample.pas',
  sqliteVecForDelphi in '..\..\sqliteVecForDelphi.pas',
  mormot.core.base,
  mormot.core.unicode,
  mormot.db.sql,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static;

procedure RunProductSearchDemo;
var
  lSearch: TProductSemanticSearch;
  lResults: TRawUtf8DynArray;
  i: Integer;
  lProductId: Int64;
  lStartTime, lEndTime: Int64;
begin
  WriteLn('╔════════════════════════════════════════════════════════════════╗');
  WriteLn('║   SQLite Vector + Lembed Demo - Produktsuche                  ║');
  WriteLn('║   Nutzt sqlite-vector mit Quantisierung für Performance       ║');
  WriteLn('╚════════════════════════════════════════════════════════════════╝');
  WriteLn;
  
  // Alte DB löschen für Clean Start
  DeleteFile('demo_product_search.db');
  
  lSearch := TProductSemanticSearch.Create('demo_product_search.db');
  try
    WriteLn('[1/7] Initialisiere Datenbank und lade Modell...');
    
    // WICHTIG: Modell-Datei muss vorhanden sein!
    // Download: https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
    lSearch.Initialize('all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'miniLM');
    WriteLn('      ✓ Extensions geladen: lembed0.dll + vector.dll');
    WriteLn;
    
    // Beispiel-Produkte hinzufügen
    WriteLn('[2/7] Füge Beispiel-Produkte hinzu...');
    
    // Elektronik
    lSearch.AddProduct(
      'MacBook Pro 16"',
      'Powerful laptop with M3 chip, 32GB RAM, perfect for development and video editing',
      'Electronics',
      2499.00
    );
    
    lSearch.AddProduct(
      'Dell XPS 15',
      'High-performance laptop with Intel Core i9, ideal for programming and creative work',
      'Electronics',
      1899.00
    );
    
    lSearch.AddProduct(
      'iPad Pro 12.9"',
      'Tablet with Apple M2 chip, great for drawing, note-taking and media consumption',
      'Electronics',
      1299.00
    );
    
    lSearch.AddProduct(
      'Sony WH-1000XM5',
      'Premium noise-cancelling wireless headphones with excellent sound quality',
      'Electronics',
      399.00
    );
    
    lProductId := lSearch.AddProduct(
      'Logitech MX Master 3S',
      'Ergonomic wireless mouse for professionals, precise tracking and programmable buttons',
      'Electronics',
      109.00
    );
    
    // Möbel
    lSearch.AddProduct(
      'ErgoChair Pro',
      'Ergonomic office chair with lumbar support, breathable mesh and adjustable armrests',
      'Furniture',
      549.00
    );
    
    lSearch.AddProduct(
      'Standing Desk Pro',
      'Electric height-adjustable desk for healthier working, memory presets included',
      'Furniture',
      799.00
    );
    
    lSearch.AddProduct(
      'LED Desk Lamp',
      'Modern desk lamp with adjustable brightness and color temperature, USB charging port',
      'Furniture',
      79.00
    );
    
    // Bücher
    lSearch.AddProduct(
      'Clean Code',
      'Essential book about software craftsmanship and writing maintainable code',
      'Books',
      44.00
    );
    
    lSearch.AddProduct(
      'Design Patterns',
      'Classic book about reusable object-oriented software design patterns',
      'Books',
      54.00
    );
    
    WriteLn('      ✓ 10 Produkte hinzugefügt');
    WriteLn;
    
    // Statistiken vor Quantisierung
    WriteLn('[3/7] Statistiken:');
    WriteLn('      ' + StringReplace(lSearch.GetStats, sLineBreak, sLineBreak + '      ', [rfReplaceAll]));
    WriteLn;
    
    // Quantisierung durchführen
    WriteLn('[4/7] Quantisiere Embeddings für Performance...');
    lSearch.QuantizeEmbeddings;
    WriteLn('      ✓ Quantisierung abgeschlossen (INT8 statt FLOAT32)');
    WriteLn;
    
    WriteLn('[5/7] Lade quantisierte Daten in den Speicher...');
    lSearch.PreloadQuantized;
    WriteLn('      ✓ Daten im RAM für maximale Geschwindigkeit');
    WriteLn;
    
    // Semantische Suche durchführen
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('[6/7] Semantische Produktsuche');
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn;
    
    // Suche 1: Laptop
    WriteLn('🔍 Suche: "laptop for software development"');
    WriteLn('    (Quantisierte Suche - 4-5x schneller)');
    WriteLn;
    lStartTime := GetTickCount64;
    lResults := lSearch.SearchProducts('laptop for software development', 3, True);
    lEndTime := GetTickCount64;
    
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn('    ⏱️  Zeit: ', lEndTime - lStartTime, ' ms (quantisiert)');
    WriteLn;
    
    // Suche 2: Audio
    WriteLn('🔍 Suche: "audio device for music listening"');
    WriteLn;
    lResults := lSearch.SearchProducts('audio device for music listening', 3, True);
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn;
    
    // Suche 3: Gesundes Arbeiten
    WriteLn('🔍 Suche: "ergonomic office equipment for healthy work"');
    WriteLn;
    lResults := lSearch.SearchProducts('ergonomic office equipment for healthy work', 3, True);
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn;
    
    // Suche 4: Lernen
    WriteLn('🔍 Suche: "learning resources about programming"');
    WriteLn;
    lResults := lSearch.SearchProducts('learning resources about programming', 3, True);
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn;
    
    // Ähnliche Produkte finden
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('[7/7] Ähnliche Produkte zu "Logitech MX Master 3S" (ID: %d)', [lProductId]);
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn;
    
    lResults := lSearch.FindSimilarProducts(lProductId, 3, True);
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn;
    
    // Kategorie-Suche
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('📂 Suche in Kategorie "Electronics": "portable device"');
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn;
    
    lResults := lSearch.SearchByCategory('Electronics', 'portable device', 3);
    for i := 0 to High(lResults) do
      WriteLn('    ' + IntToStr(i+1) + '. ' + Utf8ToString(lResults[i]));
    WriteLn;
    
    // Vergleich: Normal vs. Quantisiert
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('⚡ Performance-Vergleich: Normal vs. Quantisiert');
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn;
    
    WriteLn('🔍 Testsuche: "professional computer for work"');
    WriteLn;
    
    // Normale Suche
    lStartTime := GetTickCount64;
    lResults := lSearch.SearchProducts('professional computer for work', 5, False);
    lEndTime := GetTickCount64;
    WriteLn('    Normal (FLOAT32):   ', lEndTime - lStartTime, ' ms');
    
    // Quantisierte Suche
    lStartTime := GetTickCount64;
    lResults := lSearch.SearchProducts('professional computer for work', 5, True);
    lEndTime := GetTickCount64;
    WriteLn('    Quantisiert (INT8): ', lEndTime - lStartTime, ' ms');
    WriteLn;
    WriteLn('    💡 Bei größeren Datenmengen ist der Unterschied deutlicher!');
    WriteLn;
    
    // Finale Statistiken
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('📊 Finale Statistiken');
    WriteLn('═══════════════════════════════════════════════════════════════');
    WriteLn('    ' + StringReplace(lSearch.GetStats, sLineBreak, sLineBreak + '    ', [rfReplaceAll]));
    WriteLn;
    
  finally
    lSearch.Free;
  end;
  
  WriteLn('╔════════════════════════════════════════════════════════════════╗');
  WriteLn('║   Demo abgeschlossen!                                          ║');
  WriteLn('║   Datenbank: demo_product_search.db                            ║');
  WriteLn('╚════════════════════════════════════════════════════════════════╝');
  WriteLn;
  WriteLn('Drücke Enter zum Beenden...');
  ReadLn;
end;

begin
  try
    RunProductSearchDemo;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('❌ FEHLER: ', E.Message);
      WriteLn;
      WriteLn('Mögliche Ursachen:');
      WriteLn('  1. Modell-Datei nicht gefunden');
      WriteLn('     Download: https://huggingface.co/asg017/sqlite-lembed-model-examples');
      WriteLn('  2. DLL-Dateien fehlen (lembed0.dll, vector.dll)');
      WriteLn('  3. Falscher Pfad zur Modell-Datei');
      WriteLn;
      WriteLn('Drücke Enter zum Beenden...');
      ReadLn;
    end;
  end;
end.
