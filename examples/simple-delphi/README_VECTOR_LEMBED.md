# SQLite Vector + Lembed Beispiel

Dieses Beispiel zeigt die Verwendung von **sqlite-vector** (`vector.dll`) mit **sqlite-lembed** (`lembed0.dll`) für hochperformante semantische Suche mit Quantisierung.

## 🔑 Unterschied zu vec0.dll

| Feature | **vector.dll** (sqlite-vector) | **vec0.dll** (sqlite-vec) |
|---------|-------------------------------|---------------------------|
| Tabellen-Typ | Normale SQLite-Tabelle (BLOB) | Virtuelle Tabelle |
| Quantisierung | ✅ Ja (4-5x schneller) | ❌ Nein |
| Pre-Loading | ✅ Ja (RAM-Cache) | ❌ Nein |
| Speicher-Overhead | Niedriger | Standard |
| API-Komplexität | Höher | Einfacher |
| Best für | Große Datenmengen (>10k) | Kleine bis mittlere Daten |

## 📁 Dateien

### 1. VectorLembedExample.pas
Wiederverwendbare Klasse `TProductSemanticSearch` mit:
- Produkt-Management mit Kategorien und Preisen
- Quantisierung für 4-5x Geschwindigkeit
- Memory Preloading für maximale Performance
- Kategorie-Filter mit semantischer Sortierung

### 2. VectorLembedDemo.dpr
Konsolen-Demo mit:
- 10 Beispiel-Produkten (Elektronik, Möbel, Bücher)
- Mehrere semantische Suchanfragen
- Performance-Vergleich (Normal vs. Quantisiert)
- Ähnlichkeitssuche

## 🚀 Schnellstart

### Voraussetzungen

1. **Modell herunterladen:**
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

Für deutsche oder mehrsprachige Produktdaten zuerst BGE-M3 (1024 Dimensionen) oder Nomic v1.5 (768 Dimensionen) testen. Siehe [../../EMBEDDING_MODELS_GUIDE.md](../../EMBEDDING_MODELS_GUIDE.md).

