# 🌍 Embedding-Modelle für Delphi - Vollständiger Guide

Übersicht über Embedding-Modelle für semantische Suche mit Fokus auf **deutsche Sprache** und verschiedene Einsatzmöglichkeiten.

## 📋 Inhaltsverzeichnis

- [GGUF-Modelle (sqlite-lembed)](#gguf-modelle-für-sqlite-lembed)
- [Deutsche Modelle](#deutsche-embedding-modelle)
- [Multilinguale Modelle](#multilinguale-modelle)
- [API-basierte Modelle (Ollama, OpenAI)](#api-basierte-modelle)
- [Multimodale Modelle](#multimodale-embedding-modelle)
- [Modell-Vergleich](#modell-vergleich-und-empfehlungen)
- [Performance-Benchmarks](#performance-benchmarks)

---

## 🎯 GGUF-Modelle für sqlite-lembed

Diese Modelle funktionieren direkt mit `lembed0.dll` (lokal, offline).

### ⭐ Empfohlene Modelle

#### 1. all-MiniLM-L6-v2 (Englisch - Universal)

**Eigenschaften:**
- **Dimensionen:** 384
- **Größe:** ~22 MB (Q8_0)
- **Sprache:** Englisch (funktioniert begrenzt mit Deutsch)
- **Qualität:** Gut für allgemeine Zwecke
- **Speed:** Sehr schnell

**Download:**
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

**Verwendung:**
```pascal
Search.Initialize('all-MiniLM-L6-v2.e4ce9877.q8_0.gguf', 'miniLM', 384);

// Vector-Tabelle (384 Dimensionen!)
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[384]);');
```

**Best für:**
- Englische Texte
- Prototyping
- Geringe Anforderungen an Deutsch
- Schnelle Tests

---

#### 2. nomic-embed-text-v1.5 (Multilingual)

**Eigenschaften:**
- **Dimensionen:** 768
- **Größe:** ~550 MB (f16), ~275 MB (Q8_0), ~137 MB (Q4_0)
- **Sprache:** Multilingual (inkl. Deutsch)
- **Qualität:** Sehr gut
- **Context:** Bis 8192 Token

**Download:**
```
# F16 (höchste Qualität)
https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.f16.gguf

# Q8_0 (gute Balance)
https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf

# Q4_0 (klein, schnell)
https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_0.gguf
```

**Verwendung:**
```pascal
Search.Initialize('nomic-embed-text-v1.5.Q8_0.gguf', 'nomic', 768);

// Vector-Tabelle (768 Dimensionen!)
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[768]);');
```

**Best für:**
- ✅ **Deutsche Texte**
- ✅ Multilinguale Anwendungen
- ✅ Längere Dokumente (bis 8k Token)
- ✅ Produktionsumgebungen

---

#### 3. mxbai-embed-large-v1 (High-Quality)

**Eigenschaften:**
- **Dimensionen:** 1024
- **Größe:** ~650 MB (Q8_0)
- **Sprache:** Primär Englisch; für Deutsch in der Praxis brauchbar, aber nicht die stärkste Wahl
- **Qualität:** Exzellent für Retrieval/RAG, besonders mit Query-Prompt
- **Context:** Typisch kurze bis mittlere Passagen

**Download:**
```
https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-Q8_0.gguf
```

**Verwendung:**
```pascal
Search.Initialize('mxbai-embed-large-v1-Q8_0.gguf', 'mxbai', 1024);

// Vector-Tabelle (1024 Dimensionen!)
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[1024]);');
```

**Best für:**
- ✅ Sehr gute allgemeine Retrieval-Qualität
- ✅ RAG mit englischen oder gemischten Daten
- ✅ Wenn Genauigkeit wichtiger als Speed

**Hinweis für Query-Prompts:**
Für Suchanfragen empfiehlt Mixedbread einen Prefix wie:
```
Represent this sentence for searching relevant passages: <query>
```
Dokumenttexte werden normalerweise ohne Prefix eingebettet.

**Vergleich zu BGE-M3:**
- `mxbai-embed-large-v1` ist kompakter und auf klassischen Dense Retrieval/RAG sehr stark.
- Für reine deutsche oder cross-linguale Suche ist BGE-M3 meistens die robustere Wahl.
- Für ein deutsches Mixedbread-Modell ist `mixedbread-ai/deepset-mxbai-embed-de-large-v1` interessanter, benötigt für `sqlite-lembed` aber eine passende GGUF-Konvertierung.

---

#### 4. BGE-M3 (Multilingual + Long Context)

**Kompatibilität mit diesem Projekt:**
Die mitgelieferte `sqlite-lembed v0.0.1-alpha.8` DLL kann manche BGE-M3-GGUF-Dateien nicht laden und bricht dann schon bei `lembed_model_from_file(...)` mit `SQL logic error` ab. BGE-M3 deshalb nur mit einer passend neu gebauten `lembed0.dll`/`llama.cpp`-Version verwenden. Für die gebündelte DLL zuerst `all-MiniLM-L6-v2`, `nomic-embed-text-v1.5` oder `mxbai-embed-large-v1` testen.

**Eigenschaften:**
- **Dimensionen:** 1024
- **Größe:** ca. 2.3 GB als HF-Modell; GGUF je nach Quantisierung deutlich kleiner
- **Sprache:** Multilingual, 100+ Sprachen inkl. Deutsch
- **Qualität:** Sehr gut für deutsche, multilinguale und cross-linguale Suche
- **Context:** Bis 8192 Token
- **Funktionen:** Dense Retrieval, Sparse Retrieval und Multi-Vector/ColBERT-artige Repräsentationen

**Download:**
```
# Modellkarte
https://huggingface.co/BAAI/bge-m3

# GGUF-Varianten
https://huggingface.co/gpustack/bge-m3-GGUF
https://huggingface.co/ggml-org/bge-m3-Q8_0-GGUF
```

**Verwendung:**
```pascal
Search.Initialize('bge-m3-Q8_0.gguf', 'bge-m3', 1024);

// Vector-Tabelle (1024 Dimensionen!)
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[1024]);');
```

**Best für:**
- ✅ **Deutsche Texte**
- ✅ Mehrsprachige Datenbestände
- ✅ Cross-Language Search, z.B. deutsche Query gegen englische Dokumente
- ✅ Lange Dokumente oder Abschnitte
- ✅ Wenn du später Hybrid Retrieval ergänzen willst

**Vergleich zu mxbai-embed-large-v1:**

| Kriterium | BGE-M3 | mxbai-embed-large-v1 |
|-----------|--------|----------------------|
| Dimensionen | 1024 | 1024 |
| Sprache | 100+ Sprachen, stark multilingual | Primär Englisch, Deutsch brauchbar |
| Deutsch | Sehr gut | Gut bis sehr gut, abhängig vom Datensatz |
| Cross-lingual | Sehr gut | Schwächer als BGE-M3 |
| Lange Texte | Bis 8192 Token | Eher kurze/mittlere Retrieval-Passagen |
| Retrieval-Typen | Dense + Sparse + Multi-Vector | Dense, Matryoshka/Binary-Support |
| sqlite-vec Nutzung | Dense-Vektor direkt nutzbar | Dense-Vektor direkt nutzbar |
| Empfehlung | Deutsch/multilingual/long-context | Klassisches RAG, besonders Englisch |

---

## 🇩🇪 Deutsche Embedding-Modelle

### ⭐ Speziell für Deutsch optimiert

#### 1. German E5 Base

**Eigenschaften:**
- **Dimensionen:** 768
- **Sprache:** Deutsch (spezialisiert)
- **Basis:** intfloat/e5-base-v2 + deutsche Finetuning

**Hinweis:** Muss erst zu GGUF konvertiert werden!

**PyTorch Modell:**
```
https://huggingface.co/deutsche-telekom/gbert-large-e5-base-v2
```

**Konvertierung zu GGUF:**
```bash
# Mit llama.cpp convert script
python convert-hf-to-gguf.py deutsche-telekom/gbert-large-e5-base-v2 \
  --outfile german-e5-base.gguf --outtype q8_0
```

**Best für:**
- Deutsche Fachtexte
- Rechtsdokumente
- Medizinische Texte

---

#### 2. paraphrase-multilingual-MiniLM-L12-v2

**Eigenschaften:**
- **Dimensionen:** 384
- **Sprache:** 50+ Sprachen inkl. Deutsch
- **Größe:** Klein (~120 MB)

**HuggingFace:**
```
https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2
```

**Konvertierung erforderlich** oder über API (siehe unten).

**Best für:**
- Multilingual Apps
- Kleine Modelle
- Cross-Language Search

---

#### 3. distiluse-base-multilingual-cased-v2

**Eigenschaften:**
- **Dimensionen:** 512
- **Sprache:** 50+ Sprachen
- **Qualität:** Gut

**HuggingFace:**
```
https://huggingface.co/sentence-transformers/distiluse-base-multilingual-cased-v2
```

**Best für:**
- Allgemeine deutsche Texte
- Gute Balance (Qualität/Größe)

---

## 🌐 Multilinguale Modelle

### Top-Empfehlungen für Deutsch + andere Sprachen

| Modell | Dim | Sprachen | Download | Deutsch-Qualität |
|--------|-----|----------|----------|------------------|
| **BGE-M3** | 1024 | 100+ | [Link](https://huggingface.co/gpustack/bge-m3-GGUF) | ⭐⭐⭐⭐⭐ |
| **nomic-embed-text-v1.5** | 768 | 100+ | [Link](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF) | ⭐⭐⭐⭐ |
| **mxbai-embed-large-v1** | 1024 | Primär Englisch | [Link](https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1) | ⭐⭐⭐⭐ |
| **multilingual-e5-large** | 1024 | 100+ | [Link](https://huggingface.co/intfloat/multilingual-e5-large) | ⭐⭐⭐⭐ |
| **LaBSE** | 768 | 109 | [Link](https://huggingface.co/sentence-transformers/LaBSE) | ⭐⭐⭐ |

---

## 🔌 API-basierte Modelle

Für Anwendungen ohne lokale GGUF-Modelle.

### 1. Ollama (Lokal + API)

**Installation:**
```bash
# Windows: https://ollama.ai/download
# Nach Installation:
ollama pull nomic-embed-text
ollama pull mxbai-embed-large
ollama pull all-minilm
```

**Verfügbare Embedding-Modelle:**
- `nomic-embed-text` - 768 Dimensionen, multilingual
- `mxbai-embed-large` - 1024 Dimensionen, starkes Dense Retrieval
- `all-minilm` - 384 Dimensionen, schnell
- `snowflake-arctic-embed` - 1024 Dimensionen, performant

**API-Verwendung (HTTP):**
```pascal
uses
  System.Net.HttpClient, System.JSON;

function GetEmbeddingFromOllama(const AText: string): TArray<Double>;
var
  lHTTP: THTTPClient;
  lRequest: TStringStream;
  lResponse: IHTTPResponse;
  lJSON, lResponseJSON: TJSONObject;
  lEmbedding: TJSONArray;
  i: Integer;
begin
  lHTTP := THTTPClient.Create;
  try
    // Request JSON
    lJSON := TJSONObject.Create;
    try
      lJSON.AddPair('model', 'nomic-embed-text');
      lJSON.AddPair('prompt', AText);
      
      lRequest := TStringStream.Create(lJSON.ToString, TEncoding.UTF8);
      try
        // API Call
        lResponse := lHTTP.Post('http://localhost:11434/api/embeddings', lRequest);
        
        // Parse Response
        lResponseJSON := TJSONObject.ParseJSONValue(lResponse.ContentAsString) as TJSONObject;
        try
          lEmbedding := lResponseJSON.GetValue<TJSONArray>('embedding');
          SetLength(Result, lEmbedding.Count);
          
          for i := 0 to lEmbedding.Count - 1 do
            Result[i] := lEmbedding.Items[i].AsType<Double>;
            
        finally
          lResponseJSON.Free;
        end;
      finally
        lRequest.Free;
      end;
    finally
      lJSON.Free;
    end;
  finally
    lHTTP.Free;
  end;
end;

// Verwendung:
var
  lEmbedding: TArray<Double>;
  lBlob: TBytes;
begin
  lEmbedding := GetEmbeddingFromOllama('Dies ist ein deutscher Text');
  
  // In BLOB konvertieren für SQLite
  lBlob := EmbeddingToBlob(lEmbedding);
  
  // In DB speichern
  sql.Execute('INSERT INTO products(embedding, text) VALUES (?, ?);', 
              [lBlob, 'Dies ist ein deutscher Text']);
end;
```

**Vorteile Ollama:**
- ✅ Lokal (keine Cloud)
- ✅ Kostenlos
- ✅ Einfache API
- ✅ Viele Modelle
- ✅ GPU-Support

---

### 2. OpenAI Embeddings (Cloud API)

**Modelle:**
- `text-embedding-3-small` - 1536 Dimensionen, $0.02 / 1M Token
- `text-embedding-3-large` - 3072 Dimensionen, $0.13 / 1M Token
- `text-embedding-ada-002` - 1536 Dimensionen (Legacy)

**Sprachen:** Exzellent für Deutsch!

**API-Verwendung:**
```pascal
uses
  System.Net.HttpClient, System.JSON;

function GetEmbeddingFromOpenAI(const AText: string; const AApiKey: string): TArray<Double>;
var
  lHTTP: THTTPClient;
  lRequest: TStringStream;
  lResponse: IHTTPResponse;
  lJSON, lResponseJSON: TJSONObject;
  lData: TJSONArray;
  lEmbedding: TJSONArray;
  i: Integer;
begin
  lHTTP := THTTPClient.Create;
  try
    lHTTP.CustomHeaders['Authorization'] := 'Bearer ' + AApiKey;
    lHTTP.ContentType := 'application/json';
    
    lJSON := TJSONObject.Create;
    try
      lJSON.AddPair('model', 'text-embedding-3-small');
      lJSON.AddPair('input', AText);
      
      lRequest := TStringStream.Create(lJSON.ToString, TEncoding.UTF8);
      try
        lResponse := lHTTP.Post('https://api.openai.com/v1/embeddings', lRequest);
        
        lResponseJSON := TJSONObject.ParseJSONValue(lResponse.ContentAsString) as TJSONObject;
        try
          lData := lResponseJSON.GetValue<TJSONArray>('data');
          lEmbedding := (lData.Items[0] as TJSONObject).GetValue<TJSONArray>('embedding');
          
          SetLength(Result, lEmbedding.Count);
          for i := 0 to lEmbedding.Count - 1 do
            Result[i] := lEmbedding.Items[i].AsType<Double>;
            
        finally
          lResponseJSON.Free;
        end;
      finally
        lRequest.Free;
      end;
    finally
      lJSON.Free;
    end;
  finally
    lHTTP.Free;
  end;
end;
```

**Vorteile OpenAI:**
- ✅ Beste Qualität
- ✅ Keine lokale Installation
- ✅ Skalierbar
- ⚠️ Kostet Geld
- ⚠️ Cloud (Datenschutz beachten!)

---

### 3. Cohere Embeddings (Cloud API)

**Modelle:**
- `embed-multilingual-v3.0` - 1024 Dimensionen, **exzellent für Deutsch**
- `embed-english-v3.0` - 1024 Dimensionen
- `embed-multilingual-light-v3.0` - 384 Dimensionen (schneller)

**Besonderheit:** Speziell für Retrieval optimiert!

**API:** Ähnlich wie OpenAI
```
https://api.cohere.ai/v1/embed
```

---

### 4. Voyage AI (Cloud API)

**Modelle:**
- `voyage-large-2` - 1536 Dimensionen
- `voyage-2` - 1024 Dimensionen
- `voyage-lite-02-instruct` - 1024 Dimensionen

**Sprachen:** Multilingual inkl. Deutsch

---

## 🎨 Multimodale Embedding-Modelle

Für Bilder + Text kombiniert.

### 1. CLIP (Contrastive Language-Image Pre-training)

**Eigenschaften:**
- **Text & Bilder** in gemeinsamen Vektorraum
- **Dimensionen:** 512 oder 768 (je nach Variante)
- **Sprachen:** Primär Englisch, multilingual mit mCLIP

**Verfügbare Varianten:**
- `clip-ViT-B-32` - Schnell, 512 Dim
- `clip-ViT-L-14` - Besser, 768 Dim

**HuggingFace:**
```
https://huggingface.co/openai/clip-vit-base-patch32
```

**Hinweis:** Noch kein GGUF-Support in sqlite-lembed, aber:
- Über **Ollama** verfügbar: `ollama pull llava` (enthält CLIP)
- Über **OpenAI API**: `CLIP` Endpoints
- Über **Python-Bridge** (ONNX/PyTorch)

**Verwendung (Konzept):**
```pascal
// Text-Embedding
TextEmbedding := GetCLIPEmbedding('Ein roter Sportwagen');

// Bild-Embedding
ImageEmbedding := GetCLIPEmbedding(ImagePath);

// Beide im gleichen Vektorraum - vergleichbar!
Similarity := CosineSimilarity(TextEmbedding, ImageEmbedding);
```

**Use Cases:**
- Bild-Suche per Text ("zeige mir rote Autos")
- Text-Suche per Bild (Bild hochladen → ähnliche Texte finden)
- Cross-Modal Retrieval

---

### 2. SigLIP (Improved CLIP)

**Eigenschaften:**
- Nachfolger von CLIP
- Bessere Performance
- **Dimensionen:** 768 oder 1152

**HuggingFace:**
```
https://huggingface.co/google/siglip-base-patch16-256
```

---

### 3. ImageBind (Meta)

**Eigenschaften:**
- **6 Modalitäten:** Text, Bild, Audio, Video, Thermal, Depth
- Gemeinsamer Vektorraum

**Noch nicht für sqlite-lembed**, aber über Python/API möglich.

---

### 4. Jina CLIP v2 (Multilingual)

**Eigenschaften:**
- **Dimensionen:** 768
- **Sprachen:** 89+ inkl. Deutsch
- Text + Bilder
- Kommerziell nutzbar

**HuggingFace:**
```
https://huggingface.co/jinaai/jina-clip-v1
```

**API:**
```
https://api.jina.ai/v1/embeddings
```

**Best für:**
- ✅ **Deutsche multimodale Suche**
- ✅ E-Commerce (Produktbilder + Beschreibungen)
- ✅ Medien-Archive

---

## 📊 Modell-Vergleich und Empfehlungen

### Für deutsche Texte (Ranking)

| Rang | Modell | Dimensionen | Größe | Verfügbarkeit | Qualität |
|------|--------|-------------|-------|---------------|----------|
| 🥇 | **BGE-M3** | 1024 | je nach GGUF | GGUF | ⭐⭐⭐⭐⭐ |
| 🥈 | **mxbai-embed-large-v1** | 1024 | 650 MB | GGUF | ⭐⭐⭐⭐ |
| 🥉 | **nomic-embed-text-v1.5** | 768 | 275 MB | GGUF | ⭐⭐⭐⭐ |
| 4 | **OpenAI text-embedding-3** | 1536 | API | Cloud | ⭐⭐⭐⭐⭐ |
| 5 | **Cohere embed-multilingual-v3** | 1024 | API | Cloud | ⭐⭐⭐⭐⭐ |
| 6 | **multilingual-e5-large** | 1024 | ~2 GB | HF* | ⭐⭐⭐⭐ |

*HF = HuggingFace (Konvertierung zu GGUF nötig)

---

### Nach Anwendungsfall

#### 📝 Allgemeine Dokumentensuche (Deutsch)
**Empfehlung:** BGE-M3 (Q8_0) oder nomic-embed-text-v1.5 (Q8_0)
- BGE-M3: beste lokale Wahl für Qualität, multilingual und längere Texte
- Nomic: bessere Balance aus Qualität, Größe und Speed
- Lokal & offline

#### 🛒 E-Commerce / Produktsuche (Deutsch)
**Empfehlung:** BGE-M3 oder mxbai-embed-large-v1 + Quantisierung
- BGE-M3 für deutsche/multilinguale Produktdaten
- mxbai für klassische Dense-Retrieval-Setups und englische Produktdaten
- Mit Quantisierung schnell genug

#### 💼 Enterprise / Kritisch (Deutsch)
**Empfehlung:** OpenAI text-embedding-3-large oder Cohere
- Beste Qualität
- Support verfügbar
- Skalierbar
- ⚠️ Kosten beachten!

#### 🚀 Prototyping / Testing
**Empfehlung:** all-MiniLM-L6-v2
- Sehr klein (22 MB)
- Sehr schnell
- Für erste Tests ausreichend

#### 🎨 Multimodal (Bild + Text, Deutsch)
**Empfehlung:** Jina CLIP v2 (API) oder Ollama llava
- Deutsch-Support
- Text & Bilder
- Praktisch einsetzbar

#### 🌍 Multilingual (viele Sprachen)
**Empfehlung:** BGE-M3
- 100+ Sprachen
- Sehr gute Deutsch- und Cross-Language-Qualität
- Lange Texte bis 8192 Token
- Lokal verfügbar

---

## ⚡ Performance-Benchmarks

### Embedding-Generierung (10.000 Texte, Ø 100 Wörter)

| Modell | Zeit | Speed | GPU? |
|--------|------|-------|------|
| all-MiniLM-L6-v2 (Q8) | ~45s | ⭐⭐⭐⭐⭐ | Optional |
| nomic-v1.5 (Q8) | ~2.5min | ⭐⭐⭐⭐ | Optional |
| BGE-M3 (Q8) | ~4-6min | ⭐⭐⭐ | Empfohlen |
| mxbai-large (Q8) | ~4min | ⭐⭐⭐ | Empfohlen |
| OpenAI API | ~30s | ⭐⭐⭐⭐⭐ | - |
| Ollama (GPU) | ~1min | ⭐⭐⭐⭐⭐ | Ja |

### Such-Performance (10k Vektoren)

| Methode | Zeit | Speed |
|---------|------|-------|
| vec0 (Normal) | ~150ms | ⭐⭐⭐ |
| vector (Quantisiert) | ~30ms | ⭐⭐⭐⭐⭐ |
| vector (Preloaded) | ~15ms | ⭐⭐⭐⭐⭐ |

---

## 🔧 Praktische Beispiele

### Beispiel 1: Nomic v1.5 mit Delphi

```pascal
uses
  VectorLembedExample;

var
  Search: TProductSemanticSearch;
begin
  Search := TProductSemanticSearch.Create('products_de.db');
  try
    // Nomic-Modell (768 Dimensionen!)
    Search.Initialize('nomic-embed-text-v1.5.Q8_0.gguf', 'nomic', 768);
    
    // Deutsche Produkte
    Search.AddProduct(
      'MacBook Pro 16 Zoll',
      'Leistungsstarker Laptop mit M3 Chip, ideal für Entwicklung und Videoschnitt',
      'Elektronik',
      2499.00
    );
    
    // Deutsche Suche
    Results := Search.SearchProducts('tragbarer Computer für Programmierung', 10);
  finally
    Search.Free;
  end;
end;
```

### Beispiel 2: Ollama Integration

```pascal
type
  TOllamaEmbedding = class
  private
    FBaseURL: string;
    FModel: string;
  public
    constructor Create(const AModel: string = 'nomic-embed-text');
    function GetEmbedding(const AText: string): TArray<Double>;
  end;

constructor TOllamaEmbedding.Create(const AModel: string);
begin
  FBaseURL := 'http://localhost:11434';
  FModel := AModel;
end;

function TOllamaEmbedding.GetEmbedding(const AText: string): TArray<Double>;
var
  lHTTP: THTTPClient;
  lRequest: TStringStream;
  lResponse: IHTTPResponse;
  lJSON: TJSONObject;
begin
  // [Implementation wie oben]
  // Gibt TArray<Double> zurück
end;

// Verwendung:
var
  Ollama: TOllamaEmbedding;
  Embedding: TArray<Double>;
begin
  Ollama := TOllamaEmbedding.Create('nomic-embed-text');
  try
    Embedding := Ollama.GetEmbedding('Deutscher Text hier');
    
    // In SQLite speichern
    // [BLOB-Konvertierung]
  finally
    Ollama.Free;
  end;
end;
```

---

## 🎓 Entscheidungshilfe

### Flowchart

```
Benötigst du Multimodal (Bilder)?
├─ Ja → Jina CLIP v2 (API) oder Ollama llava
└─ Nein → Weiter

Offline/Lokal notwendig?
├─ Ja → GGUF-Modelle
│   └─ Primär Deutsch?
│       ├─ Ja, beste Qualität → BGE-M3 (1024 Dim)
│       ├─ Ja, gute Balance → nomic-embed-text-v1.5 (768 Dim)
│       └─ Multilingual/Cross-Language → BGE-M3
│
└─ Nein (Cloud OK) → API-Modelle
    └─ Budget?
        ├─ Unlimited → OpenAI text-embedding-3-large
        ├─ Moderat → Cohere embed-multilingual-v3
        └─ Kostenlos → Ollama (lokal hosted)
```

---

## 📥 Download-Links Zusammenfassung

### Direkt verwendbar (GGUF)

| Modell | Dimensionen | Download |
|--------|-------------|----------|
| all-MiniLM-L6-v2 | 384 | [Link](https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf) |
| nomic-v1.5 (Q8) | 768 | [Link](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf) |
| nomic-v1.5 (Q4) | 768 | [Link](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q4_0.gguf) |
| BGE-M3 (GGUF) | 1024 | [Link](https://huggingface.co/gpustack/bge-m3-GGUF) |
| BGE-M3 (Q8) | 1024 | [Link](https://huggingface.co/ggml-org/bge-m3-Q8_0-GGUF) |
| mxbai-large (Q8) | 1024 | [Link](https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-Q8_0.gguf) |

### API-Services

| Service | Modelle | Preise | Link |
|---------|---------|--------|------|
| Ollama | nomic, mxbai, etc. | Kostenlos (lokal) | [ollama.ai](https://ollama.ai) |
| OpenAI | text-embedding-3 | $0.02-0.13/1M | [platform.openai.com](https://platform.openai.com) |
| Cohere | embed-multilingual-v3 | $0.10/1M | [cohere.ai](https://cohere.ai) |
| Jina AI | jina-clip-v2 | $0.02/1M | [jina.ai](https://jina.ai) |

---

## 🔍 GGUF-Konvertierung

Falls du eigene Modelle konvertieren willst:

### Installation llama.cpp
```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make
```

### Konvertierung
```bash
# PyTorch/HuggingFace → GGUF
python convert-hf-to-gguf.py \
  /path/to/model \
  --outfile model.gguf \
  --outtype q8_0

# Quantisierungen:
# - f32: Volle Präzision
# - f16: Half Precision
# - q8_0: 8-bit Quantisierung (empfohlen)
# - q4_0: 4-bit (klein, etwas Qualitätsverlust)
# - q2_k: 2-bit (sehr klein, mehr Verlust)
```

---

## 💡 Pro-Tips

### Für deutsche Anwendungen

1. **Nutze BGE-M3 oder nomic-v1.5 als Standard**
   - BGE-M3 für beste lokale Deutsch-/Multilingual-Qualität
   - Nomic-v1.5 für bessere Balance aus Größe und Geschwindigkeit
   - Lokal & offline
   - Gute Qualität

2. **Test verschiedene Modelle mit deinen Daten**
   - Jeder Anwendungsfall ist anders
   - Erstelle Test-Set mit typischen Queries

3. **Quantisierung ist OK**
   - Q8_0 ist kaum schlechter als f16
   - Q4_0 oft noch gut genug
   - Deutlich schneller

4. **API vs. Lokal**
   - Lokal: Datenschutz, keine Kosten, Offline
   - API: Beste Qualität, keine Hardware, Skalierbar

5. **Multimodal nur wenn nötig**
   - Text-Only-Modelle sind besser für reinen Text
   - CLIP/Jina nur wenn wirklich Bilder + Text

---

## 🔗 Weiterführende Links

- **HuggingFace MTEB Leaderboard:** [Link](https://huggingface.co/spaces/mteb/leaderboard) - Modell-Rankings
- **Ollama Models:** [Link](https://ollama.ai/library?sort=popular&q=embed) - Verfügbare Embeddings
- **sqlite-lembed:** [GitHub](https://github.com/asg017/sqlite-lembed)
- **llama.cpp:** [GitHub](https://github.com/ggerganov/llama.cpp) - GGUF-Konvertierung
- **MTEB (Massive Text Embedding Benchmark):** [GitHub](https://github.com/embeddings-benchmark/mteb) - Benchmarks

---

**Viel Erfolg mit deinen deutschen Embeddings! 🇩🇪🚀**
