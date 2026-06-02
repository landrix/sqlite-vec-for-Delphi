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
    class procedure EnableExtensionLoading(aDB: TSqlite3DB);
    class procedure ExtractVec0Dll;
    class procedure ExtractVectorDll;
    class procedure ExtractLembed0Dll;
    class procedure LoadExtension(aDB: TSqlite3DB; const aFileName: RawUtf8);
  end;

{$R sqliteVecForDelphiResource.res}

implementation

{ TSQLDatabaseVectorHelper }

class procedure TSQLDatabaseVectorHelper.EnableExtensionLoading(aDB: TSqlite3DB);
var
  lResult: Integer;
  lEnabled: Integer;
begin
  if not Assigned(sqlite3.db_config) then
    raise Exception.Create('sqlite3_db_config ist nicht verfügbar.');

  lEnabled := 0;
  lResult := sqlite3.db_config(
    aDB,
    SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION,
    1,
    @lEnabled
  );
  if lResult <> SQLITE_OK then
    raise Exception.CreateFmt(
      'Extension loading konnte nicht aktiviert werden: %s',
      [Utf8ToString(sqlite3.errmsg(aDB))]
    );
end;

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

class procedure TSQLDatabaseVectorHelper.ExtractVectorDll;
var
  rcstr : TResourceStream;
begin
  rcstr := TResourceStream.Create(hInstance, 'VECTORDLL', RT_RCDATA);
  try
    rcstr.Position := 0;
    rcstr.SaveToFile(ExtractFilePath(ParamStr(0))+'vector.dll');
  finally
    rcstr.Free;
  end;
end;

class procedure TSQLDatabaseVectorHelper.LoadExtension(aDB: TSqlite3DB;
  const aFileName: RawUtf8);
var
  lMsg: PUtf8Char;
  lError: string;
  lResult: Integer;
begin
  lMsg := nil;
  lResult := sqlite3.load_extension(
    aDB,
    PUtf8Char(pointer(aFileName)),
    nil,
    lMsg
  );
  if lResult = SQLITE_OK then
    Exit;

  if lMsg <> nil then
  begin
    lError := Utf8ToString(lMsg);
    sqlite3.free_(lMsg);
  end
  else
    lError := Utf8ToString(sqlite3.errmsg(aDB));

  raise Exception.CreateFmt(
    'Fehler beim Laden von %s: %s',
    [Utf8ToString(aFileName), lError]
  );
end;

end.
