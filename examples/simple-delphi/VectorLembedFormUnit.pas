unit VectorLembedFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.StrUtils,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, 
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  VectorLembedExample, Vcl.Samples.Spin;

type
  TFormVectorLembed = class(TForm)
    PageControl1: TPageControl;
    TabProducts: TTabSheet;
    TabSearch: TTabSheet;
    TabStats: TTabSheet;
    PanelTop: TPanel;
    Label1: TLabel;
    EditModelPath: TEdit;
    ButtonInitialize: TButton;
    ButtonBrowseModel: TButton;
    LabelStatus: TLabel;
    GroupBoxAddProduct: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    EditProductName: TEdit;
    MemoDescription: TMemo;
    ComboCategory: TComboBox;
    EditPrice: TEdit;
    ButtonAddProduct: TButton;
    GroupBoxSearch: TGroupBox;
    Label6: TLabel;
    EditSearchQuery: TEdit;
    ButtonSearch: TButton;
    CheckBoxQuantized: TCheckBox;
    SpinEditLimit: TSpinEdit;
    Label7: TLabel;
    MemoResults: TMemo;
    Label8: TLabel;
    GroupBoxStats: TGroupBox;
    MemoStats: TMemo;
    ButtonRefreshStats: TButton;
    GroupBoxQuantize: TGroupBox;
    ButtonQuantize: TButton;
    ButtonPreload: TButton;
    LabelQuantizeStatus: TLabel;
    ProgressBar1: TProgressBar;
    OpenDialogModel: TOpenDialog;
    GroupBoxCategorySearch: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    ComboCategoryFilter: TComboBox;
    EditCategoryQuery: TEdit;
    ButtonSearchCategory: TButton;
    ButtonLoadSample: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonInitializeClick(Sender: TObject);
    procedure ButtonBrowseModelClick(Sender: TObject);
    procedure ButtonAddProductClick(Sender: TObject);
    procedure ButtonSearchClick(Sender: TObject);
    procedure ButtonRefreshStatsClick(Sender: TObject);
    procedure ButtonQuantizeClick(Sender: TObject);
    procedure ButtonPreloadClick(Sender: TObject);
    procedure ButtonSearchCategoryClick(Sender: TObject);
    procedure ButtonLoadSampleClick(Sender: TObject);
  private
    FSearch: TProductSemanticSearch;
    FInitialized: Boolean;
    procedure UpdateStatus(const AMessage: string; AColor: TColor = clGreen);
    procedure UpdateQuantizeStatus;
  public
    { Public declarations }
  end;

var
  FormVectorLembed: TFormVectorLembed;

implementation

{$R *.dfm}

uses
  mormot.core.base, mormot.core.unicode;

procedure TFormVectorLembed.FormCreate(Sender: TObject);
begin
  FInitialized := False;
  FSearch := TProductSemanticSearch.Create('products_demo.db');
  
  // Default-Werte
  EditModelPath.Text := ExtractFilePath(Application.ExeName) + 
                        'all-MiniLM-L6-v2.e4ce9877.q8_0.gguf';
  SpinEditLimit.Value := 10;
  CheckBoxQuantized.Checked := True;
  
  // Kategorien
  ComboCategory.Items.Clear;
  ComboCategory.Items.Add('Electronics');
  ComboCategory.Items.Add('Furniture');
  ComboCategory.Items.Add('Books');
  ComboCategory.Items.Add('Clothing');
  ComboCategory.Items.Add('Sports');
  ComboCategory.ItemIndex := 0;
  
  ComboCategoryFilter.Items.Assign(ComboCategory.Items);
  ComboCategoryFilter.ItemIndex := 0;
  
  UpdateStatus('Bereit. Bitte Modell initialisieren.', clBlue);
  UpdateQuantizeStatus;
  
  PageControl1.ActivePageIndex := 0;
end;

procedure TFormVectorLembed.FormDestroy(Sender: TObject);
begin
  FSearch.Free;
end;

procedure TFormVectorLembed.UpdateStatus(const AMessage: string; AColor: TColor);
begin
  LabelStatus.Caption := AMessage;
  LabelStatus.Font.Color := AColor;
  Application.ProcessMessages;
end;

procedure TFormVectorLembed.UpdateQuantizeStatus;
begin
  if FInitialized then
  begin
    if FSearch.Quantized then
      LabelQuantizeStatus.Caption := '✓ Quantisiert (4-5x schneller)'
    else
      LabelQuantizeStatus.Caption := '○ Nicht quantisiert';
      
    ButtonQuantize.Enabled := not FSearch.Quantized;
    ButtonPreload.Enabled := FSearch.Quantized;
  end
  else
  begin
    LabelQuantizeStatus.Caption := '○ Nicht initialisiert';
    ButtonQuantize.Enabled := False;
    ButtonPreload.Enabled := False;
  end;
