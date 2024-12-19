unit uMain;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls;

// DLL은 정적 또는 동적으로 로드 가능하다.
// 아래 DEFINE문을 활성화하면 동적로드로 사용한다.
{.$DEFINE USE_DYNAMIC}

type
  TfrmMain = class(TForm)
    btnConnect: TButton;
    mmo1: TMemo;
    procedure btnConnectClick(Sender: TObject);
  private
    {$IFDEF USE_DYNAMIC}
    FHandle: THandle;
    Connect: procedure(ACommand: PChar; var AResult: PChar); stdcall;
    Disconnect: procedure(ACommand: PChar; var AResult: PChar); stdcall;
    SendData: procedure(ACommand: PChar; var AResult: PChar); stdcall;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

{$IFNDEF USE_DYNAMIC}
const
  DLL_NAME = 'MES_IF.DLL';

  procedure Connect(ACommand: PChar; var AResult: PChar); stdcall; external DLL_NAME name 'Connect';
  procedure Disconnect(ACommand: PChar; var AResult: PChar); stdcall; external DLL_NAME name 'Disconnect';
  procedure SendData(ACommand: PChar; var AResult: PChar); stdcall; external DLL_NAME name 'SendData';
{$ENDIF}

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;

  {$IFDEF USE_DYNAMIC}
  //
  // DLL을 동적으로 읽어서 EXPORT된 함수를 가져온다
  //
  FHandle := LoadLibrary('MES_IF.DLL');
  if (FHandle > 0) then
  begin
    @Connect := GetProcAddress(FHandle, 'Connect');
    @Disconnect := GetProcAddress(FHandle, 'Disconnect');
    @SendData := GetProcAddress(FHandle, 'SendData');
  end;
  {$ENDIF}
end;

destructor TfrmMain.Destroy;
begin
  {$IFDEF USE_DYNAMIC}
  //
  // DLL을 메모리에서 해제한다
  //
  if (FHandle <> 0) then
    FreeLibrary(FHandle);
  {$ENDIF}

  inherited;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var
  LCommand: string;
  LResult: PChar;
begin
  // 함수 호출 후 결과값을 담을 변수를 초기화한다.
  GetMem(LResult, 4096);

  try
    // 연결
    LCommand := '{"MES_CONNECT": "CONNECT"}';
    mmo1.Lines.Add('COMMAND: ' + LCommand);
    Connect(PChar(LCommand), LResult);
    mmo1.Lines.Add(string(LResult));

    // StartCheck
    LCommand := '{"START_CHECK": "24073100102922H110S200_DV"}';
    mmo1.Lines.Add('COMMAND: ' + LCommand);
    SendData(PChar(LCommand), LResult);
    mmo1.Lines.Add(string(LResult));

    // Barcode
    LCommand :=
      '{"BARCODE_NO":"24073100102832H110S200_DV",' +
      '"CHANNEL_NO":"1",'+
      '"INSPECT_FINAL_RESULT":"OK",'+
      '"INSPECT_START_TIME":"2024-08-03 09:16:37",'+
      '"INSPECT_END_TIME":"2024-08-03 09:16:46",'+
      '"INSPECT_INFO":[{"BAR_SUB_NO":"24073100102832H110S200_DV",'+
      '"BAR_SUB_RST":"OK",'+
      '"INSPECT_CODE":"CRC VALUE,PINCOUNT",'+
      '"INSPECT_SUB_CODE":"CRCALUE,1",'+
      '"INSPECT_RESULT":"OK",'+
      '"INSPECT_VALUE":"0x2278A7BD,16129",'+
      '"INSPECT_ENV_CODE":"",'+
      '"INSPECT_ENV_VALUE":""}]}';
    mmo1.Lines.Add('COMMAND: ' + LCommand);
    Connect(PChar(LCommand), LResult);
    mmo1.Lines.Add(string(LResult));

    // 연결 끊기
    LCommand := '{"MES_DISCONNECT": "DISCONNECT"}';
    mmo1.Lines.Add('COMMAND: ' + LCommand);
    Disconnect(PChar(LCommand), LResult);
    mmo1.Lines.Add(string(LResult));
  finally
    FreeMem(LResult);
  end;
end;

end.
