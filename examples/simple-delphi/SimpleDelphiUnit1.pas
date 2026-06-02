unit SimpleDelphiUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs

  ,mormot.core.os,mormot.db.sql,mormot.core.unicode
  ,mormot.core.base
  ,mormot.db.raw.sqlite3.static
  ,mormot.db.raw.sqlite3
  ,mormot.db.sql.sqlite3
  ,mormot.db.core,mormot.core.datetime

  ,sqliteVecForDelphi
  ;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  sql : TSQLDatabase;
  aStmt : TSQLRequest;
  sResult : string;
begin
  // 1. Beide DLLs extrahieren
  TSQLDatabaseVectorHelper.ExtractLembed0Dll;
  TSQLDatabaseVectorHelper.ExtractVec0Dll;

  DeleteFile(ExtractFilePath(Application.ExeName)+'sample.db');

  sql := TSQLDatabase.Create(ExtractFilePath(Application.ExeName)+'sample.db','');
  try
    // Extension loading aktivieren
    TSQLDatabaseVectorHelper.EnableExtensionLoading(sql.DB);

    // 2. Beide Extensions laden
    TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'lembed0.dll');
    TSQLDatabaseVectorHelper.LoadExtension(sql.DB, 'vec0.dll');

    // 3. Embedding-Modell registrieren (Datei muss im Programmverzeichnis liegen!)
    // Download: https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
    sql.Execute('INSERT INTO temp.lembed_models(name, model) ' +
                'SELECT ''all-MiniLM-L6-v2'', ' +
                '       lembed_model_from_file(''all-MiniLM-L6-v2.e4ce9877.q8_0.gguf'');');

    // 4. Tabelle für Textdaten erstellen
    sql.Execute('CREATE TABLE articles(headline TEXT);');

    // 5. Beispieldaten einfügen
    sql.Execute('INSERT INTO articles VALUES ' +
                '(''Shohei Ohtani''''s ex-interpreter pleads guilty to charges related to gambling and theft''), ' +
                '(''The jury has been selected in Hunter Biden''''s gun trial''), ' +
                '(''Larry Allen, a Super Bowl champion and famed Dallas Cowboy, has died at age 52''), ' +
                '(''After saying Charlotte, a lone stingray, was pregnant, aquarium now says she''''s sick''), ' +
                '(''An Epoch Times executive is facing money laundering charge'');');

    // 6. Vector-Tabelle erstellen (384 Dimensionen für all-MiniLM-L6-v2 Modell)
    sql.Execute('CREATE VIRTUAL TABLE vec_articles USING vec0(' +
                '  headline_embeddings float[384]' +
                ');');

    // 7. Embeddings generieren und in Vector-Tabelle speichern
    sql.Execute('INSERT INTO vec_articles(rowid, headline_embeddings) ' +
                'SELECT rowid, lembed(''all-MiniLM-L6-v2'', headline) ' +
                'FROM articles;');

    // 8. Semantische Suche durchführen
    sResult := 'Semantische Suche nach "firearm courtroom":' + sLineBreak + sLineBreak;
    
    try
      aStmt.Prepare(sql.DB,
        'WITH matches AS ( ' +
        '  SELECT rowid, distance ' +
        '  FROM vec_articles ' +
        '  WHERE headline_embeddings MATCH lembed(''all-MiniLM-L6-v2'', ''firearm courtroom'') ' +
        '  ORDER BY distance ' +
        '  LIMIT 3 ' +
        ') ' +
        'SELECT headline, distance ' +
        'FROM matches ' +
        'LEFT JOIN articles ON articles.rowid = matches.rowid;');
        
      while aStmt.Step = SQLITE_ROW do
      begin
        sResult := sResult + 
                   'Headline: ' + aStmt.FieldS(0) + sLineBreak +
                   'Distance: ' + aStmt.FieldS(1) + sLineBreak + sLineBreak;
      end;
    finally
      aStmt.Close;
    end;

    ShowMessage(sResult);

  finally
    sql.Free;
  end;
end;

end.