end;

procedure TFormVectorLembed.ButtonBrowseModelClick(Sender: TObject);
begin
  OpenDialogModel.Filter := 'GGUF Models (*.gguf)|*.gguf|All Files (*.*)|*.*';
  OpenDialogModel.FileName := EditModelPath.Text;
  
  if OpenDialogModel.Execute then
    EditModelPath.Text := OpenDialogModel.FileName;
end;

procedure TFormVectorLembed.ButtonInitializeClick(Sender: TObject);
begin
  if not FileExists(EditModelPath.Text) then
  begin
    MessageDlg('Modell-Datei nicht gefunden!' + sLineBreak + sLineBreak +
               'Bitte lade das Modell herunter von:' + sLineBreak +
               'https://huggingface.co/asg017/sqlite-lembed-model-examples',
               mtError, [mbOK], 0);
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  ProgressBar1.Style := pbstMarquee;
  ButtonInitialize.Enabled := False;
  
  try
    UpdateStatus('Lade Extensions und Modell...', clBlue);
    
    FSearch.Initialize(EditModelPath.Text, 'embedder');
    
    FInitialized := True;
    UpdateStatus('✓ Initialisierung erfolgreich!', clGreen);
    
    // UI aktivieren
    TabProducts.Enabled := True;
    TabSearch.Enabled := True;
    TabStats.Enabled := True;
    
    UpdateQuantizeStatus;
    ButtonRefreshStatsClick(nil);
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler beim Initialisieren:' + sLineBreak + E.Message,
                 mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
  ProgressBar1.Style := pbstNormal;
  ButtonInitialize.Enabled := True;
end;

procedure TFormVectorLembed.ButtonLoadSampleClick(Sender: TObject);
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  UpdateStatus('Lade Beispiel-Produkte...', clBlue);
  
  try
    // Elektronik
    FSearch.AddProduct(
      'MacBook Pro 16"',
      'Powerful laptop with M3 chip, 32GB RAM, perfect for development',
      'Electronics',
      2499.00
    );
    
    FSearch.AddProduct(
      'iPad Pro 12.9"',
      'Tablet with Apple M2 chip, great for drawing and note-taking',
      'Electronics',
      1299.00
    );
    
    FSearch.AddProduct(
      'Sony WH-1000XM5',
      'Premium noise-cancelling wireless headphones',
      'Electronics',
      399.00
    );
    
    // Möbel
    FSearch.AddProduct(
      'ErgoChair Pro',
      'Ergonomic office chair with lumbar support and breathable mesh',
      'Furniture',
      549.00
    );
    
    FSearch.AddProduct(
      'Standing Desk Pro',
      'Electric height-adjustable desk for healthier working',
      'Furniture',
      799.00
    );
    
    // Bücher
    FSearch.AddProduct(
      'Clean Code',
      'Essential book about software craftsmanship and maintainable code',
      'Books',
      44.00
    );
    
    FSearch.AddProduct(
      'Design Patterns',
      'Classic book about reusable object-oriented design patterns',
      'Books',
      54.00
    );
    
    UpdateStatus('✓ 7 Beispiel-Produkte geladen', clGreen);
    MessageDlg('Beispiel-Produkte erfolgreich geladen!' + sLineBreak + sLineBreak +
               'Tipp: Jetzt quantisieren für schnellere Suche!',
               mtInformation, [mbOK], 0);
               
    UpdateQuantizeStatus;
    ButtonRefreshStatsClick(nil);
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler beim Laden: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
end;

procedure TFormVectorLembed.ButtonAddProductClick(Sender: TObject);
var
  lPrice: Currency;
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  if Trim(EditProductName.Text) = '' then
  begin
    MessageDlg('Bitte Produktnamen eingeben!', mtWarning, [mbOK], 0);
    EditProductName.SetFocus;
    Exit;
  end;
  
  if not TryStrToCurr(EditPrice.Text, lPrice) then
  begin
    MessageDlg('Ungültiger Preis!', mtWarning, [mbOK], 0);
    EditPrice.SetFocus;
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  UpdateStatus('Füge Produkt hinzu und generiere Embedding...', clBlue);
  
  try
    FSearch.AddProduct(
      EditProductName.Text,
      MemoDescription.Text,
      ComboCategory.Text,
      lPrice
    );
    
    UpdateStatus('✓ Produkt hinzugefügt', clGreen);
    
    // Felder leeren
    EditProductName.Clear;
    MemoDescription.Clear;
    EditPrice.Clear;
    ComboCategory.ItemIndex := 0;
    EditProductName.SetFocus;
    
    UpdateQuantizeStatus;
    ButtonRefreshStatsClick(nil);
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
end;

