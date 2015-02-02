unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, UTF8Process, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, LIniFiles, LGraphics, LLevel, LTypes, fphttpclient, LSize,
  LPosition
  {$IfDef WINDOWS}, windows, mmsystem{$EndIf}, process, Unit2, LCLIntf;

type

  { TForm1 }

  TForm1 = class(TForm)
    resultp: TProcess;
    settings: TProcess;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
  private
    { private declarations }
    procedure setLevel(i: Integer);
  public
    { public declarations }
    function move(ADirection: TLDirection=0; ASteps: Integer=1;
      AUpdate: Boolean=True): TLPlayerPosition;
    function getPos: TL2DPosition;
    procedure setPos(value: TL2DPosition);
    property Pos: TL2DPosition read getPos write setPos;
    function getSize: TL2DSize;
    procedure setSize(Value: TL2DSize);
    property Size: TL2DSize read getSize write setSize;
  end;

var
  Form1: TForm1;
  ini, levelsini: TLIniFile;
  levels: TLLevelArray;
  Visualisator: TVisualisator;
  net: TFPHTTPClient;
  start: TDateTime;
  ido: Integer;
  steps: Integer;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var cini: TLIniFile;
    stream: TStringStream;
begin
  //stream:=TStringStream.Create;
  //;
  //cini:=TLIniFile.Create(stream);
  ini:=TLIniFile.Create('../../main.ini');
  Size:=ini.ReadL2DSize('Form', 'size', Size);
  Pos:=ini.ReadL2DPosition('Form', 'pos', Pos);
  Form2:=TForm2.Create(Form1);
  Visualisator:=TVisualisator.Create(Form1, ini.ReadIni('Visualisator', 'ini'));
  levelsini:=ini.ReadIni('Form', 'levelsini');
  levels:=ReadLevelArray('levels', levelsini);
  //Visualisator.Level:=levels[0];
  settings.Executable:=
    ini.ReadString('Settings', 'executable', '../settings/project1.exe');
  settings.Parameters.Add('--ini='+ini.FileName);
  resultp.Executable:=
    ini.ReadString('Result', 'executable', '../result/project1.exe');
  resultp.Parameters.Add('--ini='+ini.FileName);
  Color:=clGreen;
  Repaint;
  Timer1.Enabled:=True;
  Timer2.Interval:=ini.ReadInteger('Form', 'timerinterval', Timer2.Interval);
  Timer2.Enabled:=ini.ReadBool('Form', 'timer', Timer2.Enabled);
  Timer3.Interval:=ini.ReadInteger('Form', 'keydetect', Timer3.Interval);
  Timer3.Enabled:=True;
  sndPlaySound(PChar(ini.ReadFn('Form', 'music', '')), SND_ASYNC or SND_LOOP);
end;

