object FormVectorLembed: TFormVectorLembed
  Left = 0
  Top = 0
  Caption = 'SQLite Vector + Lembed Demo - Produkt-Suche'
  ClientHeight = 640
  ClientWidth = 920
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  object PageControl1: TPageControl
    Left = 0
    Top = 89
    Width = 920
    Height = 551
    ActivePage = TabProducts
    Align = alClient
    TabOrder = 0
    object TabProducts: TTabSheet
      Caption = 'Produkte'
      object GroupBoxAddProduct: TGroupBox
        Left = 3
        Top = 3
        Width = 906
        Height = 228
        Caption = ' Produkt hinzuf'#252'gen '
        TabOrder = 0
        object Label2: TLabel
          Left = 16
          Top = 27
          Width = 67
          Height = 13
          Caption = 'Produktname:'
        end
        object Label3: TLabel
          Left = 16
          Top = 54
          Width = 68
          Height = 13
          Caption = 'Beschreibung:'
        end
        object Label4: TLabel
          Left = 16
          Top = 139
          Width = 50
          Height = 13
          Caption = 'Kategorie:'
        end
        object Label5: TLabel
          Left = 16
          Top = 166
          Width = 44
          Height = 13
          Caption = 'Preis ('#8364'):'
        end
        object EditProductName: TEdit
          Left = 104
          Top = 24
          Width = 329
          Height = 21
          TabOrder = 0
        end
        object MemoDescription: TMemo
          Left = 104
          Top = 51
          Width = 788
          Height = 76
          ScrollBars = ssVertical
          TabOrder = 1
        end
        object ComboCategory: TComboBox
          Left = 104
          Top = 136
          Width = 169
          Height = 21
          Style = csDropDownList
          TabOrder = 2
        end
        object EditPrice: TEdit
          Left = 104
          Top = 163
          Width = 121
          Height = 21
          TabOrder = 3
          Text = '0.00'
        end
        object ButtonAddProduct: TButton
          Left = 104
          Top = 190
          Width = 153
          Height = 25
          Caption = 'Produkt hinzuf'#252'gen'
          TabOrder = 4
          OnClick = ButtonAddProductClick
        end
        object ButtonLoadSample: TButton
          Left = 263
          Top = 190
          Width = 170
          Height = 25
          Caption = 'Beispiel-Produkte laden'
          TabOrder = 5
          OnClick = ButtonLoadSampleClick
        end
      end
      object GroupBoxQuantize: TGroupBox
        Left = 3
        Top = 237
        Width = 906
        Height = 110
        Caption = ' Performance-Optimierung '
        TabOrder = 1
        object LabelQuantizeStatus: TLabel
          Left = 16
          Top = 24
          Width = 84
          Height = 13
          Caption = #9675' Nicht initialisiert'
        end
        object ButtonQuantize: TButton
          Left = 16
          Top = 48
          Width = 185
          Height = 25
          Caption = 'Embeddings quantisieren'
          Enabled = False
          TabOrder = 0
          OnClick = ButtonQuantizeClick
        end
        object ButtonPreload: TButton
          Left = 16
          Top = 79
          Width = 185
          Height = 25
          Caption = 'In Speicher laden (RAM)'
          Enabled = False
          TabOrder = 1
          OnClick = ButtonPreloadClick
        end
      end
    end
    object TabSearch: TTabSheet
      Caption = 'Suche'
      ImageIndex = 1
      object GroupBoxSearch: TGroupBox
        Left = 3
        Top = 3
        Width = 906
        Height = 150
        Caption = ' Semantische Suche '
        TabOrder = 0
        object Label6: TLabel
          Left = 16
          Top = 27
          Width = 59
          Height = 13
          Caption = 'Suchbegriff:'
        end
        object Label7: TLabel
          Left = 16
          Top = 83
          Width = 83
          Height = 13
          Caption = 'Max. Ergebnisse:'
        end
        object EditSearchQuery: TEdit
          Left = 104
          Top = 24
          Width = 529
          Height = 21
          TabOrder = 0
          TextHint = 'z.B. "laptop for programming"'
        end
        object ButtonSearch: TButton
          Left = 639
          Top = 22
          Width = 98
          Height = 25
          Caption = 'Suchen'
          TabOrder = 1
          OnClick = ButtonSearchClick
        end
        object CheckBoxQuantized: TCheckBox
          Left = 104
          Top = 56
          Width = 273
          Height = 17
          Caption = 'Quantisierte Suche (4-5x schneller)'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object SpinEditLimit: TSpinEdit
          Left = 104
          Top = 80
          Width = 81
          Height = 22
          MaxValue = 100
          MinValue = 1
          TabOrder = 3
          Value = 10
        end
      end
      object GroupBoxCategorySearch: TGroupBox
        Left = 3
        Top = 159
        Width = 906
        Height = 110
        Caption = ' Kategorie-Suche '
        TabOrder = 1
        object Label9: TLabel
          Left = 16
          Top = 27
          Width = 50
          Height = 13
          Caption = 'Kategorie:'
        end
        object Label10: TLabel
          Left = 16
          Top = 54
          Width = 59
          Height = 13
          Caption = 'Suchbegriff:'
        end
        object ComboCategoryFilter: TComboBox
          Left = 104
          Top = 24
          Width = 169
          Height = 21
          Style = csDropDownList
          TabOrder = 0
        end
        object EditCategoryQuery: TEdit
          Left = 104
          Top = 51
          Width = 529
          Height = 21
          TabOrder = 1
          TextHint = 'z.B. "portable device"'
        end
        object ButtonSearchCategory: TButton
          Left = 639
          Top = 49
          Width = 98
          Height = 25
          Caption = 'Suchen'
          TabOrder = 2
          OnClick = ButtonSearchCategoryClick
        end
      end
      object MemoResults: TMemo
        Left = 3
        Top = 275
        Width = 906
        Height = 245
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 2
        WordWrap = False
      end
    end
    object TabStats: TTabSheet
      Caption = 'Statistiken'
      ImageIndex = 2
      object GroupBoxStats: TGroupBox
        Left = 3
        Top = 3
        Width = 906
        Height = 517
        Caption = ' Datenbank-Statistiken '
        TabOrder = 0
        object MemoStats: TMemo
          Left = 16
          Top = 48
          Width = 874
          Height = 453
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object ButtonRefreshStats: TButton
          Left = 16
          Top = 17
          Width = 153
          Height = 25
          Caption = 'Aktualisieren'
          TabOrder = 1
          OnClick = ButtonRefreshStatsClick
        end
      end
    end
  end
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 60
      Height = 13
      Caption = 'Modell-Pfad:'
    end
    object LabelStatus: TLabel
      Left = 16
      Top = 69
      Width = 182
      Height = 13
      Caption = 'Bereit. Bitte Modell initialisieren.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 16
      Top = 43
      Width = 682
      Height = 13
      Caption = 
        'Download: https://huggingface.co/asg017/sqlite-lembed-model-exam' +
        'ples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_' +
        '0.gguf'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object EditModelPath: TEdit
      Left = 96
      Top = 13
      Width = 649
      Height = 21
      TabOrder = 0
    end
    object ButtonInitialize: TButton
      Left = 751
      Top = 11
      Width = 73
      Height = 25
      Caption = 'Initialisieren'
      TabOrder = 1
      OnClick = ButtonInitializeClick
    end
    object ButtonBrowseModel: TButton
      Left = 830
      Top = 11
      Width = 75
      Height = 25
      Caption = 'Durchsuchen'
      TabOrder = 2
      OnClick = ButtonBrowseModelClick
    end
    object ProgressBar1: TProgressBar
      Left = 456
      Top = 66
      Width = 449
      Height = 17
      TabOrder = 3
    end
  end
  object OpenDialogModel: TOpenDialog
    Filter = 'GGUF Models (*.gguf)|*.gguf|All Files (*.*)|*.*'
    Left = 840
    Top = 56
  end
end