procedure TFormVectorLembed.ButtonSearchClick(Sender: TObject);
var
  lResults: TRawUtf8DynArray;
  i: Integer;
  lStartTime: Int64;
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  if Trim(EditSearchQuery.Text) = '' then
  begin
    MessageDlg('Bitte Suchbegriff eingeben!', mtWarning, [mbOK], 0);
    EditSearchQuery.SetFocus;
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  UpdateStatus('Suche läuft...', clBlue);
  MemoResults.Clear;
  
  try
    lStartTime := GetTickCount64;
    
    lResults := FSearch.SearchProducts(
      EditSearchQuery.Text,
      SpinEditLimit.Value,
      CheckBoxQuantized.Checked
    );
    
    MemoResults.Lines.Add('=== Suchergebnisse für: "' + EditSearchQuery.Text + '" ===');
    MemoResults.Lines.Add('Zeit: ' + IntToStr(GetTickCount64 - lStartTime) + ' ms');
    MemoResults.Lines.Add('Modus: ' + 
      IfThen(CheckBoxQuantized.Checked, 'Quantisiert (schnell)', 'Normal (präzise)'));
    MemoResults.Lines.Add('');
    
    if Length(lResults) = 0 then
    begin
      MemoResults.Lines.Add('Keine Ergebnisse gefunden.');
    end
    else
    begin
      for i := 0 to High(lResults) do
      begin
        MemoResults.Lines.Add(Format('%d. %s', [i+1, Utf8ToString(lResults[i])]));
        MemoResults.Lines.Add('');
      end;
    end;
    
    UpdateStatus('✓ Suche abgeschlossen', clGreen);
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
end;

procedure TFormVectorLembed.ButtonSearchCategoryClick(Sender: TObject);
var
  lResults: TRawUtf8DynArray;
  i: Integer;
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  MemoResults.Clear;
  
  try
    lResults := FSearch.SearchByCategory(
      ComboCategoryFilter.Text,
      EditCategoryQuery.Text,
      SpinEditLimit.Value
    );
    
    MemoResults.Lines.Add('=== Suche in Kategorie: ' + ComboCategoryFilter.Text + ' ===');
    MemoResults.Lines.Add('Query: "' + EditCategoryQuery.Text + '"');
    MemoResults.Lines.Add('');
    
    if Length(lResults) = 0 then
      MemoResults.Lines.Add('Keine Ergebnisse in dieser Kategorie.')
    else
    begin
      for i := 0 to High(lResults) do
      begin
        MemoResults.Lines.Add(Format('%d. %s', [i+1, Utf8ToString(lResults[i])]));
        MemoResults.Lines.Add('');
      end;
    end;
    
    UpdateStatus('✓ Kategorie-Suche abgeschlossen', clGreen);
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
end;

procedure TFormVectorLembed.ButtonQuantizeClick(Sender: TObject);
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  UpdateStatus('Quantisiere Embeddings...', clBlue);
  ProgressBar1.Style := pbstMarquee;
  
  try
    FSearch.QuantizeEmbeddings;
    
    UpdateStatus('✓ Quantisierung erfolgreich!', clGreen);
    MessageDlg('Embeddings wurden quantisiert!' + sLineBreak + sLineBreak +
               'Suchen sind jetzt 4-5x schneller.' + sLineBreak +
               'Für maximale Performance: "In Speicher laden" klicken.',
               mtInformation, [mbOK], 0);
               
    UpdateQuantizeStatus;
    
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
  ProgressBar1.Style := pbstNormal;
end;

procedure TFormVectorLembed.ButtonPreloadClick(Sender: TObject);
begin
  if not FInitialized then
  begin
    MessageDlg('Bitte zuerst initialisieren!', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  Screen.Cursor := crHourGlass;
  UpdateStatus('Lade quantisierte Daten in Speicher...', clBlue);
  ProgressBar1.Style := pbstMarquee;
  
  try
    FSearch.PreloadQuantized;
    
    UpdateStatus('✓ Daten im Speicher!', clGreen);
    MessageDlg('Quantisierte Embeddings im RAM!' + sLineBreak + sLineBreak +
               'Maximale Suchgeschwindigkeit aktiviert.',
               mtInformation, [mbOK], 0);
               
  except
    on E: Exception do
    begin
      UpdateStatus('Fehler: ' + E.Message, clRed);
      MessageDlg('Fehler: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  
  Screen.Cursor := crDefault;
  ProgressBar1.Style := pbstNormal;
end;

procedure TFormVectorLembed.ButtonRefreshStatsClick(Sender: TObject);
begin
  if not FInitialized then
    Exit;
    
  try
    MemoStats.Clear;
    MemoStats.Lines.Text := FSearch.GetStats;
  except
    on E: Exception do
      MemoStats.Lines.Text := 'Fehler: ' + E.Message;
  end;
end;

end.
