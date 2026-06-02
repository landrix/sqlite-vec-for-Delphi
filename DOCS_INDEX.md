# 📚 Dokumentations-Index

Komplette Übersicht aller Dokumentationen für sqlite-vec-for-Delphi.

## 🎯 Nach Ziel

### Ich will schnell starten
- **[GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md)** - 10-Min-Guide für deutsche Apps
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Code-Snippets & Spickzettel
- **[examples/README.md](examples/README.md)** - Lauffähige Beispiele

### Ich brauche vollständige Infos
- **[LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md)** - Kompletter Workflow & API
- **[EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md)** - Alle Modelle (deutsch!)
- **[EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md)** - Vergleich vec0 vs vector

### Ich habe spezielle Anforderungen
- **Deutsche Texte** → [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) - Deutsche Modelle
- **Performance** → [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md) - Quantisierung
- **Einfachheit** → [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md) - vec0 + lembed
- **Multimodal** → [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) - CLIP & Co

---

## 📖 Nach Dokumenttyp

### 🚀 Schnellstart-Guides

| Datei | Beschreibung | Dauer | Zielgruppe |
|-------|--------------|-------|------------|
| [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md) | Deutsche Anwendungen | 10 Min | 🇩🇪 Deutsche Entwickler |
| [README.md](README.md) | Projekt-Übersicht | 5 Min | Alle |
| [examples/README.md](examples/README.md) | Beispiel-Übersicht | 5 Min | Einsteiger |

### 📘 Vollständige Anleitungen

