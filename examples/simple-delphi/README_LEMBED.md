# SQLite Lembed + Vec Beispiele für Delphi

Dieses Verzeichnis enthält praktische Beispiele für die Verwendung von **sqlite-lembed** und **sqlite-vec** in Delphi-Anwendungen.

## Dateien

### 1. SimpleDelphiUnit1.pas
Grundlegendes Beispiel mit einer VCL-Form, das zeigt:
- Laden der Extensions (`lembed0.dll` und `vec0.dll`)
- Registrierung eines Embedding-Modells
- Semantische Suche über Artikel-Überschriften
- Integration mit mORMot2

**Verwendung:**
- Öffne `SimpleDelphi.dproj`
- Stelle sicher, dass `all-MiniLM-L6-v2.e4ce9877.q8_0.gguf` im Programmverzeichnis liegt
- Kompiliere und führe aus

### 2. LembedVectorExample.pas
Eine wiederverwendbare Klasse `TSemanticDocumentSearch` mit:
- Vollständiger Dokumentenverwaltung
- Semantischer Suche
- Ähnlichkeits-Suche (Find Similar)
- Statistiken
- Fehlerbehandlung

**API:**
```pascal
var
  Search: TSemanticDocumentSearch;
begin
  Search := TSemanticDocumentSearch.Create('mydb.db');
  try
    // Initialisieren
    Search.Initialize('model.gguf', 'modelname');
    
    // Dokument hinzufügen
    DocId := Search.AddDocument('Titel', 'Inhalt...');
    
    // Suchen
    Results := Search.Search('Suchbegriff', 10);
    
    // Ähnliche finden
    Similar := Search.FindSimilar(DocId, 5);
    
    // Löschen
    Search.DeleteDocument(DocId);
  finally
    Search.Free;
  end;
end;
```

### 3. LembedVectorDemo.dpr
Konsolen-Demo-Programm, das `TSemanticDocumentSearch` verwendet und demonstriert:
- Initialisierung
- Hinzufügen mehrerer Dokumente
- Verschiedene Suchanfragen
- Ähnlichkeits-Suche
- Löschen von Dokumenten

**Ausführung:**
```cmd
LembedVectorDemo.exe
```

## Voraussetzungen

### 1. Embedding-Modell herunterladen

**all-MiniLM-L6-v2** (empfohlen für den Einstieg):
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

**Eigenschaften:**
- Größe: ~22 MB
- Dimensionen: 384
- Sprache: Englisch (funktioniert begrenzt auch mit Deutsch)
- Gut für: Allgemeine semantische Suche, Ähnlichkeitsvergleiche

**Alternative Modelle:**

