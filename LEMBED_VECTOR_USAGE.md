# Verwendung von sqlite-lembed mit sqlite-vec in Delphi

## Überblick

**sqlite-lembed** und **sqlite-vec** arbeiten perfekt zusammen, um semantische Suche in SQLite zu ermöglichen:

- **`sqlite-lembed`**: Generiert Text-Embeddings (Vektoren) mittels KI-Modellen im GGUF-Format
- **`sqlite-vec`**: Speichert Vektoren und ermöglicht effiziente Ähnlichkeitssuche (Vector Search)

## Voraussetzungen

### 1. DLL-Dateien
- `lembed0.dll` - im Verzeichnis `lib\sqlite-lembed\`
- `vec0.dll` - im Verzeichnis `lib\sqlite-vec\`

### 2. Embedding-Modell herunterladen

Das **all-MiniLM-L6-v2** Modell (empfohlen für den Start):

```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

- **Größe**: ca. 22 MB
- **Dimensionen**: 384
- **Sprache**: Englisch
- **Qualität**: Gut für allgemeine semantische Suche

Für deutsche oder mehrsprachige Daten ist `all-MiniLM-L6-v2` nur ein schnelles Demo-Modell. Bessere lokale Optionen sind `BGE-M3` (1024 Dimensionen) oder `nomic-embed-text-v1.5` (768 Dimensionen). Siehe [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md).

Speichere die `.gguf` Datei im Programmverzeichnis oder einem bekannten Pfad.

## Workflow

### Schritt 1: Extensions laden

```pascal
// Extensions extrahieren (falls embedded)
TSQLDatabaseVectorHelper.ExtractLembed0Dll;
TSQLDatabaseVectorHelper.ExtractVec0Dll;

// Datenbank öffnen
sql := TSQLDatabase.Create('mydb.db', '');

// Extension loading aktivieren
TSQLDatabaseVectorHelper.EnableExtensionLoading(sql.DB);

// Extensions laden
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'lembed0.dll');
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vec0.dll');
```

### Schritt 2: Embedding-Modell registrieren

```pascal
sql.Execute(
  'INSERT INTO temp.lembed_models(name, model) ' +
  'SELECT ''all-MiniLM-L6-v2'', ' +
  '       lembed_model_from_file(''all-MiniLM-L6-v2.e4ce9877.q8_0.gguf'');'
);
```

**Wichtig**: Der Modellname (hier `'all-MiniLM-L6-v2'`) ist frei wählbar und wird später für Embeddings verwendet.

### Schritt 3: Tabellen erstellen

```pascal
// Text-Tabelle (normale SQLite-Tabelle)
sql.Execute('CREATE TABLE documents(id INTEGER PRIMARY KEY, content TEXT);');

// Vector-Tabelle (virtuelle Tabelle für Embeddings)
sql.Execute(
  'CREATE VIRTUAL TABLE vec_documents USING vec0(' +
  '  content_embedding float[384]' +  // 384 = Dimensionen des Modells
  ');'
);
```

### Schritt 4: Daten einfügen

```pascal
// Text einfügen
sql.Execute('INSERT INTO documents(content) VALUES (''Hier steht der Text'');');

// Embedding generieren und speichern
sql.Execute(
  'INSERT INTO vec_documents(rowid, content_embedding) ' +
  'SELECT id, lembed(''all-MiniLM-L6-v2'', content) ' +
  'FROM documents;'
);
```

### Schritt 5: Semantische Suche

```pascal
aStmt.Prepare(sql.DB,
  'WITH matches AS ( ' +
  '  SELECT rowid, distance ' +
  '  FROM vec_documents ' +
  '  WHERE content_embedding MATCH lembed(''all-MiniLM-L6-v2'', ?) ' +
  '    AND k = ? ' +
  '  ORDER BY distance ' +
  ') ' +
  'SELECT documents.content, matches.distance ' +
  'FROM matches ' +
  'LEFT JOIN documents ON documents.id = matches.rowid;'
);
aStmt.Bind(1, 'Suchbegriff hier');
aStmt.Bind(2, 10);

while aStmt.Step = SQLITE_ROW do
begin
  Memo1.Lines.Add(aStmt.FieldS(0) + ' (Distance: ' + aStmt.FieldS(1) + ')');
end;
```

## Vollständiges Beispiel: Artikel-Suche

