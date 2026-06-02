# 🚀 SQLite Vector + Lembed - Quick Reference

Ein Spickzettel für die schnelle Verwendung.

## 📦 Basis-Setup (Beide Varianten)

```pascal
uses
  mormot.db.sql, mormot.db.raw.sqlite3, mormot.db.raw.sqlite3.static,
  sqliteVecForDelphi;

var
  sql: TSQLDatabase;
begin
  // DLLs extrahieren
  TSQLDatabaseVectorHelper.ExtractLembed0Dll;
  TSQLDatabaseVectorHelper.ExtractVec0Dll;  // oder ExtractVectorDll
  
  sql := TSQLDatabase.Create('mydb.db', '');
  TSQLDatabaseVectorHelper.EnableExtensionLoading(sql.DB);
  
  // Extensions laden
  TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'lembed0.dll');
  TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vec0.dll');  // oder vector.dll
  
  // Modell registrieren
  sql.Execute(
    'INSERT INTO temp.lembed_models(name, model) ' +
    'SELECT ''model'', lembed_model_from_file(''model.gguf'');'
  );
end;
```

---

## 🎯 Variante 1: vec0 + lembed (Einfach)

### Tabellen erstellen
```pascal
// Text-Tabelle
sql.Execute('CREATE TABLE docs(id INTEGER PRIMARY KEY, text TEXT);');

// Vector-Tabelle (virtuell)
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[384]);');
```

### Daten einfügen
```pascal
sql.Execute('INSERT INTO docs(text) VALUES (''My document text'');');

sql.Execute(
  'INSERT INTO vec_docs(rowid, embedding) ' +
  'SELECT id, lembed(''model'', text) FROM docs;'
);
```

### Suchen
```pascal
aStmt.Prepare(sql.DB,
  'SELECT d.text, v.distance ' +
  'FROM vec_docs v ' +
  'JOIN docs d ON d.id = v.rowid ' +
  'WHERE v.embedding MATCH lembed(''model'', ?) ' +
  '  AND k = ? ' +
  'ORDER BY v.distance;'
);
aStmt.Bind(1, 'search query');
aStmt.Bind(2, 10);
```

### Vollständige Klasse
```pascal
uses LembedVectorExample;

var
  Search: TSemanticDocumentSearch;
begin
  Search := TSemanticDocumentSearch.Create('docs.db');
  try
    Search.Initialize('model.gguf', 'embedder');
    
    DocId := Search.AddDocument('Title', 'Content');
    Results := Search.Search('query', 10);
    Similar := Search.FindSimilar(DocId, 5);
  finally
    Search.Free;
  end;
end;
```

---

## ⚡ Variante 2: vector + lembed (Performant)

### Tabellen erstellen
```pascal
// Normale Tabelle mit BLOB
sql.Execute('CREATE TABLE products(id INTEGER PRIMARY KEY, embedding BLOB, text TEXT);');

// Vector initialisieren
sql.Execute('SELECT vector_init(''products'', ''embedding'', ''type=FLOAT32,dimension=384'');');
```

### Daten einfügen
```pascal
sql.Execute(
  'INSERT INTO products(embedding, text) ' +
  'VALUES (lembed(''model'', ''Product description''), ''Product description'');'
);
```

### Quantisieren (WICHTIG für Performance!)
```pascal
// Nach vielen Inserts:
sql.Execute('SELECT vector_quantize(''products'', ''embedding'');');
sql.Execute('SELECT vector_quantize_preload(''products'', ''embedding'');');
```

### Suchen (quantisiert)
```pascal
aStmt.Prepare(sql.DB,
  'SELECT p.text, v.distance ' +
  'FROM products p ' +
  'JOIN vector_quantize_scan(''products'', ''embedding'', lembed(''model'', ?), 10) v ' +
  '  ON p.id = v.rowid;'
);
aStmt.Bind(1, 'search query');
```

### Suchen (normal - präziser, langsamer)
```pascal
aStmt.Prepare(sql.DB,
  'SELECT text, vector_distance(embedding, lembed(''model'', ?)) as distance ' +
  'FROM products ' +
  'ORDER BY distance LIMIT 10;'
);
aStmt.Bind(1, 'search query');
```

### Vollständige Klasse
```pascal
uses VectorLembedExample;

var
  Search: TProductSemanticSearch;
begin
  Search := TProductSemanticSearch.Create('products.db');
  try
    Search.Initialize('model.gguf', 'embedder');
    
    // Produkte hinzufügen
    Search.AddProduct('Name', 'Description', 'Category', 99.99);
    
    // Quantisieren für 4-5x Speed
    Search.QuantizeEmbeddings;
    Search.PreloadQuantized;
    
    // Schnell suchen
    Results := Search.SearchProducts('query', 10, True);
    Similar := Search.FindSimilarProducts(ProductId, 5, True);
    ByCategory := Search.SearchByCategory('Category', 'query', 10);
  finally
    Search.Free;
  end;
end;
```

---

## 📊 Vergleich auf einen Blick

| Feature | vec0 + lembed | vector + lembed |
|---------|---------------|-----------------|
| **Tabellen** | Virtuell | Normal (BLOB) |
| **Setup** | Einfacher | Mehr Code |
| **Quantisierung** | ❌ Nein | ✅ Ja |
| **Performance** | Gut | 4-5x besser |
| **Speicher** | Standard | 75% weniger |
| **Best für** | <10k Docs | >10k Docs |

