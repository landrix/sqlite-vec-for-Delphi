# 🚀 SQLite Vector Extensions - Delphi Beispiele

Vollständige Beispiele für semantische Suche mit SQLite in Delphi.

## 📁 Verzeichnisstruktur

```
examples/
└── simple-delphi/
    ├── 📘 Dokumentation
    │   ├── README_LEMBED.md              # vec0 + lembed Beispiele
    │   ├── README_VECTOR_LEMBED.md       # vector + lembed Beispiele
    │   └── EXTENSIONS_COMPARISON.md      # Vergleich aller Extensions
    │
    ├── 🎯 Konsolen-Demos
    │   ├── LembedVectorDemo.dpr          # vec0 + lembed (einfach)
    │   └── VectorLembedDemo.dpr          # vector + lembed (performant)
    │
    ├── 🖥️ GUI-Demos (VCL)
    │   ├── SimpleDelphi.dpr              # Original-Demo (alle Extensions)
    │   └── VectorLembedFormDemo.dpr      # Produkt-Verwaltung GUI
    │
    └── 📦 Wiederverwendbare Klassen
        ├── LembedVectorExample.pas       # TSemanticDocumentSearch
        └── VectorLembedExample.pas       # TProductSemanticSearch
```

## 🎯 Welches Beispiel soll ich nutzen?

### Für Einsteiger: LembedVectorDemo.dpr ✨
```pascal
// Einfachste Variante - vec0.dll + lembed0.dll
// ✅ Wenig Code
// ✅ Schneller Einstieg
// ✅ Für kleine Datenmengen
```
**Start hier:** [README_LEMBED.md](simple-delphi/README_LEMBED.md)

### Für Produktion: VectorLembedDemo.dpr ⭐
```pascal
// Hochperformant - vector.dll + lembed0.dll
// ✅ 4-5x schnellere Suche
// ✅ Quantisierung
// ✅ Große Datenmengen
```
**Start hier:** [README_VECTOR_LEMBED.md](simple-delphi/README_VECTOR_LEMBED.md)

### Für Vergleich: EXTENSIONS_COMPARISON.md 📊
**Detaillierter Vergleich aller Kombinationen**

---

## ⚡ Schnellstart (5 Minuten)

### 1. Modell herunterladen
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```
→ Speichere als `all-MiniLM-L6-v2.e4ce9877.q8_0.gguf` im Programmverzeichnis

### 2. Beispiel öffnen
```
examples\simple-delphi\LembedVectorDemo.dpr
```

### 3. Kompilieren & Ausführen
```
F9
```

**Fertig!** Du solltest jetzt semantische Suche in Aktion sehen.

---

## 📚 Beispiel-Übersicht

### 1. LembedVectorDemo (Konsole) - Einfach

**Was macht es:**
- Erstellt Dokumenten-Datenbank
- Fügt Artikel hinzu
- Semantische Suche
- Findet ähnliche Dokumente

**Code-Beispiel:**
```pascal
Search := TSemanticDocumentSearch.Create('docs.db');
try
  Search.Initialize('model.gguf', 'embedder');
  
  DocId := Search.AddDocument('Title', 'Content here...');
  Results := Search.Search('query text', 10);
  Similar := Search.FindSimilar(DocId, 5);
finally
  Search.Free;
end;
```

**Features:**
- ✅ Dokumente hinzufügen
- ✅ Semantische Suche
- ✅ Ähnlichkeitssuche
- ✅ Statistiken

---

### 2. VectorLembedDemo (Konsole) - Performant

**Was macht es:**
- Erstellt Produkt-Datenbank
- 10 Beispiel-Produkte
- Quantisierung für Speed
- Performance-Vergleich

**Code-Beispiel:**
```pascal
Search := TProductSemanticSearch.Create('products.db');
try
  Search.Initialize('model.gguf', 'embedder');
  
  // Produkte hinzufügen
  Search.AddProduct('Laptop', 'Description', 'Electronics', 1299.00);
  
  // Performance-Boost!
  Search.QuantizeEmbeddings;
  Search.PreloadQuantized;
  
  // Schnelle Suche (quantisiert)
  Results := Search.SearchProducts('computer', 10, True);
finally
  Search.Free;
