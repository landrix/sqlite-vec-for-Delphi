# Vergleich: Vector Extensions für Delphi

Übersicht über die verschiedenen Kombinationsmöglichkeiten von Extensions.

## 📊 Extension-Kombinationen

| Kombination | Extensions | Beispiel-Projekt | Best für |
|-------------|-----------|------------------|----------|
| **1. vec0 + lembed** | `vec0.dll` + `lembed0.dll` | `LembedVectorExample.pas` | Kleine bis mittlere Daten, Prototyping |
| **2. vector + lembed** | `vector.dll` + `lembed0.dll` | `VectorLembedExample.pas` | Große Datenmengen, Produktion |
| **3. vector standalone** | `vector.dll` | `SimpleDelphiUnit1.pas` (auskommentiert) | Eigene Vektoren, kein Text |

## 🔍 Detaillierter Vergleich

### 1. vec0.dll + lembed0.dll

**Vorteile:**
- ✅ Einfache API (virtuelle Tabelle)
- ✅ Schnelle Einrichtung
- ✅ Ideal für Prototyping
- ✅ Geringe Komplexität

**Nachteile:**
- ❌ Keine Quantisierung
- ❌ Langsamer bei >10k Vektoren
- ❌ Höherer Speicher-Overhead

**Code-Beispiel:**
```pascal
// Virtuelle Tabelle erstellen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[384]);');

// Embedding einfügen
sql.Execute(
  'INSERT INTO vec_docs(rowid, embedding) ' +
  'SELECT id, lembed(''model'', text) FROM documents;'
);

// Suchen
sql.Execute(
  'SELECT rowid, distance FROM vec_docs ' +
  'WHERE embedding MATCH lembed(''model'', ?) ' +
  '  AND k = ? ' +
  'ORDER BY distance;'
);
```

**Verwendung:**
```pascal
uses
  LembedVectorExample;  // Aus examples/simple-delphi/

var
  Search: TSemanticDocumentSearch;
begin
  Search := TSemanticDocumentSearch.Create('docs.db');
  try
    Search.Initialize('model.gguf', 'embedder');
    Search.AddDocument('Title', 'Content');
    Results := Search.Search('query', 10);
  finally
    Search.Free;
  end;
end;
```

---

### 2. vector.dll + lembed0.dll ⭐ **EMPFOHLEN FÜR PRODUKTION**

**Vorteile:**
- ✅ **4-5x schnellere Suche** (mit Quantisierung)
- ✅ 75% weniger Speicher (INT8 statt FLOAT32)
- ✅ Memory Preloading für max. Speed
- ✅ Skaliert gut mit großen Datenmengen
- ✅ Normale SQLite-Tabellen (kein Virtual Table)

**Nachteile:**
- ⚠️ Komplexere API
- ⚠️ Quantisierung muss explizit aufgerufen werden

**Code-Beispiel:**
```pascal
// Normale Tabelle mit BLOB
sql.Execute('CREATE TABLE products(id INTEGER PRIMARY KEY, embedding BLOB, text TEXT);');

// Vector initialisieren
sql.Execute('SELECT vector_init(''products'', ''embedding'', ''type=FLOAT32,dimension=384'');');

// Embeddings einfügen
sql.Execute(
  'INSERT INTO products(embedding, text) ' +
  'SELECT lembed(''model'', content), content FROM source;'
);

// Quantisieren für Performance
sql.Execute('SELECT vector_quantize(''products'', ''embedding'');');
sql.Execute('SELECT vector_quantize_preload(''products'', ''embedding'');');

// Quantisierte Suche (4-5x schneller!)
sql.Execute(
  'SELECT p.id, v.distance FROM products p ' +
  'JOIN vector_quantize_scan(''products'', ''embedding'', lembed(''model'', ?), 10) v ' +
  'ON p.id = v.rowid;'
);
```

**Verwendung:**
```pascal
uses
  VectorLembedExample;  // Aus examples/simple-delphi/

var
  Search: TProductSemanticSearch;
begin
  Search := TProductSemanticSearch.Create('products.db');
  try
    Search.Initialize('model.gguf', 'embedder');
    
    // Produkte hinzufügen
    Search.AddProduct('Name', 'Description', 'Category', 99.99);
    
    // WICHTIG: Quantisieren für Performance!
    Search.QuantizeEmbeddings;
    Search.PreloadQuantized;
    
    // Schnelle Suche (quantisiert)
    Results := Search.SearchProducts('query', 10, True);
  finally
    Search.Free;
  end;
end;
```

---

### 3. vector.dll standalone (ohne lembed)

**Vorteile:**
- ✅ Volle Kontrolle über Vektoren
- ✅ Eigene Embedding-Modelle nutzbar
- ✅ Keine Abhängigkeit von GGUF-Modellen

**Nachteile:**
- ❌ Keine automatische Embedding-Generierung
- ❌ Manuelles Vector-Management

**Code-Beispiel:**
```pascal
// Nur vector.dll laden
TSQLDatabaseVectorHelper.EnableExtensionLoading(sql.DB);
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vector.dll');

// Tabelle mit manuellen Vektoren
sql.Execute('CREATE TABLE images(id INTEGER PRIMARY KEY, embedding BLOB, label TEXT);');

// Vector initialisieren
sql.Execute('SELECT vector_init(''images'', ''embedding'', ''type=FLOAT32,dimension=512'');');

// Vektor manuell als JSON einfügen
sql.Execute(
  'INSERT INTO images(embedding, label) ' +
  'VALUES (vector_as_f32(''[0.1, 0.2, ..., 0.9]''), ''cat'');'
);

// Oder BLOB binding (schneller)
aStmt.Prepare(sql.DB, 'INSERT INTO images(embedding, label) VALUES (?, ?);');
aStmt.Bind(1, VectorBlob);  // Dein eigener FLOAT32 BLOB
aStmt.Bind(2, 'dog');
```

