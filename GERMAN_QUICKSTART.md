# 🇩🇪 Schnellstart für deutsche Anwendungen

Ein 10-Minuten-Guide für semantische Suche in deutschen Texten.

## 🎯 Ziel

Semantische Suche in deutschen Dokumenten/Produkten mit SQLite und Delphi.

## 📥 Schritt 1: Modell herunterladen (2 Min)

### Empfehlung: Nomic Embed Text v1.5

**Warum?**
- ✅ Sehr gut für Deutsch
- ✅ Mittlere Größe (~275 MB)
- ✅ Gute Performance
- ✅ Bis 8k Token Context

**Download:**
```
https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF/resolve/main/nomic-embed-text-v1.5.Q8_0.gguf
```

**Speichern als:**
```
C:\Projekte\MeinProjekt\nomic-embed-text-v1.5.Q8_0.gguf
```

### Alternative: Beste Qualität (größer)

**mxbai-embed-large-v1** (~650 MB)
```
https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-Q8_0.gguf
```

### Alternative: Kleineres Modell (schneller)

**all-MiniLM-L6-v2** (~22 MB, Englisch-fokussiert)
```
https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```

---

## 💻 Schritt 2: Code einbinden (3 Min)

### Projekt-Setup

1. **Units hinzufügen:**
```pascal
uses
  VectorLembedExample,  // Für vector.dll (performant)
  // oder
  LembedVectorExample,  // Für vec0.dll (einfach)
  
  sqliteVecForDelphi,
  mormot.db.sql,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static;
```

2. **Dateien ins Projekt:**
- `VectorLembedExample.pas` aus `examples/simple-delphi/`
- `sqliteVecForDelphi.pas` aus Root

---

## 🚀 Schritt 3: Erste Suche (5 Min)

### Variante A: Produkt-Suche (Empfohlen)

```pascal
uses
  VectorLembedExample;

procedure TForm1.SetupSearch;
var
  Search: TProductSemanticSearch;
  Results: TRawUtf8DynArray;
  i: Integer;
begin
  Search := TProductSemanticSearch.Create('produkte.db');
  try
    // 1. Modell laden (768 Dimensionen für Nomic!)
    Search.Initialize(
      ExtractFilePath(Application.ExeName) + 'nomic-embed-text-v1.5.Q8_0.gguf',
      'nomic'
    );
    
    // 2. Deutsche Produkte hinzufügen
    Search.AddProduct(
      'Ergonomischer Bürostuhl',
      'Atmungsaktiver Netzrücken, verstellbare Armlehnen, Lordosenstütze',
      'Möbel',
      399.00
    );
    
    Search.AddProduct(
      'Höhenverstellbarer Schreibtisch',
      'Elektrisch höhenverstellbar, Memory-Funktion, stabile Konstruktion',
      'Möbel',
      799.00
    );
    
    Search.AddProduct(
      'LED Schreibtischlampe',
      'Dimmbar, verschiedene Farbtemperaturen, USB-Ladeport',
      'Beleuchtung',
      79.00
    );
    
    // 3. Quantisieren für Performance (bei vielen Produkten)
    Search.QuantizeEmbeddings;
    Search.PreloadQuantized;
    
    // 4. Deutsche Suche!
    Results := Search.SearchProducts('ergonomische Büromöbel', 5, True);
    
    // 5. Ergebnisse anzeigen
    Memo1.Lines.Clear;
    Memo1.Lines.Add('Suchergebnisse für: "ergonomische Büromöbel"');
    Memo1.Lines.Add('');
    
    for i := 0 to High(Results) do
    begin
      Memo1.Lines.Add(IntToStr(i+1) + '. ' + Utf8ToString(Results[i]));
      Memo1.Lines.Add('');
    end;
    
  finally
    Search.Free;
  end;
end;
```

### Variante B: Dokumenten-Suche (Einfacher)

