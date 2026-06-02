program VectorLembedFormDemo;

uses
  Vcl.Forms,
  VectorLembedFormUnit in 'VectorLembedFormUnit.pas' {FormVectorLembed},
  VectorLembedExample in 'VectorLembedExample.pas',
  sqliteVecForDelphi in '..\..\sqliteVecForDelphi.pas',
  mormot.core.base,
  mormot.core.unicode,
  mormot.db.sql,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static,
  mormot.db.core,
  mormot.core.os;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Vector + Lembed Demo';
  Application.CreateForm(TFormVectorLembed, FormVectorLembed);
  Application.Run;
end.