---

## 🎯 Entscheidungshilfe

### Nutze **vec0 + lembed** wenn:
- ✅ Du schnell prototypen willst
- ✅ Datenmengen < 10.000 Dokumente
- ✅ Einfachheit wichtiger als Performance
- ✅ Entwicklung/Testing

### Nutze **vector + lembed** wenn: ⭐
- ✅ Produktionsumgebung
- ✅ Datenmengen > 10.000 Dokumente
- ✅ Performance kritisch
- ✅ Große Datenbanken (GB+)
- ✅ E-Commerce, große Dokumenten-Archive

### Nutze **vector standalone** wenn:
- ✅ Eigenes Embedding-System
- ✅ Andere ML-Frameworks (ONNX, TensorFlow, etc.)
- ✅ Nicht-Text-Daten (Bilder, Audio)
- ✅ Custom Vector-Dimensionen

---

## 📦 Beispiel-Projekte

### Konsolen-Programme

| Datei | Extensions | Beschreibung |
|-------|-----------|--------------|
| `LembedVectorDemo.dpr` | vec0 + lembed | Dokumentensuche, einfache API |
| `VectorLembedDemo.dpr` | vector + lembed | Produktsuche mit Quantisierung |

### VCL-GUI-Programme

| Datei | Extensions | Beschreibung |
|-------|-----------|--------------|
| `SimpleDelphi.dpr` | vec0 + lembed + vector | Alle drei Extensions, verschiedene Demos |
| `VectorLembedFormDemo.dpr` | vector + lembed | Produkt-Verwaltung mit GUI |

### Wiederverwendbare Klassen

| Datei | Extensions | API |
|-------|-----------|-----|
| `LembedVectorExample.pas` | vec0 + lembed | `TSemanticDocumentSearch` |
| `VectorLembedExample.pas` | vector + lembed | `TProductSemanticSearch` |

---

## ⚡ Performance-Messung

### Beispiel-Benchmark (10.000 Produkte)

| Operation | vec0 | vector (normal) | vector (quantized) |
|-----------|------|----------------|-------------------|
| Insert 10k | ~45s | ~45s | ~45s |
| Quantisierung | - | - | ~2s |
| Suche (Top 10) | ~150ms | ~140ms | **~30ms** |
| Speicher | 150 MB | 120 MB | **30 MB** |

**Fazit:** vector.dll mit Quantisierung ist **4-5x schneller** und nutzt **75% weniger RAM**.

---

## 🔧 API-Vergleich

### Tabellen erstellen

**vec0:**
```pascal
sql.Execute('CREATE VIRTUAL TABLE vec_data USING vec0(embedding float[384]);');
```

**vector:**
```pascal
sql.Execute('CREATE TABLE data(id INTEGER PRIMARY KEY, embedding BLOB);');
sql.Execute('SELECT vector_init(''data'', ''embedding'', ''type=FLOAT32,dimension=384'');');
```

### Embeddings einfügen

**Beide gleich:**
```pascal
sql.Execute(
  'INSERT INTO vec_data(rowid, embedding) ' +
  'SELECT id, lembed(''model'', text) FROM documents;'
);
```

### Suche

**vec0:**
```pascal
sql.Execute(
  'SELECT rowid, distance FROM vec_data ' +
  'WHERE embedding MATCH lembed(''model'', ?) ' +
  '  AND k = ? ' +
  'ORDER BY distance;'
);
```

**vector (normal):**
```pascal
sql.Execute(
  'SELECT id, vector_distance(embedding, lembed(''model'', ?)) as distance ' +
  'FROM data ORDER BY distance LIMIT 10;'
);
```

**vector (quantized):**
```pascal
sql.Execute(
  'SELECT p.id, v.distance FROM data p ' +
  'JOIN vector_quantize_scan(''data'', ''embedding'', lembed(''model'', ?), 10) v ' +
  'ON p.id = v.rowid;'
);
```

---

## 🎓 Lernpfad

1. **Anfänger:** Starte mit `LembedVectorDemo.dpr` (vec0 + lembed)
   - Einfache API verstehen
   - Grundkonzepte: Embeddings, Distance

2. **Fortgeschritten:** Nutze `VectorLembedDemo.dpr` (vector + lembed)
   - Quantisierung verstehen
   - Performance optimieren

3. **Experte:** Custom Integration
   - Eigene Embedding-Systeme
   - Hybrid-Suche (Text + Vektoren)
   - Multi-Index-Strategien

---

## 🔗 Ressourcen

- **Haupt-Dokumentation:** [LEMBED_VECTOR_USAGE.md](../../LEMBED_VECTOR_USAGE.md)
- **vec0 + lembed:** [README_LEMBED.md](README_LEMBED.md)
- **vector + lembed:** [README_VECTOR_LEMBED.md](README_VECTOR_LEMBED.md)
- **sqlite-vec:** [GitHub](https://github.com/asg017/sqlite-vec)
- **sqlite-vector:** [GitHub](https://github.com/sqliteai/sqlite-vector)
- **sqlite-lembed:** [GitHub](https://github.com/asg017/sqlite-lembed)

---

## 📝 Fazit

**Für die meisten Produktions-Anwendungen empfehlen wir `vector.dll` + `lembed0.dll`** wegen der deutlich besseren Performance durch Quantisierung. 

Für Prototyping und kleinere Projekte ist `vec0.dll` + `lembed0.dll` einfacher zu handhaben.
