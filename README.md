# 🚀 sqlite-vec-for-Delphi

**Semantische Suche für SQLite in Delphi** - Vektorbasierte Ähnlichkeitssuche direkt in deiner Datenbank!

Dieses Projekt ist ein Delphi-Wrapper für die SQLite-Extensions:
- [**sqlite-vec**](https://github.com/asg017/sqlite-vec) - Vektorspeicherung und -suche
- [**sqlite-vector**](https://github.com/sqliteai/sqlite-vector) - Alternative mit Quantisierung
- [**sqlite-lembed**](https://github.com/asg017/sqlite-lembed) - Text-zu-Vektor-Konvertierung mit KI-Modellen

## ✨ Features

- ✅ **Semantische Suche** - Finde Dokumente/Produkte nach Bedeutung, nicht nur Keywords
- ✅ **Offline & Lokal** - Keine Cloud, keine API-Kosten, voller Datenschutz
- ✅ **Verschiedene Extensions** - vec0, vector, lembed - wähle die passende
- ✅ **Deutsche Unterstützung** - Speziell für deutsche Texte optimierbar
- ✅ **Quantisierung** - 4-5x schnellere Suche bei großen Datenmenken
- ✅ **mORMot2 Integration** - Nahtlose Verwendung mit mORMot2
- ✅ **Vollständige Beispiele** - Lauffähige Demos mit GUI und Konsole

## 🎯 Use Cases

- **Dokumentensuche** - Semantische Suche in Wissensdatenbanken
- **E-Commerce** - Produktsuche mit natürlicher Sprache
- **Support-Systeme** - Finde ähnliche Tickets/Anfragen
- **Content-Management** - Intelligente Artikel-Empfehlungen
- **Code-Suche** - Finde Code-Snippets nach Funktion

## 📚 Dokumentation

**→ [DOCS_INDEX.md](DOCS_INDEX.md) - Vollständiger Dokumentations-Index nach Ziel, Sprache & Anwendungsfall**

### 🇩🇪 Für deutsche Anwendungen
- **[GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md)** - 10-Min-Schnellstart mit deutschen Modellen
- **[EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md)** - Deutsche & multilinguale Modelle

### Schnellstart
- **[LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md)** - Kompletter Workflow & Anleitung
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Spickzettel für schnellen Zugriff

### Beispiele
- **[examples/README.md](examples/README.md)** - Übersicht aller Beispiele
- **[examples/simple-delphi/](examples/simple-delphi/)** - Lauffähige Demos

### Vergleiche & Details
- **[EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md)** - vec0 vs. vector
- **[README_LEMBED.md](examples/simple-delphi/README_LEMBED.md)** - vec0 + lembed Guide
- **[README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md)** - vector + lembed Guide

## 🚀 Schnellstart (5 Minuten)

### 🇩🇪 Für deutsche Anwendungen
**→ [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md)** - Kompletter Guide mit deutschen Modellen & Beispielen

### English / Universal

#### 1. Embedding-Modell herunterladen
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

#### 2. Beispiel öffnen
```
examples\simple-delphi\LembedVectorDemo.dpr
```

#### 3. Kompilieren & Ausführen
```
F9
```

**Fertig!** Du siehst jetzt semantische Suche in Aktion.

## 💻 Code-Beispiel

```pascal
uses
  LembedVectorExample;

var
  Search: TSemanticDocumentSearch;
  Results: TRawUtf8DynArray;
begin
  // Datenbank erstellen
  Search := TSemanticDocumentSearch.Create('docs.db');
  try
    // Modell laden
    Search.Initialize('all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'embedder');
    
    // Dokument hinzufügen
    Search.AddDocument('Titel', 'Inhalt des Dokuments...');
    
    // Semantisch suchen
    Results := Search.Search('Suchbegriff', 10);
    
    // Ergebnisse anzeigen
    for Result in Results do
      WriteLn(Utf8ToString(Result));
  finally
    Search.Free;
  end;
end;
```

## 📦 Enthaltene Extensions

### sqlite-vec v0.1.7-alpha.2
- **Quelle:** [asg017/sqlite-vec](https://github.com/asg017/sqlite-vec/releases/tag/v0.1.7-alpha.2)
- **Datei:** `vec0.dll`
- **Features:** Virtuelle Tabellen, einfache API

### sqlite-vector v0.9.34
- **Quelle:** [sqliteai/sqlite-vector](https://github.com/sqliteai/sqlite-vector/releases)
- **Datei:** `vector.dll`
- **Features:** Quantisierung, 4-5x schneller für große Daten

### sqlite-lembed v0.0.1-alpha.8
- **Quelle:** [asg017/sqlite-lembed](https://github.com/asg017/sqlite-lembed/releases/tag/v0.0.1-alpha.8)
- **Datei:** `lembed0.dll`
- **Features:** Text-zu-Vektor mit GGUF-Modellen

## 🌍 Deutsche Embedding-Modelle

Speziell für deutsche Texte empfohlene Modelle:

| Modell | Dimensionen | Qualität | Download |
|--------|-------------|----------|----------|
| **nomic-embed-text-v1.5** ⭐ | 768 | ⭐⭐⭐⭐ | [Link](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF) |
| **mxbai-embed-large-v1** | 1024 | ⭐⭐⭐⭐⭐ | [Link](https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1) |
| all-MiniLM-L6-v2 | 384 | ⭐⭐⭐ | [Link](https://huggingface.co/asg017/sqlite-lembed-model-examples) |

**→ Mehr Modelle:** [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md)

## 📊 Performance

### Embedding-Generierung (10.000 Dokumente)
- all-MiniLM-L6-v2: ~45 Sekunden
- nomic-v1.5 (Q8): ~2.5 Minuten
- mxbai-large (Q8): ~4 Minuten

### Suche (10.000 Vektoren)
- vec0 (normal): ~150ms
- vector (quantisiert): ~30ms ⚡
- vector (preloaded): ~15ms ⚡⚡

**Mit Quantisierung 4-5x schneller!**

## 🛠️ Voraussetzungen

- **Delphi:** 10.3 oder höher
- **Framework:** [mORMot2](https://github.com/synopse/mORMot2)
- **OS:** Windows (Linux/Mac mit Wine möglich)
- **Embedding-Modell:** GGUF-Datei (siehe Download-Links)

## 📖 Beispiel-Projekte

### Konsolen-Demos
- **LembedVectorDemo.dpr** - Einfache Dokumentensuche (vec0 + lembed)
- **VectorLembedDemo.dpr** - Produktsuche mit Quantisierung (vector + lembed)

### VCL-GUI-Demos
- **SimpleDelphi.dpr** - Original-Demo (alle Extensions)
- **VectorLembedFormDemo.dpr** - Interaktive Produkt-Verwaltung

### Wiederverwendbare Klassen
- **LembedVectorExample.pas** - `TSemanticDocumentSearch`
- **VectorLembedExample.pas** - `TProductSemanticSearch`

## 🤝 Danksagungen

Dieses Projekt basiert auf der exzellenten Arbeit von:
- [Alex Garcia (asg017)](https://github.com/asg017) - sqlite-vec, sqlite-lembed
- [SQLite Cloud](https://github.com/sqliteai) - sqlite-vector
- [Arnaud Bouchez (synopse)](https://github.com/synopse) - mORMot2

## 📄 Lizenz

Siehe [LICENSE](LICENSE) Datei.

## 🔗 Links

- **sqlite-vec:** https://github.com/asg017/sqlite-vec
- **sqlite-vector:** https://github.com/sqliteai/sqlite-vector
- **sqlite-lembed:** https://github.com/asg017/sqlite-lembed
- **mORMot2:** https://github.com/synopse/mORMot2
- **Embedding-Modelle:** https://huggingface.co/asg017/sqlite-lembed-model-examples

---

**Happy Semantic Searching! 🎉**