| Modell | Dimensionen | Größe | Qualität | Download |
|--------|------------|-------|----------|----------|
| all-MiniLM-L6-v2 | 384 | 22 MB | Gut | [Link](https://huggingface.co/asg017/sqlite-lembed-model-examples/tree/main/all-MiniLM-L6-v2) |
| nomic-embed-text-v1.5 | 768 | ~500 MB | Sehr gut | [Link](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF) |
| mxbai-embed-large-v1 | 1024 | ~1 GB | Exzellent | [Link](https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1) |

### 2. DLL-Dateien

Die DLLs werden automatisch aus den Ressourcen extrahiert:
- `lembed0.dll` - Generiert Embeddings aus Text
- `vec0.dll` - Speichert und durchsucht Vektoren

**Oder manuell:**
- Kopiere `lembed0.dll` von `lib\sqlite-lembed\` ins Programmverzeichnis
- Kopiere `vec0.dll` von `lib\sqlite-vec\` ins Programmverzeichnis

### 3. mORMot2

Stelle sicher, dass der mORMot2-Pfad in den Projekt-Optionen korrekt ist.

## Schnellstart

### Minimal-Beispiel

```pascal
uses
  LembedVectorExample, System.SysUtils;

var
  Search: TSemanticDocumentSearch;
  Results: TRawUtf8DynArray;
  i: Integer;
begin
  // 1. Datenbank erstellen
  Search := TSemanticDocumentSearch.Create('mydb.db');
  try
    // 2. Initialisieren mit Modell
    Search.Initialize('all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'embedder');
    
    // 3. Dokumente hinzufügen
    Search.AddDocument(
      'Machine Learning Tutorial',
      'Learn about neural networks and deep learning...'
    );
    
    Search.AddDocument(
      'Database Design',
      'Best practices for relational database design...'
    );
    
    // 4. Semantisch suchen
    Results := Search.Search('artificial intelligence', 5);
    
    // 5. Ergebnisse anzeigen
    for i := 0 to High(Results) do
      WriteLn(Utf8ToString(Results[i]));
      
  finally
    Search.Free;
  end;
end;
```

## Wie funktioniert es?

### 1. Text → Embedding
```pascal
// "Hello World" wird zu einem 384-dimensionalen Vektor
Embedding := lembed('model-name', 'Hello World')
// Ergebnis: [0.123, -0.456, 0.789, ..., 0.321]  // 384 Zahlen
```

### 2. Embedding → Speichern
```pascal
// Vektor wird in sqlite-vec Tabelle gespeichert
INSERT INTO vec_documents(rowid, embedding)
VALUES (1, lembed('model', 'Hello World'));
```

### 3. Suche
```pascal
// Finde ähnliche Vektoren
WHERE embedding MATCH lembed('model', 'Hi there')
// Vergleicht den Query-Vektor mit allen gespeicherten Vektoren
// Gibt die ähnlichsten zurück (niedrigste Distance)
```

### Distance (Abstand)
- **Niedriger Wert** = Sehr ähnlich (z.B. 0.5)
- **Hoher Wert** = Nicht ähnlich (z.B. 2.0)

## Anwendungsfälle

### 1. Dokumentensuche
Finde Dokumente basierend auf Bedeutung, nicht nur Stichworten:
```pascal
Search.Search('Wie funktioniert KI?', 10)
// Findet auch Dokumente über "Machine Learning", "Neural Networks", etc.
```

### 2. Duplikat-Erkennung
```pascal
Similar := Search.FindSimilar(DocId, 5);
// Findet ähnliche/doppelte Dokumente
```

### 3. Empfehlungssystem
```pascal
// Nutzer liest Dokument mit ID 42
Recommendations := Search.FindSimilar(42, 5);
// Empfehle ähnliche Dokumente
```

### 4. Kategorisierung
```pascal
// Definiere Kategorien als Referenz-Dokumente
CatId_Tech := Search.AddDocument('Tech Category', 'technology computers software...');
CatId_Sport := Search.AddDocument('Sport Category', 'football basketball sports...');

// Neues Dokument kategorisieren
NewDocId := Search.AddDocument('Article', 'New smartphone released...');
Similar := Search.FindSimilar(NewDocId, 2);
// Schaut, welche Kategorie am nächsten ist
```

## Performance-Tipps

### 1. Batch-Insert
```pascal
// Besser: Viele Dokumente in einer Transaktion
FDatabase.TransactionBegin;
try
  for i := 1 to 1000 do
    Search.AddDocument(...);
  FDatabase.Commit;
except
  FDatabase.Rollback;
  raise;
end;
```

### 2. Limitiere Ergebnisse
```pascal
// Nur Top 10 statt alle
Results := Search.Search('query', 10);  // Schneller!
```

### 3. Modell-Wahl
- **Kleine Datenmengen (<10k Docs)**: all-MiniLM-L6-v2
- **Mittlere Datenmengen**: nomic-embed-text-v1.5
- **Große Datenmengen + Qualität**: mxbai-embed-large-v1

### 4. Quantisierte Modelle
Nutze `.Q8_0` oder `.Q4_0` Versionen für schnellere Generierung:
```
all-MiniLM-L6-v2.e4ce9877.q8_0.gguf  // Q8_0 = Quantisiert
```

## Fehlerbehandlung

### "Model file not found"
```pascal
// Absoluten Pfad verwenden
Search.Initialize('C:\models\all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'model');
```

### "Dimension mismatch"
```pascal
// Vector-Tabelle muss Modell-Dimensionen entsprechen:
// all-MiniLM-L6-v2 = 384
// nomic-1.5 = 768
// mxbai-large = 1024

// Falsch:
CREATE VIRTUAL TABLE vec USING vec0(embedding float[768]);  // 768
lembed('all-MiniLM-L6-v2', 'text')  // Erzeugt 384 → Fehler!

// Richtig:
CREATE VIRTUAL TABLE vec USING vec0(embedding float[384]);  // 384
```

### Langsame Performance
- Verwende quantisierte Modelle (`.Q8_0`, `.Q4_0`)
- Kompiliere `lembed0.dll` mit GPU-Support (CUDA/Metal)
- Nutze Batch-Processing
- Limitiere Suchergebnisse

## Weitere Ressourcen

- [Hauptdokumentation](../../LEMBED_VECTOR_USAGE.md)
- [sqlite-lembed GitHub](https://github.com/asg017/sqlite-lembed)
- [sqlite-vec GitHub](https://github.com/asg017/sqlite-vec)
- [Embedding-Modelle](https://huggingface.co/asg017/sqlite-lembed-model-examples)
- [mORMot2 Dokumentation](https://synopse.info/files/html/Synopse%20mORMot%202%20Framework%20SAD%201.18.html)

## Lizenz

Siehe Haupt-Repository Lizenz.