```pascal
procedure TForm1.CreateArticleSearch;
var
  sql: TSQLDatabase;
  aStmt: TSQLRequest;
begin
  sql := TSQLDatabase.Create('articles.db', '');
  try
    // Extensions laden
    TSQLDatabaseVectorHelper.EnableExtensionLoading(sql.DB);
    TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'lembed0.dll');
    TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vec0.dll');

    // Modell registrieren
    sql.Execute(
      'INSERT INTO temp.lembed_models(name, model) ' +
      'SELECT ''miniLM'', lembed_model_from_file(''all-MiniLM-L6-v2.e4ce9877.q8_0.gguf'');'
    );

    // Tabellen erstellen
    sql.Execute('CREATE TABLE IF NOT EXISTS articles(id INTEGER PRIMARY KEY, headline TEXT);');
    sql.Execute('CREATE VIRTUAL TABLE IF NOT EXISTS vec_articles USING vec0(embedding float[384]);');

    // Artikel hinzufügen
    sql.Execute(
      'INSERT INTO articles(headline) VALUES ' +
      '(''Breaking: New AI model achieves record performance''), ' +
      '(''Scientists discover breakthrough in quantum computing''), ' +
      '(''Local sports team wins championship'');'
    );

    // Embeddings generieren
    sql.Execute(
      'INSERT INTO vec_articles(rowid, embedding) ' +
      'SELECT id, lembed(''miniLM'', headline) FROM articles;'
    );

    // Suche durchführen
    aStmt.Prepare(sql.DB,
      'WITH matches AS ( ' +
      '  SELECT rowid, distance FROM vec_articles ' +
      '  WHERE embedding MATCH lembed(''miniLM'', ''artificial intelligence'') ' +
      '    AND k = 5 ' +
      '  ORDER BY distance ' +
      ') ' +
      'SELECT a.headline, m.distance ' +
      'FROM matches m JOIN articles a ON a.id = m.rowid;'
    );

    while aStmt.Step = SQLITE_ROW do
      ShowMessage(aStmt.FieldS(0) + ' - ' + aStmt.FieldS(1));

    aStmt.Close;
  finally
    sql.Free;
  end;
end;
```

## Alternative: sqlite-vector Extension

Für Produktionsumgebungen mit großen Datensätzen kannst du auch `vector.dll` (sqlite-vector) verwenden:

```pascal
TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vector.dll');

// Tabelle erstellen
sql.Execute('CREATE TABLE images(id INTEGER PRIMARY KEY, embedding BLOB, label TEXT);');

// Vector initialisieren
sql.Execute('SELECT vector_init(''images'', ''embedding'', ''type=FLOAT32,dimension=384'');');

// Embeddings einfügen (mit lembed generiert)
sql.Execute(
  'INSERT INTO images(embedding, label) ' +
  'SELECT lembed(''all-MiniLM-L6-v2'', description), label ' +
  'FROM source_table;'
);

// Quantisierung für 4-5x Geschwindigkeit
sql.Execute('SELECT vector_quantize(''images'', ''embedding'');');
sql.Execute('SELECT vector_quantize_preload(''images'', ''embedding'');');

// Suche mit Quantisierung
aStmt.Prepare(sql.DB,
  'SELECT e.id, v.distance ' +
  'FROM images AS e ' +
  'JOIN vector_quantize_scan(''images'', ''embedding'', ' +
  '     lembed(''all-MiniLM-L6-v2'', ?), 20) AS v ' +
  'ON e.id = v.rowid;'
);
```

**Siehe auch:** Vollständiges Beispiel mit `vector.dll` + `lembed0.dll` im Verzeichnis `examples/simple-delphi/`:
- `VectorLembedExample.pas` - Wiederverwendbare Klasse mit Quantisierung
- `VectorLembedDemo.dpr` - Konsolen-Demo
- `VectorLembedFormDemo.dpr` - VCL-GUI-Demo
- `README_VECTOR_LEMBED.md` - Ausführliche Dokumentation

## Weitere Embedding-Modelle

### 📖 Vollständiger Modell-Guide

Für eine **umfassende Übersicht** über Embedding-Modelle mit Fokus auf **deutsche Sprache**, siehe:

**→ [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md)**

Enthält:
- ✅ Deutsche Embedding-Modelle
- ✅ Multilinguale Modelle
- ✅ API-basierte Lösungen (Ollama, OpenAI, Cohere)
- ✅ Multimodale Modelle (Bild + Text)
- ✅ Performance-Vergleiche
- ✅ Download-Links
- ✅ Entscheidungshilfen

### Schnellübersicht Beliebte Modelle

#### BGE-M3 ⭐ (Beste lokale Wahl für Deutsch/Multilingual)
- **Download**: https://huggingface.co/gpustack/bge-m3-GGUF
- **Q8_0**: https://huggingface.co/ggml-org/bge-m3-Q8_0-GGUF
- **Dimensionen**: 1024
- **Sprachen**: 100+ inkl. Deutsch
- **Vorteile**: Sehr gute Deutsch- und Cross-Language-Qualität, bis 8192 Token

```pascal
sql.Execute(
  'INSERT INTO temp.lembed_models(name, model) ' +
  'SELECT ''bge-m3'', lembed_model_from_file(''bge-m3-Q8_0.gguf'');'
);

// Vector-Tabelle mit 1024 Dimensionen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[1024]);');
```