procedure TForm1.FormDeactivate(Sender: TObject);
begin

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(Visualisator) then Visualisator:=nil;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: char);
begin
  //Color:=RGBToColor(Random(255), Random(255), Random(255));
  Color:=clRed;
  Repaint;
  case Key of
    'o':  FormCreate(Sender);
    '0'..'9': setLevel(StrToInt(Key));
    ' ':  Visualisator.draw;
    //'.':  Visualisator.drawNewGen;
    {$IfDef WINDOWS}#208{$Else}'#'{$EndIf}: Visualisator.dbg:=not Visualisator.dbg;                 //Dbg
    {$IfDef WINDOWS}#38 {$Else}'&'{$EndIf}: Visualisator.DrawCorner:=not Visualisator.DrawCorner;   //drawCorner
    {$IfDef WINDOWS}#228{$Else}'<'{$EndIf}: Visualisator.Animate:=not Visualisator.Animate;         //Animate
    //#163: Visualisator.DrawDirect:=not Visualisator.DrawDirect;   //Lowmem
    '[':  begin                                                   //Fullscreen
            Visualisator.Width:=Width;
            Visualisator.Height:=Height;
          end;
    #08:  FormDestroy(Self);                                      //backspace
    #27:  Close;                                                  //ESCape
    #240: begin                                                   //settings
            ini.Free;
            settings.Execute;
            Timer1.Enabled:=False;
            Timer2.Enabled:=False;
            Timer3.Enabled:=False;
            Visualisator.Picture.Bitmap:=ini.ReadBitmap('Form', 'wait', Visualisator.Picture.Bitmap);
            while settings.Active do
            begin
              //Sleep(1000);
              Repaint;
            end;
            FormCreate(Nil);
          end;
    else
      begin
        Color:=clYellow;
        Repaint;
        //Timer1.Enabled:=True;
      end;
  end;
  //Caption:=Key+'#'+IntToStr(Ord(Key));
  Repaint;
  Color:=clDefault;
  Repaint;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Form2.Left:=Left+Width+3;
  Form2.Top:=Top;
  Visualisator.Size.Width:=Width;
  Visualisator.Size.Height:=Height;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if Visualisator.Level<>Nil then Inc(ido);
  //Color:=clDefault;
  //Enabled:=False;
  if Visualisator.Level=Nil then Exit;
  if Visualisator.Level.getSucessed then
  begin
    resultp.Parameters.Add('--time='+IntToStr(ido));
    //resultp.Parameters.Add('--start='+FloatToStr(start));
    resultp.Parameters.Add('--steps='+IntToStr(steps));
    resultp.Parameters.Add('--action=win');
    ini.Free;
    //ShowMessage(resultp.Parameters.Text);
    //ShowMessage(IntToStr(steps)+#10#13+FloatToStr(start)+#10#13+FloatToStr(Now));
    resultp.Execute;
    Timer1.Enabled:=False;
    Timer2.Enabled:=False;
    Timer3.Enabled:=False;
    //ShowMessage('Executed...');
    while resultp.Running do
      Sleep(1);
    FormCreate(Nil);
  end else
  if Visualisator.Level.Death then
  begin
    resultp.Parameters.Add('--start='+FloatToStr(start));
    resultp.Parameters.Add('--steps='+IntToStr(steps));
    resultp.Parameters.Add('--action=death');
    ini.Free;
    resultp.Execute;
    Timer1.Enabled:=False;
    Timer2.Enabled:=False;
    Timer3.Enabled:=False;
    while resultp.Running do
      Sleep(1);
    FormCreate(Nil);
  end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  Color:=clRed;
  Repaint;
  if Visualisator.Level<>Nil then
  begin
    Visualisator.draw;
  end;
  Color:=clDefault;
  Repaint;
end;

procedure TForm1.Timer3Timer(Sender: TObject);
var i: Integer;
begin
  Caption:='';
if (Visualisator<>Nil) and (Visualisator.Level<>Nil) then
  for i:=1 to 255 do
  begin
    if GetKeyState(i)<0 then
    begin
      case chr(i) of
        'W':  move(0*right_angle, 3);
        'A':  move( -right_angle, 3);
        'S':  move(2*right_angle, 3);
        'D':  move( +right_angle, 3);
        {$IfDef WINDOWS}#226{$Else}#16{$EndIf}: Visualisator.Level.PlayerPosition.direction:=Visualisator.Level.PlayerPosition.direction-0.1; //í
        'C':  Visualisator.Level.PlayerPosition.direction:=Visualisator.Level.PlayerPosition.direction+0.1;
        else Caption:='Pressed:'+chr(i)+'['+IntToStr(i)+']';
      end;
    end;
  end;
end;

procedure TForm1.setLevel(i: Integer);
begin
  if levels[i-1].hasMinimap then
  begin
    Form2.Show;
    Visualisator.Minimap:=Form2;
  end else
  begin
    Form2.Hide;
    Visualisator.Minimap:=Nil;
  end;
  Visualisator.Level:=levels[i-1];
  Show;
  start:=Now;
  ido:=0;
end;

function TForm1.move(ADirection: TLDirection=0; ASteps: Integer=1;
  AUpdate: Boolean=True): TLPlayerPosition;
begin
  Result:=Visualisator.Level.move(ADirection, ASteps, AUpdate);
  Inc(steps);
end;

function TForm1.getPos:TL2DPosition;
begin
  Result:=TL2DPosition.Create(Left, Top);
end;

procedure TForm1.setPos(Value: TL2DPosition);
begin
  Left:=Value.X;
  Top:=Value.Y;
end;

function TForm1.getSize: TL2DSize;
begin
  Result:=TL2DSize.Create(Width, Height);
end;

procedure TForm1.setSize(Value: TL2DSize);
begin
  Width:=Value.x;
  Height:=Value.y;
end;

end.

