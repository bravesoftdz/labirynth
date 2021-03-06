unit LMap;

{$mode objfpc}{$H+}{$Define LMAP}

interface

uses
  Classes, SysUtils, IniFiles, Graphics, LTypes, LIniFiles, LPixelStorage, LSize;

type
  TLMap=class(TObject)
  private
    {types and vars}
    var
      FData, FFloor, FSky: TBitmap;
      FTexture: TLTexture;
      Fini: TLIniFile;
      FSize: TL2Dsize;
  public
    {functions and procedures}
    constructor Create(Aini: TLIniFile);
    destructor Destroy; override;
  private
    {propertyes}
    property ini: TLIniFile read Fini write Fini;
  public
    {propertyes}
    property data: TBitmap read FData write FData;
    property Floor: TBitmap read FFloor;
    property Sky: TBitmap read FSky;
    //procedure setTextures(Value: TLTextures);
    property texture: TLTexture read FTexture write FTexture;
    function getSize: TL2DSize;
    procedure setSize(Value: TL2DSize);
    property Size: TL2DSize read FSize write FSize;
  end;

implementation

constructor TLMap.Create(AIni: TLIniFile);
begin
  inherited Create;
  Fini:=AIni;
  Fdata:=ini.ReadBitmap('Map', 'data', nil);
  FFloor:=ini.ReadBitmap('Map', 'floor', nil);
  FSky:=ini.ReadBitmap('Map', 'sky', nil);
  Size:=getSize;
end;

destructor TLMap.Destroy;
begin
  inherited Destroy;
  setSize(Size);
end;

{
procedure TLMap.setTextures(Value: TLTextures);
var i: integer;
begin
  if Value=Nil then FTextures:=Nil
  else
  begin
    SetLength(FTextures, Length(Value));
    for i:=0 to Length(Value) do
      FTextures[i]:=Value[i];
  end;
end;
}

function TLMap.getSize: TL2DSize;
begin
  Result:=ini.ReadL2DSize('Map', 'size', TL2DSize.Create(data.Width, data.Height));
end;

procedure TLMap.setSize(Value: TL2DSize);
begin
  ini.WriteL2DSize('Map', 'size', Value);
end;

end.