```pascal
uses
  LembedVectorExample;

procedure TForm1.SetupDocumentSearch;
var
  Search: TSemanticDocumentSearch;
  Results: TRawUtf8DynArray;
begin
  Search := TSemanticDocumentSearch.Create('dokumente.db');
  try
    // 1. Modell laden
    Search.Initialize(
      'nomic-embed-text-v1.5.Q8_0.gguf',
      'nomic'
    );
    
    // 2. Deutsche Dokumente hinzufügen
    Search.AddDocument(
      'Datenschutz-Grundverordnung',
      'Die DSGVO regelt den Schutz personenbezogener Daten in der EU...'
    );
    
    Search.AddDocument(
      'Arbeitsrecht in Deutschland',
      'Das deutsche Arbeitsrecht umfasst Regelungen zum Arbeitsverhältnis...'
    );
    
    // 3. Suchen
    Results := Search.Search('Datenschutzbestimmungen', 5);
    
    // 4. Anzeigen
    for Result in Results do
      ShowMessage(Utf8ToString(Result));
      
  finally
    Search.Free;
  end;
end;
```

---

## 🎨 Typische deutsche Anwendungsfälle

### 1. E-Commerce (Online-Shop)

```pascal
// Produkte
Search.AddProduct(
  'Nike Air Max Sneaker',
  'Sportlicher Laufschuh mit Air-Dämpfung, atmungsaktives Mesh',
  'Sportschuhe',
  129.99
);

// Suche (versteht Synonyme!)
Results := Search.SearchProducts('bequeme Turnschuhe zum Joggen', 10);
// Findet "Nike Air Max" trotz anderer Begriffe!
```

### 2. Wissensdatenbank / FAQ

```pascal
// Fragen & Antworten
Search.AddDocument(
  'Wie kann ich mein Passwort zurücksetzen?',
  'Klicken Sie auf "Passwort vergessen" auf der Login-Seite...'
);

Search.AddDocument(
  'Wie ändere ich meine E-Mail-Adresse?',
  'Gehen Sie zu Einstellungen > Konto > E-Mail ändern...'
);

// Kundenanfrage
Results := Search.Search('Ich habe mein Kennwort vergessen', 3);
// Findet "Passwort zurücksetzen" trotz "Kennwort"!
```

### 3. Dokumentenarchiv

```pascal
// Verträge, Rechnungen, etc.
Search.AddDocument(
  'Mietvertrag Wohnung München',
  'Zwischen Vermieter Hans Müller und Mieter...'
);

Search.AddDocument(
  'Rechnung Webhosting 2024',
  'Hiermit stellen wir Ihnen die Hosting-Leistungen...'
);

// Suche
Results := Search.Search('Wohnungsmiete Vereinbarung', 5);
```

### 4. Produktempfehlungen

```pascal
// Kunde schaut Produkt an
CurrentProductId := 42; // "Laptop für Entwickler"

// Finde ähnliche Produkte
Similar := Search.FindSimilarProducts(CurrentProductId, 5, True);

// Zeige als "Kunden kauften auch:"
for Item in Similar do
  AddToRecommendations(Item);
```

---

## 📊 Modell-Dimensionen beachten!

### Wichtig: Vector-Tabelle muss passen!

```pascal
// Nomic v1.5 = 768 Dimensionen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[768]);');

// mxbai-large = 1024 Dimensionen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[1024]);');

// all-MiniLM = 384 Dimensionen
sql.Execute('CREATE VIRTUAL TABLE vec_docs USING vec0(embedding float[384]);');
```

**Fehler wenn nicht passend:**
```
Error: dimension mismatch
```

---

## ⚡ Performance-Tipps für Deutsch

### 1. Quantisierung nutzen (bei vector.dll)

```pascal
// Nach vielen Inserts
Search.QuantizeEmbeddings;  // INT8 statt FLOAT32
Search.PreloadQuantized;     // In RAM laden

// Jetzt 4-5x schneller!
Results := Search.SearchProducts('Suche', 10, True);  // True = quantisiert
```

### 2. Batch-Processing

```pascal
// Viele Produkte auf einmal
DB.TransactionBegin;
try
  for Produkt in Produktliste do
    Search.AddProduct(Produkt.Name, Produkt.Beschreibung, ...);
    
  // DANACH einmal quantisieren
  Search.QuantizeEmbeddings;
  
  DB.Commit;
except
  DB.Rollback;
end;
```

### 3. Deutsche Stop-Words (Optional)