end;
```

**Features:**
- ✅ Produkt-Management
- ✅ Kategorien + Preise
- ✅ **Quantisierung** (4-5x schneller)
- ✅ Memory Preloading
- ✅ Kategorie-Filter
- ✅ Performance-Messung

---

### 3. VectorLembedFormDemo (GUI) - Interaktiv

**Was macht es:**
- Vollständige GUI-Anwendung
- Produkte hinzufügen/suchen
- Quantisierung per Klick
- Live-Statistiken

**Screenshots (konzeptuell):**
```
┌─────────────────────────────────────────────┐
│ Tab: Produkte                               │
│ ┌─────────────────────────────────────────┐ │
│ │ Name:    [________________]             │ │
│ │ Beschr:  [________________]             │ │
│ │ Kategorie: [Electronics ▼]              │ │
│ │ Preis:   [99.99]                        │ │
│ │ [Hinzufügen] [Beispiele laden]          │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ Tab: Suche                                  │
│ ┌─────────────────────────────────────────┐ │
│ │ Query: [laptop for programming______]   │ │
│ │ ☑ Quantisiert  Max: [10▼]              │ │
│ │ [Suchen]                                │ │
│ │                                          │ │
│ │ Ergebnisse:                             │ │
│ │ 1. MacBook Pro - Distance: 0.45         │ │
│ │ 2. Dell XPS - Distance: 0.52            │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

**Features:**
- ✅ Intuitive GUI
- ✅ Produkt-Verwaltung
- ✅ Echtzeit-Suche
- ✅ Kategorie-Filter
- ✅ Performance-Monitoring
- ✅ Quantisierungs-Control

---

## 🔧 Wiederverwendbare Klassen

### TSemanticDocumentSearch (LembedVectorExample.pas)

**Nutzt:** vec0.dll + lembed0.dll

```pascal
type
  TSemanticDocumentSearch = class
  public
    procedure Initialize(const AModelPath, AModelName: string);
    function AddDocument(const ATitle, AContent: string): Int64;
    function Search(const AQuery: string; ALimit: Integer = 10): TRawUtf8DynArray;
    function FindSimilar(ADocumentId: Int64; ALimit: Integer = 5): TRawUtf8DynArray;
    procedure DeleteDocument(ADocumentId: Int64);
    function GetStats: string;
  end;
```

**Ideal für:**
- Dokumenten-Archive
- Knowledge Bases
- Content-Management
- Wiki-Systeme

---

### TProductSemanticSearch (VectorLembedExample.pas)

**Nutzt:** vector.dll + lembed0.dll

```pascal
type
  TProductSemanticSearch = class
  public
    procedure Initialize(const AModelPath, AModelName: string);
    function AddProduct(const AName, ADescription, ACategory: string; 
                       APrice: Currency): Int64;
    procedure QuantizeEmbeddings;
    procedure PreloadQuantized;
    function SearchProducts(const AQuery: string; ALimit: Integer = 10; 
                           AUseQuantized: Boolean = True): TRawUtf8DynArray;
    function FindSimilarProducts(AProductId: Int64; ALimit: Integer = 5;
                                AUseQuantized: Boolean = True): TRawUtf8DynArray;
    function SearchByCategory(const ACategory, AQuery: string; 
                             ALimit: Integer = 10): TRawUtf8DynArray;
    procedure DeleteProduct(AProductId: Int64);
    function GetStats: string;
    property Quantized: Boolean read FQuantized;
  end;
```

**Ideal für:**
- E-Commerce
- Produktkataloge
- Inventory-Systeme
- Empfehlungssysteme

---

## 📖 Tutorials

### Tutorial 1: Erste Schritte (10 Min)

1. **Modell herunterladen**
   ```
   https://huggingface.co/asg017/sqlite-lembed-model-examples
   ```

2. **LembedVectorDemo.dpr öffnen**

3. **Kompilieren & Ausführen**
   - F9 drücken
   - Ausgabe beobachten

4. **Code verstehen**
   - `Initialize()` - Lädt Modell
   - `AddDocument()` - Fügt Text hinzu
   - `Search()` - Semantische Suche

---

### Tutorial 2: Produkt-Suche (20 Min)

1. **VectorLembedDemo.dpr öffnen**

2. **Code anschauen:**
   ```pascal
   // Produkt hinzufügen
   Search.AddProduct('Name', 'Description', 'Category', 99.99);
   
   // Quantisieren
   Search.QuantizeEmbeddings;
   Search.PreloadQuantized;
   
   // Schnell suchen
   Results := Search.SearchProducts('query', 10, True);
   ```

3. **Experimentieren:**
   - Andere Produkte hinzufügen
   - Verschiedene Suchbegriffe
   - Performance messen