| Datei | Beschreibung | Umfang | Best für |
|-------|--------------|--------|----------|
| [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Kompletter Workflow | ⭐⭐⭐⭐⭐ | Alle Features verstehen |
| [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Modell-Übersicht | ⭐⭐⭐⭐⭐ | Modellwahl, Deutsch |
| [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md) | vector.dll Guide | ⭐⭐⭐⭐ | Produktion |
| [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md) | vec0.dll Guide | ⭐⭐⭐ | Prototyping |

### 🔍 Vergleiche & Referenzen

| Datei | Beschreibung | Nützlich für |
|-------|--------------|--------------|
| [EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md) | vec0 vs. vector | Entscheidungsfindung |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Code-Spickzettel | Schnelle Antworten |

---

## 🎓 Nach Erfahrungslevel

### 👶 Anfänger (noch nie semantische Suche gemacht)

1. **Start:** [examples/README.md](examples/README.md) - Was ist das überhaupt?
2. **Dann:** [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md) - Erstes Beispiel
3. **Üben:** `examples/simple-delphi/LembedVectorDemo.dpr` ausführen
4. **Vertiefen:** [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md)

### 👨‍💻 Fortgeschritten (SQLite-Kenntnisse)

1. **Start:** [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) - Überblick
2. **Modell wählen:** [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md)
3. **Performance:** [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md)
4. **Code:** `VectorLembedExample.pas` anschauen

### 🧙 Experte (Vector-Search-Erfahrung)

1. **Vergleich:** [EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md)
2. **Referenz:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
3. **Modelle:** [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) - API-Section
4. **Source:** Code direkt nutzen und anpassen

---

## 🌍 Nach Sprache / Region

### 🇩🇪 Deutsche Anwendungen

| Prio | Dokument | Warum |
|------|----------|-------|
| 1 | [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md) | Schnellster Einstieg |
| 2 | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Deutsche Modelle |
| 3 | [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md) | Produktions-Setup |

**Empfohlene Modelle:**
- BGE-M3 (1024 Dim)
- nomic-embed-text-v1.5 (768 Dim)

### 🌐 Internationale Anwendungen

| Prio | Dokument | Warum |
|------|----------|-------|
| 1 | [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Universeller Guide |
| 2 | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Multilinguale Modelle |
| 3 | [examples/README.md](examples/README.md) | Beispiele |

**Empfohlene Modelle:**
- nomic-embed-text-v1.5 (100+ Sprachen)
- multilingual-e5-large

### 🇬🇧 English-only

| Prio | Dokument | Warum |
|------|----------|-------|
| 1 | [README.md](README.md) | Project overview |
| 2 | [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick code snippets |
| 3 | [examples/README.md](examples/README.md) | Examples |

**Recommended Models:**
- all-MiniLM-L6-v2 (384 Dim, fast)
- OpenAI text-embedding-3

---

## 🎯 Nach Anwendungsfall

### E-Commerce / Produktsuche

| Was | Dokument | Kapitel |
|-----|----------|---------|
| Konzept | [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Workflow |
| Code | [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md) | TProductSemanticSearch |
| Modell | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Deutsche Modelle |
| Beispiel | `VectorLembedDemo.dpr` | - |

**Setup:**
- Extension: vector.dll + lembed0.dll
- Modell: BGE-M3 oder nomic-v1.5
- Features: Quantisierung, Kategorien, Preise

### Dokumenten-Management

| Was | Dokument | Kapitel |
|-----|----------|---------|
| Konzept | [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Vollständiges Beispiel |
| Code | [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md) | TSemanticDocumentSearch |
| Modell | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Nach Sprache |
| Beispiel | `LembedVectorDemo.dpr` | - |

**Setup:**
- Extension: vec0.dll + lembed0.dll
- Modell: BGE-M3 oder nomic-v1.5 (für Deutsch)
- Features: Einfach, schnell zu implementieren

### Multimodale Suche (Bild + Text)

| Was | Dokument | Kapitel |
|-----|----------|---------|
| Modelle | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Multimodale Modelle |
| API | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Ollama / Jina CLIP |

**Setup:**
- Extension: vector.dll
- Modell: Jina CLIP v2 (API) oder Ollama llava
- Features: Text & Bilder im gleichen Vektorraum

### Knowledge Base / FAQ

| Was | Dokument | Kapitel |
|-----|----------|---------|
| Schnellstart | [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md) | FAQ-Beispiel |
| Konzept | [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Semantische Suche |
| Code | [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md) | Dokumentensuche |

---

## 🔧 Nach Technik

### Extensions

| Extension | Dokumentation | Best für |
|-----------|---------------|----------|
| **vec0.dll** | [README_LEMBED.md](examples/simple-delphi/README_LEMBED.md) | Einfachheit, kleine Daten |
| **vector.dll** | [README_VECTOR_LEMBED.md](examples/simple-delphi/README_VECTOR_LEMBED.md) | Performance, große Daten |
| **lembed0.dll** | [LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md) | Text → Vektor |
| **Alle** | [EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md) | Vergleich |

### Embedding-Quellen

| Quelle | Dokumentation | Vorteile |
|--------|---------------|----------|
| **GGUF (lokal)** | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Offline, kostenlos |
| **Ollama API** | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Lokal + API, flexibel |
| **OpenAI API** | [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) | Beste Qualität |
| **Custom** | [EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md) | Volle Kontrolle |

---

## 📝 Checkliste vor dem Start

### Planung

- [ ] Anwendungsfall definiert? (E-Commerce, Docs, etc.)
- [ ] Sprache festgelegt? (Deutsch, Multilingual, English)
- [ ] Datenmenge geschätzt? (<10k, >10k)
- [ ] Offline oder Cloud-API? (Datenschutz, Kosten)

### Dokumente gelesen

- [ ] [README.md](README.md) - Projekt verstanden
- [ ] [GERMAN_QUICKSTART.md](GERMAN_QUICKSTART.md) - Falls deutsch
- [ ] [EMBEDDING_MODELS_GUIDE.md](EMBEDDING_MODELS_GUIDE.md) - Modell gewählt
- [ ] [EXTENSIONS_COMPARISON.md](examples/simple-delphi/EXTENSIONS_COMPARISON.md) - Extension gewählt

### Setup

- [ ] Modell heruntergeladen (.gguf Datei)
- [ ] Beispiel-Projekt läuft (LembedVectorDemo oder VectorLembedDemo)
- [ ] Dimensionen geprüft (384/768/1024)
- [ ] Code-Klasse gewählt (TSemanticDocumentSearch oder TProductSemanticSearch)

### Entwicklung

- [ ] Erste Daten eingefügt
- [ ] Erste Suche funktioniert
- [ ] Performance gemessen
- [ ] Bei vector.dll: Quantisierung getestet

---

## 🔗 Quick-Links

### Am häufigsten benötigt

- 🇩🇪 **[Deutsche Apps](GERMAN_QUICKSTART.md)**
- ⚡ **[Code-Snippets](QUICK_REFERENCE.md)**
- 📦 **[Beispiele](examples/README.md)**
- 🤖 **[Modelle](EMBEDDING_MODELS_GUIDE.md)**

### Detaillierte Guides

- 📘 **[Vollständiger Guide](LEMBED_VECTOR_USAGE.md)**
- ⚙️ **[vec0 Guide](examples/simple-delphi/README_LEMBED.md)**
- 🚀 **[vector Guide](examples/simple-delphi/README_VECTOR_LEMBED.md)**
- ⚖️ **[Vergleich](examples/simple-delphi/EXTENSIONS_COMPARISON.md)**

### Downloads

- **Modelle:** https://huggingface.co/asg017/sqlite-lembed-model-examples
- **BGE-M3 GGUF:** https://huggingface.co/gpustack/bge-m3-GGUF
- **Nomic v1.5:** https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF
- **mxbai Large:** https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1

---

## 🆘 Hilfe & Support

### Bei Problemen

1. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Häufige Fehler
2. **[LEMBED_VECTOR_USAGE.md](LEMBED_VECTOR_USAGE.md)** - Troubleshooting-Kapitel
3. **GitHub Issues:** [sqlite-vec-for-Delphi Issues](https://github.com/landrix/sqlite-vec-for-Delphi/issues)

### Weitere Ressourcen

- **mORMot2 Forum:** https://synopse.info/forum
- **sqlite-vec Docs:** https://github.com/asg017/sqlite-vec
- **sqlite-lembed Docs:** https://github.com/asg017/sqlite-lembed

---

## 🎓 Lernpfad

### Woche 1: Grundlagen
- [ ] README.md lesen
- [ ] GERMAN_QUICKSTART.md durcharbeiten
- [ ] LembedVectorDemo.dpr ausführen
- [ ] Eigene Testdaten einfügen

### Woche 2: Vertiefen
- [ ] LEMBED_VECTOR_USAGE.md studieren
- [ ] EMBEDDING_MODELS_GUIDE.md durchgehen
- [ ] Verschiedene Modelle testen
- [ ] Performance messen

### Woche 3: Produktion
- [ ] VectorLembedDemo.dpr verstehen
- [ ] Quantisierung testen
- [ ] In eigenes Projekt integrieren
- [ ] Optimierungen vornehmen

---

**Viel Erfolg! 🚀**
