unit LLevel;

{$mode objfpc}{$H+}{$Define LLEVEL}

interface

uses
  Classes, SysUtils, IniFiles, Graphics, LMap, LTypes, LIniFiles, LPosition,
  LSize{$IfDef WINDOWS}, mmsystem{$EndIf};

type
  TLLevel=class(TObject)
  private
    {types and vars}
    var
      FIni: TLIniFile;
      FMap: TLMap;
      FPlayerPosition: TLPlayerPosition;
      FwallMod: Integer;
      FDeath, FReachedWin, FCanWin: Boolean;
  public
    {types and vars}
    type
      TLLevelArray=array of TLLevel;
  public
    {functions and procedures}
    constructor Create(Aini: TLIniFile);
    function move(ADirection: TLDirection=0; ASteps: Integer=1;
      AUpdate: Boolean=True): TLPlayerPosition;
    destructor Destroy; override;
  private
    {propertyes}
    property ini: TLIniFile read FIni write FIni;
  public
    {propertyes}
    property Map: TLMap read FMap write FMap;
    procedure setPlayerPosition(Value: TLPlayerPosition);
    function isPlayerPosition(Value: TLPlayerPosition): Boolean;
    property PlayerPosition: TLPlayerPosition read FPlayerPosition
                                              write setPlayerPosition;
    function getWidth: Integer;
    procedure setWidth(Value: Integer);
    property Width: Integer read getWidth
                            write setWidth;
    function getHeight: Integer;
    procedure setHeight(Value: Integer);
    property Height: Integer read getHeight
                             write setHeight;
    function getViewSize: TL2DSize;
    procedure setViewSize(Value: TL2DSize);
    property ViewSize: TL2DSize read getViewSize
                                write setViewSize;
    function getHasMinimap: Boolean;
    property hasMinimap: Boolean read getHasMinimap;
    procedure setwallMod(Value: Integer);
    property wallMod: Integer read FwallMod
                              write setwallMod;
    function getFloor(APosition: TL2DPosition=nil): TColor;
    property Floor[APosition: TL2DPosition]: TColor read getFloor;

    function getSky(APosition: TL2DPosition=nil): TColor;
    property Sky[APosition: TL2DPosition]: TColor read getSky;

    function getIsWall(APosition: TL2DPosition=nil): Boolean;
    property isWall[APosition: TL2DPosition]: Boolean read getIsWall;

    property Death: Boolean read FDeath;
    property ReachedWin: Boolean read FReachedWin;
    property CanWin: Boolean read FCanWin;

    function getSucessed(APosition: TL2DPosition=nil): Boolean;
    property Sucessed[APosition: TL2DPosition]: Boolean read getSucessed;

    function getFloorDec(APosition: TL2DPosition): Boolean;
    property FloorDec[APosition: TL2DPosition]: Boolean read getFloorDec;

    function getdata(Aposition: TL2DPosition=nil): TColor;
    property data[APosition: TL2DPosition]: TColor read getdata;
  end;

TLLevelArray=TLLevel.TLLevelArray;

function ReadLevelArray(const Ident: String; var ini: TLIniFile): TLLevelArray;

implementation

constructor TLLevel.Create(AIni: TLIniFile);
begin
  inherited Create;
  Fini:=AIni;
  FMap:=TLMap.Create(ini.ReadIni('Map', 'ini'));
  FPlayerPosition:=TLPlayerPosition.Create;
  PlayerPosition.coords:=ini.ReadPoint('Player', 'coords', Point(round(Width/2), round(Height/2)));
  PlayerPosition.direction:=ini.ReadFloat('Player', 'direction', 0);
  FwallMod:=ini.ReadInteger('Map', 'wallmod', 1);
  FCanWin:=not ini.ReadBool('Map', 'key', False);
  FDeath:=ini.ReadBool('Player', 'death', False);
end;