---

## 🎯 SQL-Cheatsheet

### Modell laden
```sql
INSERT INTO temp.lembed_models(name, model)
  SELECT 'mymodel', lembed_model_from_file('path/to/model.gguf');
```

### Embedding generieren
```sql
SELECT lembed('modelname', 'Text to embed');
```

### vec0: Virtuelle Tabelle
```sql
CREATE VIRTUAL TABLE vec_data USING vec0(
  embedding float[384]  -- Dimensionen des Modells
);
```

### vector: Normale Tabelle + Init
```sql
CREATE TABLE data(id INTEGER PRIMARY KEY, embedding BLOB);
SELECT vector_init('data', 'embedding', 'type=FLOAT32,dimension=384');
```

### Quantisieren (nur vector.dll)
```sql
SELECT vector_quantize('tablename', 'columnname');
SELECT vector_quantize_preload('tablename', 'columnname');
```

### Suchen (vec0)
```sql
SELECT rowid, distance 
FROM vec_data
WHERE embedding MATCH lembed('model', 'query')
  AND k = 10
ORDER BY distance;
```

### Suchen (vector quantisiert)
```sql
SELECT p.id, v.distance
FROM products p
JOIN vector_quantize_scan('products', 'embedding', lembed('model', 'query'), 10) v
  ON p.id = v.rowid;
```

### Distance-Metriken
```sql
-- Verfügbare Metriken:
-- L2 (Standard), COSINE, DOT, L1, SQUARED_L2

-- Bei vec0:
CREATE VIRTUAL TABLE vec_data USING vec0(
  embedding float[384] distance=cosine
);

-- Bei vector:
SELECT vector_init('data', 'embedding', 'type=FLOAT32,dimension=384,distance=COSINE');
```

---

## 🔧 Modell-Dimensionen

| Modell | Dimensionen | Code |
|--------|-------------|------|
| all-MiniLM-L6-v2 | 384 | `float[384]` |
| nomic-embed-text-v1.5 | 768 | `float[768]` |
| BGE-M3 | 1024 | `float[1024]` |
| mxbai-embed-large-v1 | 1024 | `float[1024]` |

**Wichtig:** Vector-Tabelle muss Modell-Dimensionen entsprechen!

---

## 🐛 Häufige Fehler

### "Model not found"
```pascal
// Lösung: Absoluten Pfad verwenden
sql.Execute(
  'INSERT INTO temp.lembed_models(name, model) ' +
  'SELECT ''model'', lembed_model_from_file(''' + 
  ExtractFilePath(Application.ExeName) + 'model.gguf'');'
);
```

### "Dimension mismatch"
```pascal
// Falsch: 768 Dimensionen, aber Modell hat 384
sql.Execute('CREATE VIRTUAL TABLE vec USING vec0(embedding float[768]);');

// Richtig:
sql.Execute('CREATE VIRTUAL TABLE vec USING vec0(embedding float[384]);');
```

### "No such function: vector_quantize"
```pascal
// Falsch: vec0.dll geladen (hat keine Quantisierung)
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vec0.dll');

// Richtig: vector.dll laden
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vector.dll');
```

---

## 📈 Performance-Checkliste

### Vor dem Deployment

- [ ] Richtiges Modell gewählt? (Dimensionen, Sprache)
- [ ] Quantisierung aktiviert? (bei vector.dll)
- [ ] Preload aktiviert? (bei großen Daten)
- [ ] Batch-Inserts statt einzeln?
- [ ] Indizes auf Filter-Spalten?
- [ ] `k = ?` oder LIMIT in vec0-KNN-Queries?

### Optimierungen

```pascal
// 1. Batch-Processing
DB.TransactionBegin;
try
  for Item in Items do
    AddItem(Item);
  QuantizeEmbeddings;  // Nur 1x am Ende!
  DB.Commit;
except
  DB.Rollback;
end;

// 2. Indizes erstellen
sql.Execute('CREATE INDEX idx_category ON products(category);');

// 3. LIMIT nutzen
Results := Search('query', 10);  // Nicht 1000!
```

---

## 🔗 Schnellzugriff

- **Hauptdoku:** [LEMBED_VECTOR_USAGE.md](../LEMBED_VECTOR_USAGE.md)
- **Beispiele:** [examples/README.md](../examples/README.md)
- **Vergleich:** [EXTENSIONS_COMPARISON.md](../examples/simple-delphi/EXTENSIONS_COMPARISON.md)
- **vec0 Guide:** [README_LEMBED.md](../examples/simple-delphi/README_LEMBED.md)
- **vector Guide:** [README_VECTOR_LEMBED.md](../examples/simple-delphi/README_VECTOR_LEMBED.md)

---

## 💡 Pro-Tips

1. **Wähle vector.dll für Produktion** (4-5x schneller mit Quantisierung)
2. **Quantisiere nach Batch-Inserts**, nicht nach jedem Dokument
3. **Nutze Preload** für maximale Performance
4. **Kombiniere Filter** (z.B. Kategorie) mit semantischer Suche
5. **Teste verschiedene Distance-Metriken** (COSINE oft besser als L2)

---

**Viel Erfolg! 🚀**