```pascal
// Für bessere Ergebnisse deutsche Füllwörter entfernen
function RemoveGermanStopWords(const Text: string): string;
const
  StopWords: array[0..9] of string = (
    'der', 'die', 'das', 'ein', 'eine', 'und', 'oder', 'aber', 'wenn', 'weil'
  );
var
  Word: string;
begin
  Result := Text;
  for Word in StopWords do
    Result := StringReplace(Result, ' ' + Word + ' ', ' ', [rfReplaceAll, rfIgnoreCase]);
end;

// Beim Einfügen
CleanText := RemoveGermanStopWords(OriginalText);
Search.AddDocument(Title, CleanText);
```

---

## 🔍 Test-Queries für deutsche Texte

### E-Commerce
```pascal
'bequeme Schuhe für den Alltag'
'wasserdichte Jacke für den Winter'
'leistungsstarker Laptop für Büro'
'energieeffiziente Waschmaschine'
```

### Dokumente
```pascal
'Regelungen zum Datenschutz'
'Kündigungsfristen Arbeitsvertrag'
'Steuererklärung Hinweise'
'Mietrecht Kündigungsschutz'
```

### Support / FAQ
```pascal
'Wie kann ich meine Bestellung stornieren?'
'Wo finde ich meine Rechnungen?'
'Passwort zurücksetzen funktioniert nicht'
'Lieferung nach Österreich möglich?'
```

---

## 🐛 Häufige Fehler

### 1. Modell nicht gefunden

❌ **Fehler:**
```
Model file not found
```

✅ **Lösung:**
```pascal
// Absoluten Pfad verwenden
Search.Initialize(
  ExtractFilePath(Application.ExeName) + 'nomic-embed-text-v1.5.Q8_0.gguf',
  'nomic'
);
```

### 2. Dimensionen stimmen nicht

❌ **Fehler:**
```
dimension mismatch
```

✅ **Lösung:**
```pascal
// Prüfe Modell-Dimensionen:
// Nomic = 768
// mxbai = 1024
// all-MiniLM = 384

// Passe Vector-Tabelle an:
sql.Execute('CREATE VIRTUAL TABLE vec USING vec0(embedding float[768]);');
```

### 3. Schlechte deutsche Ergebnisse

❌ **Problem:** all-MiniLM-L6-v2 funktioniert nicht gut für Deutsch

✅ **Lösung:** Nutze Nomic oder mxbai:
```pascal
// Statt all-MiniLM:
Search.Initialize('nomic-embed-text-v1.5.Q8_0.gguf', 'nomic');
```

---

## 📈 Nächste Schritte

### Erweiterte Features

1. **Kategorie-Filter:**
```pascal
Results := Search.SearchByCategory('Elektronik', 'Laptop', 10);
```

2. **Ähnlichkeitssuche:**
```pascal
Similar := Search.FindSimilarProducts(ProductId, 5, True);
```

3. **Hybrid-Suche (Text + Vektor):**
```pascal
// SQL: Kombiniere Fulltext + Semantisch
SELECT * FROM products
WHERE name LIKE '%Laptop%'
  AND id IN (SELECT rowid FROM semantic_matches)
ORDER BY distance;
```

4. **Multi-Language:**
```pascal
// Nomic v1.5 unterstützt 100+ Sprachen
Search.AddProduct('Laptop', 'English description', ...);
Search.AddProduct('Ordinateur', 'Description français', ...);
Search.AddProduct('Laptop', 'Deutsche Beschreibung', ...);

// Suche funktioniert sprachübergreifend!
Results := Search.SearchProducts('Computer', 10);
```

---

## 🔗 Ressourcen

- **Vollständige Doku:** [LEMBED_VECTOR_USAGE.md](../LEMBED_VECTOR_USAGE.md)
- **Modell-Guide:** [EMBEDDING_MODELS_GUIDE.md](../EMBEDDING_MODELS_GUIDE.md)
- **Beispiele:** [examples/README.md](../examples/README.md)
- **Vergleich:** [EXTENSIONS_COMPARISON.md](../examples/simple-delphi/EXTENSIONS_COMPARISON.md)

---

**Viel Erfolg mit deiner deutschen semantischen Suche! 🇩🇪🚀**