2. **DLLs:**
- `lembed0.dll` (aus `lib\sqlite-lembed\`)
- `vector.dll` (aus `lib\sqlite-vector\`)

### Ausführen

```cmd
cd examples\simple-delphi
VectorLembedDemo.exe
```

### Code-Beispiel

```pascal
uses
  VectorLembedExample;

var
  Search: TProductSemanticSearch;
  Results: TRawUtf8DynArray;
begin
  Search := TProductSemanticSearch.Create('products.db');
  try
    // Initialisieren
    Search.Initialize('all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'embedder');
    
    // Produkte hinzufügen
    Search.AddProduct(
      'Laptop XYZ',
      'Powerful laptop for development',
      'Electronics',
      1299.00
    );
    
    // WICHTIG: Quantisierung für Performance
    Search.QuantizeEmbeddings;      // INT8 statt FLOAT32
    Search.PreloadQuantized;         // In RAM laden
    
    // Semantisch suchen (quantisiert = 4-5x schneller)
    Results := Search.SearchProducts('computer for programming', 10, True);
    
    // Ähnliche Produkte finden
    Results := Search.FindSimilarProducts(ProductId, 5, True);
    
  finally
    Search.Free;
  end;
end;
```

## 🔧 API-Dokumentation

### Initialize
```pascal
procedure Initialize(const AModelPath: string; const AModelName: string = 'embedder');
```
Lädt Extensions und registriert Embedding-Modell.

### AddProduct
```pascal
function AddProduct(const AName, ADescription, ACategory: string; 
                   APrice: Currency): Int64;
```
Fügt Produkt hinzu und generiert automatisch Embedding.
- Kombiniert Name + Description + Category für besseres Embedding
- Gibt ID des neuen Produkts zurück

### QuantizeEmbeddings
```pascal
procedure QuantizeEmbeddings;
```
**WICHTIG für Performance!** Konvertiert FLOAT32 → INT8.
- Reduziert Speicher um ~75%
- Ermöglicht 4-5x schnellere Suche
- Minimaler Genauigkeitsverlust (<1%)
- Sollte nach dem Hinzufügen vieler Produkte aufgerufen werden

### PreloadQuantized
```pascal
procedure PreloadQuantized;
```
Lädt quantisierte Embeddings in RAM.
- Maximale Geschwindigkeit
- Muss nach `QuantizeEmbeddings` aufgerufen werden

### SearchProducts
```pascal
function SearchProducts(const AQuery: string; ALimit: Integer = 10; 
                       AUseQuantized: Boolean = True): TRawUtf8DynArray;
```
Semantische Produktsuche.
- `AUseQuantized=True`: 4-5x schneller (empfohlen)
- `AUseQuantized=False`: Präziser, aber langsamer

### FindSimilarProducts
```pascal
function FindSimilarProducts(AProductId: Int64; ALimit: Integer = 5;
                            AUseQuantized: Boolean = True): TRawUtf8DynArray;
```
Findet ähnliche Produkte (z.B. für "Kunden kauften auch").

### SearchByCategory
```pascal
function SearchByCategory(const ACategory, AQuery: string; 
                         ALimit: Integer = 10): TRawUtf8DynArray;
```
Kombiniert Kategorie-Filter mit semantischer Suche.

## 📊 Quantisierung erklärt

### Was ist Quantisierung?

```
FLOAT32 (Original):     [0.3456, -0.8923, 0.1234, ...]  // 4 Bytes pro Wert
         ↓ Quantisierung
INT8 (Quantisiert):     [88, -227, 31, ...]             // 1 Byte pro Wert
```

### Vorteile:
- ✅ **4-5x schnellere Suche**
- ✅ **75% weniger Speicher**
- ✅ **Minimal Genauigkeitsverlust** (<1%)
- ✅ **Besser für große Datenmengen**

### Workflow:

```pascal
// 1. Produkte hinzufügen
for i := 1 to 10000 do
  Search.AddProduct(...);

// 2. Quantisieren (einmal nach allen Inserts)
Search.QuantizeEmbeddings;

// 3. In RAM laden (optional, für max. Speed)
Search.PreloadQuantized;

// 4. Schnelle Suche genießen!
Results := Search.SearchProducts('query', 10, True);
```

## 🎯 Anwendungsfälle

### 1. E-Commerce Produktsuche
```pascal
// Kunde sucht: "günstige Laptops für Studenten"
Results := Search.SearchProducts('affordable laptops for students', 20, True);
```

### 2. Empfehlungssystem
```pascal
// Kunde betrachtet Produkt #123
Recommendations := Search.FindSimilarProducts(123, 5, True);
// "Kunden, die dies kauften, kauften auch..."
```

### 3. Kategorie-Navigation
```pascal
// "Zeige mir Gaming-Mäuse"
Results := Search.SearchByCategory('Electronics', 'gaming mouse', 10);
```

### 4. Duplikat-Erkennung
```pascal
NewProductId := Search.AddProduct('iPhone 15', '...', 'Electronics', 999);
Similar := Search.FindSimilarProducts(NewProductId, 1, True);
if (Distance < 0.5) then
  ShowMessage('Ähnliches Produkt bereits vorhanden!');
```

## ⚡ Performance-Tipps

### 1. Batch-Processing
```pascal
FDatabase.TransactionBegin;
try
  for Product in ProductList do
    Search.AddProduct(...);
  
  // Quantisierung NACH allen Inserts
  Search.QuantizeEmbeddings;
  Search.PreloadQuantized;
  
  FDatabase.Commit;
except
  FDatabase.Rollback;
end;
```

### 2. Wann quantisieren?
- ✅ Nach dem initialen Import von vielen Produkten
- ✅ Nach größeren Updates (>100 neue Produkte)
- ❌ Nach jedem einzelnen Insert (zu teuer!)

### 3. Memory vs. Disk
```pascal
// Ohne Preload: Daten werden von Disk gelesen
Search.QuantizeEmbeddings;

// Mit Preload: Daten im RAM (4-5x schneller)
Search.PreloadQuantized;
```

### 4. Distance-Metriken wählen
```pascal
// Bei Initialize():
FDatabase.Execute(
  'SELECT vector_init(''products'', ''embedding'', ' +
  '''type=FLOAT32,dimension=1024,distance=COSINE'');'  // 1024 = BGE-M3/mxbai, COSINE statt L2
);
```

Verfügbare Metriken:
- **L2** (Standard): Euclidean Distance
- **COSINE**: Für normalisierte Vektoren
- **DOT**: Dot Product
- **L1**: Manhattan Distance
- **SQUARED_L2**: Squared Euclidean

## 🔍 Vergleich: vector.dll vs. vec0.dll

### Wann vector.dll nutzen?
✅ Große Datenmengen (>10,000 Vektoren)
✅ Performance ist kritisch
✅ Bereitschaft für etwas komplexere API
✅ Produktions-Umgebungen

### Wann vec0.dll nutzen?
✅ Kleine bis mittlere Datenmengen
✅ Einfachheit vor Performance
✅ Prototyping / Entwicklung
✅ Virtuelle Tabellen bevorzugt

### Code-Vergleich

**vec0.dll (einfach):**
```pascal
// Virtuelle Tabelle
sql.Execute('CREATE VIRTUAL TABLE vec_data USING vec0(embedding float[384]);');

// Direkt suchen
sql.Execute('SELECT rowid FROM vec_data WHERE embedding MATCH ? AND k = 10;');
```

**vector.dll (performant):**
```pascal
// Normale Tabelle
sql.Execute('CREATE TABLE data(id INTEGER PRIMARY KEY, embedding BLOB);');

// Initialisieren
sql.Execute('SELECT vector_init(''data'', ''embedding'', ''type=FLOAT32,dimension=384'');');

// Quantisieren
sql.Execute('SELECT vector_quantize(''data'', ''embedding'');');
sql.Execute('SELECT vector_quantize_preload(''data'', ''embedding'');');

// Suchen (quantisiert)
sql.Execute('SELECT * FROM data JOIN vector_quantize_scan(...) ON id = rowid;');
```

## 🐛 Troubleshooting

### Fehler: "no such function: vector_init"
→ `vector.dll` nicht geladen. Prüfe `LoadExtensions()`.

### Fehler: "quantization not available"
→ Rufe zuerst `QuantizeEmbeddings()` auf.

### Langsame Suche trotz Quantisierung
→ Vergessen `PreloadQuantized()` aufzurufen?

### "Dimension mismatch"
→ Vector-Init muss Modell-Dimensionen entsprechen:
- all-MiniLM-L6-v2: 384
- nomic-embed-text-v1.5: 768
- BGE-M3: 1024
- mxbai-embed-large-v1: 1024

### Speicher-Warnung bei PreloadQuantized
→ Normal bei großen Datenmengen. Embeddings werden in RAM geladen.

## 📚 Weiterführende Ressourcen

- [Haupt-Dokumentation](../../LEMBED_VECTOR_USAGE.md)
- [sqlite-vector API](../../lib-source/sqlite-vector/API.md)
- [sqlite-vector Quantization Guide](../../lib-source/sqlite-vector/QUANTIZATION.md)
- [sqlite-lembed GitHub](https://github.com/asg017/sqlite-lembed)
- [sqlite-vector GitHub](https://github.com/sqliteai/sqlite-vector)

## 📄 Lizenz

Siehe Haupt-Repository Lizenz.