function TLLevel.move(
  ADirection: TLDirection=0;
  ASteps: Integer=1;
  AUpdate: Boolean=True
): TLPlayerPosition;
var dir: TLDirection;
begin
  Result:=PlayerPosition.move(ADirection, ASteps, False);
  if not isPlayerPosition(Result) then
    Result:=PlayerPosition
  else if AUpdate then
  begin
    PlayerPosition:=Result;
    sndPlaySound(PChar(ini.ReadFn('Visualisator', 'walk_sound', '')), SND_ASYNC or SND_NODEFAULT);
  end;
end;

destructor TLLevel.Destroy;
begin
  inherited Destroy;
end;

function TLLevel.isPlayerPosition(Value: TLPlayerPosition):Boolean;
var minx, maxx, miny, maxy: Integer;
    cl: TColor;
begin
  minx:=1;
  maxx:=Map.Size.Width;
  miny:=1;
  maxy:=Map.Size.Height;
  Result:=(
    //((0<=Value.direction) and (Value.direction<=1)) and
    ((0<=Value.X) and (Value.X<=maxx)) and
    ((0<=Value.Y) and (Value.Y<=maxy))
  );
end;

procedure TLLevel.setPlayerPosition(Value: TLPlayerPosition);
begin
  if isPlayerPosition(Value) then
  begin
    FPlayerPosition:=Value;
    if (data[Value]=clBlue) then FCanWin:=True;
    if (data[Value]=clGreen) then FReachedWin:=True;
    if (data[Value]=clRed) then FDeath:=True;
  end;
end;

function TLLevel.getWidth: Integer;
begin
  Result:=Map.Size.Height;
end;

procedure TLLevel.setWidth(Value: Integer);
begin
  Map.Size.Width:=Value;
end;

function TLLevel.getHeight: Integer;
begin
  Result:=Map.Size.Height;
end;

procedure TLLevel.setHeight(Value: Integer);
begin
  Map.Size.Height:=Value;
end;

function TLLevel.getViewSize: TL2DSize;
begin
  Result:=ini.ReadL2DSize('Player', 'viewsize', TL2DSize.Create(Width, Height));
end;

procedure TLLevel.setViewSize(Value:TL2DSize);
begin
  ini.WriteL2DSize('Player', 'viewsize', Value);
end;



function TLLevel.getHasMinimap: Boolean;
begin
  Result:=ini.ReadBool('Level', 'minimap', True);
end;

procedure TLLevel.setwallMod(Value: Integer);
begin
  ini.WriteInteger('Map', 'wallmod', Value);
end;

function ReadLevelArray(const Ident: String; var ini: TLIniFile): TLLevelArray;
var inis: TLIniFileArray;
    i: Integer;
begin
  inis:=ini.ReadIniArray(Ident);

  SetLength(Result, Length(inis));
  for i:=0 to Length(inis)-1 do
  begin
    Result[i]:=TLLevel.Create(inis[i]);
  end;
end;

function TLLevel.getFloor(APosition: TL2DPosition=nil): TColor;
begin
  if Map.Floor<>Nil then
  begin
    if APosition=nil then APosition:=PlayerPosition;
    Result:=Map.Floor.Canvas.Pixels[APosition.X, APosition.Y];
  end else
    Result:=clWhite;
end;

function TLLevel.getSky(APosition: TL2DPosition=nil): TColor;
begin
  if Map.Sky<>Nil then
  begin
    if APosition=nil then APosition:=PlayerPosition;
    Result:=Map.Sky.Canvas.Pixels[APosition.X, APosition.Y];
  end else
    Result:=clWhite;
end;

function TLLevel.getdata(APosition: TL2DPosition=nil): TColor;
begin
  if APosition=nil then APosition:=PlayerPosition;
  Result:=Map.data.Canvas.Pixels[APosition.X, APosition.Y];
end;

function TLLevel.getSucessed(APosition: TL2DPosition=nil): Boolean;
begin
  Result:=ReachedWin and CanWin;
end;

function TLLevel.getFloorDec(APosition: TL2DPosition=nil): Boolean;
begin
  Result:=data[APosition]=clYellow;
end;

function TLLevel.getIsWall(APosition: TL2DPosition=nil): Boolean;
begin
  Result:=data[APosition]=clBlack;
end;

end.