#### Nomic Embed Text v1.5 (gute Balance für Deutsch)
- **Download**: https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF
- **Dimensionen**: 768
- **Sprachen**: Multilingual (100+) inkl. Deutsch
- **Vorteile**: Höhere Qualität, längere Kontexte (8k Token)

```pascal
sql.Execute(
  'INSERT INTO temp.lembed_models(name, model) ' +
  'SELECT ''nomic-1.5'', lembed_model_from_file(''nomic-embed-text-v1.5.Q8_0.gguf'');'
);

// Vector-Tabelle mit 768 Dimensionen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[768]);');
```

#### MixedBread AI Large (starkes Dense Retrieval)
- **Download**: https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1
- **Dimensionen**: 1024
- **Vorteile**: Sehr stark für klassisches RAG, besonders englische oder gemischte Daten

Für reine deutsche oder cross-linguale Suche ist BGE-M3 meistens die robustere lokale Wahl. Für ein speziell deutsches Mixedbread-Modell siehe `mixedbread-ai/deepset-mxbai-embed-de-large-v1` (für `sqlite-lembed` ggf. erst zu GGUF konvertieren).

## Best Practices

1. **Ein Modell pro Projekt**: Verwende konsistent dasselbe Modell für alle Embeddings
2. **Dimensionen beachten**: Die Vector-Tabelle muss zur Modell-Dimension passen
3. **Batch-Processing**: Füge mehrere Embeddings in einem INSERT ein
4. **Distance-Metrik**: Standardmäßig L2 (Euclidean), alternativ: COSINE, DOT, L1
5. **Modell-Cache**: Lade das Modell einmal bei Programmstart, nicht bei jedem Query

## Distanz-Metriken

```sql
-- L2 (Standard - Euclidean Distance)
CREATE VIRTUAL TABLE vec_data USING vec0(embedding float[384]);

-- Cosine Similarity (für normalisierte Vektoren)
CREATE VIRTUAL TABLE vec_data USING vec0(
  embedding float[384] distance=cosine
);

-- Dot Product
CREATE VIRTUAL TABLE vec_data USING vec0(
  embedding float[384] distance=dot
);
```

## Performance-Tipps

1. **Indexierung**: `sqlite-vec` erstellt automatisch optimierte Strukturen
2. **LIMIT nutzen**: Begrenze Suchergebnisse auf nötige Anzahl
3. **Quantisierung**: Bei sqlite-vector für 4-5x Geschwindigkeit
4. **Memory**: lembed nutzt standardmäßig wenig RAM (~30MB für kleine Modelle)

## Troubleshooting

### Fehler: "Model not found"
- Prüfe Pfad zur `.gguf` Datei
- Verwende absoluten Pfad: `lembed_model_from_file('C:\path\to\model.gguf')`

### Fehler: "Dimension mismatch"
- Vector-Tabelle muss Modell-Dimensionen entsprechen
- all-MiniLM-L6-v2: 384
- nomic-1.5: 768
- BGE-M3: 1024
- mxbai-large: 1024

### Langsame Performance
- GPU-Unterstützung: Kompiliere lembed0.dll mit CUDA/Metal
- Nutze quantisierte Modelle (Q8_0, Q4_0)
- Bei sqlite-vector: `vector_quantize_preload()` verwenden

## Beispiel-Projekte

Das Repository enthält vollständige, lauffähige Beispiele:

### 📁 examples/simple-delphi/

**Konsolen-Demos:**
- `LembedVectorDemo.dpr` - Dokumentensuche mit vec0 + lembed (einfach)
- `VectorLembedDemo.dpr` - Produktsuche mit vector + lembed (performant, mit Quantisierung)

**VCL-GUI-Demos:**
- `VectorLembedFormDemo.dpr` - Interaktive Produkt-Verwaltung mit GUI

**Wiederverwendbare Klassen:**
- `LembedVectorExample.pas` - `TSemanticDocumentSearch` (vec0 + lembed)
- `VectorLembedExample.pas` - `TProductSemanticSearch` (vector + lembed)

**Dokumentation:**
- `README_LEMBED.md` - Anleitung für vec0 + lembed
- `README_VECTOR_LEMBED.md` - Anleitung für vector + lembed mit Quantisierung
- `EXTENSIONS_COMPARISON.md` - Detaillierter Vergleich aller Extensions
- `README.md` - Übersicht über alle Beispiele

**→ Start hier:** [examples/README.md](examples/README.md)

## Ressourcen

- **sqlite-lembed**: https://github.com/asg017/sqlite-lembed
- **sqlite-vec**: https://github.com/asg017/sqlite-vec
- **sqlite-vector**: https://github.com/sqliteai/sqlite-vector
- **Modelle**: https://huggingface.co/asg017/sqlite-lembed-model-examples