---

### Tutorial 3: Eigene Anwendung (30 Min)

1. **Klasse wählen:**
   - `TSemanticDocumentSearch` für Dokumente
   - `TProductSemanticSearch` für Produkte

2. **In dein Projekt einbinden:**
   ```pascal
   uses
     LembedVectorExample;  // oder VectorLembedExample
   ```

3. **Anpassen:**
   - Eigene Datenbank-Felder
   - Custom Kategorien
   - Eigene Suchlogik

---

## 🎓 Lernressourcen

### Dokumentation (Reihenfolge)

1. **Start:** [README_LEMBED.md](simple-delphi/README_LEMBED.md)
   - Grundkonzepte
   - Einfache Beispiele
   - vec0 + lembed

2. **Fortgeschritten:** [README_VECTOR_LEMBED.md](simple-delphi/README_VECTOR_LEMBED.md)
   - Quantisierung
   - Performance-Optimierung
   - vector + lembed

3. **Vergleich:** [EXTENSIONS_COMPARISON.md](simple-delphi/EXTENSIONS_COMPARISON.md)
   - Alle Extensions
   - Entscheidungshilfe
   - Benchmarks

4. **Referenz:** [../../LEMBED_VECTOR_USAGE.md](../../LEMBED_VECTOR_USAGE.md)
   - Vollständige API
   - Alle Modelle
   - Troubleshooting

---

## 🛠️ Voraussetzungen

### Software
- ✅ Delphi 10.3+
- ✅ mORMot2 Framework
- ✅ Windows (oder Wine für Linux/Mac)

### Dateien
- ✅ `lembed0.dll` (automatisch extrahiert)
- ✅ `vec0.dll` oder `vector.dll` (automatisch extrahiert)
- ✅ Embedding-Modell `.gguf` (Download erforderlich)

### Download Modell
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```
→ ~22 MB, 384 Dimensionen, Englisch

---

## 🐛 Troubleshooting

### "Model file not found"
→ Modell-Datei ins Programmverzeichnis kopieren

### "Extension loading failed"
→ DLLs vorhanden? (sollten automatisch extrahiert werden)

### "Dimension mismatch"
→ Vector-Tabelle muss Modell-Dimensionen entsprechen:
- all-MiniLM-L6-v2: 384
- nomic-1.5: 768

### Langsame Suche
→ Bei vector.dll: `QuantizeEmbeddings()` + `PreloadQuantized()` verwenden

### Mehr Hilfe
→ Siehe [Hauptdokumentation](../../LEMBED_VECTOR_USAGE.md#troubleshooting)

---

## 📊 Performance-Tipps

### 1. Wähle richtige Extension
- Kleine Daten (<10k): vec0
- Große Daten (>10k): vector

### 2. Quantisierung nutzen
```pascal
Search.QuantizeEmbeddings;  // 4-5x schneller
Search.PreloadQuantized;     // + RAM cache
```

### 3. Batch-Processing
```pascal
DB.TransactionBegin;
try
  for Doc in Docs do
    Search.AddDocument(...);
  Search.QuantizeEmbeddings;
  DB.Commit;
except
  DB.Rollback;
end;
```

### 4. Limitiere Ergebnisse
```pascal
Results := Search.Search('query', 10);  // Nicht 1000!
```

---

## 🔗 Links

- **Haupt-Projekt:** [sqlite-vec-for-Delphi](https://github.com/landrix/sqlite-vec-for-Delphi)
- **sqlite-vec:** [GitHub](https://github.com/asg017/sqlite-vec)
- **sqlite-vector:** [GitHub](https://github.com/sqliteai/sqlite-vector)
- **sqlite-lembed:** [GitHub](https://github.com/asg017/sqlite-lembed)
- **mORMot2:** [Synopse](https://synopse.info)
- **Embedding-Modelle:** [HuggingFace](https://huggingface.co/asg017/sqlite-lembed-model-examples)

---

## 📄 Lizenz

Siehe Haupt-Repository Lizenz.

---

## 💡 Weitere Ideen

### Erweiterungen
- Multi-Language Support (Deutsche Modelle)
- Hybrid-Suche (Text + Vektor)
- Caching-Layer
- REST-API Wrapper

### Use Cases
- Dokumenten-Management
- E-Commerce-Suche
- Support-Tickets
- Code-Suche
- Email-Archiv
- Rechtsdatenbank

**Viel Erfolg mit semantischer Suche in Delphi! 🚀**
