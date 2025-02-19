unit sqliteVecForDelphi;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes

  ,mormot.core.os,mormot.db.sql,mormot.core.unicode
  ,mormot.core.base
  ,mormot.db.raw.sqlite3.static
  ,mormot.db.raw.sqlite3
  ,mormot.db.sql.sqlite3
  ,mormot.db.core,mormot.core.datetime
  ;

type
  TSQLDatabaseVector = class(TObject)
  public

  end;

  TSQLDatabaseVectorHelper = class
  public
    class procedure ExtractVec0Dll;
    class procedure ExtractLembed0Dll;
  end;

{$R sqliteVecForDelphi.res}

implementation

{ TSQLDatabaseVectorHelper }

class procedure TSQLDatabaseVectorHelper.ExtractLembed0Dll;
var
  rcstr : TResourceStream;
begin
  rcstr := TResourceStream.Create(hInstance, 'LEMBED0DLL', RT_RCDATA);
  try
    rcstr.Position := 0;
    rcstr.SaveToFile(ExtractFilePath(ParamStr(0))+'lembed0.dll');
  finally
    rcstr.Free;
  end;
end;

class procedure TSQLDatabaseVectorHelper.ExtractVec0Dll;
var
  rcstr : TResourceStream;
begin
  rcstr := TResourceStream.Create(hInstance, 'VEC0DLL', RT_RCDATA);
  try
    rcstr.Position := 0;
    rcstr.SaveToFile(ExtractFilePath(ParamStr(0))+'vec0.dll');
  finally
    rcstr.Free;
  end;
end;

end.
