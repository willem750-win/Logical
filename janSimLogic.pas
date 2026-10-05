unit janSimLogic;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages,  Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs,extctrls,
  menus, Stdctrls, ActnList,chatgridpcodeSmall, Inifiles, TypInfo, SZCodeBaseX, LResources;

type
 // type om in main.pas button btDelCurObject te sturen voor deleten van ogject Tjan....
  TSimSelectEvent = procedure(Sender: TObject; SelectedObj: TObject) of object;
 //TjanSimPuls  object
  TState = (stStarted, stStopped);
  TStateChangeEvent = procedure(Sender : TObject; State : TState) of object;
  //TjanTeller object
  TStat1 = (stBit1Start, stBit1Stop);
  TBit1ChangeEvent = procedure(Sender : TObject; State : TStat1) of object;
  TStat2 = (stBit2Start, stBit2Stop);
  TBit2ChangeEvent = procedure(Sender : TObject; State : TStat2) of object;
  TStat4 = (stBit4Start, stBit4Stop);
  TBit4ChangeEvent = procedure(Sender : TObject; State : TStat4) of object;
  TStat8 = (stBit8Start, stBit8Stop);
  TBit8ChangeEvent = procedure(Sender : TObject; State : TStat8) of object;
  //TjanMemory object
  TStatMem1 = (stBitMem1Start, stBitMem1Stop);
  TBitMem1ChangeEvent = procedure(Sender : TObject; State : TStatMem1) of object;
  TStatMem2 = (stBitMem2Start, stBitMem2Stop);
  TBitMem2ChangeEvent = procedure(Sender : TObject; State : TStatMem2) of object;
  TStatMem4 = (stBitMem4Start, stBitmem4Stop);
  TBitMem4ChangeEvent = procedure(Sender : TObject; State : TStatMem4) of object;
  TStatMem8 = (stBitMem8Start, stBitMem8Stop);
  TBitMem8ChangeEvent = procedure(Sender : TObject; State : TStatMem8) of object;
  TStatMemB = (stMemButtonStart, stMemButtonStop);
  TMemBChangeEvent = procedure(Sender : TObject; State : TStatMemB) of object;
  //TjanSimButton  object
  TStatButton = (stButtonStart, stButtonStop);
  TButtonChangeEvent = procedure(Sender : TObject; State : TStatButton) of object;
  // TjanSimKnop
  TStatKnop = (stKnopStart, stKnopStop);
  TKnopChangeEvent = procedure(Sender : TObject; State : TStatKnop) of object;
  //TjanSimSensor licht object
  TStatLicht = (stLichtStart, stLichtStop);
  TLichtChangeEvent = procedure(Sender : TObject; State : TStatLicht) of object;

  //TjanDipSwitsh  object
  TStatDip = (stDipStart, stDipStop);
  TDipChangeEvent = procedure(Sender : TObject; State : TStatDip; Bits:Integer) of object;

  //TjanSimWarm Temperatuur object
  TStatTemp = (stTempStart, stTempStop);
  TTempChangeEvent = procedure(Sender : TObject; State : TStatTemp) of object;
  //TjanLogic Poort-object
  TStatPoort = (stPoortStart, stPoortStop);
  TPoortChangeEvent = procedure(Sender : TObject; State : TStatPoort) of object;
  //TjanSimLogicBox Box object
  TStatTaal = (stDutch, stEnglish, stFrench, stGerman);

  TObjectStatusEvent = procedure(Sender: TObject; const AText: string; APanel: Integer) of object;

  TjanSimLogicBox = class;  // forward


  // Event doorgeven van Strings naar TStatusBar panels in main
  TSimStatusEvent = procedure(Sender: TObject; const AText: string; APanel: Integer) of object;
  TSimStatusEventEx = procedure(Sender: TObject; ASource: TObject;const AText: string; APanel: Integer) of object;

  TjanLogic=class;
  TjanTeller=class;
  TjanMemory=class;

  TjanGateStyle=(jgsDI,jgsDO);
  TjanLogicFunc=(jlfAND,jlfOR,jlfNOT);
  TjanMeterFunc=(jlfEN);


  TjanGate = record
    Style:TjanGateStyle;
    State:boolean;
    Active:Boolean;
    pos:TPoint;
  end;

  TjanConMode=(jcmTL,jcmTR,jcmBR,jcmBL);
  TjanConPos=(jcpTL,jcpTR,jcpBR,jcpBL);
  TjanConShape=(jcsTLBR,jcsTRBL);

  TInputBoxForm = class(TForm)
  private
    FEdit: TEdit;
    FLabel: TLabel;
    FOkButton: TButton;
    FCancelButton:TButton;
  public
    constructor Create(AOwner: TComponent); override;
    function Execute(const ACaption, APrompt, ADefault: string; out AResult: string): Boolean;
  end;

  TjanDisplay = class(TGraphicControl)
  private
    Select:Boolean;

    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FBits       : Integer;
    FDigit      : char;
    FOnColor    : TColor;
    FOffColor   : TColor;
    FBackColor  : TColor;
    FSegWidth   : integer;
    FMargin     : integer;
    FPenOnColor : TColor;
    FPenOffColor: TColor;
    UpLeft      : array[0..34] of TPoint;
    SegHorLen   : integer;
    SegVerLen   : integer;
    SegHalf     : integer;
    OldWidth    : integer;
    OldHeight   : integer;
    newleft:integer;
    newtop:integer;
    FInfo:String;
    FLock:Boolean;
    //
    FOnEnter: TNotifyEvent;//xxx
    FOnExit: TNotifyEvent;//xxx
    FDown: boolean;//xxx
    FDepressed:boolean;//xxx
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FSelected: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    //
    procedure SendStatusToBar;//xxx
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetDown(const Value: boolean);//xxx
    procedure UpdateHintText; //xxxx
    //
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    //old
    procedure Click1(sender:TObject);
    procedure Click2(sender:TObject);
    procedure Click3(sender:TObject);
    //new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer
    //
    procedure SetBits(const Value: Integer);
    procedure SetDigit(WhatDigit: char);
    procedure SetOnColor(WhatColor: TColor);
    procedure SetOffColor(WhatColor: TColor);
    procedure SetBackColor(WhatColor: TColor);
    procedure SetSegWidth(WhatWidth: integer);
    procedure SetMargin(WhatWidth: integer);
    procedure SetPenOnColor(WhatColor: TColor);
    procedure SetPenOffColor(WhatColor: TColor);
    procedure Hexagon(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
    procedure DrawDot(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
    procedure DrawBulb(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
    procedure DrawTopSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
    procedure DrawBottomSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
    procedure DrawLeftSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
    procedure DrawRightSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
    procedure DrawNorthWest(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
    procedure DrawNorthEast(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
    procedure DrawDigit(WhereTo: TBitmap);
    procedure SetMeasures;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    //new
    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx
  public
    procedure Paint; override;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  published
    property Bits:Integer read FBits write SetBits;
    property Digit: char read FDigit write SetDigit;
    property OnColor: TColor read FOnColor write SetOnColor;
    property OffColor: TColor read FOffColor write SetOffColor;
    property BackColor: TColor read FBackColor write SetBackColor;
    property SegWidth: integer read FSegWidth write SetSegWidth;
    property Margin: integer read FMargin write SetMargin;
    property Info:String read FInfo write SetInfo;
    property Lock:boolean read FLock write SetLock;
    property PenOnColor: TColor read FPenOnColor write SetPenOnColor default clGray;
    property PenOffColor: TColor read FPenOffColor write SetPenOffColor default clGray;

    property ShowHint;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property Down:boolean read FDown write SetDown default false;
    property BTaal:String read FTaal write SetTaal; //xxx
    property Naam :String read FNaam write SetNaam;//xxx
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx
     property HelpKeyword;

  end;

  TjanConnector = class(TGraphicControl)
  private
    { Private declarations }
    Hit:Boolean;
    TSchrijf:Boolean;
    VAdres:Integer;
    Ledd:Integer;
    Tmemlist: Array[0..15] of integer;
    FParent:TWinControl;
    FPower:Boolean;
    mdp:TPoint;
    oldp:TPoint;
    ConAnchor:TPoint;
    ConOffset:TPoint;
    ConMode:TjanConMode;
    ConHot:TjanConPos;
    doMove:boolean;
    doEdge:boolean;
    DisCon:Tcontrol;
    DisConI:integer;

    Mode:TjanConMode;
    Shape:TjanConShape;
    conPos:TjanConPos;
    Edge:extended;


    S_Mode:String;
    S_Shape:String;
    S_Pos:String;
    S_Edge:String;
    conSize:integer;

    FLock:Boolean;

    FToTeller:TjanTeller;
    FFromLogic: TjanLogic;
    FToLogic: TjanLogic;
    FFromGate: integer;
    FToGate: integer;
    FFromPoint: TPoint;
    FToPoint: TPoint;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    select:Boolean;
    procedure SetJanConMode(value: TjanConMode);
    procedure SetJanConShape(value: TjanConShape);
    procedure SetJanConPos(value: TjanConPos);
    procedure SetJanEdge(value: extended);
    procedure SetLock(const Value:  Boolean);
    procedure DraadClick(sender:TObject); // verwijderen van draad ??
    procedure SetFromLogic(const Value: TjanLogic);
    procedure SetToLogic(const Value: TjanLogic);
    procedure SetToTeller(const Value: TjanTeller);
    procedure SetFromGate(const Value: integer);
    procedure SetToGate(const Value: integer);
    procedure SetFromPoint(const Value: TPoint);
    procedure SetToPoint(const Value: TPoint);
    procedure setpower(const Value:  Boolean);
    procedure SetS_Edge(Value: string);
    procedure SetS_mode(Value: string);
    procedure SetS_pos(Value: string);
    procedure SetS_Shape(Value: string);
    procedure DisConnectFinal;
    procedure CMHitTest(var Msg: TCMHitTest); message CM_HITTEST;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;

  protected
    { Protected declarations }
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
  public
    { Public declarations }
    constructor Create(AOwner:TComponent); override;
    procedure paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoMouseDown(x, y: integer);
    procedure DoMouseMove(dx, dy: integer);
    procedure AnchorCorner(logTL:TPoint;ACorner:TjanConMode);
    procedure MoveConnector(logTL:TPoint);

    property ToPoint:TPoint read FToPoint write SetToPoint;
    property FromPoint:TPoint read FFromPoint write SetFromPoint;

    procedure Connect;
    procedure DisConnect;

  published
    { Published declarations }
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property V_ConPos:TjanConPos read ConPos write SetjanConPos;
    property V_ConMode:TjanConMode read Mode write SetjanconMode;
    property V_ConShape:TjanConShape read Shape write SetjanconShape;
    property V_Edge:extended read Edge write SetjanEdge;
    property W_ConPos:String read S_Pos write S_Pos;
    property W_ConMode:String read S_Mode write S_Mode;
    property W_ConShape:String read S_Shape write s_Shape;
    property W_Edge:String read S_Edge write S_Edge;
    property FromLogic:TjanLogic read FFromLogic write SetFromLogic;
    property FromGate:integer read FFromGate write SetFromGate;

    property ToLogic:TjanLogic read FToLogic write SetToLogic;
    property ToTeller:TjanTeller read FToTeller write SetToTeller;
    property ToGate:integer read FToGate write SetToGate;

    property Power:Boolean read Fpower write Setpower;
    property Lock:Boolean read FLock write SetLock;
    property visible;
     property HelpKeyword;
  end;


  TjanLogic = class(TGraphicControl)
  private
    Select:Boolean;
    FType:String;
    FStatPoort  : TStatPoort;
    FOnStatPoortChange            : TPoortChangeEvent;
    lIn:TBitmap;
    lUit:TBitmap;
    FPcolor:TColor;
    FLock:Boolean;
    FInfo:String;

    doMove:boolean;
    doStyle:boolean;
    StyleDown:boolean;
    mdp:TPoint;
    oldp:TPoint;
    FGates: array[0..5] of TjanGate;
    Connectors:TList;
    newLeft:integer;
    newTop:integer;
    FOutPut1: boolean;
    FInput2: boolean;
    FOutPut3: boolean;
    FInput3: boolean;
    FOutPut2: boolean;
    FInput1: boolean;
    FLogicAndFunc: TjanLogicFunc;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FTaal:string;//xxxx
    FSoort:String;//xxxx
    FNaam:String;//xxxx
    FDown:Boolean;//xxxx
    FDepressed:boolean;//xxxx
    FSelected: Boolean;//xxxx
    FMouseOver: Boolean; //xxxx

    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    FOnStatus: TSimStatusEvent;//xxxx doorgeven van strings naan StatusBar1 panels
    procedure  SendStatusToBar;//xxxx
    procedure SetNaam(const Value: String);//xxxx

    procedure SetTaal(const Value: String);
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;


    function  GetGate(Index: Integer): TjanGate;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(index:integer);
    function GetLogicFuncText: string;
    procedure SetDown(const Value: boolean);//xxxx
    // new
     procedure ButtonClick1(sender:TObject);  // blokkeer object FLock
     procedure ButtonClick3(sender:TObject);  // info Ja/Nee
     procedure ButtonNClick(sender:TObject); //wijzig naam
     procedure ButtonClick4(sender:TObject); // selecteer object

    procedure SetInput1(const Value: boolean);
    procedure SetInput2(const Value: boolean);
    procedure SetInput3(const Value: boolean);
    procedure SetOutPut1(const Value: boolean);
    procedure SetOutPut2(const Value: boolean);
    procedure SetOutPut3(const Value: boolean);
    procedure SetLogicFunc(const Value: TjanLogicFunc);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    procedure SetPcolor(const Value:TColor);
    procedure Settype(const Value: String);
    procedure OutCalc;

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;

    procedure BuildPopup; //xxxx
    procedure UpdatePopupCaptions;//xxxx
    procedure UpdateHintText; ////xxxx
    procedure Resize; override;

  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property Gates[index:integer]: TjanGate read GetGate;
    property StatPoort  : TStatPoort read FStatPoort;
  published
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;

    property BTaal:String read FTaal write SetTaal;
    property Naam :String read FNaam write SetNaam; //xxxx
    property Soort:String read FSoort write FSoort;// invoer,verwerking,uitvoer xxxx
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxxx
    property Selected: Boolean read FSelected write FSelected;//xxxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxxx
    property Down:boolean read FDown write SetDown;
    property Input1:boolean read FInput1 write SetInput1;
    property Input2:boolean read FInput2 write SetInput2;
    property Input3:boolean read FInput3 write SetInput3;
    property OutPut1:boolean read FOutPut1 write SetOutPut1;
    property OutPut2:boolean read FOutPut2 write SetOutPut2;
    property OutPut3:boolean read FOutPut3 write SetOutPut3;
    property LogicFunc:TjanLogicFunc read FLogicAndFunc write SetLogicFunc;
    property Lock:boolean read FLock write SetLock;
    property L_Type:String read FType write Settype;
    property Info:String read FInfo write SetInfo;
    property PColor:TColor read FPcolor write SetPcolor;
    property ShowHint;
     property HelpKeyword;
    property OnPoortOutChange : TPoortChangeEvent read FOnStatPoortChange write FOnStatPoortChange;

  end;

  //nu
  TjanTeller = class(TGraphicControl)
  private
    Select:Boolean;
    FStat1  : TStat1;
    FOnStat1Change            : TBit1ChangeEvent;
    FStat2  : TStat2;
    FOnStat2Change            : TBit2ChangeEvent;
    FStat4  : TStat4;
    FOnStat4Change            : TBit4ChangeEvent;
    FStat8  : TStat8;
    FOnStat8Change            : TBit8ChangeEvent;
    Uit:TBitmap;
    lIn:TBitmap;
    lUit:TBitmap;
    lBitUit:TBitmap;
    FLedColUit:TColor;
    FLedColAan:TColor;
    FBits:Integer;
    FBitsChar:Char;
    FLoop:Boolean;
    FPcolor:TColor;
    FLock:Boolean;
    FInfo:String;
    doMove:boolean;
    doStyle:boolean;
    StyleDown:boolean;
    mdp:TPoint;
    oldp:TPoint;
    FGates: array[0..6] of TjanGate;
    Connectors:TList;
    newLeft:integer;
    newTop:integer;
    FInput3: boolean;
    FOutPutDisplay: boolean; // uitgang naar display
    FOutPutBit1: boolean;
    FOutPutBit2: boolean;
    FOutPutBit4: boolean;
    FOutPutBit8: boolean;
    FOutPutBits: boolean;
    FInput1: boolean;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    Ftaal:string;
    // nieuw
    FSoort:String;//xxxx
    FNaam:String;//xxxx ok
    FDown:Boolean;//xxxx
    FDepressed:boolean;//xxxx
    FSelected: Boolean;//xxxx
    FMouseOver: Boolean; //xxxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    procedure SetDown(const Value: boolean);//xxxx
    procedure SetNaam(const Value: String);//xxxx
    procedure SendStatusToBar;//xxx

    procedure SetTaal(const Value: String);
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;//xxxx
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;//xxxx
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    function  GetGate(Index: Integer): TjanGate;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLeds(bit:Integer);
    procedure PaintLed8(status:integer);
    procedure PaintLed4(status:Integer);
    procedure PaintLed2(status:Integer);
    procedure PaintLed1(status:Integer);
    //new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer

    procedure SetInput1(const Value: boolean);
    procedure SetInput3(const Value: boolean);
    procedure SetOutPutDisplay(const Value: boolean);// uitgang naar display
    procedure SetOutPutBit1(const Value: boolean);
    procedure SetOutPutBit2(const Value: boolean);
    procedure SetOutPutBit4(const Value: boolean);
    procedure SetOutPutBit8(const Value: boolean);
    procedure SetOutPutBits(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetLoop(const Value: boolean);
    procedure SetInfo(const Value: String);
    procedure SetBits(const Value: Integer);
    procedure SetBitsChar(const Value: char);
    procedure SetPcolor(const Value:TColor);
    procedure SetLedColUit(const Value:TColor);
    procedure SetLedColAan(const Value:TColor);


  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxxx
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;//xxxx
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxxx
    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx
    procedure UpdateHintText; //xxxx
    procedure Resize; override;



  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property Gates[index:integer]: TjanGate read GetGate;
    property Stat1  : TStat1 read FStat1;
    property Stat2  : TStat2 read FStat2;
    property Stat4  : TStat4 read FStat4;
    property Stat8  : TStat8 read FStat8;

  published
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnBit1Change : TBit1ChangeEvent read FOnStat1Change write FOnStat1Change;
    property OnBit2Change : TBit2ChangeEvent read FOnStat2Change write FOnStat2Change;
    property OnBit4Change : TBit4ChangeEvent read FOnStat4Change write FOnStat4Change;
    property OnBit8Change : TBit8ChangeEvent read FOnStat8Change write FOnStat8Change;
    property Reset:boolean read FInput1 write SetInput1;
    property Input:boolean read FInput3 write SetInput3;
    property OutPutDisplay:boolean read FOutPutDisplay write SetOutPutDisplay;
    property OutPutBit1:boolean read FOutPutBit1 write SetOutPutBit1;
    property OutPutBit2:boolean read FOutPutBit2 write SetOutPutBit2;
    property OutPutBit4:boolean read FOutPutBit4 write SetOutPutBit4;
    property OutPutBit8:boolean read FOutPutBit8 write SetOutPutBit8;
    property visible;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property PColor:TColor read FPcolor write SetPcolor;
    property LedkleurUit:TColor read FLedColUit write SetLedColUit;
    property LedkleurAan:TColor read FLedColAan write SetLedColAan;
    property Bits:Integer read FBits write SetBits;
    property BitsChar:Char read FBitsChar write SetBitsChar default '0';
    property TelOp:Boolean read FLoop write SetLoop;
    property ShowHint;

    property Down:boolean read FDown write SetDown default false;//xxxx
    property BTaal:String read FTaal write SetTaal;//xxxx
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx
    property Naam :String read FNaam write SetNaam;//xxxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxxx
    property Soort:String read FSoort write FSoort;//xxxx invoer,verwerking,uitvoer
     property HelpKeyword;
  end;

  TjanMemory = class(TGraphicControl)
  private
    Select:Boolean;
    schrijf:boolean;
    Lijst:TStringList;
    FStatMem1  : TStatMem1;
    FOnStatMem1Change            : TBitMem1ChangeEvent;
    FStatMem2  : TStatMem2;
    FOnStatMem2Change            : TBitMem2ChangeEvent;
    FStatMem4  : TStatMem4;
    FOnStatMem4Change            : TBitMem4ChangeEvent;
    FStatMem8  : TStatMem8;
    FOnStatMem8Change            : TBitMem8ChangeEvent;
    FStatMemB  : TStatMemB;
    FOnStatMemBChange            : TMemBChangeEvent;

    FConnector:Boolean;
    Bin:TBitmap;
    BinAan:TBitmap;
    Uit:TBitmap;
    Inv:TBitmap;
    lIn:TBitmap;
    lUit:TBitmap;
    lBitUit:TBitmap;
    lBitUit1:TBitmap;
    lAcoo:TBitmap;
    FLedColUit:TColor;
    FLedColAan:TColor;
    FBits:Integer;
    FAdress:Integer;
    FA1:Boolean;
    FA2:Boolean;
    FA4:Boolean;
    FA8:Boolean;
    FBitsChar:Char;
    FPcolor:TColor;
    FLock:Boolean;
    FInfo:String;
    doMove:boolean;
    doStyle:boolean;
    StyleDown:boolean;
    mdp:TPoint;
    oldp:TPoint;
    FGates: array[0..10] of TjanGate;
    Connectors:TList;
    newLeft:integer;
    newTop:integer;
    FInputMem3: boolean;
    FOutPutDisplay: boolean; // uitgang naar display
    FOutPutBitMem1: boolean;
    FOutPutBitMem2: boolean;
    FOutPutBitMem4: boolean;
    FOutPutBitMem8: boolean;
    FInputMem1: boolean;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;

    // nieuw
    Ftaal:string; //xxxx
    FSoort:String;//xxxx
    FNaam:String;//xxxx ok
    FDown:Boolean;//xxxx
    FDepressed:boolean;//xxxx
    FSelected: Boolean;//xxxx
    FMouseOver: Boolean; //xxxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    procedure SendStatusToBar;//xxx
    procedure SetDown(const Value: boolean);//xxxx
    procedure SetNaam(const Value: String);//xxxx
    procedure SetTaal(const Value: String);

    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    function  GetGate(Index: Integer): TjanGate;
    procedure AnchorConnectors;
    procedure MoveConnectors;

    procedure SetA1(const Value: boolean);
    procedure SetA2(const Value: boolean);
    procedure SetA4(const Value: boolean);
    procedure SetA8(const Value: boolean);
    procedure SetConnector(const Value: boolean);
    procedure PaintLeds(bit:Integer);
    procedure PaintLed8(status:integer);
    procedure PaintLed4(status:Integer);
    procedure PaintLed2(status:Integer);
    procedure PaintLed1(status:Integer);
    // old
      //procedure MemoryClick(sender:TObject);
      //procedure MemoryClick1(sender:TObject);
      //procedure MemoryClick2(sender:TObject);
    // new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer


    procedure SetInputMem1(const Value: boolean);

    procedure SetInputMem3(const Value: boolean);
    procedure SetOutPutMemDisplay(const Value: boolean);// uitgang naar display
    procedure SetOutPutMemBit1(const Value: boolean);
    procedure SetOutPutMemBit2(const Value: boolean);
    procedure SetOutPutMemBit4(const Value: boolean);
    procedure SetOutPutMemBit8(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    procedure SetBits(const Value: Integer);
    procedure SetAdress(const Value: Integer);
    procedure SetBitsChar(const Value: char);
    procedure SetPcolor(const Value:TColor);
    procedure SetLedColUit(const Value:TColor);
    procedure SetLedColAan(const Value:TColor);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxxx
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;//xxxx
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxxx

    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx
    procedure UpdateHintText; //xxxx

    procedure Resize; override;

  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    procedure getadress;
    property Gates[index:integer]: TjanGate read GetGate;
    property StatMem1  : TStatMem1 read FStatMem1;
    property StatMem2  : TStatMem2 read FStatMem2;
    property StatMem4  : TStatMem4 read FStatMem4;
    property StatMem8  : TStatMem8 read FStatMem8;
    property StatMemB  : TStatMemB read FStatMemB;
  published
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnBitMem1Change : TBitMem1ChangeEvent read FOnStatMem1Change write FOnStatMem1Change;
    property OnBitMem2Change : TBitMem2ChangeEvent read FOnStatMem2Change write FOnStatMem2Change;
    property OnBitMem4Change : TBitMem4ChangeEvent read FOnStatMem4Change write FOnStatMem4Change;
    property OnBitMem8Change : TBitMem8ChangeEvent read FOnStatMem8Change write FOnStatMem8Change;
    property OnMemButtonChange : TMemBChangeEvent read FOnStatMemBChange write FOnStatMemBChange;
    property Reset:boolean read FInputMem1 write SetInputMem1;
    property Input:boolean read FInputMem3 write SetInputMem3;
    property Connector:boolean read FConnector write SetConnector default true;
    property OutPutDisplay:boolean read FOutPutDisplay write SetOutPutMemDisplay;
    property OutPutBitMem1:boolean read FOutPutBitMem1 write SetOutPutMemBit1;
    property OutPutBitMem2:boolean read FOutPutBitMem2 write SetOutPutMemBit2;
    property OutPutBitMem4:boolean read FOutPutBitMem4 write SetOutPutMemBit4;
    property OutPutBitMem8:boolean read FOutPutBitMem8 write SetOutPutMemBit8;
    property ButtonDown:boolean read FDown write SetDown default false;
    property A1:boolean read FA1 write SetA1 default false;
    property A2:boolean read FA2 write SetA2 default false;
    property A4:boolean read FA4 write SetA4 default false;
    property A8:boolean read FA8 write SetA8 default false;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property PColor:TColor read FPcolor write SetPcolor;
    property LedkleurUit:TColor read FLedColUit write SetLedColUit;
    property LedkleurAan:TColor read FLedColAan write SetLedColAan;
    property Adress:Integer read FAdress write SetAdress;
    property Bits:Integer read FBits write SetBits;
    property BitsChar:Char read FBitsChar write SetBitsChar default '0';
    property ShowHint;

    property Down:boolean read FDown write SetDown default false;//xxxx
    property Naam :String read FNaam write SetNaam;//xxxx
    property BTaal:String read FTaal write SetTaal;//xxxx
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxxx
    property Soort:String read FSoort write FSoort;//xxxx invoer,verwerking,uitvoer
     property HelpKeyword;
  end;


  TjanMeter = class(TGraphicControl)
  private
    Select:Boolean;
    lIn:TBitmap;
    V0:TBitmap;V5:TBitmap;
    FPcolor:TColor;
    FLock:Boolean;
    FInfo:String;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    FGates: array[0..5] of TjanGate;
    Connectors:TList;
    newLeft:integer;
    newTop:integer;
    FInput3: boolean;
    FOutPut2: boolean;
    FInput1: boolean;
    FLogicAndFunc: TjanMeterFunc;
    function  GetGate(Index: Integer): TjanGate;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(index:integer);
    procedure MeterClick(sender:TObject);
    procedure MeterClick1(sender:TObject);
    procedure MeterClick2(sender:TObject);
    procedure SetInput1(const Value: boolean);

    procedure SetInput3(const Value: boolean);

    procedure SetOutPut2(const Value: boolean);

    procedure SetLogicFunc(const Value: TjanMeterFunc);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    procedure SetPcolor(const Value:TColor);
    procedure OutCalc;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure Resize; override;
  public
     constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property Gates[index:integer]: TjanGate read GetGate;
  published
    property Input1:boolean read FInput1 write SetInput1;
    property Input3:boolean read FInput3 write SetInput3;
    property OutPut2:boolean read FOutPut2 write SetOutPut2;
    property LogicFunc:TjanMeterFunc read FLogicAndFunc write SetLogicFunc;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property PColor:TColor read FPcolor write SetPcolor;
    property ShowHint;
     property HelpKeyword;
  end;



  TjanSimButton = class (TGraphicControl)
  private

    select:Boolean;
    FRuntime:Boolean;
    FInfo:String;
    FConnectie:Boolean;
    FAction:TAction;
    FModus:Boolean;
    FModusSquare:Boolean;
    FText:string;
    FStatButton  : TStatButton;
    FOnStatButtonChange  : TButtonChangeEvent;
    FPuls:Integer;
    FActiv:Boolean;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    doMove:boolean;
    FDraad:Boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FDown: boolean;
    FDepressed:boolean;
    newLeft:integer;
    newTop:integer;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FTaal:string;

    FNaam:String;
    FSoort:String;
    FMouseOver: Boolean;

    FSelected: Boolean;//xxxx
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    FOnStatus: TSimStatusEvent; //doorgeven van strings naan StatusBar1 panels
    procedure SendXYmoveToBar;
    Procedure SendStatusToBar;
    procedure UpdateHintText;
    procedure SetTaal(const Value: String);

    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SetRuntime(const value:Boolean);
    procedure SetInfo(const Value: String);
    procedure SetNaam(const Value: String);
    procedure SetAction(Aktie:Taction);
    procedure PaintLed(pt:TPoint;lit:boolean);
    procedure SetConnectie(const Value:Boolean);
    procedure Setdraad(const Value:Boolean);
    procedure SetDown(const Value: boolean);
    procedure SetModus(const Value: Boolean);
    procedure SetModusSquare(const Value: Boolean);
    procedure SetText(const value: string);
    procedure SetLock(const Value: boolean);

    procedure ButtonClick1(sender:TObject);  // xxxx blokkeer object FLock
    procedure ButtonClick3(sender:TObject);  // xxxx info Ja/Nee
    procedure ButtonNClick(sender:TObject);  // xxxx wijzig naam
    procedure ButtonClick4(sender:TObject);  // xxxx selecteer object voor verwijdering
    // test
    procedure SetPuls(const Value:Integer);
    procedure SetActiv(const Value:Boolean);

    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;//xxxx
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;//xxxx

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure Resize; override;

    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx
  public

    constructor Create(AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override; // xxxx

    property StatButton  : TStatButton read FStatButton;
  published
    property Text:string read FText write SetText;
    property Runtime:boolean read FRuntime write SetRuntime default true;
    property BTaal:String read FTaal write SetTaal;//xxxx
    property Action:TAction read FAction write SetAction;
    property Puls:Integer read FPuls write setpuls default 0;
    property Down:boolean read FDown write SetDown default false;
    property ModusSmall:boolean read FModus write SetModus default false;
    property ModusSquare:boolean read FModusSquare write SetModusSquare default false;
    property Lock:boolean read FLock write SetLock;
    property Connector:boolean read FConnectie write SetConnectie default false;
    property Aktief:boolean read FActiv write SetActiv default false;
    property Draad:Boolean read FDraad write Setdraad;
    property OnButtonChange : TButtonChangeEvent read FOnStatButtonChange write FOnStatButtonChange;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;// xxxx
    property OnExit: TNotifyEvent read FOnExit write FOnExit;// xxxx
    property onclick;
    property Info:String read FInfo write SetInfo; // xxxx
    property OnMouseDown;
    property OnMouseUp;
    property Hint;
    property ShowHint;
    property Enabled;
    property Naam :String read FNaam write SetNaam; //xxxx
    property Soort:String read FSoort write FSoort;// invoer,verwerking,uitvoer xxxx
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property Selected: Boolean read FSelected write FSelected;//xxxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property HelpKeyword;
  end;

  TjanSimKnop = class (TGraphicControl)
  private
    Select:Boolean;
    FPuls:Integer;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FDown: boolean;
    FStart: boolean;
    FDepressed:boolean;
    newLeft:integer;
    newTop:integer;
    FInfo:String;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;

    FStatKnop  : TStatKnop;//xxx
    FOnStatKnopChange  : TKnopChangeEvent;//xxx
    FTaal:string;
    FNaam:String;
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FSelected: Boolean;//xxxx
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    FOnStatus: TSimStatusEvent;// doorgeven van strings naan StatusBar1 panels
    procedure SendXYmoveToBar;
    procedure  SendStatusToBar;//xxx
    procedure UpdateHintText;
    procedure SetNaam(const Value: String);
    procedure SetTaal(const Value: String);
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(pt:TPoint;lit:boolean);
    procedure SetDown(const Value: boolean);
    procedure SetPuls(const Value:Integer);
    procedure SetLock(const Value: boolean);


    // new
     procedure ButtonClick1(sender:TObject);  // blokkeer object FLock
     procedure ButtonClick3(sender:TObject);  // info Ja/Nee
     procedure ButtonNClick(sender:TObject); //wijzig naam
     procedure ButtonClick4(sender:TObject); // selecteer object

     procedure SetInfo(const Value: String);
     procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
     procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
  protected
     procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
     procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
     procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
     procedure BuildPopup;
     procedure UpdatePopupCaptions;
     procedure Resize; override;
  public
     constructor Create (AOwner:TComponent); override;
     destructor  Destroy; override;
     procedure Paint; override;

     property StatKnop  : TStatKnop read FStatKnop;//xxx

  published
     property BTaal:String read FTaal write SetTaal;
     property Down:boolean read FDown write SetDown default false;
     property Puls:Integer read FPuls write SetPuls default 0;
     property Lock:boolean read FLock write SetLock;
     property Info:String read FInfo write SetInfo;
     property Hint;//xxx
     property OnMouseDown;//xxx
     property OnMouseUp;//xxx
     property ShowHint;
     property Naam :String read FNaam write SetNaam;
     property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
     property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
     property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
     property OnExit: TNotifyEvent read FOnExit write FOnExit;

     property Selected: Boolean read FSelected write FSelected;//xxxx
     property Box: TjanSimLogicBox read FBox write FBox;//xxx
     property HelpKeyword;
 end;

 TjanDipSwitsh = class (TGraphicControl)
  private
    Select:Boolean;
    FStatDip  : TStatDip;
    FOnStatDipChange: TDipChangeEvent;
    FGates: array[0..6] of TjanGate;
    FPuls8:Integer;
    FPuls4:Integer;
    FPuls2:Integer;
    FPuls1:Integer;
    FPuls:Integer;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    drukUp:TBitmap;
    drukDown:TBitmap;
    Connectoren:TBitmap;
    Ingang:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FStart:Boolean;
    FDown:Boolean;
    FConnector:Boolean;
    FDepressed:boolean;
    FDown8: boolean;

    FDepressed8:boolean;
    FDown4: boolean;

    FDepressed4:boolean;
    FDown2: boolean;

    FDepressed2:boolean;
    FDown1: boolean;

    FDepressed1:boolean;
    newLeft:integer;
    newTop:integer;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    // xxx
    FInfo:String;
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FSelected:Boolean;
    FMouseOver: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    procedure SendStatusToBar;//xxx

    procedure UpdateHintText;
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetInfo(const Value: String); //xxx

    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SetDown(const Value: boolean);
    procedure SetConnector(const Value: boolean);
    procedure SetStart(const Value: boolean);
    procedure SetDown8(const Value: boolean);
    procedure SetDown4(const Value: boolean);
    procedure SetDown2(const Value: boolean);
    procedure SetDown1(const Value: boolean);
    procedure SetLock(const Value: boolean);

    procedure Knop1Click(sender:TObject);
    procedure Knop1Click2(sender:TObject);
    //new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure Resize; override;


    procedure BuildPopup;//xxx
    procedure UpdatePopupCaptions;//xxx
  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property StatDip  : TStatDip read FStatDip;
  published
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property Down:boolean read FDown write SetDown default false;
    property Connector:boolean read FConnector write SetConnector default true;
    property Down8:boolean read FDown8 write SetDown8 default false;
    property Down4:boolean read FDown4 write SetDown4 default false;
    property Down2:boolean read FDown2 write SetDown2 default false;
    property Down1:boolean read FDown1 write SetDown1 default false;
    property Puls8:Integer read FPuls8 write FPuls8 default 0;
    property Puls4:Integer read FPuls4 write FPuls4 default 0;
    property Puls2:Integer read FPuls2 write FPuls2 default 0;
    property Puls1:Integer read FPuls1 write FPuls1 default 0;
    property Bits:Integer read FPuls write FPuls default 0;
    property Lock:boolean read FLock write SetLock;
    property OnDipChange : TDipChangeEvent read FOnStatDipChange write FOnStatDipChange;
    property Start:boolean read FStart write SetStart default false;
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property BTaal:String read FTaal write SetTaal; //xxx
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    property Naam :String read FNaam write SetNaam;// TOEGEVOEGD
    property ShowHint;
    property Selected:Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
     property HelpKeyword;
 end;


 TjanSimPuls = class (TGraphicControl)
  private
    Select:Boolean;//xxx
    FState  : TState;
    FPulsen:integer;
   // FSlider: TSlideSmall;
    FPulsinterval:integer;
    FPuls:Boolean;
    puls:TTimer;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FDown: boolean;
    FDepressed:boolean;
    newLeft:integer;
    newTop:integer;

    FSelected: Boolean;//xxxx
     FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStateChange: TStateChangeEvent;
    FInfo:String;
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels

    procedure  SendStatusToBar;//xxx
    procedure UpdateHintText;
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx

    procedure AnchorConnectors;
    procedure MoveConnectors;

    procedure PaintLed(pt:TPoint;lit:boolean);
    procedure SetPulsen(const value:Integer);
    procedure SetPuls(const Value: boolean);
    procedure SetPulsinterval(const Value: integer);
    procedure SetDown(const Value: boolean);
    procedure SetLock(const Value: boolean);

    // new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject);  // xxxx selecteer object voor verwijdering
    procedure SetInfo(const Value: String); //xxx

    procedure mTimer(sender: TObject);
    procedure Inter(sender:TObject);
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure BuildPopup;//xxx
    procedure UpdatePopupCaptions;//xxx
    procedure Resize; override;
  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property State  : TState read FState;

  published
    property BTaal:String read FTaal write SetTaal; //xxx
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnPulsChange : TStateChangeEvent read FOnStateChange write FOnStateChange;
    property PulsInterval:integer read FPulsinterval write SetPulsinterval;
    property Pulsen:boolean read FPuls write setpuls;
    property Pulser:Integer read FPulsen write SetPulsen default 0;
    property Starten:boolean read FDown write SetDown;
    property Lock:boolean read FLock write SetLock;
    property Naam :String read FNaam write SetNaam;//xxx
    //xxx
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    property Selected: Boolean read FSelected write FSelected;//xxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
     property HelpKeyword;
  end;


 TjanSimSensor = class (TGraphicControl)
  private
    Select:Boolean;
    FStatLicht  : TStatLicht;

    FPuls:Integer;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FDown: boolean;
    FDepressed:boolean;
    newLeft:integer;
    newTop:integer;
    FInfo:String;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;


    FOnStatLichtChange: TLichtChangeEvent;
    FNaam:String;
    FTaal:string;
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FSelected: Boolean;//xxxx
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object
    procedure SendXYmoveToBar;
    procedure SendStatusToBar;
    procedure UpdateHintText;
    procedure SetNaam(const Value: String);
    procedure SetTaal(const Value: String);
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(pt:TPoint;lit:boolean);
    procedure SetDown(const Value: boolean);
    procedure SetLock(const Value: boolean);

    // new
    procedure ButtonClick1(sender:TObject);  // blokkeer object FLock
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); // selecteer object

    procedure SetPuls(const Value:Integer);
    procedure SetInfo(const Value: String);
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure BuildPopup;
    procedure UpdatePopupCaptions;
    procedure Resize; override;

  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property StatLicht  : TStatLicht read FStatLicht;
  published
    property BTaal:String read FTaal write SetTaal;
    property Down:boolean read FDown write SetDown;
    property Lock:boolean read FLock write SetLock;
    property puls:Integer read FPuls write SetPuls default 0;
    property OnLichtChange : TLichtChangeEvent read FOnStatLichtChange write FOnStatLichtChange;
    property Info:String read FInfo write SetInfo;
    property ShowHint;
    property Naam :String read FNaam write SetNaam;
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;

    property Selected: Boolean read FSelected write FSelected;//xxxx
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property HelpKeyword;
 end;

 TjanSimWarm = class (TGraphicControl)
  private
    Select:Boolean;
    FStatTemp : TStatTemp;
    FOnStatTempChange: TTempChangeEvent;
    FPuls:Integer;
    FLock:Boolean;
    knopUp:TBitmap;
    knopDown:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FDown: boolean;
    FDepressed:boolean;
    newLeft:integer;
    newTop:integer;
    FInfo:String;

    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FNaam:String; // TOEGEVOEGD
    FTaal:string;
    FSoort:String;

    FSelected: Boolean;//xxxx
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    FMouseOver: Boolean; // TOEGEVOEGD
    FOnStatus: TSimStatusEvent; // TOEGEVOEGD
    procedure SendStatusToBar; // TOEGEVOEGD
    procedure UpdateHintText;
    procedure SetNaam(const Value: String);
    procedure SetTaal(const Value: String);
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(pt:TPoint;lit:boolean);
    procedure SetDown(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetPuls(const Value: Integer);

    // new events vervangen of toevoegen
    procedure ButtonClick1(sender:TObject);  // blokkeer object FLock
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject);  // xxxx selecteer object voor verwijdering

    procedure SetInfo(const Value: String);
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure Resize; override;
    procedure BuildPopup;// TOEGEVOEGD
    procedure UpdatePopupCaptions;// TOEGEVOEGD
  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    property StatTemp  : TStatTemp read FStatTemp;
  published
    property BTaal:String read FTaal write SetTaal;
    property Puls:Integer read FPuls write SetPuls default 0;
    property Down:boolean read FDown write SetDown;
    property Lock:boolean read FLock write SetLock;
    property OnTempChange : TTempChangeEvent read FOnStatTempChange write FOnStatTempChange;
    property Info:String read FInfo write SetInfo;
    property ShowHint;
    property Naam :String read FNaam write SetNaam;// TOEGEVOEGD
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;// TOEGEVOEGD
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;

     property Selected: Boolean read FSelected write FSelected;//xxxx
     property Box: TjanSimLogicBox read FBox write FBox;//xxx
      property HelpKeyword;
 end;


  TjanSimLight = class (TGraphicControl)
  private
    Select:Boolean;
    FLock:Boolean;
    lUit:TBitmap;
    lAan:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FLit: boolean;
    newleft:integer;
    newtop:integer;
    FInfo:String;

    FOnEnter: TNotifyEvent;//xxx
    FOnExit: TNotifyEvent;//xxx
    FDown: boolean;//xxx
    FDepressed:boolean;//xxx
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FSelected: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    procedure SendStatusToBar;//xxx
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetDown(const Value: boolean);//xxx
    procedure UpdateHintText; //xxxx

    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SetLit(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    // old
   { procedure LampClick(sender:TObject);
    procedure LampClick1(sender:TObject);
    procedure LampClick2(sender:TObject);
    procedure LampClick3(sender:TObject);}
    //new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxx
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;//xxx

    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx


    procedure Resize; override;
  public
    constructor Create (AOwner:TComponent); override; //xxx
    destructor  Destroy; override;
    procedure Paint; override;  //xxx
  published
    property Lit:boolean read FLit write SetLit;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property ShowHint;

    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property Down:boolean read FDown write SetDown default false;
    property BTaal:String read FTaal write SetTaal; //xxx
    property Naam :String read FNaam write SetNaam;//xxx
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx
     property HelpKeyword;
  end;

  TjanSimRelais = class (TGraphicControl)
  private
    Select:Boolean;

    FLock:Boolean;
    lUit:TBitmap;
    lAan:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FLit: boolean;
    FOnMouseLeave: TNotifyEvent;
    FOnMouseEnter: TNotifyEvent;
    newleft:integer;
    newtop:integer;
    FInfo:String;
    // new
    FOnEnter: TNotifyEvent;//xxx
    FOnExit: TNotifyEvent;//xxx
    FDown: boolean;//xxx
    FDepressed:boolean;//xxx
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FSelected: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    procedure SendStatusToBar;//xxx
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetDown(const Value: boolean);//xxx
    procedure UpdateHintText; //xxxx
    // end new

    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SetLit(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);
    // new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer
    // end new
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;

    procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx

    procedure Resize; override;
   // procedure DblClick; override;
  public
    constructor Create (AOwner:TComponent); override;//xxxx
    destructor  Destroy; override;
    procedure Paint; override;//xxxx
  published
    property Lit:boolean read FLit write SetLit;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property ShowHint;

    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property Down:boolean read FDown write SetDown default false;
    property BTaal:String read FTaal write SetTaal; //xxx
    property Naam :String read FNaam write SetNaam;//xxx
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx
     property HelpKeyword;
  end;


  TjanSimBuzzer = class (TGraphicControl)
  private
    Select:Boolean;
    FInfo:String;
    FLock:Boolean;
    lUit:TBitmap;lAan:TBitmap;
    doMove:boolean;
    mdp:TPoint;
    oldp:TPoint;
    Connectors:TList;
    FLit: boolean;
    FOnMouseLeave: TNotifyEvent;
    FOnMouseEnter: TNotifyEvent;
    newleft:integer;
    newtop:integer;

    FOnEnter: TNotifyEvent;//xxx
    FOnExit: TNotifyEvent;//xxx
    FDown: boolean;//xxx
    FDepressed:boolean;//xxx
    FTaal:string;//xxx
    FNaam:String;//xxx
    FSoort:String; //xxx
    FMouseOver: Boolean; //xxx
    FSelected: Boolean; //xxx
    FOnStatus: TSimStatusEvent;// xxx doorgeven van strings naan StatusBar1 panels
    FBox: TjanSimLogicBox;//xxxx  nodig voor selectie van object

    procedure SendStatusToBar;//xxx
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetDown(const Value: boolean);//xxx
    procedure UpdateHintText; //xxxx

    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SetLit(const Value: boolean);
    procedure SetLock(const Value: boolean);
    procedure SetInfo(const Value: String);

    // new
    procedure ButtonClick1(sender:TObject);  // Ontgrendel Vergrendel
    procedure ButtonClick3(sender:TObject);  // info Ja/Nee
    procedure ButtonNClick(sender:TObject); //wijzig naam
    procedure ButtonClick4(sender:TObject); //selecteer
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE; //xxx
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    procedure Resize; override;
     procedure BuildPopup;//xxxx
    procedure UpdatePopupCaptions;//xxxx
  public
    constructor Create (AOwner:TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
  published
    property Lit:boolean read FLit write SetLit;
    property Lock:boolean read FLock write SetLock;
    property Info:String read FInfo write SetInfo;
    property ShowHint;
    // new
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property Box: TjanSimLogicBox read FBox write FBox;//xxx
    property Soort:String read FSoort write FSoort;//xxx invoer,verwerking,uitvoer
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;//xxx
    Property Selected:Boolean read FSelected write FSelected;//xxxx

    property Down:boolean read FDown write SetDown default false;
    property BTaal:String read FTaal write SetTaal; //xxx
    property Naam :String read FNaam write SetNaam;//xxx
     property HelpKeyword;
  end;

   // Event voor objectverplaatsing
  TObjectMoveEvent = procedure(Sender: TObject; Obj: TControl; X, Y: Integer) of object;

 TjanSimLogicBox = class(TGraphicControl)
  private
    // voor type TObjectStatusEvent = procedure(Sender: TObject; const AText: string; APanel: Integer) of object;
    FOnStatusText: TObjectStatusEvent;
    FOnStatusEx: TSimStatusEventEx;
    FLastHintText: string;//new
    FLastStatusSender: TObject;
    FSelectedSender: TObject;    // welk object Tjan... is er geselecteerd na click
    FOnSelected: TSimSelectEvent;// event voor bij selectie van Tjan... te gebruiken
    FOpen:Boolean;
    Taal:string;
    Fx:Integer;
    Fy:Integer;
    TempFile:TStringlist;
    templijst:TStringlist;
    FFilterLijst: TStringList;
    FFirst:Boolean;
    FImputColor:TColor;
    FOutputColor:TColor;
    FVerwerkingColor:TColor;
    FNew:Boolean;
    FImputAantal:Integer;
    FVerwerkingAantal:Integer;
    FOutPutAantal:Integer;
    FMaak:Boolean;
    FParent:TWinControl;
    FObjectID:Integer;
    FStart:Boolean;
    FDrukknop:Boolean;
    FSchakelaar:Boolean;
    FPuls:Boolean;
    FLamp:Boolean;
    FLogicAnd:Boolean;
    FLogicOr:Boolean;
    FLogicNot:Boolean;
    FDraad:Boolean;
    FRelais:Boolean;
    FGrid:Boolean;
    FBuzzer:Boolean;
    FTeller:Boolean;
    FMemory:Boolean;
    FDipSwitsh:Boolean;
    FKnopLeft:Integer;
    FSpatie:Integer;
    FSensor:Boolean;
    FWarm:Boolean;
    FDisplay:Boolean;
    cpu:TTimer;
    Fdraden:Boolean;
    FMeter:Boolean;
    FKader: Boolean;

    // rect + down-state
    RSquare: TRect;
    DSquare: Boolean;




    // optioneel bitmap (als je een icoon wil)
 //   bmSquare: TBitmap;
    //hint
    FHSquare: string;

    bmCon:Tbitmap;
    RCon:TRect;
    DCon:boolean;

    {bmCon2:Tbitmap;
    RCon2:TRect;
    DCon2:Boolean;}

    bmLogicAnd:Tbitmap;
    RLogicAnd:TRect;
    DLogicAnd:Boolean;

    bmLogicOr:Tbitmap;
    RLogicOr:TRect;
    DLogicOr:Boolean;

    bmLogicNot:Tbitmap;
    RLogicNot:TRect;
    DLogicNot:Boolean;

    bmGrid:TBitmap;
    RGrid:TRect;
    DGrid:boolean;


    bmButton:Tbitmap;
    RButton:TRect;
    DButton:boolean;

    bmKnop:TBitmap;
    RKnop:TRect;
    Dknop:boolean;

    bmPuls:TBitmap;
    RPuls:TRect;
    DPuls:boolean;

    bmLight:Tbitmap;
    RLight:TRect;
    DLight:boolean;

    bmRelais:Tbitmap;
    RRelais:TRect;
    DRelais:boolean;

    bmBuzzer:Tbitmap;
    RBuzzer:TRect;
    DBuzzer:boolean;

    bmSensor:Tbitmap;
    RSensor:TRect;
    DSensor:boolean;

    bmWarm:Tbitmap;
    RWarm:TRect;
    DWarm:boolean;


    bmTeller:TBitmap;
    RTeller:TRect;
    DTeller:boolean;

    bmDipSwitsh:TBitmap;
    RDipSwitsh:TRect;
    DDipSwitsh:boolean;


    bmMemory:TBitmap;
    RMemory:TRect;
    DMemory:boolean;

    bmDisplay:TBitmap;
    RDisplay:TRect;
    DDisplay:boolean;

    bmMeter:TBitmap; //icon voor V-Meter
    RMeter:TRect;
    DMeter:boolean;

    FOnEnter: TNotifyEvent;
    FOnLeave: TNotifyEvent;

    FHoverRect: TRect;
    FHoverText: string;
    // variablen voor info van de verschillende buttons
    FHKader:String;
    FHDrukknop:String;
    FHSchakelaar:String;
    FHPuls:String;
    FHLamp:String;
    FHLogicAnd:String;
    FHLogicOr:String;
    FHLogicNot:String;
    FHDraad:String;
    FHRelais:String;
    FHBuzzer:String;
    FHSensor:String;
    FHWarm:String;
    FHLock:String;
    FHTeller:String;
    FHMemory:String;
    FHDipSwitsh:String;
    FHDisplay:String;
    FBColor:TColor;
    FKnopTop:Integer;
    FHGrid:String;
    FHMeter:String;
    FBoxTaal:TStatTaal;
    FOnObjectMove: TObjectMoveEvent;

    procedure SetOpen(const Value: Boolean);
    Procedure SetLijst(Value: TStringList);
    PROCEDURE SetBColor(const Value: TColor);
 //   PROCEDURE SetHKader(const Value: String);
    PROCEDURE SetHDrukknop(const Value: String);
    PROCEDURE SetHSchakelaar(const Value: String);
    PROCEDURE SetHPuls(const Value: String);
    PROCEDURE SetHLamp(const Value: String);
    PROCEDURE SetHLogicAnd(const Value: String);
    PROCEDURE SetHLogicOr(const Value: String);
    PROCEDURE SetHLogicNot(const Value: String);
    PROCEDURE SetHDraad(const Value: String);
    PROCEDURE SetHRelais(const Value: String);
    PROCEDURE SetHBuzzer(const Value: String);
    PROCEDURE SetHSensor(const Value: String);
    PROCEDURE SetHWarm(const Value: String);
    PROCEDURE SetHTeller(const Value: String);
    PROCEDURE SetHMemory(const Value: String);
    PROCEDURE SetHDipSwitsh(const Value: String);
    PROCEDURE SetHLock(const Value: String);
    PROCEDURE SetHDisplay(const Value: String);
    PROCEDURE SetHGrid(const Value: String);
    PROCEDURE SetHMeter(const Value: String);
    PROCEDURE SetStart(const Value: Boolean);
    PROCEDURE SetDrukknop(const Value: Boolean);
    PROCEDURE SetSchakelaar(const Value: Boolean);
    PROCEDURE SetPuls(const Value: Boolean);
    PROCEDURE SetLamp(const Value: Boolean);
    PROCEDURE SetLogicAnd(const Value: Boolean);
    PROCEDURE SetLogicOr(const Value: Boolean);
    PROCEDURE SetLogicNot(const Value: Boolean);
    PROCEDURE SetDraad(const Value: Boolean);
    PROCEDURE SetRelais(const Value: Boolean);
    PROCEDURE SetNewObject(const Value: Boolean);
    PROCEDURE SetTeller(const Value: Boolean);
    PROCEDURE SetMemory(const Value: Boolean);
    PROCEDURE SetDipSwitsh(const Value: Boolean);
    PROCEDURE SetBuzzer(const Value: Boolean);
    PROCEDURE SetSensor(const Value: Boolean);
    PROCEDURE SetWarm(const Value: Boolean);
    PROCEDURE SetDisplay(const Value: Boolean);
    PROCEDURE SetMeter(const Value: Boolean);
    PROCEDURE SetKnopLeft(const Value: Integer);
    PROCEDURE SetKnopTop(const Value: Integer);
    PROCEDURE SetKnopSpatie(const Value: Integer);
    PROCEDURE SetImputColor(const Value:TColor);
    PROCEDURE SetOutputColor(const Value:TColor);
    PROCEDURE SetVerwerkingColor(const Value:TColor);
    PROCEDURE cpuOnTimer(sender:TObject);
    PROCEDURE SetParent(const Value:TWincontrol);
    PROCEDURE SetObjectID(const Value:Integer);
    PROCEDURE SetImputAantal(const Value:Integer);
    PROCEDURE SetOutputAantal(const Value:Integer);
    PROCEDURE SetVerwerkingAantal(const Value:Integer);
    PROCEDURE SetGrid(const Value: Boolean);
    PROCEDURE Setdraden(const Value: Boolean);
    PROCEDURE SetFx(const Value:Integer);
    PROCEDURE SetFy(const Value:Integer);
  protected
    PROCEDURE CMMouseEnter(var Msg:TMessage); message CM_MOUSEENTER;
    PROCEDURE CMMouseLeave(var Msg:TMessage); message CM_MOUSELEAVE;
    PROCEDURE MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    PROCEDURE MouseMove(Shift: TShiftState; X, Y: Integer);override;
    PROCEDURE MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);override;
    PROCEDURE resize; override;
    PROCEDURE Loaded; override;
    PROCEDURE WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    // Laatste aanpassen
    procedure ChildMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
    procedure ApplyLanguageToSimObj(AComponent: TComponent);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ChildMouseEnter(Sender: TObject);
    procedure ChildMouseExit(Sender: TObject);
  public
    constructor create(AOwner:Tcomponent); override;
    destructor  Destroy; override;
    procedure DoObjectMove(Obj: TControl; X, Y: Integer);
    procedure StatusFromChild(Sender: TObject; const AText: string; APanel: Integer);
    PROCEDURE Paint; override;
    PROCEDURE PaintBoxLeft;
    PROCEDURE PaintBoxTop;
    PROCEDURE PaintBoxBottom;
    // kontrole of er connectors zijn gemaakt
    PROCEDURE MoveObjekten(hoeveel:Integer);
    PROCEDURE kontrolconnectors;
    PROCEDURE maakpanel;
    PROCEDURE Zettaal;
    PROCEDURE BlokkeerObjecten(blokkeer:Boolean);
    PROCEDURE Killpanel;
    PROCEDURE KillConnectors;
    PROCEDURE SavePanelTemp(Paneel:TjanGridS);

    procedure ClearSelectedSender;

    procedure InternalLoadFromList(AList: TStrings; Paneel: TjanGridS);
    PROCEDURE SavePanel(waar:String; paneel:TjanGridS; codec:Boolean);

    // ophalen van paneel uit tempFile
    PROCEDURE LoadPanelTemp(Paneel:TjanGridS);
    // ophalen van opgeslagen Paneel uit bestand
    PROCEDURE LoadPanel(welke:String;Paneel:TjanGridS;codec:Boolean);
    // ophalen van paneelopbouw uit exe
    PROCEDURE LoadStream(welke:TStream;inf:Boolean);
    procedure LoadStreamNew(welke: TStream; Paneel: TjanGridS; Inf: Boolean);
    // imput van de objectomschrijving voor het opslaan van de panelen
    PROCEDURE SetDefaultFilt;
    PROCEDURE AddFilter (s: STRING);
    FUNCTION  InFilterL (aCompClassName, aPropName: STRING): BOOLEAN;
    FUNCTION  GetPropAsStringe (obj: TObject; info: PPropInfo): STRING;
  //  PROCEDURE SetPropFromStringe (obj: TObject; info: PPropInfo; CONST str: STRING);
      procedure SetPropFromStringe(obj: TObject; info: PPropInfo; const str: string);


    PROCEDURE encode(tekst:TStringList);
    PROCEDURE decode(tekst:TStringList);
    PROCEDURE SetBoxTaal(const Value: TStatTaal);

    procedure DoStatusText(const AText: string; APanel: Integer = 0);
    procedure PushStatus(ASource: TObject;const AText: string; APanel: Integer);
    procedure RefreshStatusBarLanguage;
    procedure ApplyLanguageToGridChildren(const NewBTaal: TStatTaal; AGrid: TWinControl);
    // nodig om het oject te selecteren via popup-menu-item miSelect
    procedure SelectObject(AObj: TObject);
  public
   property LastStatusSender: TObject read FLastStatusSender;
   property SelectedSender: TObject read FSelectedSender;


  published
    property OnObjectMove: TObjectMoveEvent read FOnObjectMove write FOnObjectMove;

    property Language:TStatTaal read FBoxTaal write SetBoxTaal;
    property X:Integer read Fx write SetFx;
    property Y:Integer read Fy write SetFy;


     // Property nodig om geselecteerd object Tjan... te gebruiken
    property OnSelected: TSimSelectEvent read FOnSelected write FOnSelected;

    property KDrukknop:Boolean read FDrukknop write SetDrukknop;
    property KSchakelaar:Boolean read FSchakelaar write SetSchakelaar;
    property KPuls:Boolean read FPuls write SetPuls;
    property KLamp:Boolean read FLamp write SetLamp;
    property KLogicAnd:Boolean read FLogicAnd write SetLogicAnd;
    property KLogicOr:Boolean read FLogicOr write SetLogicOr;
    property KLogicNot:Boolean read FLogicNot write SetLogicNot;
    property KDraad:Boolean read FDraad write SetDraad;
    property KRelais:Boolean read Frelais write Setrelais;
    property KGrid:Boolean read FGrid write SetGrid;
    property KBuzzer:Boolean read FBuzzer write SetBuzzer;
    property KSensor:Boolean read FSensor write SetSensor;
    property KWarm:Boolean read FWarm write SetWarm;
    property KTeller:Boolean read FTeller write SetTeller;
    property KMemory:Boolean read FMemory write SetMemory;
    property KDipSwitsh:Boolean read FDipSwitsh write SetDipSwitsh;
    property KDisplay:Boolean read FDisplay write SetDisplay;
    property KMeter:Boolean read FMeter write SetMeter;
    property PStandaard:Boolean read FStart write SetStart;
    property NewObject:Boolean read FNew write SetNewObject;
    property HDrukknop:String read FHDrukknop write SetHDrukknop;

    property HSchakelaar:String read FHSchakelaar write SetHSchakelaar;
    property HGrid:String read FHGrid write SetHgrid;
    property HMeter:String read FHMeter write SetHMeter;
    property HPuls:String read FHPuls write SetHPuls;
    property HLamp:String read FHLamp write SetHLamp;
    property HLogicAnd:String read FHLogicAnd write SetHLogicAnd;
    property HLogicOr:String read FHLogicOr write SetHLogicOr;
    property HLogicNot:String read FHLogicNot write SetHLogicNot;
    property HDraad:String read FHDraad write SetHDraad;
    property HRelais:String read FHrelais write SetHrelais;
    property HBuzzer:String read FHBuzzer write SetHBuzzer;
    property HWarm:String read FHWarm write SetHWarm;
    property HSensor:String read FHSensor write SetHSensor;
    property HLock:String read FHLock write SetHlock;
    property HTeller:String read FHTeller write SetHTeller;
    property HMemory:String read FHMemory write SetHMemory;
    property HDipSwitsh:string read FHDipSwitsh write SetHDipSwitsh;
    property HDisplay:String read FHDisplay write SetHDisplay;
    property BColor:TColor read FBColor write SetBColor;
    property KnopLeft:Integer read FKnopLeft write SetKnopLeft;
    property KnopTop:Integer read FKnopTop write SetKnopTop;
    property KnopSpatie:Integer read FSpatie write SetKnopSpatie;
    property Eigenaar:TWinControl read FParent write SetParent;
    property ObjectID:Integer read FObjectID write SetObjectID;
    property A_Imput:Integer read FImputAantal write SetImputAantal;
    property A_Output:Integer read FOutputAantal write SetOutputAantal;
    property A_Verwerking:Integer read FVerwerkingAantal write SetVerwerkingAantal;
    property B_Imput:TColor read FImputColor write SetImputColor;
    property B_Output:TColor read FOutputColor write SetOutputColor;
    property B_Verwerking:TColor read FVerwerkingColor write SetVerwerkingColor;
    property Open:Boolean read FOpen write SetOpen;
    property Draden:Boolean Read FDraden write Setdraden;
    property Lijst:TstringList read templijst write SetLijst;
    property Align;
    property visible;
    property ShowHint;
    property Hint;
    property Enabled;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnLeave: TNotifyEvent read FOnLeave write FOnLeave;
    property OnStatusText: TObjectStatusEvent read FOnStatusText write FOnStatusText;
    property OnStatusEx: TSimStatusEventEx read FOnStatusEx write FOnStatusEx;
     property HelpKeyword;
   // property LastStatusSender: TObject read FLastStatusSender;
end;

  { TjanGroupSelect: meerdere objecten tegelijk selecteren en verplaatsen.
    Wordt als onzichtbaar besturingselement op het paneel gezet. Tijdens het
    slepen van een selectierechthoek toont het die rechthoek; daarna ligt het
    als kader over de geselecteerde objecten en vangt het de muis op om de
    hele groep (met de draden) te verplaatsen. }
  TjanGroupSelect = class(TGraphicControl)
  private
    FItems: TList;               // geselecteerde objecten (TControl)
    FBanding: Boolean;           // selectierechthoek wordt getekend
    FBandStart: TPoint;
    FDragging: Boolean;
    FDragStart: TPoint;          // muis bij begin slepen (paneel-coördinaten)
    FFrameStart: TPoint;
    FItemStart: array of TPoint;
    FCons: array of TjanConnector;
    FConMove: array of Integer;  // 1 = hele draad mee, 2 = één uiteinde mee
    FConStart: array of TPoint;
    FBTaal: string;
    function IsGroupable(C: TControl): Boolean;
    procedure UpdateFrame;
    procedure PrepareDrag;
    procedure ApplyDelta(DX, DY: Integer);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginBand(X, Y: Integer);
    procedure MoveBand(X, Y: Integer);
    procedure EndBand(X, Y: Integer);
    procedure SelectRect(R: TRect);
    procedure SelectAll;
    procedure Clear;
    function Count: Integer;
    property Banding: Boolean read FBanding;
    property BTaal: string read FBTaal write FBTaal;
  end;

procedure Register;

implementation

  {$R janSimImages.res}
  {$R Cursors.RES}

  var
    GlobalSimBox: TjanSimLogicBox;

CONST
 crDrukknop          = 1;
 crSchakelaar        = 2;
 crSensor            = 3;
 crWarm              = 4;
 crPuls              = 5;
 crDip               = 6;
 crAnd               = 7;
 crOr                = 8;
 crNot               = 9;
 crTeller            = 10;
 crGeheugen          = 11;
 crLamp              = 12;
 crRelais            = 13;
 crZoemer            = 14;
 crDisplay           = 15;
 crDraad             = 16;
 crMeter             = 17;

 function BuildSimHint(const ANaam, ABTaal: string): string;
 var
   s: string;
 begin
   if ABTaal = 'NL' then
     s := 'Rechter muisknop voor extra instellingen'
   else if ABTaal = 'ENG' then
     s := 'Right mouse button for extra settings'
   else if ABTaal = 'FR' then
     s := 'Bouton droit pour paramètres supplémentaires'
   else if ABTaal = 'DU' then
     s := 'Rechte Maustaste für zusätzliche Einstellungen'
   else
     s := 'Right mouse button for extra settings';
   Result := ANaam + #13#10 + s;
 end;



 function StatTaalToBTaal(T: TStatTaal): string;
 begin
   case T of
     stDutch:  Result := 'NL';
     stEnglish: Result := 'ENG';
     stFrench:  Result := 'FR';
     stGerman:  Result := 'DU';
   else
     Result := 'ENG';
   end;
 end;

function Tr(const BTaal, NL, ENG, FR, DU: string): string;
begin
  if BTaal = 'NL' then Result := NL
  else if BTaal = 'ENG' then Result := ENG
  else if BTaal = 'FR' then Result := FR
  else if BTaal = 'DU' then Result := DU
  else Result := ENG;
end;


constructor TInputBoxForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Width := 300;
  Height := 130;

  Caption := 'Input';

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Left := 8;
  FLabel.Top := 8;

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Left := 8;
  FEdit.Top := 28;
  FEdit.Width := ClientWidth - 16;

  FOkButton := TButton.Create(Self);
  FOkButton.Parent := Self;
  FOkButton.Caption := 'OK';
  FOkButton.ModalResult := mrOk;
  FOkButton.Left := ClientWidth - 170;
  FOkButton.Top := 65;
  FOkButton.Width := 75;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.Left := ClientWidth - 85;
  FCancelButton.Top := 65;
  FCancelButton.Width := 75;

  ActiveControl := FEdit;
end;


function TInputBoxForm.Execute(
  const ACaption, APrompt, ADefault: string;
  out AResult: string): Boolean;
begin
  Caption := ACaption;
  FLabel.Caption := APrompt;
  FEdit.Text := ADefault;

  Result := ShowModal = mrOk;
  if Result then
    AResult := FEdit.Text;
end;




procedure Register;
begin
  RegisterComponents('JWLOGIC', [TjanMeter,TjanDisplay,TjanConnector,TjanLogic,TjanTeller,TjanSimButton,TjanSimKnop,
                                 TjanSimPuls,TjanSimLight, TjanSimRelais,TjanSimBuzzer,TjanSimSensor,TjanSimWarm,
                                 TjanSimLogicBox,TjanMemory,TjanDipSwitsh]);
end;

procedure movecursor;
var
pt:TPoint;
begin
if (screen.cursor=crDraad) then
   begin
    Application.ProcessMessages;
    GetCursorPos(pt);
    SetCursorPos(pt.x + 35 - 10, pt.y+15);
    //screen.cursor:=crDefault;
   end;
end;

procedure Maakdraad(T,L:integer;wc:TWincontrol);
begin
with TjanConnector.create(wc) do   //wc
 begin
 parent:=wc;
 left:=L;top:=T;height:=25;width:=35;visible:=true;
 tag:= wc.ControlCount;
end;
end;

procedure Maakconnector(T,L,R,B:integer;wc:TWincontrol);
begin
with TjanConnector.create(wc) do
 begin
 parent:=wc;
 left:=L;top:=T;
 height:=B;width:=R;
 visible:=true;
 tag:= wc.ControlCount;
 BringToFront;
 end;
end;



{ TjanDisplay }
const
  SegState: array[0..127] of word =   { all ASCII chars, display '-' if unknown }
              ($0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $007d, $0050, $0037, $0057, $005a, $004f, $006f, $0051,   { 0 1 2 3 4 5 6 7 }
               $007f, $005f, $0002, $0002, $0002, $0002, $0002, $0002,   { 8 9             }
               $0002, $007b, $006e, $002d, $0076, $002f, $002b, $0002,   { A B C D E F G   }
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $007b, $006e, $002d, $0076, $002f, $002b, $0002,   { a b c d e f g   }
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002);


constructor TjanDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Select:=false;
  Width := 74;
  Height := 90;
  FOnColor := clBlue;
  FOffColor :=clCream;
  //willem
  FBackColor := clSilver;
  FPenOnColor := clAqua;
  FPenOffColor:= clgray;
  FSegWidth := 3;
  FMargin := 25;
  FDigit:='0';
  FBits:=0;
  OldWidth := Width;
  OldHeight := Height;
  SetMeasures;

  connectors:=TList.create;

  FInfo:= 'Display';
  FDown:=false; //xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Display';//xxx
  ShowHint:=true;
end;

destructor TjanDisplay.Destroy;
begin
  inherited;
  connectors.free;
end;

procedure TjanDisplay.SendStatusToBar;
var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Uitvoer','Export','Exporter','Export');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanDisplay.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanDisplay.SetTaal(const Value: String);
begin
if value<>FTaal then
 begin
   FTaal:= Value;
end;
// ✅ Onmiddellijke refresh als muis erboven staat
   if FMouseOver then
     SendStatusToBar;
   UpdateHintText;
   invalidate;
end;

procedure TjanDisplay.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanDisplay.BuildPopup;
 var
   miLock, miName, miInfo, miSelect: TMenuItem;
 begin
   if not Assigned(PopupMenu) then
     PopupMenu := TPopupMenu.Create(Self)
   else
     PopupMenu.Items.Clear;

   // --- Lock / Unlock
   miLock := TMenuItem.Create(PopupMenu);
   miLock.Name := 'miLock';
   miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
   PopupMenu.Items.Add(miLock);

   // --- Naam wijzigen
   miName := TMenuItem.Create(PopupMenu);
   miName.Name := 'miName';
   miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
   PopupMenu.Items.Add(miName);

   // --- Info aan/uit
   miInfo := TMenuItem.Create(PopupMenu);
   miInfo.Name := 'miInfo';
   miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
   PopupMenu.Items.Add(miInfo);

   // --- Selecteer voor verwijdering
   miSelect := TMenuItem.Create(PopupMenu);
   miSelect.Name := 'miSelect';
   miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
   PopupMenu.Items.Add(miSelect);
 end;

 procedure TjanDisplay.UpdatePopupCaptions;
        var
          miLock, miName, miInfo, miSelect: TMenuItem;
          s: string;
        begin
          if not Assigned(PopupMenu) then Exit;

          miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
          miName   := TMenuItem(PopupMenu.FindComponent('miName'));
          miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
          miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

          // --- Lock / Unlock
          if Assigned(miLock) then
          begin
            if BTaal = 'NL' then
            begin
              if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
            end
            else if BTaal = 'FR' then
            begin
              if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
            end
            else if BTaal = 'DU' then
            begin
              if FLock then s := 'Entsperren' else s := 'Sperren';
            end
            else
            begin
              if FLock then s := 'Unlock' else s := 'lock';
            end;
            miLock.Caption := s;
          end;

          // --- Naam wijzigen
          if Assigned(miName) then
          begin
            if BTaal = 'NL' then s := 'Wijzig Naam'
            else if BTaal = 'FR' then s := 'Changer le nom'
            else if BTaal = 'DU' then s := 'Namen ändern'
            else s := 'Change name';
            miName.Caption := s;
          end;

          // --- Select / Deselect (TOGGLE)
          if Assigned(miSelect) then
          begin
            if not Selected then
            begin
              if BTaal = 'NL' then s := 'Selecteer object'
              else if BTaal = 'FR' then s := 'Sélectionner un objet'
              else if BTaal = 'DU' then s := 'Objekt auswählen'
              else s := 'Select object';
            end
            else
            begin
              if BTaal = 'NL' then s := 'Deselecteer object'
              else if BTaal = 'FR' then s := 'Désélectionner l''objet'
              else if BTaal = 'DU' then s := 'Objekt abwählen'
              else s := 'Deselect object';
            end;
            miSelect.Caption := s;
          end;

          // --- Info aan/uit
          if Assigned(miInfo) then
          begin
            if ShowHint then
            begin
              if BTaal = 'NL' then s := 'Info uit'
              else if BTaal = 'FR' then s := 'Infos off'
              else if BTaal = 'DU' then s := 'Infos aus'
              else s := 'Information off';
            end
            else
            begin
              if BTaal = 'NL' then s := 'Info aan'
              else if BTaal = 'FR' then s := 'Infos on'
              else if BTaal = 'DU' then s := 'Infos an'
              else s := 'Information on';
            end;
            miInfo.Caption := s;
          end;
        end;

procedure TjanDisplay.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;


procedure TjanDisplay.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

procedure TjanDisplay.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanDisplay.Click1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDisplay.Click2(sender:TObject);
Begin
free;
end;

procedure TjanDisplay.Click3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDisplay.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDisplay.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDisplay.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanDisplay.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;


procedure TjanDisplay.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanDisplay.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanDisplay.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanDisplay.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
 UpdateHintText;
if Assigned(FOnEnter) then
   FOnEnter(Self);


// ✅ statusbar meteen vullen
 FMouseOver := True;
 SendStatusToBar;  // vult panel 0/1/2


 BringToFront;
 if not FLock then
 begin
   Select := True;
   Invalidate;
 end;
end;

procedure TjanDisplay.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;


procedure TjanDisplay.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
p : TPoint;
S:String;
begin
  inherited;
   if (Button = mbRight) and (FLock = False) then
   begin
     BuildPopup;
     UpdatePopupCaptions;
     p := Point(0, Height);
     p := ClientToScreen(p);
     PopupMenu.Popup(p.X, p.Y - 1);
     Exit;
   end;
  mdp:=point(x,y);
  doMove:= true;
  oldp:=point(x,y);
  AnchorConnectors;
    // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanDisplay.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock=true then exit;
   if FDepressed then exit;
   if Parent = nil then Exit;

   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);


   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;
     Left:=newleft;
     Top:=newtop;

     MoveConnectors;

     if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
  SendStatusToBar;
     end
   end;

end;

procedure TjanDisplay.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var R:TRect;
      p:Tpoint;
  begin
   inherited;
    if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;
    movecursor;
    FDepressed:=false;
    p:=point(x,y);
    R:=Rect(13,66,37,75);

    if ptinrect(R,p) then Down:=not FDown;

    FMouseOver := True;
    SendStatusToBar;
  end;

procedure TjanDisplay.SetBits(const Value:Integer);

begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then FDigit:='0';
     If FBits=1 then FDigit:='1';
     If FBits=2 then FDigit:='2';
     If FBits=3 then FDigit:='3';
     If FBits=4 then FDigit:='4';
     If FBits=5 then FDigit:='5';
     If FBits=6 then FDigit:='6';
     If FBits=7 then FDigit:='7';
     If FBits=8 then FDigit:='8';
     If FBits=9 then FDigit:='9';
     If FBits=10 then FDigit:='A';
     If FBits=11 then FDigit:='B';
     If FBits=12 then FDigit:='C';
     If FBits=13 then FDigit:='D';
     If FBits=14 then FDigit:='E';
     If FBits=15 then FDigit:='F';
  invalidate;
  end;
end;



procedure TjanDisplay.SetDigit(WhatDigit: char);
begin
  if WhatDigit <> FDigit then
  begin
    FDigit := WhatDigit;
    if FDigit='0' then FBits:=0;
    if FDigit='1' then FBits:=1;
    if FDigit='2' then FBits:=2;
    if FDigit='3' then FBits:=3;
    if FDigit='4' then FBits:=4;
    if FDigit='5' then FBits:=5;
    if FDigit='6' then FBits:=6;
    if FDigit='7' then FBits:=7;
    if FDigit='8' then FBits:=8;
    if FDigit='9' then FBits:=9;
    if FDigit='A' then FBits:=10;
    if FDigit='B' then FBits:=11;
    if FDigit='C' then FBits:=12;
    if FDigit='D' then FBits:=13;
    if FDigit='E' then FBits:=14;
    if FDigit='F' then FBits:=15;
  invalidate;
  end;
end;

procedure TjanDisplay.SetOnColor(WhatColor: TColor);
begin
  if WhatColor <> FOnColor then
  begin
    FOnColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetPenOnColor(WhatColor: TColor);
begin
  if WhatColor <> FPenOnColor then
  begin
    FPenOnColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetOffColor(WhatColor: TColor);
begin
  if WhatColor <> FOffColor then
  begin
    FOffColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetPenOffColor(WhatColor: TColor);
begin
  if WhatColor <> FPenOffColor then
  begin
    FPenOffColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetBackColor(WhatColor: TColor);
begin
  if WhatColor <> FBackColor then
  begin
    FBackColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetSegWidth(WhatWidth: integer);
begin
  if WhatWidth <> FSegWidth then
  begin
    FSegWidth := WhatWidth;
    SetMeasures;
    Refresh;
  end;
end;

procedure TjanDisplay.SetMargin(WhatWidth: integer);
begin
  if WhatWidth <> FMargin then
  begin
    FMargin := WhatWidth;
    SetMeasures;
    Refresh;
  end;
end;



procedure TjanDisplay.Hexagon(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  if h > w then { vertical, w is SegWidth }
    WhereTo.Canvas.Polygon([Point(x, y + SegHalf), Point(x + SegHalf, y),
                            Point(x + w, y + SegHalf), Point(x + w, y + h - SegHalf),
                            Point(x + SegHalf, y + h), Point(x, y + h - SegHalf)])
  else          { horizontal, h is SegWidth }
    WhereTo.Canvas.Polygon([Point(x, y + SegHalf), Point(x + SegHalf, y),
                            Point(x + w - SegHalf, y), Point(x + w, y + SegHalf),
                            Point(x + w - SegHalf, y + h), Point(x + SegHalf, y + h)]);
end;

procedure TjanDisplay.DrawDot(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Rectangle(x, y, x + FSegWidth, y + FSegWidth);
end;

procedure TjanDisplay.DrawBulb(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Ellipse(x, y, x + FSegWidth, y + FSegWidth);
end;

procedure TjanDisplay.DrawTopSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y), Point(x + FSegWidth, y + h),
                          Point(x + w - FSegWidth, y + h), Point(x + w, y)]);
end;

procedure TjanDisplay.DrawBottomSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y + h), Point(x + FSegWidth, y),
                          Point(x + w - FSegWidth, y), Point(x + w, y + h)]);
end;

procedure TjanDisplay.DrawLeftSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y), Point(x + w, y + FSegWidth),
                          Point(x + w, y + h - FSegWidth), Point(x, y + h)]);
end;

procedure TjanDisplay.DrawRightSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x + w, y), Point(x, y + FSegWidth),
                          Point(x, y + h - FSegWidth), Point(x + w, y + h)]);
end;

procedure TjanDisplay.DrawNorthWest(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x1, y1), Point(x1 + SegHalf, y1),
                          Point(x2, y2 - FSegWidth), Point(x2, y2),
                          Point(x2 - SegHalf, y2), Point(x1, y1 + FSegWidth)]);
end;

procedure TjanDisplay.DrawNorthEast(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x1, y1), Point(x1, y1 - FSegWidth),
                          Point(x2 - SegHalf, y2), Point(x2, y2),
                          Point(x2, y2 + FSegWidth), Point(x1 + SegHalf, y1)]);
end;

procedure TjanDisplay.SetMeasures;
begin
 SegHalf := FSegWidth div 2;
 SegHorLen := Width - FMargin * 2 - FSegWidth;
 SegVerLen := Height div 2 - FSegWidth - SegHalf - FMargin;
 UpLeft[0] := Point(FMargin + SegHalf, FMargin);                         { 3 hor }
 UpLeft[1] := Point(FMargin + SegHalf, Height div 2 - SegHalf);
 UpLeft[2] := Point(FMargin + SegHalf, Height - FMargin - FSegWidth);
 UpLeft[3] := Point(FMargin, FMargin + FSegWidth);                       { 4 ver }
 UpLeft[4] := Point(Width - FMargin - FSegWidth, FMargin + FSegWidth);
 UpLeft[5] := Point(FMargin, Height div 2 + SegHalf);
 UpLeft[6] := Point(Width - FMargin - FSegWidth, Height div 2 + SegHalf);
end;

procedure TjanDisplay.DrawDigit(WhereTo: TBitmap);
var
  i : integer;
begin
   with WhereTo.Canvas do
        begin
          Lock;
          i := ord(FDigit);
          Hexagon(WhereTo, UpLeft[0].x, UpLeft[0].y, SegHorLen, FSegWidth, SegState[i] and $0001 <> 0);
          Hexagon(WhereTo, UpLeft[1].x, UpLeft[1].y, SegHorLen, FSegWidth, SegState[i] and $0002 <> 0);
          Hexagon(WhereTo, UpLeft[2].x, UpLeft[2].y, SegHorLen, FSegWidth, SegState[i] and $0004 <> 0);
          Hexagon(WhereTo, UpLeft[3].x, UpLeft[3].y, FSegWidth, SegVerLen, SegState[i] and $0008 <> 0);
          Hexagon(WhereTo, UpLeft[4].x, UpLeft[4].y, FSegWidth, SegVerLen, SegState[i] and $0010 <> 0);
          Hexagon(WhereTo, UpLeft[5].x, UpLeft[5].y, FSegWidth, SegVerLen, SegState[i] and $0020 <> 0);
          Hexagon(WhereTo, UpLeft[6].x, UpLeft[6].y, FSegWidth, SegVerLen, SegState[i] and $0040 <> 0);
          Unlock;
        end;
end;

procedure TjanDisplay.Paint;
var
  R: TRect;
  PaintBMP, lIn: TBitmap;
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited;

  if (OldHeight <> Height) or (OldWidth <> Width) then
  begin
    SetMeasures;
    OldHeight := Height;
    OldWidth  := Width;
  end;

  Canvas.Lock;
  try
    // Achtergrond component
    Canvas.Brush.Color := FBackColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style   := psDot;
    Canvas.Rectangle(22, 10, Width - 10, Height - 10);

    // Digit bitmap
    PaintBMP := TBitmap.Create;
    try
      PaintBMP.Height := Height - 2;
      PaintBMP.Width  := Width - 2;

      with PaintBMP.Canvas do
      begin
        Lock;
        try
          Brush.Color := clCream;
          R := Rect(0, 0, PaintBMP.Width, PaintBMP.Height);
          FillRect(R);
        finally
          Unlock;
        end;
      end;

      DrawDigit(PaintBMP);

      Canvas.CopyMode := cmSrcCopy;
      PaintBMP.Transparent := True;
      PaintBMP.TransparentColor := clFuchsia;
      Canvas.Draw(0, 0, PaintBMP);
    finally
      PaintBMP.Free;
    end;

    // LOG_IN bitmap
    lIn := TBitmap.Create;
    try
      lIn.LoadFromResourceName(HInstance, 'LOG_IN');
      lIn.Transparent := True;

      for YY := 0 to lIn.Height - 1 do
        for XX := 0 to lIn.Width - 1 do
        begin
          PixelColor := lIn.Canvas.Pixels[XX, YY];
          if (Red(PixelColor) > 200) and
             (Green(PixelColor) > 200) and
             (Blue(PixelColor) > 200) then
            lIn.Canvas.Pixels[XX, YY] := clFuchsia;
        end;

      lIn.TransparentColor := clFuchsia;
      lIn.Transparent := True;
      Canvas.Draw(0, (Height div 2) - (lIn.Height div 2), lIn);
    finally
      lIn.Free;
    end;

    // Selectiekader ALS LAATSTE tekenen
    if Select then
    begin
      R := ClientRect;
      InflateRect(R, -1, -1);   // 1 pixel naar binnen

      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color   := clBlack;
      Canvas.Pen.Style   := psDot;
      Canvas.Rectangle(R);

      Canvas.Pen.Style   := psSolid;
    end;
    // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
     R := ClientRect;
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
     // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;

  finally
    Canvas.Unlock;
  end;
end;


{ TjanConnector }

constructor TjanConnector.Create(AOwner: TComponent);
var
i:integer;
begin
   inherited Create(AOwner);
   width:=60;
   height:=8;
   mode:=jcmTL;
   shape:=jcsTLBR;
   conPos:=jcpTL;
   W_Conmode:='jcmTL';
   W_Conshape:='jcsTLBR';
   W_ConPos:='jcpTL';
   conSize:=8;
   Edge:=0.5;
   S_Edge:='0,5';
   FPower:=false;
   Ledd:=0;
   VAdres:=0;
   For i:= 0 to 15 do Tmemlist[i]:=0;
   TSchrijf:=false;
   FLock:=false;
   Hit:=false;
   select:=false;
  // FNaam:='Draad';
   //FTaal:='NL';
end;

procedure TjanConnector.DoMouseDown(x,y:integer);
var p:Tpoint;
    Rtl,Rbr,Rtr,Rbl:TRect;
    d:integer;
begin
  doMove:=false;
  doEdge:=false;
  d:=conSize;
  oldp:=point(x,y);
  Rtl:=rect(0,0,d,d);
  Rbr:=rect(width-1-d,height-1-d,width-1,height-1);
  Rtr:=rect(width-1-d,0,width-1,d);
  Rbl:=rect(0,height-1-d,d,height-1);
  p:=point(x,y);
  if ptinrect(Rtl,p)and (shape=jcsTLBR) then
  begin
    //showMessage('jcsTLBR');
    mode:=jcmTL;S_Mode:= 'jcmTL';
    mdp:=point(x,y);
  end
  else if ptinrect(Rtr,p) and (shape=jcsTRBL) then
  begin
    //showMessage('jcsTRBL');
    mode:=jcmTR;S_mode:='jcmTR';
    mdp:=point(width-x,y);
  end
  else if ptinrect(Rbr,p) and (shape=jcsTLBR) then
  begin
    //showMessage('jcsBR');
    mode:=jcmBR; S_mode:='jcmBR';
    mdp:=point(width-x,height-y);
  end
  else if ptinrect(Rbl,p) and (shape=jcsTRBL) then
  begin
    //showMessage('jcsTRBL');
    mode:=jcmBL; S_mode:='jcmBL';
    mdp:=point(x,height-y);
  end
  else if (abs(x-round(Edge*width))<10) then
  begin
    doEdge:=true;
  end
  else
  begin
    doMove:=true;
    mdp:=point(x,y);
    SetFromLogic(nil);
    SetToLogic(nil);
  end;
  if not doEdge then
    DisConnect;
end;


procedure TjanConnector.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  pop: TPopupMenu;
  miSel: TMenuItem;
begin
  {
 // if FLock = false then
 // begin
    pop := TPopupMenu.Create(Self);
   // Select/Deselect voor delete-knop
    miSel := TMenuItem.Create(pop);
    if FSelected then
      miSel.Caption := 'Deselecteer draad'
    else
      miSel.Caption := 'Selecteer draad';

    miSel.OnClick := DraadSelectClick;
    pop.Items.Add(miSel);

    if (Button = mbRight) then
    begin
      p.X := 0;
      p.Y := Self.Height;
      p := ClientToScreen(p);
      pop.Popup(p.X, p.Y-1);
    end;
 // end;}
  DoMouseDown(x,y);


end;


procedure TjanConnector.DoMouseMove(dx,dy:integer);
var
    p:Tpoint;
    d,d2,nw,nh:integer;
    x,y:integer;
begin
   x:=dx+oldp.x;
   y:=dy+oldp.y;
   oldp:=point(x,y);
   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);
   d:=conSize;
   d2:= d div 2;
   if doEdge then
   begin
     Edge := x / width;S_Edge :=Format('%.2n', [Edge]);
     invalidate;
   end
   else if doMove then
   begin
     left:=p.x-mdp.x;
     top:=p.y-mdp.y;
   end
   else
   begin
      case mode of
      jcmTL:
      begin
        left:=p.x-mdp.x;
        top:=p.y-mdp.y;
        nw:=width+(mdp.x-X);
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmTR;S_mode:='jcmTR';
          shape:=jcsTRBL; S_shape:='jcsTRBL';
          case conPos of
            jcpTL: begin conPos:=jcpTR;S_Pos:='jcpTR';end;
            jcpBR: begin conPos:=jcpBL;S_Pos:='jcpBL';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
          width:=nw;
        nh:=height+(mdp.y-Y);
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmBL;  S_mode:='jcmBL';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpTL: begin conPos:=jcpBL;S_Pos:='jcpBL'; end;
            jcpBR: begin conPos:=jcpTR;S_Pos:='jcpTR'; end;
          end;
        end
        else
         height:=nh;
      end;
      jcmTR:
      begin
        top:=p.y-mdp.y;
        nw:=X+mdp.x;
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmTL; S_mode:='jcmTL';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpTR: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
            jcpBL: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
         width:=nw;
        nh:=height+(mdp.y-Y);
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmBR;S_mode:='jcmBR';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpTR: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
            jcpBL: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
          end;
        end
        else
          height:=nh;
      end;
      jcmBR:
      begin
        nw:=X+mdp.x;
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmBL;S_mode:='jcmBL';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpBR: begin conPos:=jcpBL; S_Pos:='jcpBL'; end;
            jcpTL: begin conPos:=jcpTR; S_Pos:='jcpTR'; end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
         width:=nw;
        nh:=Y+mdp.y;
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmTR; S_mode:='jcmTR';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpBR: begin conPos:=jcpTR;S_Pos:='jcpTR';end;
            jcpTL: begin conPos:=jcpBL;S_Pos:='jcpBL';end;
          end;
        end
        else
          height:=nh;
      end;
      jcmBL:
      begin
        left:=p.x-mdp.x;
        nw:=width+(mdp.x-x);
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmBR;S_mode:='jcmBR';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpBL: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
            jcpTR: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
          width:=nw;
        nh:=Y+mdp.y;
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmTL; S_mode:='jcmTL';
          shape:=jcsTLBR; S_shape:='jcsTLBR';
          case conPos of
             jcpBL: begin conPos:=jcpTL; S_Pos:='jcpTL';end;
             jcpTR: begin conPos:=jcpBR; S_Pos:='jcpBR';end;
          end;
        end
        else
          height:=nh;
      end;
      end;
   end;
end;

procedure TjanConnector.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
   if (ssleft in shift) then
   begin

     doMouseMove(x-oldp.x,y-oldp.y);
   end;
end;


procedure TjanConnector.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
if not doEdge then
    DisConnectFinal;
    //SendToBack;
    select:=false;invalidate;
end;

procedure TjanConnector.DisConnectFinal;
begin
  if DisCon=nil then exit;
  if (Discon is TjanSimLight) then
  begin
    TjanSimLight(Discon).lit:=false;
  end
  else if (Discon is TjanDipSwitsh) then
  begin
    TjanDipSwitsh(Discon).Down:=false;
  end
  else if (Discon is TjanDisplay) then
  begin
    TjanDisplay(Discon).digit:='0';
  end
  else if (Discon is TjanSimRelais) then
  begin
    TjanSimRelais(Discon).lit:=false;
  end
  else if (Discon is TjanSimBuzzer) then
  begin
    TjanSimBuzzer(Discon).lit:=false;
  end
  else if (Discon is TjanMeter) then
  begin
    if DisConI=1 then
      TjanMeter(DisCon).input1:=false
    else if DisConI=3 then
      TjanMeter(DisCon).input3:=false
  end
  else if (DisCon is TjanTeller) then
  begin
    if DisConI=1 then
      TjanTeller(DisCon).reset:=true
    else if DisConI=3 then
      TjanTeller(DisCon).reset:=true
  end
  else if (DisCon is TjanMemory) then
  begin
    if DisConI=1 then
      TjanMemory(DisCon).reset:=true
    else if DisConI=3 then
      TjanMemory(DisCon).reset:=true
  end
  else if (DisCon is TjanLogic) then
  begin
    if DisConI=1 then
      TjanLogic(DisCon).input1:=false
    else if DisConI=2 then
      TjanLogic(DisCon).input2:=false
    else if DisConI=3 then
      TjanLogic(DisCon).input3:=false
  end;
end;

procedure TjanConnector.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (operation=opremove) and (AComponent=FFromLogic) then
    SetFromLogic(nil);
  if (operation=opremove) and (AComponent=FToLogic) then
    SetToLogic(nil);
end;

procedure TjanConnector.draadClick(sender:TObject);
Begin
  disconnectFinal;
  free;
end;

procedure TjanConnector.Paint;
var
  d, d2, w2, xw, yh: Integer;
  R: TRect;
begin
  d  := conSize;
  d2 := d div 2;
  w2 := Round(Edge * Width);
  xw := Width - 1;
  yh := Height - 1;

  with Canvas do
  begin
    Lock;
    try
      Brush.Color := clLime;
      if FPower = True then
        Pen.Color := clRed
      else
        Pen.Color := clBlack;
      case Shape of
        jcsTLBR:
          begin
            case conPos of
              jcpTL:
                begin
                  MoveTo(d, d2);
                  LineTo(w2, d2);
                  LineTo(w2, yh - d2);
                  LineTo(xw - d, yh - d2);

                  if (FLock = False) and (yh > 20) and (xw > 20) and (hit = True) then
                  begin
                    Brush.Style := bsSolid;
                    Brush.Color := clWhite;
                    Ellipse(w2 - 4, (yh div 2) - 4, w2 + 4, (yh div 2) + 4);
                  end;

                  Brush.Style := bsClear;
                  Rectangle(0, 0, d, d);

                  Brush.Style := bsSolid;
                  Brush.Color := clLime;
                  Rectangle(xw - d, yh - d, xw, yh);
                end;

              jcpBR:
                begin
                  MoveTo(d, d2);
                  LineTo(xw - d2, d2);
                  LineTo(xw - d2, yh - d);

                  Brush.Color := clLime;
                  Rectangle(0, 0, d, d);

                  Brush.Style := bsClear;
                  Rectangle(xw - d, yh - d, xw, yh);

                  Brush.Style := bsSolid;
                end;
            end;
          end;

        jcsTRBL:
          begin
            case conPos of
              jcpTR:
                begin
                  MoveTo(xw - d2, d);
                  LineTo(xw - d2, yh - d2);
                  LineTo(d, yh - d2);

                  Brush.Style := bsClear;
                  Rectangle(xw - d, 0, xw, d);

                  Brush.Style := bsSolid;
                  Brush.Color := clLime;
                  Rectangle(0, yh - d, d, yh);
                end;

              jcpBL:
                begin
                  MoveTo(xw - d, d2);
                  LineTo(w2, d2);
                  LineTo(w2, yh - d2);
                  LineTo(d - 1, yh - d2);

                  if (FLock = False) and (yh > 20) and (xw > 20) and (hit = True) then
                  begin
                    Brush.Style := bsSolid;
                    Brush.Color := clWhite;
                    Ellipse(w2 - 4, (yh div 2) - 4, w2 + 4, (yh div 2) + 4);
                  end;

                  Brush.Color := clLime;
                  Rectangle(xw - d, 0, xw, d);

                  Brush.Style := bsClear;
                  Rectangle(0, yh - d, d, yh);

                  Brush.Style := bsSolid;
                end;
            end;
          end;
      end; // case Shape

      // -----------------------------
      // Selectiekader ALS LAATSTE
      // -----------------------------
      {if FSelected then
      begin
        R := ClientRect;
       // InflateRect(R, -2, -2);
        Brush.Style := bsClear;
        Pen.Color := clRed;
        Pen.Width := 1;
        Rectangle(R);
        // restore defaults (netjes)
        Pen.Width := 1;
        Brush.Style := bsSolid;
      end;}

    finally
      Unlock;
    end;
  end;
end;


{
procedure TjanConnector.paint;
var
    d,d2,w2,xw,yh:integer;
    R:TRect;
begin
  d:=conSize;
  d2:=d div 2;
  w2:=round(Edge * width);
  xw:=width-1;
  yh:=height-1;
  with canvas do
  begin
  Lock;
  brush.color:=cllime;
  if FPower=true then Pen.Color:=clred else Pen.Color:=clblack;
  case shape of
  jcsTLBR:
    begin
      case conPos of
        jcpTL: // draw regular connector
        begin
          moveto(d,d2);
          lineto(w2,d2);
          lineto(w2,yh-d2);
          lineto(xw-d,yh-d2);
          if (FLock=false)  and (yh > 20) and (xw > 20) and (hit=true) then
           begin
           brush.Style:=bsSolid;
           brush.color:=clWhite;
           Ellipse(w2-4,(yh div 2)-4,w2+4,(yh div 2)+4);
           end;
          brush.Style:=bsClear;
          rectangle(0,0,d,d);
          brush.Style:=bsSolid;
          brush.color:=clLime;
          rectangle(xw-d,yh-d,xw,yh);
        end;
        jcpBR:
        begin
          moveto(d,d2);
          lineto(xw-d2,d2);
          lineto(xw-d2,yh-d);
          brush.color:=clLime;
          rectangle(0,0,d,d);
          brush.Style:=bsClear;
          rectangle(xw-d,yh-d,xw,yh);
          brush.Style:=bsSolid;
        end;
      end;
    end;
  jcsTRBL:
    begin
      case conPos of
        jcpTR: // draw reverted connector
        begin
          moveto(xw-d2,d);
          lineto(xw-d2,yh-d2);
          lineto(d,yh-d2);
          brush.Style:=bsClear;
          rectangle(xw-d,0,xw,d);
          brush.Style:=bsSolid;
          brush.color:=clLime;
          rectangle(0,yh-d,d,yh);
        end;
        jcpBL: // draw regular connector
        begin
          moveto(xw-d,d2);
          lineto(w2,d2);
          lineto(w2,yh-d2);
          lineto(d-1,yh-d2);
          if (FLock=false) and (yh > 20) and (xw > 20)and( hit=true) then
           begin
           brush.Style:=bsSolid;
           brush.color:=clWhite;
           Ellipse(w2-4,(yh div 2)-4,w2+4,(yh div 2)+4);
           end;
          brush.color:=clLime;
          rectangle(xw-d,0,xw,d);
          brush.Style:=bsClear;
          rectangle(0,yh-d,d,yh);
          brush.Style:=bsSolid;
        end;
      end;
    end;
  end; // case
  unlock;

end; //canvas
end;}

procedure TjanConnector.SetFromGate(const Value: integer);
begin
  FFromGate := Value;
end;

procedure TjanConnector.SetFromLogic(const Value: TjanLogic);
begin
  FFromLogic := Value;
end;

procedure TjanConnector.SetToGate(const Value: integer);
begin
  FToGate := Value;
end;

procedure TjanConnector.SetPower(const Value: Boolean);
begin
  if power <> value then invalidate;
  Fpower := Value;
end;

procedure TjanConnector.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanConnector.SetS_mode(Value: string);
begin
  S_mode := Value;
  invalidate;
end;
procedure TjanConnector.SetS_Edge(Value: string);
begin
  S_Edge := Value;
invalidate;
end;
procedure TjanConnector.SetS_Pos(Value: string);
begin
  S_Pos := Value;
  invalidate;
end;
procedure TjanConnector.SetS_Shape(Value: string);
begin
  S_Shape := Value;
  invalidate;
end;


procedure TjanConnector.Setjanconmode(Value: TjanConMode);
begin
  mode := Value;
  case Mode of
        jcmTL:
        begin S_Mode:='jcmTL'end;
        jcmBR:
        begin S_Mode:='jcmBR'end;
        jcmBL:
        begin S_Mode:='jcmBL'end;
        jcmTR:
        begin S_Mode:='jcmTR'end;
      end;
  invalidate;
end;
procedure TjanConnector.Setjanconpos(Value: TjanConpos);
begin
  ConPos := Value;
  case ConPos of
        jcpTL:
        begin S_Pos:='jcpTL'end;
        jcpBR:
        begin S_Pos:='jcpBR'end;
        jcpBL:
        begin S_Pos:='jcpBL'end;
        jcpTR:
        begin S_Pos:='jcpTR'end;
      end;
  invalidate;
end;
procedure TjanConnector.SetjanconShape(Value: TjanConShape);
begin
  shape := Value;
  case Shape of
        jcsTLBR:
        begin S_Shape:='jcsTLBR'end;
        jcsTRBL:
        begin S_Shape:='jcsTRBL'end;
      end;
  invalidate;
end;

procedure TjanConnector.SetjanEdge(Value: extended);
begin
  Edge := Value;
  S_Edge:=Format('%.2n', [Edge]);
  invalidate;
end;
procedure TjanConnector.SetToLogic(const Value: TjanLogic);
begin
  FToLogic := Value;
end;

procedure TjanConnector.SetToTeller(const Value: TjanTeller);
begin
  FToTeller := Value;
end;
procedure TjanConnector.SetFromPoint(const Value: TPoint);
begin
  FFromPoint := Value;
end;

procedure TjanConnector.SetToPoint(const Value: TPoint);
begin
  FToPoint := Value;
end;
{
procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
var
RegLB,RegLO,RegRO,RegRB,RegM:HRGN;
w2 : Integer;
begin
   //if FLock=true then exit;
   w2:=round(Edge * width);
   RegLB:=CreateRectRgn(1,1,9,9);
   RegLO:=CreateRectRgn(1,height-9,9,height-1);
   RegM:=CreateRectRgn(w2- 2,0,w2 + 2,height);
   RegRO:=CreateRectRgn(width - 9,height-1,width-1,height - 9);
   RegRB:=CreateRectRgn(width - 9,1,width-1,9);
   Msg.Result := HTNOWHERE;
 with Msg do
    Begin
    if Canvas.Pixels[XPos,YPos] = clWhite then Result := HTCLIENT;
    if PtInRegion(RegLB, XPos, YPos) then Result := HTCLIENT;
    if PtInRegion(RegLO, XPos, YPos) then Result := HTCLIENT ;
    if PtInRegion(RegM, XPos, YPos) then
      begin
       Hit := TRUE ;
       Result := HTCLIENT;
       invalidate;
       end
       else
       begin
       hit:=false;
       Result := HTCLIENT;
       invalidate;
       Result := HTNOWHERE;
       end;
    if PtInRegion(RegRo, XPos, YPos) then Result := HTCLIENT ;
    if PtInRegion(RegRB, XPos, YPos) then Result := HTCLIENT ;
    end;
   DeleteObject(RegLB);
   DeleteObject(RegLO);
   DeleteObject(RegM);
   DeleteObject(RegRO);
   DeleteObject(RegRB);
end;}
{
procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
begin
  Msg.Result := HTCLIENT;
end;}

procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
var
  RegLB, RegLO, RegRO, RegRB, RegM: HRGN;
  w2, d: Integer;
begin
  // if FLock then Exit;  // indien nodig

  d  := conSize;                // grootte van de hoek-blokjes (meestal 8)
  w2 := Round(Edge * Width);    // positie van de midden-lijn

  // Regio's voor de 4 hoeken + midden-strook
  RegLB := CreateRectRgn(0, 0, d, d);                       // links-boven
  RegLO := CreateRectRgn(0, Height - d, d, Height);         // links-onder
  RegRB := CreateRectRgn(Width - d, 0, Width, d);           // rechts-boven
  RegRO := CreateRectRgn(Width - d, Height - d, Width, Height); // rechts-onder (lime)
  RegM  := CreateRectRgn(w2 - 2, 0, w2 + 2, Height);        // middenlijn

  Msg.Result := HTNOWHERE;

  with Msg do
  begin
    // 1) Witte cirkel in het midden (clWhite) mag ook hit zijn
    if Canvas.Pixels[XPos, YPos] = clWhite then
      Result := HTCLIENT;
    // 2) Hoeken: als je in een van de hoek-regio's zit → HTCLIENT
    if PtInRegion(RegLB, XPos, YPos) or  // links-boven
       PtInRegion(RegLO, XPos, YPos) or  // links-onder
       PtInRegion(RegRB, XPos, YPos) or  // rechts-boven
       PtInRegion(RegRO, XPos, YPos)     // rechts-onder (lime)
    then
      Result := HTCLIENT;

    // 3) Middenlijn (hit = true/false)
    if PtInRegion(RegM, XPos, YPos) then
    begin
      Hit := True;
      Result := HTCLIENT;

      Invalidate;
    end
    else
    begin
      Hit := False;

      Invalidate;
      // BELANGRIJK: Result hier NIET terug op HTNOWHERE zetten,
      // anders gooi je de hoek-hits weer weg.
    end;
  end;

  DeleteObject(RegLB);
  DeleteObject(RegLO);
  DeleteObject(RegRB);
  DeleteObject(RegRO);
  DeleteObject(RegM);
end;


procedure TjanConnector.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   if Assigned (FonExit) then FonExit(Self);
   if not FLock then
   begin
    select:=false;
    invalidate;
   end;
end;

procedure TjanConnector.CMMouseEnter(var Msg: TMessage);
begin
  inherited;

  if Assigned (FOnEnter) then FOnEnter(Self);
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;

procedure TjanConnector.AnchorCorner(logTL: TPoint; ACorner: TjanConMode);
var Rc:TRect;
begin
  ConMode:=ACorner;
  Rc:=boundsrect;
  ConHot:=ConPos;
  case Acorner of
  jcmTL:
    begin
      ConOffset:=point(Rc.left-logTL.x,Rc.top-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(width,height)));
    end;
  jcmTR:
    begin
      ConOffset:=point(Rc.Right-logTL.x,Rc.top-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(0,height)));
    end;
  jcmBR:
    begin
      ConOffset:=point(Rc.Right-logTL.x,Rc.bottom-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(0,0)));
    end;
  jcmBL:
    begin
      ConOffset:=point(Rc.left-logTL.x,Rc.bottom-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(width,0)));
    end;
  end;
end;

procedure TjanConnector.MoveConnector(logTL: TPoint);
var nw,nh:integer;
    d,dd,d2:integer;
    nc:Tpoint;
begin
   d:=conSize;
   d2:= d div 2;
   nc:=point(LogTL.x+ConOffset.x,logTL.y+ConOffset.y);
  case conMode of
  jcmTL:
    begin
    nw:=conAnchor.x-nc.x;
    if nw<d then
    begin
      left:=conAnchor.x-d;
      width:=-nw+d+d;
    end
    else begin
      left:=nc.x;
      width:=ConAnchor.x-left;
    end;
    nh:=ConAnchor.y-nc.y;

// adjust new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpTL: conPos:=jcpTR;
        jcpBR: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTL: conPos:=jcpBR;
        jcpBR: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTL: conPos:=jcpBL;
        jcpBR: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else begin
      case conHot of
        jcpTL: conPos:=jcpTL;
        jcpBR: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end;
// end of adjust TL new hot
    if nh<d then
    begin
      top:=ConAnchor.y-d;
      height:=-nh+d+d;
    end
    else begin
      top:=nc.y;
      height:=ConAnchor.y-Top;
    end;
    end;
  jcmTR:
    begin
    nw:=nc.x-ConAnchor.x;
    if nw<=0 then
    begin
      left:=conAnchor.x+nw-d;
      width:=-nw+d+d;
    end
    else if nw<=d then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else begin
      width:=nw;
    end;
    nh:=ConAnchor.y-nc.y;
// adjust TR new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpTR: conPos:=jcpTL;
        jcpBL: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTR: conPos:=jcpBL;
        jcpBL: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTR: conPos:=jcpBR;
        jcpBL: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else begin
      case conHot of
        jcpTR: conPos:=jcpTR;
        jcpBL: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end;
// end of adjust TR new hot
    if nh<d then
    begin
      top:=ConAnchor.y-d;
      height:=-nh+d+d;
    end
    else begin
      top:=ConAnchor.y-nh;
      height:=nh;
    end;
    end;
  jcmBR:
    begin
    nw:=nc.x-ConAnchor.x;
    if nw<=0 then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else if nw<=d then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else begin
      width:=nw;
    end;
    nh:=nc.y-ConAnchor.y;
// adjust BR new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpBR: conPos:=jcpBL;
        jcpTL: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBR: conPos:=jcpTL;
        jcpTL: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBR: conPos:=jcpTR;
        jcpTL: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else begin
      case conHot of
        jcpBR: conPos:=jcpBR;
        jcpTL: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end;
// end of adjust BR new hot
    if nh<d then
    begin
      top:=ConAnchor.y+nh-d;
      height:=-nh+d+d;
    end
    else begin
       height:=nh;
    end;
    end;
  jcmBL:
    begin
    nw:=conAnchor.x-nc.x;
    if nw<d then
    begin
      left:=conAnchor.x-d;
      width:=-nw+d+d;
    end
    else begin
      left:=ConAnchor.x-nw;
      width:=nw;
    end;
    nh:=nc.y-ConAnchor.y;
// adjust BL new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpBL: conPos:=jcpBR;
        jcpTR: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBL: conPos:=jcpTR;
        jcpTR: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBL: conPos:=jcpTL;
        jcpTR: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else begin
      case conHot of
        jcpBL: conPos:=jcpBL;
        jcpTR: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end;
// end of adjust BL new hot
    if nh<d then
    begin
       top:=ConAnchor.y+nh-d;
       height:=-nh+d+d;
    end
    else begin
      height:=nh;
    end;
    end;
  end;
end;



procedure TjanConnector.Connect;
var Pi,Po:TPoint;
    R:Trect;
    i,g,d,d2,xw,yh,puls,puls1,getal:integer;
    wc:TWinControl;
    Vi,aktief:boolean;
    Adres:Integer;
    Ledw:char;
    sBut:TjanSimButton;
    SDipSwitsh:TjanDipSwitsh;
    sKnop:TjanSimKnop;
    sPuls:TjanSimPuls;
    sSensor:TjanSimSensor;
    sWarm:TjanSimWarm;
    sLog:TjanLogic;
    sTeller:TjanTeller;
    sMemory:TjanMemory;
    sMeter:TjanMeter;
    sLight:TjanSimLight;
    sDisplay:TjanDisplay;
    sRelais:TjanSimRelais;
    sBuzzer:TjanSimBuzzer;
    pl:TPoint;

  // convert a corner point to a parent point
  function pp(x,y:integer):TPoint;
  var p:Tpoint;
  begin
    p:=point(x,y);
    p:=clienttoscreen(p);
    result:=wc.ScreenToClient(p);
  end;

  function getvi:boolean;
  var p:Tpoint;
      ii:integer;
  begin
    result:=true;
    for ii:=0 to wc.ControlCount-1 do
    begin
      if (wc.controls[ii] is TjanSimButton) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sBut:=TjanSimButton(wc.controls[ii]);
          puls:=sBut.Puls;
          Vi:=sBut.Down;
          sBut.Puls:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi)   then
        begin
          sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
          if  (sDipSwitsh.Down=true) or (sDipSwitsh.Start=true) then vi:=true else vi:=false;
          if vi=true then
          begin
             TSchrijf:=true;
             Ledd:=sDipSwitsh.Bits;
          end;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimKnop) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sKnop:=TjanSimKnop(wc.controls[ii]);
          puls:=sKnop.Puls;
          Vi:=sKnop.Down;
          sKnop.Puls:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimPuls) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sPuls:=TjanSimPuls(wc.controls[ii]);
          puls:=sPuls.Pulser;
          Vi:=sPuls.Pulsen;
          sPuls.Pulser:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimSensor) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sSensor:=TjanSimSensor(wc.controls[ii]);
          puls:=sSensor.Puls;
          Vi:=sSensor.Down;
          sSensor.Puls:=0;
          exit;
        end;
      end

      else if (wc.controls[ii] is TjanSimWarm) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sWarm:=TjanSimWarm(wc.controls[ii]);
          puls:=sWarm.Puls;
          Vi:=sWarm.Down;
          sWarm.Puls:=0;
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          R:=rect(sMeter.left+33,sMeter.top+23,sMeter.left+sMeter.Width+ConSize,smeter.Top+44);
          if ptinrect(R,Pi) and SMeter.Gates[4].Active then
          begin  // output is gate 4
            vi:=SMeter.OutPut2;
            exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          R:=rect(sTeller.left+33,sTeller.top+40,sTeller.left+ sTeller.Width+ConSize,sTeller.Top+48);
          if ptinrect(R,Pi) and STeller.Gates[4].Active then
          begin  // output is op aansluiting naar display
            vi:=STeller.OutPutDisplay;LedW:=STeller.FBitsChar;exit;
          end;
          R:=rect(sTeller.left+30,sTeller.top + 75,sTeller.left+30+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[2].Active then
          begin  // output is op aansluiting bit8
            vi:=STeller.OutPutBit8;exit;
          end;
          R:=rect(sTeller.left + 55,sTeller.top + 75,sTeller.left + 55 + ConSize,sTeller.top+83);
          if ptinrect(R,Pi) and STeller.Gates[3].Active then
          begin  // output is op aansluiting bit4
            vi:=STeller.OutPutBit4;exit;
          end;
          R:=rect(sTeller.left+80,sTeller.top+ 75,sTeller.left+80+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[5].Active then
          begin  // output is op aansluiting bit2
            vi:=STeller.OutPutBit2;exit;
          end;
          R:=rect(sTeller.left+105,sTeller.top+ 75,sTeller.left+105+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[6].Active then
          begin  // output is op aansluiting bit1
            vi:=STeller.OutPutBit1;exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
          R:=rect(sMemory.left+ 192,sMemory.top + 90,sMemory.left+ 200,sMemory.Top+98);
          if ptinrect(R,Pi) and SMemory.Gates[4].Active then
          begin  // output is op aansluiting naar display
            vi:=SMemory.OutPutDisplay;LedW:=SMemory.FBitsChar;exit;
          end;
          //nieuw 28 december
          //draw(81,138,Uit);
          R:=rect(sMemory.left+81,sMemory.top + 138,sMemory.left+81+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[2].Active then
          begin  // output is op aansluiting bit8
            vi:=sMemory.OutPutBitMem8;exit;
          end;
          //draw(106,138,Uit);
          R:=rect(sMemory.left + 106,sMemory.top + 138,sMemory.left + 106 + ConSize,sMemory.top+138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[3].Active then
          begin  // output is op aansluiting bit4
            vi:=sMemory.OutPutBitMem4;exit;
          end;
          //draw(134,138,Uit);
          R:=rect(sMemory.left+134,sMemory.top+ 138,sMemory.left+134+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[5].Active then
          begin  // output is op aansluiting bit2
            vi:=sMemory.OutPutBitMem2;exit;
          end;
          //draw(156,138,Uit);
          R:=rect(sMemory.left+156,sMemory.top + 138,sMemory.left+156+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[6].Active then
          begin  // output is op aansluiting bit1
            vi:=sMemory.OutPutBitmem1;exit;
          end;
          // einde nieuw 28 december
        end;
      end
      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 output area's
          R:=rect(sLog.left+33,sLog.top,sLog.left+slog.Width+ConSize,sLog.Top+22);
          if ptinrect(R,Pi) and SLog.Gates[3].Active then
          begin  // output is gate 3
            vi:=SLog.OutPut1;
            exit;
          end;
          R:=rect(sLog.left+33,sLog.top+23,sLog.left+slog.Width+ConSize,sLog.Top+44);
          if ptinrect(R,Pi) and SLog.Gates[4].Active then
          begin  // output is gate 4
            vi:=SLog.OutPut2;
            //If SLog.OutPut2=true then puls:=1 else puls:=0;
            exit;
          end;
          R:=rect(sLog.left+33,sLog.top+45,sLog.left+slog.Width+ConSize,sLog.Top+64);
          if ptinrect(R,Pi) and SLog.Gates[5].Active then
          begin  // output is gate 5
            vi:=SLog.OutPut3;
            exit;
          end;
        end;
      end;
    end;
    result:=false;
  end;

  procedure setVo;  // deze procedure kontroleert of er op een imput van een
  var p:Tpoint;     // object een aansluiting is gemaakt van een ander object
      ii,Q:integer; // doormiddel van Tjanconnector en veranderd een status in
  begin             // het object doormiddel van de variable vi dat op true/false
    getal:=0;       // wordt gezet in de procedure getvi hierboven
    if vi=true then setpower(true) else setpower(false);
    for ii:=0 to wc.ControlCount-1 do
    begin
      if (wc.controls[ii] is TjanSimLight) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLight:=TjanSimLight(wc.controls[ii]);
          If SLight.Lit<> Vi then SLight.Lit:=Vi;
          exit;
        end;
      end
      else if(wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
        sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
        //draw(91,15,Ingang);
        R:=rect(sDipSwitsh.left + 91,sDipSwitsh.top + 15,sDipSwitsh.left + 100,sDipSwitsh.Top + 30);
          if ptinrect(R,Po)  then
          begin  // input is op schrijfingang vanuit externe aansluiting
           if SDipSwitsh.start <> Vi then  SDipSwitsh.start:=vi;
           puls1:=1;
           exit;
          end;
        end;
      end
      else if(wc.controls[ii] is TjanDisplay) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDisplay:=TjanDisplay(wc.controls[ii]);
          if LedW=#0 then // gewone aan/uit-bron (drukknop, schakelaar, poort...)
            if vi then LedW:='1' else LedW:='0';
          If SDisplay.Digit <> LedW then  SDisplay.digit:=LedW;
          exit;
        end;
      end
      else if(wc.controls[ii] is TjanSimRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sRelais:=TjanSimRelais(wc.controls[ii]);
          If Srelais.Lit <>vi then Srelais.Lit:=Vi;
          exit;
        end;
      end

      else if(wc.controls[ii] is TjanSimBuzzer) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sBuzzer:=TjanSimBuzzer(wc.controls[ii]);
          if SBuzzer.Lit <> vi then  SBuzzer.Lit:=Vi;
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          // nu wordt gekontroleer of p is in een van de 2 input area's
          R:=rect(sMeter.left+5,sMeter.top+ 35,sMeter.left+13,sMeter.Top+43);
         // in input gate 0
         if ptinrect(R,Po) and SMeter.Gates[0].Active then
          begin
            SMeter.Input1:=vi;exit;
          end;
          R:=rect(sMeter.left+ 85,sMeter.top+ 35,sMeter.left+ 93,sMeter.Top+ 43);
          // in input gate 2
          if ptinrect(R,Po) and SMeter.Gates[2].Active then
          begin
            SMeter.Input3:=vi;exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          // now check if p is in one of the 2 input area's
          R:=rect(sTeller.left-d,sTeller.top,sTeller.left+32,sTeller.Top+22);
          if ptinrect(R,Po) and sTeller.Gates[0].Active then
          begin  // input is op Re (reset)
             if sTeller.reset <> vi then sTeller.reset:=vi;
            exit;
          end;
          R:=rect(sTeller.left-d,sTeller.top+45,sTeller.left+32,sTeller.Top+64);
          if ptinrect(R,Po) and sTeller.Gates[1].Active then
          begin  // input is op Te (teller)
            //if puls <> 0  then
            if sTeller.telop <> vi then sTeller.telop:=vi;
            //puls:=0;
            exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        // now check if p is in one of the imput area's ( Gates[0] )
        if ptinrect(R,Po) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
            R:=rect(sMemory.left + 17 ,sMemory.top + 120,sMemory.left + 30,sMemory.Top + 130);
          if ptinrect(R,Po) and sMemory.Gates[0].Active then
            begin  // input is op schrijfingang vanuit DipSwitsh
              sMemory.schrijf:=TSchrijf;
              If TSchrijf=true then sMemory.Bits:=Ledd;
              TSchrijf:=false;
              //sMemory.telop:=vi;
              exit;
            end;
          R:=rect(sMemory.left + 80 ,sMemory.top + 33,sMemory.left + 90,sMemory.Top + 42);
          // input is op adressingang A8
          if ptinrect(R,Po) and sMemory.Gates[1].Active then
          Begin sMemory.A8:=vi;end;
          R:=rect(sMemory.left + 105 ,sMemory.top + 33,sMemory.left + 115,sMemory.Top + 42);
          // input is op adressingang A4
          if ptinrect(R,Po) and sMemory.Gates[7].Active then
          begin sMemory.A4:=vi;end;
          R:=rect(sMemory.left + 130 ,sMemory.top + 33,sMemory.left + 140,sMemory.Top + 42);
          // input is op adressingang A2
          if ptinrect(R,Po) and sMemory.Gates[8].Active then
          begin sMemory.A2:=vi;end;
          R:=rect(sMemory.left + 155 ,sMemory.top + 33,sMemory.left + 165,sMemory.Top + 42);
          // input is op adressingang A1
          if ptinrect(R,Po) and sMemory.Gates[9].Active then
            begin sMemory.A1:=vi;end;
          sMemory.Invalidate;
        end;
      end
      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sLog.left-d,sLog.top,sLog.left+32,sLog.Top+22);
          if ptinrect(R,Po) and SLog.Gates[0].Active then
          begin  // input is gate 0
            if SLog.Input1 <> vi then SLog.Input1:=vi;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+23,sLog.left+32,sLog.Top+44);
          if ptinrect(R,Po) and SLog.Gates[1].Active then
          begin  // input is gate 1
           if SLog.Input2 <> Vi then SLog.input2:=vi;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+45,sLog.left+32,sLog.Top+64);
          if ptinrect(R,Po) and SLog.Gates[2].Active then
          begin  // input is gate 2
            if SLog.Input3 <> Vi then SLog.Input3:=vi;
            exit;
          end;
        end;
      end;
    end;
  end;
begin
  // connect input and output using the conPos
  d2:=conSize div 2;
  d:=conSize;
  xw:=width-1;
  yh:=height-1;
  wc:=parent;
  case conPos of
    jcpTL:
      begin
        Pi:=pp(d2,d2);
        Po:=pp(xw-d2,yh-d2);
      end;
    jcpTR:
      begin
        Pi:=pp(xw-d2,d2);
        Po:=pp(d2,yh-d2);
      end;
    jcpBR:
      begin
        Pi:=pp(xw-d2,yh-d2);
        Po:=pp(d2,d2);
      end;
    jcpBL:
      begin
        Pi:=pp(d2,yh-d2);
        Po:=pp(xw-d2,d2);
      end;
  end;
  LedW:=#0; // enkel teller/geheugen vullen dit in; anders toont het display 0/1
  if getvi then
  Begin
  setvo;
  end;
end;

procedure TjanConnector.DisConnect;
var Pi,Po:TPoint;
    R:Trect;
    i,g,d,d2,xw,yh:integer;
    wc:TWinControl;
    Vi:boolean;
    sKnop:TjanSimKnop;
    sPuls:TjanSimPuls;
    sSensor:TjanSimSensor;
    sWarm:TjanSimWarm;
    sBut:TjanSimButton;
    SDipSwitsh:TjanDipSwitsh;
    sLog:TjanLogic;
    sTeller:TjanTeller;
    sMemory:TjanMemory;
    sMeter:TjanMeter;
    sLight:TjanSimLight;
    sDisplay:TjanDisplay;
    sRelais:TjanSimRelais;
    sBuzzer:TjanSimBuzzer;
  // convert a corner point to a parent point
  function pp(x,y:integer):TPoint;
  var p:Tpoint;
  begin
    p:=point(x,y);
    p:=clienttoscreen(p);
    result:=wc.ScreenToClient(p);
  end;

  procedure setVo;
  var p:Tpoint;
      ii:integer;
  begin
    if vi=true then setpower(true) else setpower(false);
    for ii:=0 to wc.ControlCount-1 do
    begin
      if (wc.controls[ii] is TjanSimLight) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLight:=TjanSimLight(wc.controls[ii]);
          SLight.Lit:=false;
          DisCon:=sLight;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
          sDipSwitsh.Down:=false;
          DisCon:=sDipSwitsh;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDisplay) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDisplay:=TjanDisplay(wc.controls[ii]);
          SDisplay.digit:='0';
          DisCon:=sDisplay;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sRelais:=TjanSimRelais(wc.controls[ii]);
          SRelais.Lit:=false;
          DisCon:=sRelais;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimBuzzer) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sBuzzer:=TjanSimBuzzer(wc.controls[ii]);
          SBuzzer.Lit:=false;
          DisCon:=sBuzzer;
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sMeter.left-d,sMeter.top,sMeter.left+32,sMeter.Top+22);
          if ptinrect(R,Po) and sMeter.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sMeter;
          DisConI:=1;
//            SLog.Input1:=false;
            exit;
          end;

          //R:=rect(sMeter.left-d,sMeter.top+45,sMeter.left+32,sMeter.Top+64);
          R:=rect(sMeter.left+sMeter.Width-d,sMeter.top+sMeter.height,sMeter.left+sMeter.Width,sMeter.Top+sMeter.Height+8);

          if ptinrect(R,Po) and sMeter.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sMeter;
          DisConI:=3;
          exit;
          end;
        end;
      end

      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sTeller.left-d,sTeller.top,sTeller.left+32,sTeller.Top+22);
          if ptinrect(R,Po) and sTeller.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sTeller;
          DisConI:=1;
          exit;
          end;
          R:=rect(sTeller.left-d,sTeller.top+45,sTeller.left+32,sTeller.Top+64);
          if ptinrect(R,Po) and sTeller.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sTeller;
          DisConI:=3;
            exit;
          end;
        end;
      end

      //kontroleren
      {
      FGates[0].pos:=point(120,64); FGates[0].Active:=true;   // imput vanuit dipswitsh
      FGates[1].pos:=point(80,33); FGates[1].Active:=true;    // imput adress bit8
      FGates[7].pos:=point(105,33); FGates[7].Active:=true;   // imput adress bit4
      FGates[8].pos:=point(130,33); FGates[8].Active:=true;   // imput adress bit2
      FGates[9].pos:=point(155,33); FGates[9].Active:=true;   // imput adress bit1
      }
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sMemory.left-d,sMemory.top+64,sMemory.left+120,sMemory.Top+72);
          if ptinrect(R,Po) and sMemory.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sMemory;
          DisConI:=1;
          exit;
          end;
          R:=rect(sMemory.left-d,sMemory.top+33,sMemory.left+32,sMemory.Top+41);
          if ptinrect(R,Po) and sMemory.Gates[1].Active then
          begin  // input is gate 2
          DisCon:=sMemory;
          DisConI:=3;
            exit;
          end;
        end;
      end

      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sLog.left-d,sLog.top,sLog.left+32,sLog.Top+22);
          if ptinrect(R,Po) and SLog.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sLog;
          DisConI:=1;
//            SLog.Input1:=false;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+23,sLog.left+32,sLog.Top+44);
          if ptinrect(R,Po) and SLog.Gates[1].Active then
          begin  // input is gate 1
          DisCon:=sLog;
          DisConI:=2;
//            SLog.input2:=false;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+45,sLog.left+32,sLog.Top+64);
          if ptinrect(R,Po) and SLog.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sLog;
          DisConI:=3;
//            SLog.Input3:=false;
            exit;
          end;
        end;
      end;
    end;
  end;



begin
  // connect input and output using the conPos
  DisCon:=nil;
  disConI:=0;
  d2:=conSize div 2;
  d:=conSize;
  xw:=width-1;
  yh:=height-1;
  wc:=parent;
  case conPos of
    jcpTL:
      begin
        Pi:=pp(d2,d2);
        Po:=pp(xw-d2,yh-d2);
      end;
    jcpTR:
      begin
        Pi:=pp(xw-d2,d2);
        Po:=pp(d2,yh-d2);
      end;
    jcpBR:
      begin
        Pi:=pp(xw-d2,yh-d2);
        Po:=pp(d2,d2);
      end;
    jcpBL:
      begin
        Pi:=pp(d2,yh-d2);
        Po:=pp(xw-d2,d2);
      end;
  end;
  // clear logic inputs and lights
  setvo;
end;


{ TjanLogic }

constructor TjanLogic.Create(AOwner: TComponent);
var i:integer;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatPoort := stPoortStop;
  FType:='EN';
  width:=100;
  height:=68;
  // initialize Gates
  FGates[0].pos:=point(1,10);
  FGates[1].pos:=point(1,28);
  FGates[2].pos:=point(1,46);
  FGates[3].pos:=point(52,10);
  FGates[4].pos:=point(52,28);
  FGates[5].pos:=point(52,46);
  for i:=0 to 5 do
    FGates[i].State:=false;
  for i:=0 to 2 do
  begin
    FGates[i].style:=jgsDI;
    FGates[i+3].style:=jgsDO;
  end;
  FLogicAndFunc:=jlfAND;
  FGates[0].Active:=true;
  FGates[1].Active:=false;
  FGates[2].Active:=true;
  FGates[3].Active:=false;
  FGates[4].Active:=true;
  FGates[5].Active:=false;
  connectors:=TList.create;
  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');
  lIn.Transparent := True;
  lIn.TransParentColor := lIn.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'LOG_UIT');
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  FTaal:='NL';
  FInfo:= 'Logische poort';
  FSoort:= 'Verwerking';
  FNaam:= 'Logische Poort';
  FDown:=False;
  ShowHint:=true;
  FLock:=false;
  FPcolor:=rgb(250,250,150);
end;

function TjanLogic.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanLogic.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  doMove := False;
  doStyle := False;
  StyleDown := False;
  mdp := Point(X, Y);

  R := Rect(90,25,100,40);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 9;
    T := Top + 31;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(22,20,65,45);
  doStyle := PtInRect(R2, mdp);
  doMove := not doStyle;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end;

  if doStyle then
  begin
    StyleDown := True;
    Invalidate;
  end;

  UpdateHintText;
end;

procedure TjanLogic.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
      UpdateHintText;
    end;
  end;
end;

procedure TjanLogic.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  FDepressed := False;
  Select := False;
  Invalidate;

  if FLock = True then Exit;

  StyleDown := False;
  FMouseOver := True;
  SendStatusToBar;
end;


procedure TjanLogic.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,0);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

procedure TjanLogic.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
   if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanLogic.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2

  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
  exit;
  //If FOutPut2=true then Hint:= FInfo  + #13#10  +'Status = 1'; //test
  //If FOutPut2=false then Hint:= FInfo + #13#10  +'Status = 0';

end;



procedure TjanLogic.BuildPopup;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;

  // --- Lock / Unlock
  miLock := TMenuItem.Create(PopupMenu);
  miLock.Name := 'miLock';
  miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miLock);

  // --- Naam wijzigen
  miName := TMenuItem.Create(PopupMenu);
  miName.Name := 'miName';
  miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miName);

  // --- Info aan/uit
  miInfo := TMenuItem.Create(PopupMenu);
  miInfo.Name := 'miInfo';
  miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miInfo);

  // --- Selecteer voor verwijdering
  miSelect := TMenuItem.Create(PopupMenu);
  miSelect.Name := 'miSelect';
  miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miSelect);
end;



procedure TjanLogic.UpdatePopupCaptions;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
  s: string;
begin
  if not Assigned(PopupMenu) then Exit;

  miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
  miName   := TMenuItem(PopupMenu.FindComponent('miName'));
  miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
  miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

  // --- Lock / Unlock
  if Assigned(miLock) then
  begin
    if BTaal = 'NL' then
    begin
      if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
    end
    else if BTaal = 'FR' then
    begin
      if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
    end
    else if BTaal = 'DU' then
    begin
      if FLock then s := 'Entsperren' else s := 'Sperren';
    end
    else
    begin
      if FLock then s := 'UnLock' else s := 'Lock';
    end;
    miLock.Caption := s;
  end;

  // --- Naam wijzigen
  if Assigned(miName) then
  begin
    if BTaal = 'NL' then s := 'Wijzig Naam'
    else if BTaal = 'FR' then s := 'Changer le nom'
    else if BTaal = 'DU' then s := 'Namen ändern'
    else s := 'Change name';
    miName.Caption := s;
  end;

  // --- Select / Deselect (TOGGLE)
  if Assigned(miSelect) then
  begin
    if not Selected then
    begin
      if BTaal = 'NL' then s := 'Selecteer object'
      else if BTaal = 'FR' then s := 'Sélectionner un objet'
      else if BTaal = 'DU' then s := 'Objekt auswählen'
      else s := 'Select object';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Deselecteer object'
      else if BTaal = 'FR' then s := 'Désélectionner l''objet'
      else if BTaal = 'DU' then s := 'Objekt abwählen'
      else s := 'Deselect object';
    end;
    miSelect.Caption := s;
  end;

  // --- Info aan/uit
  if Assigned(miInfo) then
  begin
    if ShowHint then
    begin
      if BTaal = 'NL' then s := 'Info uit'
      else if BTaal = 'FR' then s := 'Infos off'
      else if BTaal = 'DU' then s := 'Infos aus'
      else s := 'Information off';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Info aan'
      else if BTaal = 'FR' then s := 'Infos on'
      else if BTaal = 'DU' then s := 'Infos an'
      else s := 'Information on';
    end;
    miInfo.Caption := s;
  end;
end;


procedure TjanLogic.PaintLed(index:integer);
var surfcol,litcol:Tcolor;
    p:Tpoint;
    x,y:integer;
    lit:boolean;
begin
  if not Gates[index].Active then exit;
  p:=Gates[index].pos;
  x:=(p.x)+23; //23 bijgevoegd om de leds naar rechts te verschuiven
  y:=(p.y);
  if index=0 then
    lit:=FInput1
  else if index=1 then
    lit:=Finput2
  else if index=2 then
    lit:=Finput3
  else if index=3 then
    lit:=Foutput1
  else if index=4 then
    lit:=Foutput2     // deze output is de normale uit
  else if index=5 then
    lit:=Foutput3;
  if lit then
  begin
    if Gates[index].Style=jgsDI then
      surfcol:=cllime
    else
      surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    if Gates[index].Style=jgsDI then
    begin
      surfcol:=clgreen;
      litcol:=cllime;  //led uit
    end
    else begin
      surfcol:=clmaroon;
      litcol:=clred; // led aan
    end;
  end;
  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    pen.color:=clgray;
    // tekenen van de aansluitingen
    If index=4 then
       begin
       lUit.Transparent := True;
       draw(x-10,y+1,lUit);
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       brush.color:=surfcol;
       ellipse(x+1,y+1,x+11,y+12);
       pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
       pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
       end
       else
       begin
       lIn.Transparent := True;
       draw(x-23,y,lIn);
       end;

     UnLock;
   end;
end;


procedure TjanLogic.Paint;
var i:integer;
    p:Tpoint;
    lit:boolean;
    R:TRect;
    s:string;
begin
   with canvas do
   begin
     Lock;
     brush.color:=FPcolor;
     R:=rect(22,5,65,63);//ClientRect;
     Fillrect(R);
     Frame3D(R,clbtnhighlight,clbtnshadow,1);
     brush.color:=clred;
     for i:=0 to 5 do
       PaintLed(i);
     R:=ClientRect;
     inflaterect(R,0,0);
     // draw caption
     case FLogicAndFunc of
       jlfAND: begin
               If BTaal='NL' then s:='EN';
               If BTaal='ENG' then s:='AND';
               If BTaal='FR' then s:='ET';
               If BTaal='DU' then s:='UND';
               end;
       jlfOR : begin
               If BTaal='NL' then s:='OF';
               If BTaal='ENG' then s:='OR';
               If BTaal='FR' then s:='OU';
               If BTaal='DU' then s:='ODER';
               end;
       jlfNOT: begin
               If BTaal='NL' then s:='NIET';
               If BTaal='ENG' then s:='NOT';
               If BTaal='FR' then s:='PAS';
               If BTaal='DU' then s:='NICHT';
               end;
     end;
     R:=rect(0,0,85,65);//ClientRect;
     brush.style:=bsclear;
     drawtext(canvas.handle,pchar(s),-1,R,DT_SINGLELINE or DT_CENTER or DT_VCENTER);

     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     If FLogicAndFunc=(jlfAND) then
     Begin
     TextOut(1,20,'A1');
     TextOut(90,38,'A');
     TextOut(1,56,'A2');
     end;
     If FLogicAndFunc=(jlfOR) then
     Begin
     TextOut(1,20,'O1');
     TextOut(90,38,'O');
     TextOut(1,56,'O2');
     end;
     If FLogicAndFunc=(jlfNOT) then
     Begin
     TextOut(1,38,'N1');
     TextOut(90,38,'N');
     end;
     Unlock;
     if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
     if FSelected then
     begin
      R := ClientRect;
     Canvas.Brush.Style := bsClear;
     Canvas.Pen.Color := clRed;
     Canvas.pen.style:=psDot;
     Canvas.Pen.Width := 1;
     Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
     end;
   end;
end;



procedure TjanLogic.Resize;
begin
  width:=100;
  height:=68;
end;



destructor TjanLogic.Destroy;
begin
  lIn.Free;
  lUit.Free;
  Connectors.Free;
  inherited;

end;
procedure TjanLogic.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanLogic.OutCalc;
begin
  case FLogicAndFunc of
  jlfAND: OutPut2:=Input1 and Input3;
  jlfOR : OutPut2:=Input1 or Input3;
  jlfNOT: OutPut2:=not Input2;
  end;

end;

procedure TjanLogic.SetInput1(const Value: boolean);
begin
  if value<>FInput1 then
  begin
    FInput1 := Value;
    invalidate;
    OutCalc;
  end;
end;

procedure TjanLogic.SetInput2(const Value: boolean);
begin
  if value<>FInput2 then
  begin
    FInput2 := Value;
    invalidate;
    OutCalc;
  end;

end;


procedure TjanLogic.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
     // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
  invalidate;
end;

procedure TjanLogic.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanLogic.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanLogic.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanLogic.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
   UpdateHintText;
end;

procedure TjanLogic.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanLogic.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanLogic.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
    OutCalc;
  end;
end;

procedure TjanLogic.SetOutPut1(const Value: boolean);
begin
  if value<>FOutput1 then
  begin
    FOutPut1 := Value;
    invalidate;
  end;
end;

procedure TjanLogic.SetOutPut2(const Value: boolean);
begin
  if value<>FOutput2 then
  begin
    FOutPut2 := Value;
    if FOutPut2=true then FStatPoort := stPoortStart else FStatPoort := stPoortStop;
    invalidate;

  end;
  if Assigned(OnPoortOutChange) then OnPoortOutChange(Self, StatPoort);
end;

procedure TjanLogic.SetOutPut3(const Value: boolean);
begin
  if value<>FOutput3 then
  begin
    FOutPut3 := Value;
    invalidate;
  end;

end;
procedure TjanLogic.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;

procedure TjanLogic.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanLogic.SetNaam(const Value: String);
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

function TjanLogic.GetLogicFuncText: string;
begin
  case LogicFunc of
    jlfAND:
      Result := Tr(BTaal,'EN','AND','ET','UND');

    jlfOR:
      Result := Tr(BTaal,'OF','OR','OU','ODER');

    jlfNOT:
      Result := Tr(BTaal,'NIET','NOT','NON','NICHT');

  else
    Result := '';
  end;
end;


procedure TjanLogic.SendStatusToBar;
var
   s, ss: string;
  // wInput:String;
   wStatus: string;

 begin
   if not Assigned(FOnStatus) then Exit;
//   wInput  := Tr(BTaal,'Verwerking','Processing','Traitement','Verarbeitung');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0  gebruikt function TjanLogic.GetLogicFuncText: string;
    if LogicFunc =jlfAND then
      FOnStatus(Self, FNaam + '(EN-AND) > ', 0);
    if LogicFunc =jlfOR then
      FOnStatus(Self, FNaam + '(OF-OR) > ', 0);
    if LogicFunc =jlfNOT then
      FOnStatus(Self, FNaam + '(NIET-NOT) > ', 0);
   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;


procedure TjanLogic.SetTaal(const Value: String);
begin

  if value<>FTaal then
  begin
    FTaal:= Value;
 end;


// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
    UpdateHintText;
    invalidate;
end;

procedure TjanLogic.SetType(const Value: String);
begin
  if value<>FType then
  begin
    FType := Value;
  invalidate;
  end;

end;

procedure TjanLogic.SetLogicFunc(const Value: TjanLogicFunc);
begin
  if value<>FLogicAndFunc then
  begin
    FLogicAndFunc := Value;
    case FLogicAndFunc of
    jlfAND:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='EN';
      end;
    jlfOR:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='OF';
      end;
    jlfNOT:
      begin
        FGates[0].Active:=false;
        FGates[1].Active:=true;
        FGates[2].Active:=false;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='NIET';
      end;
    end;
    invalidate;
    OutCalc;
  end;
end;


{ TjanTeller }

constructor TjanTeller.Create(AOwner: TComponent);
var
i:integer;
XX, YY: Integer;
PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStat1 := stBit1Stop;
  FStat2 := stBit2Stop;
  FStat4 := stBit4Stop;
  FStat8 := stBit8Stop;
  width:=150;  height:=84;
  // initialize (imputs)
  FGates[0].pos:=point(1,10); FGates[0].Active:=true;    // reset
  FGates[1].pos:=point(1,46); FGates[1].Active:=true;    // telimpuls
  // initialize (outputs)
  FGates[2].pos:=point(30,80);  FGates[2].Active:=true;  // Bit8
  FGates[3].pos:=point(55,80);  FGates[3].Active:=true;  // Bit4
  FGates[5].pos:=point(80,80);  FGates[5].Active:=true;  // Bit2
  FGates[6].pos:=point(105,80); FGates[6].Active:=true;  // Bit1

  FGates[4].pos:=point(52,28);  FGates[4].Active:=true;  // naar display

  connectors:=TList.create;

  Uit:=TBitmap.create;
  Uit.LoadFromResourceName(HInstance,'UIT');

  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');

  for YY := 0 to lIn.Height - 1 do
      for XX := 0 to lIn.Width - 1 do
      begin
        PixelColor := lIn.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lIn.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lIn.Transparent := True;
  lIn.TransParentColor := clFuchsia;//:= lIn.canvas.pixels[0,0];

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'T_UIT');
  for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lUit.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;//:= lUit.canvas.pixels[0,0];

  lBitUit:=TBitmap.Create;
  lBitUit.LoadFromResourceName(HInstance,'TBITUIT');
  for YY := 0 to lBitUit.Height - 1 do
      for XX := 0 to lBitUit.Width - 1 do
      begin
        PixelColor := lBitUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lBitUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lBitUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;//:= lBitUit.canvas.pixels[0,0];

  FLock:=false;
  FPcolor:=rgb(250,250,150);
  FBits:=0;FBitsChar:='0';
  FLedColUit:=clMaroon;
  FLedColAan:=clred;

 // FTaal:='NL';
  FInfo:= 'TellerBlok';
  ShowHint:=true;
  FSoort:='Verwerking';
  FNaam:='TellerBlok';
end;

function TjanTeller.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanTeller.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, R2, Rb8, Rb4, Rb2, Rb1: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  doMove := False;
  StyleDown := False;
  mdp := Point(X, Y);

  Rb8 := Rect(30,75,40,84); // aansluitplaats Bit8
  if PtInRect(Rb8, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 33;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb4 := Rect(55,75,65,84); // aansluitplaats Bit4
  if PtInRect(Rb4, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 58;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb2 := Rect(80,75,105,84); // aansluitplaats Bit2
  if PtInRect(Rb2, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 83;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb1 := Rect(105,75,130,84); // aansluitplaats Bit1
  if PtInRect(Rb1, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 108;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  R := Rect(135,40,150,50); // aansluitplaats display
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 41;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  // einde van het maken van een aansluiting
  Screen.Cursor := crDefault;

  R2 := Rect(22,20,65,45);
  doStyle := PtInRect(R2, mdp);
  doMove := not doStyle;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end;

  if doStyle then
  begin
    StyleDown := True;
    Invalidate;
  end;
end;

procedure TjanTeller.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanTeller.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Invalidate;

  if FLock = True then Exit;

  StyleDown := False;
  FMouseOver := True;
  SendStatusToBar;
end;



procedure TjanTeller.BuildPopup;
          var
          miLock, miName, miInfo, miSelect: TMenuItem;
         begin
           if not Assigned(PopupMenu) then
             PopupMenu := TPopupMenu.Create(Self)
           else
             PopupMenu.Items.Clear;
           // --- Lock / Unlock
            miLock := TMenuItem.Create(PopupMenu);
            miLock.Name := 'miLock';
            miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
            PopupMenu.Items.Add(miLock);

           // --- Naam wijzigen
            miName := TMenuItem.Create(PopupMenu);
            miName.Name := 'miName';
            miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
            PopupMenu.Items.Add(miName);

           // --- Info aan/uit
            miInfo := TMenuItem.Create(PopupMenu);
            miInfo.Name := 'miInfo';
            miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
            PopupMenu.Items.Add(miInfo);

            // --- Selecteer voor verwijdering
            miSelect := TMenuItem.Create(PopupMenu);
            miSelect.Name := 'miSelect';
            miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
            PopupMenu.Items.Add(miSelect);
         end;

  procedure TjanTeller.UpdatePopupCaptions;
         var
           miLock, miName, miInfo, miSelect: TMenuItem;
           s: string;
         begin
           if not Assigned(PopupMenu) then Exit;

           miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
           miName   := TMenuItem(PopupMenu.FindComponent('miName'));
           miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
           miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

           // --- Lock / Unlock
           if Assigned(miLock) then
           begin
             if BTaal = 'NL' then
             begin
               if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
             end
             else if BTaal = 'FR' then
             begin
               if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
             end
             else if BTaal = 'DU' then
             begin
               if FLock then s := 'Entsperren' else s := 'Sperren';
             end
             else
             begin
               if FLock then s := 'Unlock' else s := 'lock';
             end;
             miLock.Caption := s;
           end;

           // --- Naam wijzigen
           if Assigned(miName) then
           begin
             if BTaal = 'NL' then s := 'Wijzig Naam'
             else if BTaal = 'FR' then s := 'Changer le nom'
             else if BTaal = 'DU' then s := 'Namen ändern'
             else s := 'Change name';
             miName.Caption := s;
           end;

           // --- Select / Deselect (TOGGLE)
           if Assigned(miSelect) then
           begin
             if not Selected then
             begin
               if BTaal = 'NL' then s := 'Selecteer object'
               else if BTaal = 'FR' then s := 'Sélectionner un objet'
               else if BTaal = 'DU' then s := 'Objekt auswählen'
               else s := 'Select object';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Deselecteer object'
               else if BTaal = 'FR' then s := 'Désélectionner l''objet'
               else if BTaal = 'DU' then s := 'Objekt abwählen'
               else s := 'Deselect object';
             end;
             miSelect.Caption := s;
           end;

           // --- Info aan/uit
           if Assigned(miInfo) then
           begin
             if ShowHint then
             begin
               if BTaal = 'NL' then s := 'Info uit'
               else if BTaal = 'FR' then s := 'Infos off'
               else if BTaal = 'DU' then s := 'Infos aus'
               else s := 'Information off';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Info aan'
               else if BTaal = 'FR' then s := 'Infos on'
               else if BTaal = 'DU' then s := 'Infos an'
               else s := 'Information on';
             end;
             miInfo.Caption := s;
           end;
         end;

procedure TjanTeller.UpdateHintText;
begin
    Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanTeller.SendStatusToBar;//xxx
  var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  //FOnStatus(Self, FNaam + ' > ', 0);
    FOnStatus(Self, FNaam + ' > ', 0);
   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
end;

procedure TjanTeller.SetNaam(const Value: String);//xxxx
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanTeller.SetTaal(const Value: String);
begin
   if Value <> FTaal then
    FTaal := Value;

  if Value = 'NL' then FInfo := 'Verwerking --> Tellerblok'
  else if Value = 'ENG' then FInfo := 'Processing --> Counter block'
  else if Value = 'FR' then FInfo := 'Traitement --> Bloc compteur'
  else if Value = 'DU' then FInfo := 'Verarbeitung --> Zählerblock';

  UpdateHintText;
  Invalidate;

  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanTeller.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  if not FMouseOver then Exit;     // kleine guard
     FMouseOver := False;

 // ✅ statusbar leegmaken (zoals bij TjanSimButton)
 if Assigned(FOnStatus) then
 begin
   FOnStatus(Self, '', 0);
   FOnStatus(Self, '', 1);
   FOnStatus(Self, '', 2);
   FOnStatus(Self, '', 3);
 end;
 if Flock=false then begin select:=false;invalidate;end;

end;

procedure TjanTeller.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
   UpdateHintText;
 if Assigned(FOnEnter) then
    FOnEnter(Self);


 // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2


  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;


procedure TjanTeller.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
  { //if Flock=true then exit;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;}
end;

procedure TjanTeller.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,0);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;




procedure TjanTeller.PaintLed8(status:Integer);
var
x,y:Integer;
Begin
x:=30;y:=43;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 8
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat8 := stBit8Start;  end
          else
          begin brush.color:=FLedColUit;FStat8 := stBit8Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=clwhite;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  UnLock;
  end;
  if Assigned(OnBit8Change) then OnBit8Change(Self, Stat8);
end;

procedure TjanTeller.PaintLed4(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=55;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 4
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat4 := stBit4Start; end
          else
          begin brush.color:=FLedColUit;FStat4 := stBit4Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
  if Assigned(OnBit4Change) then OnBit4Change(Self, Stat4);
end;

procedure TjanTeller.PaintLed2(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=80;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 2
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat2 := stBit2Start;end
          else
          begin brush.color:=FLedColUit;FStat2 := stBit2Stop;end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   UnLock;
   end;
  if Assigned(OnBit2Change) then OnBit2Change(Self, Stat2);
end;

procedure TjanTeller.PaintLed1(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=105;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 1
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat1 := stBit1Start; end
          else
          begin brush.color:=FLedColUit;FStat1 := stBit1Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
if Assigned(OnBit1Change) then OnBit1Change(Self, Stat1);
end;


procedure TjanTeller.PaintLeds(bit:Integer);
begin
 PaintLed1(0);PaintLed2(0);PaintLed4(0);PaintLed8(0);
 if bit=0 then begin end;
 If bit=1 then begin PaintLed1(1);exit;end;
 If bit=2 then begin PaintLed2(1);exit;end;
 If bit=3 then begin PaintLed1(1);PaintLed2(1);exit;end;
 If bit=4 then begin PaintLed4(1);exit;end;
 If bit=5 then begin PaintLed1(1);PaintLed4(1);exit;end;
 If bit=6 then begin PaintLed2(1);PaintLed4(1);exit;end;
 If bit=7 then begin PaintLed1(1);PaintLed2(1);PaintLed4(1);exit;end;
 If bit=8 then begin PaintLed8(1);exit;end;
 If bit=9 then begin PaintLed1(1);PaintLed8(1);exit;end;
 If bit=10 then begin PaintLed2(1);PaintLed8(1);exit;end;
 If bit=11 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=12 then begin PaintLed4(1);PaintLed8(1);exit;end;
 If bit=13 then begin PaintLed4(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=14 then begin PaintLed2(1);PaintLed4(1);PaintLed8(1);exit;end;
 If bit=15 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);PaintLed4(1);exit;end;
end;


procedure TjanTeller.Paint;
var
i:integer;
R:TRect;
begin
 lIn.Transparent:=true;
 lUit.Transparent:=true;
 lBitUit.Transparent:=true;
 Uit.Transparent:=true;
   with canvas do
   begin
   Lock;
     brush.color:=FPcolor;
     R:=rect(22,15,125,65);
     Fillrect(R);
     Frame3D(R,clbtnhighlight,clbtnshadow,1);
     PaintLeds(FBits);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=8;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,20,'Re');TextOut(1,68,'Te');
     TextOut(31,16,'T');TextOut(55,16,'T');TextOut(79,16,'T');TextOut(103,16,'T');
     Font.Size:=7;
     TextOut(39,19,'8');TextOut(63,19,'4');TextOut(87,18,'2');TextOut(111,18,'1');
     pen.Color:=clSilver;
     MoveTo(48,15);LineTo(48,height-20);MoveTo(72,15);LineTo(72,height-20);MoveTo(96,15);LineTo(96,height-20);
     lUit.Transparent := True;
     draw(126,40,lUit);
     draw(0,10,lIn);
     draw(0,50,lIn);
     draw(0,height-30,lIn);
     draw(31,74,Uit);draw(56,74,Uit);draw(81,74,Uit);draw(106,74,Uit);
     draw(31,50,lBitUit);draw(56,50,lBitUit);draw(81,50,lBitUit);draw(106,50,lBitUit);
    Unlock;
   end;
   if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
   if Selected then
   Begin
     R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen
     canvas.Brush.Style := bsClear;
     canvas.Pen.Color := clRed;
     canvas.pen.style:=psDot;
     canvas.Pen.Width := 1;
     canvas.Rectangle(R);
    // restore (netjes)
     canvas.Pen.Width := 1;
     canvas.pen.style:=psSolid;
     canvas.Brush.Style := bsSolid;
  end;
end;



procedure TjanTeller.Resize;
begin
  width:=150;
  height:=84;
end;

destructor TjanTeller.Destroy;
begin
  uit.Free;
  lIn.Free;
  lUit.Free;
  lBitUit.Free;
  Connectors.Free;
  inherited;

end;

procedure TjanTeller.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;



procedure TjanTeller.SetInput1(const Value: boolean);
begin
  if value=true then
  begin
    FBits := 0;FBitsChar:='0';
    FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
    invalidate;
 end;
FInput1:=false;
end;

procedure TjanTeller.SetLoop(const Value: boolean);
begin
  FLoop := value;
  if value=true then
  begin
     inc(FBits);
     If FBits > 15 then FBits:=0;
     If FBits=0 then
        begin FBitsChar:='0';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=1 then
        begin FBitsChar:='1';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=2 then
        begin FBitsChar:='2';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=3 then
        begin FBitsChar:='3';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=4 then
        begin FBitsChar:='4';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=5 then
        begin FBitsChar:='5';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=6 then
        begin FBitsChar:='6';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=7 then
        begin FBitsChar:='7';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=8 then
        begin FBitsChar:='8';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=9 then
        begin FBitsChar:='9';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=10 then
        begin FBitsChar:='A';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=11 then
        begin FBitsChar:='B';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=12 then
        begin FBitsChar:='C';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=13 then
        begin FBitsChar:='D';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=14 then
        begin FBitsChar:='E';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=15 then
        begin FBitsChar:='F';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
  end;
end;
{
procedure TjanTeller.tellerClick(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanTeller.tellerClick2(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;}

//new
procedure TjanTeller.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanTeller.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanTeller.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanTeller.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanTeller.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanTeller.SetBits(const Value:Integer);
begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then FBitsChar:='0';
     If FBits=1 then FBitsChar:='1';
     If FBits=2 then FBitsChar:='2';
     If FBits=3 then FBitsChar:='3';
     If FBits=4 then FBitsChar:='4';
     If FBits=5 then FBitsChar:='5';
     If FBits=6 then FBitsChar:='6';
     If FBits=7 then FBitsChar:='7';
     If FBits=8 then FBitsChar:='8';
     If FBits=9 then FBitsChar:='9';
     If FBits=10 then FBitsChar:='A';
     If FBits=11 then FBitsChar:='B';
     If FBits=12 then FBitsChar:='C';
     If FBits=13 then FBitsChar:='D';
     If FBits=14 then FBitsChar:='E';
     If FBits=15 then FBitsChar:='F';
  end;
  invalidate;
end;

procedure TjanTeller.SetBitsChar(const Value:Char);
begin
  if value <> FBitsChar then
  begin
    FBitsChar := Value;
  end;
  invalidate;
end;

procedure TjanTeller.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanTeller.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
  end;
end;



procedure TjanTeller.SetOutPutDisplay(const Value: boolean);
begin
  if value <> FOutputDisplay then
  begin
    FOutPutDisplay := Value;
  end;
invalidate;
end;
procedure TjanTeller.SetOutPutBit1(const Value: boolean);
begin
  if value <> FOutputBit1 then
  begin
    FOutPutBit1 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit2(const Value: boolean);
begin
  if value <> FOutputBit2 then
  begin
    FOutPutBit2 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit4(const Value: boolean);
begin
  if value <> FOutputBit4 then
  begin
    FOutPutBit4 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit8(const Value: boolean);
begin
  if value <> FOutputBit8 then
  begin
    FOutPutBit8 := Value;
  end;
end;
procedure TjanTeller.SetOutPutBits(const Value: boolean);
begin

end;

procedure TjanTeller.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;
procedure TjanTeller.SetLedColUit(const Value: TColor);
begin
  if value<>FLedColUit then
  begin
    FLedColUit := Value;
    invalidate;
  end;
end;

procedure TjanTeller.SetLedColAan(const Value: TColor);
begin
  if value<>FLedColAan then
  begin
    FLedColAan := Value;
    invalidate;
  end;
end;

procedure TjanTeller.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;
  // puls:=1;
   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
 end;

//-----TjanMemory
constructor TjanMemory.Create(AOwner: TComponent);
var
    i,YY,XX:integer;
    PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  schrijf:=false;
  lijst:=TStringList.Create;
  //for i:= 0 to 15 do  lijst.Add('0');
  for i:= 0 to 31 do  lijst.Add('0');
  FStatMem1 := stBitMem1Stop;FStatMem2 := stBitMem2Stop;FStatMem4 := stBitMem4Stop;
  FStatMem8 := stBitMem8Stop;FStatMemB := stMemButtonStop;
  width:=200;height:=155;
  // initialize (imputs)
  FGates[0].pos:=point(120,64); FGates[0].Active:=true;   // imput vanuit dipswitsh
  FGates[1].pos:=point(80,33); FGates[1].Active:=true;    // imput adress bit8
  FGates[7].pos:=point(105,33); FGates[7].Active:=true;   // imput adress bit4
  FGates[8].pos:=point(130,33); FGates[8].Active:=true;   // imput adress bit2
  FGates[9].pos:=point(155,33); FGates[9].Active:=true;   // imput adress bit1
   // initialize (outputs)

  FGates[2].pos:=point(81,138);   FGates[2].Active:=true;  // Bit8
  FGates[3].pos:=point(106,138);  FGates[3].Active:=true;  // Bit4
  FGates[4].pos:=point(191,90);  FGates[4].Active:=true;  // naar display
  FGates[5].pos:=point(134,138);  FGates[5].Active:=true;  // Bit2
  FGates[6].pos:=point(156,138);  FGates[6].Active:=true;  // Bit1
  connectors:=TList.create;

///--------
  lAcoo:=TBitmap.create;
   lAcoo.LoadFromResourceName(HInstance,'ACO0');
      // Loop door alle pixels van de afbeelding
    for YY := 0 to lAcoo.Height - 1 do
      for XX := 0 to lAcoo.Width - 1 do
      begin
        PixelColor := lAcoo.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAcoo.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
   lAcoo.Transparent := True;
   lAcoo.TransParentColor := clFuchsia; //lAco.canvas.pixels[0,0];
///--------
  Bin:=TBitmap.create;
  Bin.LoadFromResourceName(HInstance,'BINUIT');
   // Loop door alle pixels van de afbeelding
    for YY := 0 to Bin.Height - 1 do
      for XX := 0 to Bin.Width - 1 do
      begin
        PixelColor := Bin.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Bin.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  Bin.Transparent := True;
  Bin.TransParentColor := clFuchsia;//Bin.canvas.pixels[0,0];
///--------
  BinAan:=TBitmap.create;
  BinAan.LoadFromResourceName(HInstance,'BINAAN');
  BinAan.Transparent := True;
  BinAan.TransParentColor := BinAan.canvas.pixels[0,0];
  Uit:=TBitmap.create;
  Uit.LoadFromResourceName(HInstance,'UIT');
  Inv:=TBitmap.create;
  Inv.LoadFromResourceName(HInstance,'IN');

  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');
  lIn.Transparent := True;
  lIn.TransParentColor := lIn.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'T_UIT');
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  lBitUit:=TBitmap.Create;
  lBitUit.LoadFromResourceName(HInstance,'MUIT');
  lBitUit.Transparent := True;
  lBitUit.TransParentColor := lBitUit.canvas.pixels[0,0];

  lBitUit1:=TBitmap.Create;
  lBitUit1.LoadFromResourceName(HInstance,'MUIT1');
  lBitUit1.Transparent := True;
  lBitUit1.TransParentColor := lBitUit1.canvas.pixels[0,3];

  FConnector:=true;
  FLock:=false;
  FPcolor:=rgb(250,250,150);
  FBits:=0;FBitsChar:='0';
  FLedColUit:=clMaroon;
  FLedColAan:=clred;
  FDown:=false;
  FInfo:= 'Geheugenblok';
  ShowHint:=true;
 // FTaal:='NL';
  FSoort:='Verwerking';
  FNaam:='Geheugenblok';
end;

function TjanMemory.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanMemory.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, Rb8, Rb4, Rb2, Rb1, Rb: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  doMove := False;
  mdp := Point(X, Y);

  Rb := Rect(17,12,30,37);
  doMove := not PtInRect(Rb, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;

  Rb8 := Rect(81,138,90,148); // aansluitplaats Bit8
  if PtInRect(Rb8, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 82;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb4 := Rect(106,138,116,148); // aansluitplaats Bit4
  if PtInRect(Rb4, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 107;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb2 := Rect(134,138,144,148); // aansluitplaats Bit2
  if PtInRect(Rb2, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 132;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb1 := Rect(156,138,166,148); // aansluitplaats Bit1
  if PtInRect(Rb1, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 157;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  R := Rect(191,90,199,100); // aansluitplaats display
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 192;
    T := Top + 91;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;
end;

procedure TjanMemory.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanMemory.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;
  FDepressed := False;
  SendStatusToBar;

  p := Point(X, Y);
  R := Rect(17,12,30,37);
  if PtInRect(R, p) then
    ButtonDown := not FDown;
end;


procedure TjanMemory.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  if not FMouseOver then Exit;     // kleine guard
     FMouseOver := False;

 // ✅ statusbar leegmaken (zoals bij TjanSimButton)
 if Assigned(FOnStatus) then
 begin
   FOnStatus(Self, '', 0);
   FOnStatus(Self, '', 1);
   FOnStatus(Self, '', 2);
   FOnStatus(Self, '', 3);
 end;
 if Flock=false then begin select:=false;invalidate;end;

end;

procedure TjanMemory.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
 if Assigned(FOnEnter) then
    FOnEnter(Self);


 // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2


  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;

procedure TjanMemory.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   //if Flock=true then exit;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;

procedure TjanMemory.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,0);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;



procedure TjanMemory.BuildPopup;
         var
         miLock, miName, miInfo, miSelect: TMenuItem;
        begin
          if not Assigned(PopupMenu) then
            PopupMenu := TPopupMenu.Create(Self)
          else
            PopupMenu.Items.Clear;
          // --- Lock / Unlock
           miLock := TMenuItem.Create(PopupMenu);
           miLock.Name := 'miLock';
           miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miLock);

          // --- Naam wijzigen
           miName := TMenuItem.Create(PopupMenu);
           miName.Name := 'miName';
           miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miName);

          // --- Info aan/uit
           miInfo := TMenuItem.Create(PopupMenu);
           miInfo.Name := 'miInfo';
           miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miInfo);

           // --- Selecteer voor verwijdering
           miSelect := TMenuItem.Create(PopupMenu);
           miSelect.Name := 'miSelect';
           miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miSelect);
        end;

 procedure TjanMemory.UpdatePopupCaptions;
        var
          miLock, miName, miInfo, miSelect: TMenuItem;
          s: string;
        begin
          if not Assigned(PopupMenu) then Exit;

          miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
          miName   := TMenuItem(PopupMenu.FindComponent('miName'));
          miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
          miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

          // --- Lock / Unlock
          if Assigned(miLock) then
          begin
            if BTaal = 'NL' then
            begin
              if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
            end
            else if BTaal = 'FR' then
            begin
              if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
            end
            else if BTaal = 'DU' then
            begin
              if FLock then s := 'Entsperren' else s := 'Sperren';
            end
            else
            begin
              if FLock then s := 'Unlock' else s := 'lock';
            end;
            miLock.Caption := s;
          end;

          // --- Naam wijzigen
          if Assigned(miName) then
          begin
            if BTaal = 'NL' then s := 'Wijzig Naam'
            else if BTaal = 'FR' then s := 'Changer le nom'
            else if BTaal = 'DU' then s := 'Namen ändern'
            else s := 'Change name';
            miName.Caption := s;
          end;

          // --- Select / Deselect (TOGGLE)
          if Assigned(miSelect) then
          begin
            if not Selected then
            begin
              if BTaal = 'NL' then s := 'Selecteer object'
              else if BTaal = 'FR' then s := 'Sélectionner un objet'
              else if BTaal = 'DU' then s := 'Objekt auswählen'
              else s := 'Select object';
            end
            else
            begin
              if BTaal = 'NL' then s := 'Deselecteer object'
              else if BTaal = 'FR' then s := 'Désélectionner l''objet'
              else if BTaal = 'DU' then s := 'Objekt abwählen'
              else s := 'Deselect object';
            end;
            miSelect.Caption := s;
          end;

          // --- Info aan/uit
          if Assigned(miInfo) then
          begin
            if ShowHint then
            begin
              if BTaal = 'NL' then s := 'Info uit'
              else if BTaal = 'FR' then s := 'Infos off'
              else if BTaal = 'DU' then s := 'Infos aus'
              else s := 'Information off';
            end
            else
            begin
              if BTaal = 'NL' then s := 'Info aan'
              else if BTaal = 'FR' then s := 'Infos on'
              else if BTaal = 'DU' then s := 'Infos an'
              else s := 'Information on';
            end;
            miInfo.Caption := s;
          end;
        end;

procedure TjanMemory.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanMemory.PaintLed8(status:Integer);
var
x,y:Integer;
Begin
x:=80;y:=47+50-4;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 8
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem8 := stBitMem8Start;  end
          else
          begin brush.color:=FLedColUit;FStatMem8 := stBitMem8Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=clwhite;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
  if Assigned(OnBitMem8Change) then OnBitMem8Change(Self, StatMem8);
end;

procedure TjanMemory.PaintLed4(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=105;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 4
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem4 := stBitMem4Start; end
          else
          begin brush.color:=FLedColUit;FStatMem4 := stBitMem4Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  Unlock;
  end;
  if Assigned(OnBitMem4Change) then OnBitMem4Change(Self, StatMem4);
end;

procedure TjanMemory.PaintLed2(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=130;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 2
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem2 := stBitMem2Start;end
          else
          begin brush.color:=FLedColUit;FStatMem2 := stBitMem2Stop;end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  Unlock;
  end;
  if Assigned(OnBitMem2Change) then OnBitMem2Change(Self, StatMem2);
end;

procedure TjanMemory.PaintLed1(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=155;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 1
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem1 := stBitMem1Start; end
          else
          begin brush.color:=FLedColUit;FStatMem1 := stBitMem1Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
if Assigned(OnBitMem1Change) then OnBitMem1Change(Self, StatMem1);
end;


procedure TjanMemory.PaintLeds(bit:Integer);
begin
 PaintLed1(0);PaintLed2(0);PaintLed4(0);PaintLed8(0);
 If bit=1 then begin PaintLed1(1);exit;end;
 If bit=2 then begin PaintLed2(1);exit;end;
 If bit=3 then begin PaintLed1(1);PaintLed2(1);exit;end;
 If bit=4 then begin PaintLed4(1);exit;end;
 If bit=5 then begin PaintLed1(1);PaintLed4(1);exit;end;
 If bit=6 then begin PaintLed2(1);PaintLed4(1);exit;end;
 If bit=7 then begin PaintLed1(1);PaintLed2(1);PaintLed4(1);exit;end;
 If bit=8 then begin PaintLed8(1);exit;end;
 If bit=9 then begin PaintLed1(1);PaintLed8(1);exit;end;
 If bit=10 then begin PaintLed2(1);PaintLed8(1);exit;end;
 If bit=11 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=12 then begin PaintLed4(1);PaintLed8(1);exit;end;
 If bit=13 then begin PaintLed4(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=14 then begin PaintLed2(1);PaintLed4(1);PaintLed8(1);exit;end;
 If bit=15 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);PaintLed4(1);exit;end;
end;


procedure TjanMemory.Paint;
var
i:integer;
R:TRect;
Y,x:integer;
begin
   with canvas do
   begin
     Lock;
     y:=50;x:=50;
     brush.color:=FPcolor;
     R:=rect(22+x,0+y+15,125+x,65+y);
     Fillrect(R);
     Frame3D(R,clbtnhighlight,clbtnshadow,1);
     PaintLeds(FBits);
     brush.style:=bsclear;
     Font.Name:='Arial';Font.Size:=8;Font.Style:= [];Font.Color:=clNavy;
     TextOut(31+x,2+y+15,'G');TextOut(55+x,2+y+15,'G');TextOut(79+x,2+y+15,'G');TextOut(103+x,2+y+15,'G');
     Font.Size:=7;
     TextOut(40+x,5+y+15,'8');TextOut(64+x,5+y+15,'4');TextOut(88+x,5+y+15,'2');TextOut(112+x,5+y+15,'1');
     pen.Color:=clSilver;
     MoveTo(48+x,0+y + 15);LineTo(48+x,115);
     MoveTo(72+x,0+y + 15);LineTo(72+x,115);
     MoveTo(96+x,0+y + 15);LineTo(96+x,115);

     lUit.Transparent:=true;
     draw(126+x,25+y+15,lUit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1
     Uit.Transparent:=true;
     draw(31+x,25+y+9+54,Uit);draw(56+x,25+y+9+54,Uit);draw(81+x,25+y+9+54,Uit);draw(106+x,25+y+9+54,Uit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1 -- pijlen naar boven
     lBitUit.Transparent:=true;
     draw(23+x,63+y,lBitUit);draw(48+x,63+y,lBitUit);draw(73+x,63+y,lBitUit);draw(98+x,63+y,lBitUit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1 -- pijlen naar onder
     lBitUit1.Transparent:=true;
     draw(23+x,63+y+13,lBitUit1);draw(48+x,63+y+13,lBitUit1);draw(73+x,63+y+13,lBitUit1);draw(98+x,63+y+13,lBitUit1);

     Font.Size:=7;
     TextOut(5+x,2+y-9,'A');TextOut(28+x,2+y-9,'A');TextOut(53+x,2+y-9,'A');TextOut(79+x,2+y-9,'A');TextOut(104+x,2+y-9,'A');
     Font.Size:=7;
     TextOut(13+x,5+y-10,'16');TextOut(38+x,5+y-10,'8');TextOut(64+x,5+y-10,'4');TextOut(88+x,5+y-10,'2');TextOut(112+x,5+y-10,'1');
     // tekenen van de invoerpunten Bit8,Bit4,Bit2,Bit1
     Inv.Transparent:=true;
     draw(56,25+8,Inv);   //imput adress 16
     draw(30+x,25+8,Inv); //imput adress 8   x:=50
     draw(55+x,25+8,Inv); //imput adress 4
     draw(80+x,25+8,Inv); //imput adress 2
     draw(105+x,25+8,Inv);//imput adress 1
     If FConnector=true then
       begin
       Inv.Transparent:=true;
       draw(17,71+y,Inv);
       end;
     //test voor adress  -adresregel  en adresinhoud
     //if schrijf=false then
        //TextOut(17,80,inttoStr(adress)+ ' ... ' + lijst.Strings[adress]+'   0');
     //if schrijf=true then
        //TextOut(17,80,inttoStr(adress)+ ' ... ' + lijst.Strings[adress] +'   1');

     Font.Size:=7;
     TextOut(10,80,'ADRES = '+inttoStr(adress));
     pen.Color:=clBlack;pen.Style:=psdot;

     lAcoo.Transparent:=true;
     draw(6+x,50,lAcoo); //

     if FDepressed or FDown then
     begin
     BinAan.Transparent:=true;
     draw(17,0,BinAan);
     pen.Style:=psSolid;
     end
     else
     begin
     Bin.Transparent:=true;
     draw(17,0,Bin);
     pen.Style:=psSolid
     end;
     If FConnector=true then
       begin
       MoveTo(27, 76+y);LineTo(30+x, 76+y)
       end
       else
       MoveTo(0+x, 76+y);LineTo(30+x, 76+y);
     pen.Color:=clSilver;
     MoveTo(112+x, 76+y);LineTo(124+x, 76+y);
     Unlock;
  end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
   // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
      R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen

    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clRed;
    Canvas.pen.style:=psDot;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
     end;
end;



procedure TjanMemory.Resize;
begin
  width:=200;
  height:=155;//88
end;



destructor TjanMemory.Destroy;
begin
  lAcoo.Free;
  uit.Free;
  lIn.Free;
  Inv.Free;
  lUit.Free;
  lBitUit.Free;
  lBitUit1.Free;
  Bin.Free;
  BinAan.Free;
  Connectors.Free;
  lijst.Free;
  inherited;
end;

procedure TjanMemory.getadress;
var
a,b,c,d:integer;
begin
if A1=true then a:=1 else a:=0;
if A2=true then b:=2 else b:=0;
if A4=true then c:=4 else c:=0;
if A8=true then d:=8 else d:=0;

adress:=a+b+c+d;

end;

procedure TjanMemory.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;



procedure TjanMemory.SetInputMem1(const Value: boolean);
begin
  if value=true then
  begin
    FBits := 0;FBitsChar:='0';
    FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
    invalidate;
 end;
FInputMem1:=false;
end;
{
procedure TjanMemory.SetLoop(const Value: boolean);
begin
  FLoop := value;
  if value=true then
  begin
     inc(FBits);
     If FBits > 15 then FBits:=0;
     If FBits=0 then
        begin FBitsChar:='0';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=1 then
        begin FBitsChar:='1';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=2 then
        begin FBitsChar:='2';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=3 then
        begin FBitsChar:='3';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=4 then
        begin FBitsChar:='4';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=5 then
        begin FBitsChar:='5';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=6 then
        begin FBitsChar:='6';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=7 then
        begin FBitsChar:='7';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=8 then
        begin FBitsChar:='8';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=9 then
        begin FBitsChar:='9';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=10 then
        begin FBitsChar:='A';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=11 then
        begin FBitsChar:='B';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=12 then
        begin FBitsChar:='C';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=13 then
        begin FBitsChar:='D';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=14 then
        begin FBitsChar:='E';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=15 then
        begin FBitsChar:='F';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
  end;
end;}


procedure TjanMemory.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanMemory.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanMemory.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanMemory.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanMemory.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanMemory.SetBits(const Value:Integer);
begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then
        begin FBitsChar:='0';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=1 then
        begin FBitsChar:='1';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=2 then
        begin FBitsChar:='2';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=3 then
        begin FBitsChar:='3';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=4 then
        begin FBitsChar:='4';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=5 then
        begin FBitsChar:='5';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=6 then
        begin FBitsChar:='6';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=7 then
        begin FBitsChar:='7';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=8 then
        begin FBitsChar:='8';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=9 then
        begin FBitsChar:='9';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=10 then
        begin FBitsChar:='A';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=11 then
        begin FBitsChar:='B';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=12 then
        begin FBitsChar:='C';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=13 then
        begin FBitsChar:='D';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=14 then
        begin FBitsChar:='E';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=15 then
        begin FBitsChar:='F';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     if schrijf=true then
      begin
       schrijf:=false;
       Lijst.Strings[Adress]:=IntToStr(Value);
      end;
     If (schrijf=false) then FBits:= StrToInt(Lijst.Strings[FAdress]);
  end;
invalidate;
end;

procedure TjanMemory.SetAdress(const Value:Integer);
begin
if value <> FAdress then
  begin
  FAdress := Value;
  if FDown=true then FAdress:=FAdress + 16;
  end;
If (schrijf=false) then Bits:= StrToInt(Lijst.Strings[FAdress]);
invalidate;
end;

procedure TjanMemory.SetBitsChar(const Value:Char);
begin
  if value <> FBitsChar then
  begin
    FBitsChar := Value;
 end;
invalidate;
end;




procedure TjanMemory.SendStatusToBar;//xxx
  var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
end;

procedure TjanMemory.SetNaam(const Value: String);//xxxx
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanMemory.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Geheugenblok'
 else if value='ENG' then FInfo:='Memory block'
 else if value='FR' then FInfo:= 'Bloc mémoire'
 else if value='DU' then FInfo:= 'Speicherblock';
invalidate;
// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanMemory.SetDown(const Value: boolean);
var
a1,a2,a4,a8:integer;
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   if (FDown=false) and (FAdress >15) then
       FAdress:=FAdress - 15
       else
       FAdress:=FAdress + 15;

   If FDown=true then FStatMemB := stMemButtonStop else FStatMemB := stMemButtonStart;
   invalidate;
  end;

 if Assigned(OnMemButtonChange) then OnMemButtonChange(Self, StatMemB);
  // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;
procedure TjanMemory.SetA1(const Value: boolean);
begin
   If value=true then FA1 := true else FA1:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetA2(const Value: boolean);
begin
  If value=true then FA2 := true else FA2:=false;
  getadress;
   invalidate;
end;
procedure TjanMemory.SetA4(const Value: boolean);
begin
  If value=true then FA4 := true else FA4:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetA8(const Value: boolean);
begin
  If value=true then FA8 := true else FA8:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetConnector(const Value: boolean);
begin
  if value<>FConnector then
  begin
   FConnector := Value;
   invalidate;
  end;
end;

procedure TjanMemory.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

{Procedure TjanMemory.SetLijst(const Value: TStrings);
begin
  if lijst <> value
  then
  begin
  lijst:=value;
  invalidate;
  end;
end;}

procedure TjanMemory.SetInputMem3(const Value: boolean);
begin
  if value<>FInputMem3 then
  begin
    FInputMem3 := Value;
    invalidate;
  end;
end;



procedure TjanMemory.SetOutPutMemDisplay(const Value: boolean);
begin
  if value <> FOutputDisplay then
  begin
    FOutPutDisplay := Value;
  end;
invalidate;
end;
procedure TjanMemory.SetOutPutMemBit1(const Value: boolean);
begin
  if value <> FOutputBitMem1 then
  begin
    FOutPutBitMem1 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit2(const Value: boolean);
begin
  if value <> FOutputBitMem2 then
  begin
    FOutPutBitMem2 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit4(const Value: boolean);
begin
  if value <> FOutputBitMem4 then
  begin
    FOutPutBitMem4 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit8(const Value: boolean);
begin
  if value <> FOutputBitMem8 then
  begin
    FOutPutBitMem8 := Value;
  end;
end;


procedure TjanMemory.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;
procedure TjanMemory.SetLedColUit(const Value: TColor);
begin
  if value<>FLedColUit then
  begin
    FLedColUit := Value;
    invalidate;
  end;
end;

procedure TjanMemory.SetLedColAan(const Value: TColor);
begin
  if value<>FLedColAan then
  begin
    FLedColAan := Value;
    invalidate;
  end;
end;

{TjanMeter}

constructor TjanMeter.Create(AOwner: TComponent);
var i:integer;
begin
  inherited Create(AOwner);
  Select:=false;
  width:=100;
  height:=51;
  // initialize Gates
  FGates[0].pos:=point(1,10);
  FGates[1].pos:=point(1,28);
  FGates[2].pos:=point(1,46);
  FGates[3].pos:=point(52,10);
  FGates[4].pos:=point(52,28);
  FGates[5].pos:=point(52,46);
  for i:=0 to 5 do
    FGates[i].State:=false;
  for i:=0 to 2 do
  begin
    FGates[i].style:=jgsDI;
    FGates[i+3].style:=jgsDO;
  end;
  FLogicAndFunc:=jlfEN;
  FGates[0].Active:=true;
  FGates[1].Active:=false;
  FGates[2].Active:=true;
  FGates[3].Active:=false;
  FGates[4].Active:=true;
  FGates[5].Active:=false;
  connectors:=TList.create;
  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG');
  V0:=TBitmap.create;
  V0.LoadFromResourceName(HInstance,'V0');
  V5:=TBitmap.create;
  V5.LoadFromResourceName(HInstance,'V5');

  FInfo:= 'Meter';
  ShowHint:=true;
  FLock:=false;
  FPcolor:=rgb(250,250,220);
  Cursor := crMeter;
end;

function TjanMeter.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanMeter.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var R,R2,R3:TRect;
p : TPoint;
pop:TPopupMenu;
ItemNew,ItemNew1,ItemNew2:TMenuItem;
S:String;
L,T:integer;
wc:TWinControl;
begin
  doMove:=false;
  //doStyle:=false;
  //StyleDown:=false;
  mdp:=point(x,y);
  R:=clientRect;
  // maken van aansluitdraad
  if (ptinrect(R,mdp)) and (screen.Cursor=crMeter) then
  begin
   wc:=parent;L:=left+width-9;T:=top+31;
   Maakdraad(T,L,wc);
   screen.Cursor:= crdefault;
  end;

  // einde van het maken van een aansluiting

 // R2:=rect(22,20,65,45);
 // doStyle:= ptinrect(R2,mdp);
  doMove:= true;
  oldp:=point(x,y);
  if doMove then
    AnchorConnectors;

  // opbouw popupmenu
  pop:=TPopupMenu.Create(self);
  ItemNew := TMenuItem.Create(self);
  If FLock=true then S:='Ontgrendel' else S:='Vergrendel';
  ItemNew.Caption := S;
  ItemNew.OnClick := meterClick;
  Pop.Items.Add(ItemNew);
  {ItemNew1 := TMenuItem.Create(self);
  ItemNew1.Caption := 'Verwijder poort';
  ItemNew1.OnClick := meterClick1;
  Pop.Items.Add(ItemNew1);}
  ItemNew2 := TMenuItem.Create(self);
  If ShowHint=true then S:='Info uit' else S:='Info aan';
  ItemNew2.Caption :=S;
  ItemNew2.OnClick := meterClick2;
  Pop.Items.Add(ItemNew2);
  if (Button = mbRight)  then
     begin
       p.X := 0;
       p.Y := Self.Height;
       p := ClientToScreen(p);
       pop.Popup(p.X,p.Y-1);
  end;
end;

procedure TjanMeter.MouseMove(Shift: TShiftState; X, Y: Integer);
var p:TPoint;
r:TRect;
begin
   If FLock=true then exit;
   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);
   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;
     MoveConnectors;
     left:=newleft;
     top:=newtop;
      if Assigned(GlobalSimBox) then
         GlobalSimBox.DoObjectMove(Self, Left, Top);
     end
   end;
end;

procedure TjanMeter.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,0);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;


procedure TjanMeter.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin

  select:=false;Cursor := crDefault;repaint;
  if FLock=true then exit;
end;

procedure TjanMeter.PaintLed(index:integer);
var
    lit:boolean;
    S:String;
    R:Trect;
begin
  if not Gates[index].Active then exit;
  if index=0 then
    begin
    lit:=FInput1;
    canvas.draw(85,35,lIn);
    end
    else
  if index=2 then
    begin
    lit:=Finput3;
    canvas.draw(5,35,lIn);
    end
    else
  if index=4 then
    Begin
    lit:=Foutput2;
    if lit then
      canvas.draw(25,7,V5) else canvas.draw(25,7,V0);
    end;
end;


procedure TjanMeter.Paint;
var i:integer;
    R:TRect;
begin
   with canvas do
   begin
     brush.color:=clSilver;
     R:=clientrect;
      Fillrect(R);
     Frame3D(R,clbtnhighlight,clbtnshadow,1);
     brush.color:=FPcolor;
     R:=rect(22,5,76,30);
     Fillrect(R);
     frame3D(R,clbtnshadow,clbtnhighlight,2);
     for i:=0 to 4 do
       PaintLed(i);
     brush.style:=bsclear;
     Font.Name:='Arial';Font.Size:=14;Font.Style:= [];Font.Color:=clWhite;
     TextOut(4,10,'+');TextOut(84,2,'_');Font.Color:=clBlack;Font.Size:=12;  TextOut(64,9,'V');
   end;
end;



procedure TjanMeter.Resize;
begin
  width:=100;
  height:=51;
end;


destructor TjanMeter.Destroy;
begin
  lIn.Free;
  V0.Free;
  V5.Free;
  Connectors.Free;
  inherited;

end;

procedure TjanMeter.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanMeter.OutCalc;
begin
  {case FLogicAndFunc of
  jlfEN: OutPut2:= Input1 and Input3;
 { end; }
  // Voltmeter (parallel aangesloten): toont het spanningsverschil
  // U(+) - U(-). Input1 = + (links), Input3 = - (rechts).
  //   + aan, - uit -> 5 V ; beide gelijk -> 0 V ;
  //   + uit, - aan (omgekeerd aangesloten) -> 0 V
  output2 := Input1 and not Input3;
end;

procedure TjanMeter.SetInput1(const Value: boolean);
begin
  if value<>FInput1 then
  begin
    FInput1 := Value;
    invalidate;
    OutCalc;
  end;
end;



procedure TjanMeter.MeterClick(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanMeter.MeterClick1(sender:TObject);
var
i:integer;
con:TjanConnector;
Begin
Output2:=false;
for i:=0 to connectors.count-1 do
    begin
    con:=TjanConnector(connectors[i]);
    con.connect;
    con.free;
    end;
free;
end;

procedure TjanMeter.MeterClick2(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;


procedure TjanMeter.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanMeter.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanMeter.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
    OutCalc;
  end;
end;



procedure TjanMeter.SetOutPut2(const Value: boolean);
begin
  if value<>FOutput2 then
  begin
    FOutPut2 := Value;
    invalidate;
  end;

end;

procedure TjanMeter.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;

end;

procedure TjanMeter.SetLogicFunc(const Value: TjanMeterFunc);
begin
  if value<>FLogicAndFunc then
  begin
    FLogicAndFunc := Value;
    case FLogicAndFunc of
    jlfEN:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
      end;

    end;
    invalidate;
    OutCalc;
  end;
end;


{ TjanSimButton }

procedure TjanSimButton.BuildPopup;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;

  // --- Lock / Unlock
  miLock := TMenuItem.Create(PopupMenu);
  miLock.Name := 'miLock';
  miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miLock);

  // --- Naam wijzigen
  miName := TMenuItem.Create(PopupMenu);
  miName.Name := 'miName';
  miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miName);

  // --- Info aan/uit
  miInfo := TMenuItem.Create(PopupMenu);
  miInfo.Name := 'miInfo';
  miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miInfo);

  // --- Selecteer voor verwijdering
  miSelect := TMenuItem.Create(PopupMenu);
  miSelect.Name := 'miSelect';
  miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miSelect);
end;

procedure TjanSimButton.UpdatePopupCaptions;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
  s: string;
begin
  if not Assigned(PopupMenu) then Exit;

  miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
  miName   := TMenuItem(PopupMenu.FindComponent('miName'));
  miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
  miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

  // --- Lock / Unlock
  if Assigned(miLock) then
  begin
    if BTaal = 'NL' then
    begin
      if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
    end
    else if BTaal = 'FR' then
    begin
      if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
    end
    else if BTaal = 'DU' then
    begin
      if FLock then s := 'Entsperren' else s := 'Sperren';
    end
    else
    begin
      if FLock then s := 'Unlock' else s := 'lock';
    end;
    miLock.Caption := s;
  end;

  // --- Naam wijzigen
  if Assigned(miName) then
  begin
    if BTaal = 'NL' then s := 'Wijzig Naam'
    else if BTaal = 'FR' then s := 'Changer le nom'
    else if BTaal = 'DU' then s := 'Namen ändern'
    else s := 'Change name';
    miName.Caption := s;
  end;

  // --- Select / Deselect (TOGGLE)
  if Assigned(miSelect) then
  begin
    if not Selected then
    begin
      if BTaal = 'NL' then s := 'Selecteer object'
      else if BTaal = 'FR' then s := 'Sélectionner un objet'
      else if BTaal = 'DU' then s := 'Objekt auswählen'
      else s := 'Select object';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Deselecteer object'
      else if BTaal = 'FR' then s := 'Désélectionner l''objet'
      else if BTaal = 'DU' then s := 'Objekt abwählen'
      else s := 'Deselect object';
    end;
    miSelect.Caption := s;
  end;

  // --- Info aan/uit
  if Assigned(miInfo) then
  begin
    if ShowHint then
    begin
      if BTaal = 'NL' then s := 'Info uit'
      else if BTaal = 'FR' then s := 'Infos off'
      else if BTaal = 'DU' then s := 'Infos aus'
      else s := 'Information off';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Info aan'
      else if BTaal = 'FR' then s := 'Infos on'
      else if BTaal = 'DU' then s := 'Infos an'
      else s := 'Information on';
    end;
    miInfo.Caption := s;
  end;
end;



procedure TjanSimButton.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanSimButton.Create(AOwner: TComponent);
var
XX, YY: Integer;
PixelColor: TColor;
MI:TMenuItem;
begin
  inherited Create(AOwner);
  HelpKeyword := 'button';
  Select:=false;
  FStatButton := stButtonStop;
  draad:=true;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'DRUK_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor:= clFuchsia;

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'DRUK__IN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor:= clFuchsia;;//KnopUp.canvas.pixels[0,0];

  ControlStyle := ControlStyle + [csCaptureMouse,csDoubleClicks,csClickEvents];
  FTaal:='NL';
  FNaam:='Drukknop';
  FSoort:='Invoer';
  FInfo:=  FNaam;//Druknop';
  ShowHint:=True;

  FModusSquare:=false;
end;

destructor TjanSimButton.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R, R2, R3: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
begin
  inherited;

  // =========================================================
  // 1) RECHTSKLIK: popup tonen en meteen stoppen
  // =========================================================
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  puls := 1;
  mdp := Point(X, Y);

  R  := Rect(49, 6, 57, 14);  // klik-zone voor draadaansluiting
  R2 := Rect(1, 1, 16, 15);   // klik-zone om button te bedienen
  R3 := ClientRect;           // zone voor square button

  // =========================================================
  // 2) SQUARE MODUS
  // =========================================================
  if FModusSquare = True then
  begin
    if PtInRect(R3, mdp) then
    begin
      FDepressed := True;
      doMove := False;
      Down := True;

      with Canvas do
      begin
        Lock;
        try
          Pen.Color := clRed;
          RoundRect(3, 3, 47, 47, 8, 8);
          DrawFocusRect(ClientRect);
        finally
          Unlock;
        end;
      end;

      Invalidate;
      Exit;
    end;
  end;

  // =========================================================
  // 3) NIET-SQUARE MODUS
  // =========================================================
  if FModusSquare = False then
  begin
    // maken van aansluitdraad
    if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
    begin
      wc := Parent;
      L := Left + Width - 8;
      T := Top + 7;

      Maakdraad(T, L, wc);

      doMove := False;
      movecursor;
      BringToFront;
      Exit;
    end;

    Screen.Cursor := crDefault;

    // drag of click?
    doMove := not PtInRect(R2, mdp);
    FDepressed := not doMove;
    oldp := Point(X, Y);

    if doMove then
    begin
      AnchorConnectors;

      if (Button = mbLeft) and (Parent is TjanGridS) then
        TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
    end
    else
    begin
      Canvas.Lock;
      try
        Canvas.Draw(0, 0, knopDown);
      finally
        Canvas.Unlock;
      end;

      Down := True;
      Invalidate;
    end;
  end;
end;

procedure TjanSimButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R2, R3: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;
  FDepressed := False;

  p := Point(X, Y);
  R2 := Rect(1,1,16,15);
  R3 := ClientRect;

  if PtInRect(R3, p) and (FModusSquare = True) then
  begin
    Down := False;
    with Canvas do
    begin
      Lock;
      try
        Pen.Color := clNavy;
        RoundRect(3,3,47,47,8,8);
        DrawFocusRect(ClientRect);
        Font.Style := [fsBold];
        TextOut(20,17,FText);
      finally
        Unlock;
      end;
    end;
    Exit;
  end;

  if PtInRect(R2, p) and (FModusSquare = False) then
  begin
    Down := False;
    Canvas.Lock;
    try
      Canvas.Draw(0,0,knopUp);
    finally
      Canvas.Unlock;
    end;
  end;
end;

procedure TjanSimButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p, md: TPoint;
  R2: TRect;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  R2 := Rect(1,1,16,15);
  md := Point(X, Y);

  if not PtInRect(R2, md) then
    Down := False;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // neem middenpunt van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen aan ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar Left/Top
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;
{
procedure TjanSimButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p, md: TPoint;
  R2: TRect;
begin
  inherited;

  R2 := Rect(1,1,16,15);
  md := Point(X, Y);

  if not PtInRect(R2, md) then
    Down := False;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;}




procedure TjanSimButton.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimButton.Paint;
var p:Tpoint;
R:TRect;
begin
If FModusSquare=true then
 begin
  with canvas do
   begin
   Lock;
   brush.style:=bssolid;
   if FDepressed or FDown then
     begin
     R:=ClientRect;
     pen.Color:=clred;
     canvas.RoundRect(3,3,47,47,8,8);
     DrawFocusRect(R);

     end
     else
     begin
     pen.Color:=clNavy;
     canvas.RoundRect(3,3,47,47,8,8);
     end;
   Font.Style:= [fsBold];
   Font.Color:=clNavy;
   TextOut(20,17,FText);
   Unlock;
   end;
 end
 else
 Begin
 knopUp.Transparent:=true;
 knopDown.Transparent:=true;
 with canvas do
   begin
   Lock;
     if FDepressed or FDown then
      begin
       draw(0,0,knopDown);
       brush.style:=bsclear;
       Font.Name:='Arial';Font.Size:=9;
       Font.Style:= [fsBold];Font.Color:=clRed;
       TextOut(50,14,'1');
      end
     else
      begin
       draw(0,0,knopUp);
       brush.style:=bsclear;
       Font.Name:='Arial';Font.Size:=9;
       Font.Style:= [fsBold];Font.Color:=clNavy;
       TextOut(50,14,'0');
      end;
    Unlock;
   end;
   // tekenen van selectie kader
   if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clSilver;pen.style:=psSolid;
      end;
     end;
    // tekenen van rode kader na selectie via popupmenu
     if FSelected then
  begin
    R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen

    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clRed;
    Canvas.pen.style:=psDot;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
  end;
 end;
end;

procedure TjanSimButton.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y- 5;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    lock;
    brush.style:=bsclear;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimButton.Resize;
begin
If FModusSquare=true then
     begin
     width:=50;height:=50;
     end
     else
     Begin
     width:=58;height:=32;
     end;
end;

procedure TjanSimButton.SetDown(const Value: Boolean);
begin
  if Value = FDown then Exit;   // ✅ alleen bij echte verandering

  FDown := Value;
  FDepressed := Value;

  if FDown then
    FStatButton := stButtonStop
  else
    FStatButton := stButtonStart;

  Invalidate;

  // ✅ Onmiddellijke refresh als muis erboven staat
  if FMouseOver then
    SendStatusToBar;

  // ✅ event alleen bij echte wijziging
  if Assigned(FOnStatButtonChange) then
    FOnStatButtonChange(Self, FStatButton);
end;


{
procedure TjanSimButton.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
    If FDown=true then FStatButton := stButtonStop else FStatButton := stButtonStart;
  invalidate;
  end;
if Assigned(OnButtonChange) then OnButtonChange(Self, StatButton);
end;}

procedure TjanSimButton.SetModus(const Value: boolean);
begin
  if value<>FModus then
  begin
    FModus := Value;
    If FModus=true then
     begin
     KnopUp.LoadFromResourceName(HInstance,'DRUK_UITS');
     KnopDown.LoadFromResourceName(HInstance,'DRUK_INS');
     end
     else
     Begin
     KnopUp.LoadFromResourceName(HInstance,'DRUK_UIT');
     KnopDown.LoadFromResourceName(HInstance,'DRUK__IN');
     end;
  invalidate;
  end;
end;

procedure TjanSimButton.SetModusSquare(const Value: boolean);
begin
  if value<>FModusSquare then
  begin
    FModusSquare := Value;
    If FModusSquare=true then
     begin
     width:=50;height:=50;
     end
     else
     Begin
     width:=58;height:=32;

     end;
  invalidate;
  end;
end;

procedure TjanSimButton.SetActiv(const Value: boolean);
begin
  if value<>FActiv then
  begin
    FActiv := Value;
  end;
invalidate;
end;

procedure TjanSimButton.SetRuntime(const Value: boolean);
begin
  if value<>FRuntime then
  begin
    FRuntime := Value;
  end;
invalidate;
end;

procedure TjanSimButton.SetConnectie(const Value: boolean);
var
WC:TWinControl;
L,T:integer;
begin
  if value<>FConnectie then
  begin
    FConnectie := Value;
  end;
  if Value=true then
  begin
   wc:=parent;
   L:=left + width -8;T:=top+7;
   Maakdraad(T,L,wc);
  end;
invalidate;
end;

procedure TjanSimButton.SetAction(aktie: TAction);
begin
  if aktie<>FAction then
  begin
    FAction := aktie;
  end;
//invalidate;
end;

procedure TjanSimButton.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  FMouseOver := False;
  if Assigned(FOnStatus) then
    Begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
    end;
    invalidate;
   if not FLock then
   begin
    select:=false;
    invalidate;
   end;
end;


procedure TjanSimButton.CMMouseEnter(var Msg: TMessage);
var
 s:string;
begin
  inherited;
   UpdateHintText;
   // laat status en x,y van object verschijnen in Main StatusBar Panel 1
   FMouseOver := True;
   SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);

  BringToFront;

  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;


procedure TjanSimButton.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimButton.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimButton.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimButton.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimButton.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimButton.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

procedure TjanSimButton.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
  C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;
  if LB = nil then Exit;
 s:= Format('X=%d Y=%d', [Left, Top]);
 LB.PushStatus(Self, s, 2);
end;

procedure TjanSimButton.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus,
  wT1,wT0: string;
  LB: TjanSimLogicBox;
  C: TComponent;
begin
  // Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;

  if LB = nil then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');

  wStatus := Tr(BTaal,'Drukknop','Push button','Bouton poussoir','Druckknopf');

  wT1:=Tr(BTaal,'Omlaag','Down','Vers le bas','Runter');

  wT0:=Tr(BTaal,'Omhoog','Upwards','Vers le haut','Nach oben');


  LB.PushStatus(Self, FNaam , 0);

  if FDown then
    s := wStatus + ' = ' + wT1
  else
    s := wStatus + ' = ' + wT0;

  LB.PushStatus(Self, s, 1);

  ss := Format('X=%d Y=%d', [Left, Top]);

  LB.PushStatus(Self, ss, 2);
end;

procedure TjanSimButton.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimButton.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:=FNaam
 else if value='ENG' then FInfo:='Push button'
 else if value='FR' then FInfo:= 'Poussoir'
 else if value='DU' then FInfo:= 'Druckknopf';
invalidate;
end;

procedure TjanSimButton.SetText(const Value: String);
begin
  if value<>FText then
  begin
    FText := Value;
    invalidate;
 end;
end;
procedure TjanSimButton.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;
procedure TjanSimButton.Setdraad(const Value: boolean);
begin
  if value<>FDraad then
  begin
    Fdraad := Value;
 end;
end;

procedure TjanSimButton.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;


{ TjanSimKnop }


procedure TjanSimKnop.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

procedure TjanSimKnop.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   FMouseOver := False;

   if Assigned(FOnStatus) then
   begin
     FOnStatus(Self, '', 0);
     FOnStatus(Self, '', 1);
     FOnStatus(Self, '', 2);
     FOnStatus(Self, '', 3);
   end;

    if Assigned(FOnExit) then
    FOnExit(Self);

   if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimKnop.CMMouseEnter(var Msg: TMessage);
var
 s:String;
begin
  inherited;
  UpdateHintText;

  if Assigned(FOnEnter) then
  FOnEnter(Self);

   // laat status en x,y van object verschijnen in Main StatusBar Panel 1

   FMouseOver := True;
   SendStatusToBar;

   if Assigned(FOnEnter) then
    FOnEnter(Self);


  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;


constructor TjanSimKnop.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  HelpKeyword := 'schakelaar';
  Select:=false;
  FDown:=false;
  width:=51;
  height:=50;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'SCHAK_UIT');
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := KnopUp.canvas.pixels[0,0];
  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'SCHAK__IN');
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := KnopDown.canvas.pixels[0,0];
 // FTaal:='NL';
  FInfo:= 'Schakelaar';
  ShowHint:=true;
  FSoort:='Invoer';
  FNaam:='Schakelaar';
end;

destructor TjanSimKnop.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimKnop.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  // Rechtsklik: popup tonen en stoppen
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(42,20,51,50);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 21;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(2,12,14,37);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimKnop.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);

       end;

       procedure TjanSimKnop.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'UnLock' else s := 'Lock';
           end;
           miLock.Caption := s;
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := s;
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := s;
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := s;
         end;
       end;


       procedure TjanSimKnop.MouseUp(Button: TMouseButton; Shift: TShiftState;
         X, Y: Integer);
       var
         R: TRect;
         p: TPoint;
       begin
         inherited;

         if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;

         Select := False;
         Repaint;
         FDepressed := False;

         p := Point(X, Y);
         R := Rect(2,12,14,37);

         if PtInRect(R, p) then
           Down := not Down;

         FMouseOver := True;
         SendStatusToBar;
       end;


procedure TjanSimKnop.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;

      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;



procedure TjanSimKnop.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  Select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimKnop.Paint;
var p:Tpoint;
    R:TRect;
begin
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
    knopDown.Transparent:=true;
    knopUp.Transparent:=true;;
     if FDepressed or FDown then
       begin
            draw(0,0,knopDown);
            brush.style:=bsclear;
            Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
            Font.Color:=clRed;
            TextOut(42,29,'1');
       end
       else
       begin
            draw(0,0,knopUp);
            brush.style:=bsclear;
            Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
            Font.Color:=clNavy;
            TextOut(42,29,'0');
       end;

   unlock;
   end;
   if select=true then
     begin
       with canvas do
        begin
         R:=ClientRect;
         pen.Color:=clblack;
         pen.style:=psDot;
         Lock;rectangle(R);Unlock;
         pen.Color:=clSilver;pen.style:=psSolid;
        end;
     end;
   // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if FSelected then
     begin
       R := ClientRect;
     // InflateRect(R, -1, -1);         // binnen de rand tekenen
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
      // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;
end;

procedure TjanSimKnop.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    Unlock;
   end;
end;

procedure TjanSimKnop.Resize;
begin
  width:=51;
  height:=50;
end;

//new
procedure TjanSimKnop.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimKnop.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimKnop.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimKnop.ButtonClick4(sender:TObject); // selecteer object
begin
   if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimKnop.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;
   puls:=1;
   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;
procedure TjanSimKnop.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;


procedure TjanSimKnop.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimKnop.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

procedure TjanSimKnop.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
  C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;
  if LB = nil then Exit;
 s:= Format('X=%d Y=%d', [Left, Top]);
 LB.PushStatus(Self, s, 2);
end;


procedure TjanSimKnop.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;


procedure TjanSimKnop.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimKnop.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

procedure TjanSimKnop.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='schakelaar'
 else if value='ENG' then FInfo:='switch'
 else if value='DU' then FInfo:='Schalter'
 else if value='FR' then FInfo:= 'l´interrupteur';
invalidate;
end;

{ TjanDipSwitsh }

procedure TjanDipSwitsh.SendStatusToBar;
 var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanDipSwitsh.UpdateHintText;
 begin
   Hint := BuildSimHint(FNaam, BTaal);
 end;

procedure TjanDipSwitsh.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanDipSwitsh.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Dipschakelaar'
 else if value='ENG' then FInfo:='DipSwitsh'
 else if value='FR' then FInfo:= 'Commutateur DIP'
 else if value='DU' then FInfo:= 'DipSwitch';

 invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanDipSwitsh.SetInfo(const Value: String);
begin
   if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanDipSwitsh.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  if not FMouseOver then Exit;     // kleine guard
     FMouseOver := False;

 // ✅ statusbar leegmaken (zoals bij TjanSimButton)
 if Assigned(FOnStatus) then
 begin
   FOnStatus(Self, '', 0);
   FOnStatus(Self, '', 1);
   FOnStatus(Self, '', 2);
   FOnStatus(Self, '', 3);
 end;
 if Flock=false then begin select:=false;invalidate;end;
end;



procedure TjanDipSwitsh.CMMouseEnter(var Msg: TMessage);
var
s:String;
begin
  inherited;
   UpdateHintText;
   // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2
  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
 end;

procedure TjanDipSwitsh.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   {Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;}
end;

procedure TjanDipSwitsh.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanDipSwitsh.Create(AOwner: TComponent);
var
 XX, YY: Integer;
 PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  // initialize (imputs)
  FGates[0].pos:=point(120,64); FGates[0].Active:=true;    // reset
  FStatDip := stDipStop;
  FDown8:=false;FDown4:=false;FDown2:=false;FDown1:=false;
  FStart := false;
  width:=130;height:=80;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'DI_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'DI_AAN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];

  DrukUp:=TBitmap.Create;
  DrukUp.LoadFromResourceName(HInstance,'DRUKUP');
  for YY := 0 to DrukUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := DrukUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          DrukUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  DrukUp.Transparent := True;
  DrukUp.TransParentColor:= clFuchsia;// := DrukUp.canvas.pixels[0,0];

  DrukDown:=TBitmap.Create;
  DrukDown.LoadFromResourceName(HInstance,'DRUKDOWN');
  for YY := 0 to DrukDown.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := DrukDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          DrukDown.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  DrukDown.Transparent := True;
  DrukDown.TransParentColor := clFuchsia;//:= DrukDown.canvas.pixels[0,0];

  Ingang:=TBitmap.Create;
  Ingang.LoadFromResourceName(HInstance,'IN');
  for YY := 0 to Ingang.Height - 1 do
      for XX := 0 to Ingang.Width - 1 do
      begin
        PixelColor := Ingang.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Ingang.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  Ingang.Transparent := True;
  Ingang.TransParentColor := clFuchsia;

  Connectoren:=TBitmap.Create;
  Connectoren.LoadFromResourceName(HInstance,'UIT');
  for YY := 0 to Connectoren.Height - 1 do
      for XX := 0 to Connectoren.Width - 1 do
      begin
        PixelColor := Connectoren.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Connectoren.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  Connectoren.Transparent := True;
  Connectoren.TransParentColor := clFuchsia;
  FConnector:=true;

 // FTaal:='NL';
  FInfo:= 'DipSwitsh';
  ShowHint:=True;
  FSoort:='Invoer';
  FNaam:='DipSwitsh';
  FSelected:=false;
end;

destructor TjanDipSwitsh.Destroy;
begin
  knopUp.Free; knopDown.Free;drukup.Free;drukdown.Free;Ingang.Free;
  connectors.free;
  connectoren.Free;
  inherited;
end;

procedure TjanDipSwitsh.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R8, R4, R2, R1, Rp, RD: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);

  RD := Rect(0,12,60,38);
  if PtInRect(RD, mdp) then
    Screen.Cursor := crDefault;

  R := Rect(120,64,128,72);
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 122;
    T := Top + 66;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  Rp := Rect(87,58,109,80);
  R8 := Rect(0,12,15,37);
  R4 := Rect(16,12,30,37);
  R2 := Rect(31,12,45,37);
  R1 := Rect(46,12,60,37);

  // doMove alleen True als er NIET op een bedieningszone geklikt is
  doMove := not (
    PtInRect(Rp, mdp) or
    PtInRect(R8, mdp) or
    PtInRect(R4, mdp) or
    PtInRect(R2, mdp) or
    PtInRect(R1, mdp)
  );

  FDepressed  := PtInRect(Rp, mdp);
  FDepressed8 := PtInRect(R8, mdp);
  FDepressed4 := PtInRect(R4, mdp);
  FDepressed2 := PtInRect(R2, mdp);
  FDepressed1 := PtInRect(R1, mdp);

  if (FDepressed or FDown) then
    Down := True;

  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
  begin
    Screen.Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TjanDipSwitsh.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;

  if FDepressed8 or FDepressed4 or FDepressed2 or FDepressed1 or FDepressed then
  begin
    Screen.Cursor := crDefault;
    Exit;
  end;

  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanDipSwitsh.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R8, R4, R2, R1, R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;

  FDepressed8 := False;
  FDepressed4 := False;
  FDepressed2 := False;
  FDepressed1 := False;
  FDepressed := False;

  p := Point(X, Y);

  R8 := Rect(1,12,15,37);
  if PtInRect(R8, p) then Down8 := not FDown8;

  R4 := Rect(16,12,30,37);
  if PtInRect(R4, p) then Down4 := not FDown4;

  R2 := Rect(31,12,45,37);
  if PtInRect(R2, p) then Down2 := not FDown2;

  R1 := Rect(46,12,60,37);
  if PtInRect(R1, p) then Down1 := not FDown1;

  R := Rect(87,58,109,80);
  if PtInRect(R, p) then
    Down := not FDown;

  if PtInRect(R, p) then
    FDown := False;

  FMouseOver := True;
  SendStatusToBar;
end;

{
procedure TjanDipSwitsh.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var R,R8,R4,R2,R1,Rp,RD:TRect;
p : TPoint;
pop:TPopupMenu;
ItemNew,ItemNew1,ItemNew2:TMenuItem;
S:String;
wc:TWinControl;
L,T:integer;
begin
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;              // maakt PopupMenu 1x (als nog niet bestaat)
    UpdatePopupCaptions;     // past captions aan volgens taal/lock/showhint
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp:=point(x,y);
  RD:=Rect(0,12,60,38);
   if (ptinrect(RD,mdp)) then screen.Cursor:=crDefault;
  R:=Rect(120,64,128,72);
  if (ptinrect(R,mdp)) and (screen.Cursor=crDraad) then
  begin
   wc:=parent;L:=left+ 122;T:=top + 66;
   Maakdraad(T,L,wc);doMove:=false;movecursor;BringToFront;exit;
  end;
  screen.Cursor:=crDefault;
  Rp:=Rect(87,58,109,80);
  doMove:= not (ptinrect(Rp,mdp));
  FDepressed:=not doMove;
  if (FDepressed or FDown) then Down:=true;

  R8:=Rect(0,12,15,37);
  doMove:= not (ptinrect(R8,mdp));
  FDepressed8:=not doMove;

  R4:=Rect(16,12,30,37);
  doMove:= not (ptinrect(R4,mdp));
  FDepressed4:=not doMove;

  R2:=Rect(31,12,45,37);
  doMove:= not (ptinrect(R2,mdp));
  FDepressed2:=not doMove;

  R1:=Rect(46,12,60,37);
  doMove:= not (ptinrect(R1,mdp));
  FDepressed1:=not doMove;

  oldp:=point(x,y);
  if doMove then
    begin

    AnchorConnectors;
    end
  else
    begin
    screen.cursor:=crDefault;
    invalidate;
    end;

  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TjanDipSwitsh.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var R8,R4,R2,R1,R:TRect;
    p:Tpoint;
begin
  select:=false;repaint;
  FDepressed8:=false;FDepressed4:=false;FDepressed2:=false;
  FDepressed1:=false;FDepressed:=false;
  p:=point(x,y);
  R8:=Rect(1,12,15,37);if ptinrect(R8,p) then Down8:=not FDown8;
  R4:=Rect(16,12,30,37);if ptinrect(R4,p) then Down4:=not FDown4;
  R2:=Rect(31,12,45,37);if ptinrect(R2,p) then Down2:=not FDown2;
  R1:=Rect(46,12,60,37);if ptinrect(R1,p) then Down1:=not FDown1;
  R:=Rect(87,58,109,80);if ptinrect(R,p) then Down:=not FDown;



  if ptinrect(R,p) then FDown:=false;



    FMouseOver := True;
    SendStatusToBar;
end;

procedure TjanDipSwitsh.MouseMove(Shift: TShiftState; X, Y: Integer);
var p:TPoint;
begin
   if FLock=true then exit;
   if FDepressed8 or FDepressed4 or FDepressed2 or FDepressed1 or FDepressed then
      begin
       screen.cursor:=crDefault;exit;
      end;
   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);
   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;
     MoveConnectors;
     left:=newleft;
     top:=newtop;

     FMouseOver := True;
     SendStatusToBar;
     end
   end;
end;
 }



procedure TjanDipSwitsh.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanDipSwitsh.Paint;
var p:Tpoint;
    R:TRect;
begin
knopDown.Transparent:=true;
knopUp.Transparent:=true;
Connectoren.Transparent:=true;
DrukUp.Transparent:=true;
DrukDown.Transparent:=True;
Ingang.Transparent:=true;
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
     if FDepressed8 or FDown8 then begin draw(0,0,knopDown) end else Begin draw(0,0,knopUp);end;
     if FDepressed4 or FDown4 then begin draw(15,0,knopDown)end else Begin draw(15,0,knopUp);end;
     if FDepressed2 or FDown2 then begin draw(30,0,knopDown)end else Begin draw(30,0,knopUp);end;
     if FDepressed1 or FDown1 then begin draw(45,0,knopDown)end else Begin draw(45,0,knopUp);end;
     moveto(9,height-20);lineto(70,height-20);moveto(70,20);lineto(113,20);
     moveto(70,20);lineto(70,68);moveto(113,20);lineto(113,68);moveto(70,68);lineto(width,68);
     moveto(8,60);lineto(70,60);
     if FConnector then
       begin draw(120,64,Connectoren);end;
     if (FDepressed or FDown) then
       draw(87,58,DrukDown)else draw(87,58,DrukUp);
     draw(91,15,Ingang);
     p:=point((width div 2),(height div 2)-7);
     brush.style:=bsclear;
     Font.Name:='Arial';Font.Size:=9;Font.Style:= [];Font.Color:=clNavy;
     TextOut(4,-3,'8');TextOut(19,-3,'4');TextOut(36,-3,'2');TextOut(51,-3,'1');
     TextOut(89,35,'Sc');
   if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clBlack;pen.style:=psSolid;
      end;
     end;
   if FSelected then
   Begin
    R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen
    Brush.Style := bsClear;
    Pen.Color := clRed;
    pen.style:=psDot;
    Pen.Width := 1;
    Rectangle(R);
    // restore (netjes)
     Pen.Width := 1;
     pen.style:=psSolid;
     Brush.Style := bsSolid;
  end;
  Unlock;
  end;
end;



procedure TjanDipSwitsh.Resize;
begin
  width:=130;
  height:=80;
end;

procedure TjanDipSwitsh.BuildPopup;
        var
        miLock, miName, miInfo, miPuls, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);
       end;

procedure TjanDipSwitsh.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'Unlock' else s := 'lock';
           end;
           miLock.Caption := s;
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := s;
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := s;
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := s;
         end;
       end;


procedure TjanDipSwitsh.Knop1Click(sender:TObject);
Begin
If (FDown8=true) then
      begin setdown8(false)end else setdown8(true);
invalidate;
end;

procedure TjanDipSwitsh.Knop1Click2(sender:TObject);
var
i:integer;
con:TjanConnector;
Begin
FDown8:=false;
for i:=0 to connectors.count-1 do
    begin
    con:=TjanConnector(connectors[i]);
    con.connect;
    con.free;
    end;
free;
end;

//new
procedure TjanDipSwitsh.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDipSwitsh.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDipSwitsh.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanDipSwitsh.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanDipSwitsh.SetDown8(const Value: boolean);
begin
  if value<>FDown8 then
  begin
   FDown8 := Value;
   FDepressed8:=value;
   If Value=true then Fpuls8:=8 else FPuls8:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown4(const Value: boolean);
begin
  if value<>FDown4 then
  begin
   FDown4 := Value;
   FDepressed4:=value;
   If Value=true then Fpuls4:=4 else FPuls4:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown2(const Value: boolean);
begin
  if value<>FDown2 then
  begin
   FDown2 := Value;
   FDepressed2:=value;
   If Value=true then Fpuls2:=2 else FPuls2:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown1(const Value: boolean);
begin
  if value<>FDown1 then
  begin
   FDown1 := Value;
   FDepressed1:=value;
   If Value=true then Fpuls1:=1 else FPuls1:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown(const Value: boolean);
begin
  if value <> FDown then
  begin
   FDown := Value;
   FDepressed:=value;
   If Value=true then FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   If FDown=true then FStatDip := stDipStart else FStatDip := stDipStop;
   invalidate;
  end;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
if Assigned(OnDipChange) then OnDipChange(Self, StatDip,FPuls);
end;

procedure TjanDipSwitsh.SetConnector(const Value: boolean);
begin
  if value<>FConnector then
  begin
   FConnector := Value;
   invalidate;
  end;
end;

procedure TjanDipSwitsh.SetStart(const Value: boolean);
begin
  if value <> FStart then
  begin
   FStart := Value;
   //FDepressed:=value;
   If Value=true then FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   If FStart=true then FStatDip := stDipStart else FStatDip := stDipStop;
   invalidate;
  end;
if Assigned(OnDipChange) then OnDipChange(Self, StatDip, FPuls);
end;

procedure TjanDipSwitsh.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

{ TjanSimPuls }
procedure TjanSimPuls.CMMouseLeave(var Msg: TMessage);
begin
    inherited;
   if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimPuls.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
   if FMouseOver then Exit;         // kleine guard
  // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
   UpdateHintText;
 end;

 procedure TjanSimPuls.SendStatusToBar;
 var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanSimPuls.UpdateHintText;
 begin
   Hint := BuildSimHint(FNaam, BTaal);
 end;

procedure TjanSimPuls.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimPuls.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Temperatuursensor'
 else if value='ENG' then FInfo:='emperature sensor'
 else if value='FR' then FInfo:= 'Le capteur de température'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanSimPuls.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanSimPuls.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FState := stStopped;
  FPulsinterval:=300;
  FDown:=false;
  width:=50;
  height:=80;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'PULS_UIT');
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := KnopUp.canvas.pixels[0,0];
  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'PULS_AAN');
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := KnopDown.canvas.pixels[0,0];
  FPuls:=false;
  puls:=TTimer.Create(self);
  with puls do
    begin
     OnTimer := mTimer;
     enabled:=false;
    end;
     {FSlider:=TSlideSmall.Create(self);
      With FSlider do
      Begin
        parent:=self;
        FSlider.OnChange:= Inter;
        visible:=true;

     end;
     FSlider.Visible:=false;}
 // FTaal:='NL';
  FInfo:= 'Impulsgenerator';
  ShowHint:=true;
  FSoort:='Invoer';
  FNaam:='Impulsgenerator';
end;

destructor TjanSimPuls.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  puls.Free;
  //FSlider.Free;

  inherited;
end;

procedure TjanSimPuls.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(Width - 9, 21, Width, 30);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 21;
    Maakdraad(T, L, wc);
    doMove := False;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  R2 := Rect(13,66,37,75);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimPuls.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  movecursor;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(13,66,37,75);

  if PtInRect(R, p) then
    Starten := not FDown;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimPuls.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanSimPuls.BuildPopup;
        var
        miLock, miName, miInfo, miPuls, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

           // --- Selecteer voor verwijdering
           miSelect := TMenuItem.Create(PopupMenu);
           miSelect.Name := 'miSelect';
           miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
           popupMenu.Items.Add(miSelect);
       end;

       procedure TjanSimPuls.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'Unlock' else s := 'lock';
           end;
           miLock.Caption := s;
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := s;
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := s;
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := s;
         end;
       end;




procedure TjanSimPuls.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin

  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimPuls.Paint;
var p:Tpoint;
    R:TRect;
    Pu:string;
begin
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
    knopDown.Transparent:=true;
    knopUp.Transparent:=true;
     if FDepressed or FDown then
        Begin
        draw(0,0,knopDown);

        end
        else
        Begin
        draw(0,0,knopUp);

        end;

      // Tekenen van Led
        p:=point((self.width div 2),18);
     if starten=false then
       PaintLed(p,false)
       else
       PaintLed(p,FPuls);

     Pu:=IntToStr(pulsinterval);

    Unlock;
    end;
    if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      Brush.Style:=bsClear;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clSilver;pen.style:=psSolid;
      end;
     end;
      if FSelected then
       begin
       R := ClientRect;
      // InflateRect(R, -2, -2);         // binnen de rand tekenen

       Canvas.Brush.Style := bsClear;
       Canvas.Pen.Color := clRed;
       Canvas.pen.style:=psDot;
       Canvas.Pen.Width := 1;
       Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
  end;

end;

procedure TjanSimPuls.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;

        canvas.brush.style:=bsclear;
        canvas.Font.Name:='Arial';canvas.Font.Size:=9;canvas.Font.Style:= [fsBold];
        canvas.Font.Color:=clRed;
        canvas.TextOut(4,40,'puls = 1');
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
        canvas.brush.style:=bsclear;
        canvas.Font.Name:='Arial';canvas.Font.Size:=9;canvas.Font.Style:= [fsBold];
        canvas.Font.Color:=clNavy;
        canvas.TextOut(4,40,'puls = 0');
  end;

  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);

    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);

    Unlock;
   end;
end;

procedure TjanSimPuls.Resize;
begin
  width:=50;
  height:=80;
end;

procedure TjanSimPuls.mTimer(sender: TObject);
begin
   If FPuls=true then
       Begin
       FPuls:=false;
       FState := stStopped;
       pulser:=0;
       end
       else
       begin
       FPuls:=true;
       FState := stStarted;

       pulser:=1;

       end;

       if Assigned(OnPulsChange) then OnPulsChange(Self, State);
invalidate;
end;

procedure TjanSimPuls.Inter(sender: TObject);
begin
FPulsinterval:=3 * 100;
If starten=false then exit else
 Begin
 If starten=true then Begin starten:=false;starten:=true end;

 end;
end;

procedure TjanSimPuls.SetInfo(const Value: String);
begin
   if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

//new
procedure TjanSimPuls.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimPuls.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimPuls.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimPuls.ButtonClick4(sender:TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimPuls.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls.interval := FPulsinterval;
    puls.enabled := Value;

     // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;

   // if (starten=true) then FSlider.Visible:=true else FSlider.Visible:=false;
  end;



  invalidate;
end;

procedure TjanSimPuls.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimPuls.SetPuls(const Value: boolean);
begin
  if value<>FPuls then
  begin
    FPuls := Value;
  end;
  if value=true then
invalidate;
end;

procedure TjanSimPuls.SetPulsen(const Value: Integer);
begin
  if value<>FPulsen then
  begin
    FPulsen:= Value;
  end;
end;

procedure TjanSimPuls.SetPulsinterval(const Value: integer);
begin
  if value<>FPulsinterval then
  begin
    FPulsinterval := Value;
 end;
invalidate;
end;

{ TjanSimSensor }
procedure TjanSimSensor.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

procedure TjanSimSensor.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   FMouseOver := False;
   if Assigned(FOnStatus) then
   begin
    FOnStatus(Self, '', 1);   // Panel leeg
    FOnStatus(Self, '', 0);   // Panel leeg
    FOnStatus(Self, '', 2);   // Panel leeg
    FOnStatus(Self, '', 3);   // Panel leeg
   end;
   if Assigned (FonExit) then
   FonExit(Self);
   if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimSensor.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;


  // laat Naam van object verschijnen in Main statusBar Panel 0
     FOnStatus(Self, Fnaam +'>>', 0);
   // laat status en x,y van object verschijnen in Main StatusBar Panel 1
  FMouseOver := True;
  SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;

constructor TjanSimSensor.Create(AOwner: TComponent);
var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatlicht := stLichtStop;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'LSENS_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;//:= KnopUp.canvas.pixels[0,0];

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'LSENS_IN');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];
  FTaal:='NL';
  FInfo:= 'Lichtsensor';
  ShowHint:=true;
  FNaam:='Lichtsensor';
  FSoort:='Invoer';
  HelpKeyword:='lichtsensor';
end;

destructor TjanSimSensor.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;


procedure TjanSimSensor.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);
       end;

procedure TjanSimSensor.UpdatePopupCaptions;
   var
  miLock, miName, miInfo, miSelect: TMenuItem;
  s: string;
begin
  if not Assigned(PopupMenu) then Exit;

  miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
  miName   := TMenuItem(PopupMenu.FindComponent('miName'));
  miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
  miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

  // --- Lock / Unlock
  if Assigned(miLock) then
  begin
    if BTaal = 'NL' then
    begin
      if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
    end
    else if BTaal = 'FR' then
    begin
      if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
    end
    else if BTaal = 'DU' then
    begin
      if FLock then s := 'Entsperren' else s := 'Sperren';
    end
    else
    begin
      if FLock then s := 'Unlock' else s := 'lock';
    end;
    miLock.Caption := s;
  end;

  // --- Naam wijzigen
  if Assigned(miName) then
  begin
    if BTaal = 'NL' then s := 'Wijzig Naam'
    else if BTaal = 'FR' then s := 'Changer le nom'
    else if BTaal = 'DU' then s := 'Namen ändern'
    else s := 'Change name';
    miName.Caption := s;
  end;

  // --- Select / Deselect (TOGGLE)
  if Assigned(miSelect) then
  begin
    if not Selected then
    begin
      if BTaal = 'NL' then s := 'Selecteer object'
      else if BTaal = 'FR' then s := 'Sélectionner un objet'
      else if BTaal = 'DU' then s := 'Objekt auswählen'
      else s := 'Select object';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Deselecteer object'
      else if BTaal = 'FR' then s := 'Désélectionner l''objet'
      else if BTaal = 'DU' then s := 'Objekt abwählen'
      else s := 'Deselect object';
    end;
    miSelect.Caption := s;
  end;

  // --- Info aan/uit
  if Assigned(miInfo) then
  begin
    if ShowHint then
    begin
      if BTaal = 'NL' then s := 'Info uit'
      else if BTaal = 'FR' then s := 'Infos off'
      else if BTaal = 'DU' then s := 'Infos aus'
      else s := 'Information off';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Info aan'
      else if BTaal = 'FR' then s := 'Infos on'
      else if BTaal = 'DU' then s := 'Infos an'
      else s := 'Information on';
    end;
    miInfo.Caption := s;
  end;
end;

procedure TjanSimSensor.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(49,12,57,20);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 13;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(2,6,20,26);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;


procedure TjanSimSensor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Invalidate;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(2,6,20,26);

  if PtInRect(R, p) then
    Down := not Down;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimSensor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;




procedure TjanSimSensor.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimSensor.Paint;
var
    R:TRect;
begin
knopDown.Transparent:=true;
knopUp.Transparent:=true;
   with canvas do
   begin
   Lock;
     R:=ClientRect;
     if FDepressed or FDown then
      begin
       draw(0,0,knopDown);
       brush.style:=bsclear;
       Font.Name:='Arial'; Font.Size:=9;Font.Style:= [fsBold];
       Font.Color:=clRed;
       TextOut(50,19,'1');
      end
      else
      begin
       draw(0,0,knopUp);
       brush.style:=bsclear;
       Font.Name:='Arial'; Font.Size:=9;Font.Style:= [fsBold];
       Font.Color:=clNavy;
       TextOut(50,19,'0');
      end;
   Unlock;
   end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
end;

procedure TjanSimSensor.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    lock;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimSensor.Resize;
begin
  width:=58;
  height:=32;
end;



//new
procedure TjanSimSensor.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimSensor.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimSensor.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimSensor.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimSensor.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls:=1;
  //  if FDown=true then FStatLicht := stLichtStart
  //  else FStatLicht := stLichtStop;
    invalidate;

     // ✅ Onmiddellijke refresh als muis erboven staat
     if FMouseOver then
      SendStatusToBar;
  end;
// if Assigned(OnLichtChange) then OnLichtChange(Self, StatLicht);
end;

procedure TjanSimSensor.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimSensor.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimSensor.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
    FPuls:= Value;
end;

procedure TjanSimSensor.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
 C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
 LB := nil;
 C := Owner;
 while (C <> nil) and (LB = nil) do
 begin
   if C is TjanSimLogicBox then
     LB := TjanSimLogicBox(C)
   else
     C := C.Owner;
 end;
 if LB = nil then Exit;
s:= Format('X=%d Y=%d', [Left, Top]);
LB.PushStatus(Self, s, 2);
end;

procedure TjanSimSensor.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;

procedure TjanSimSensor.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimSensor.SetNaam(const Value: String);
begin
    if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

procedure TjanSimSensor.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='schakelaar'
 else if value='ENG' then FInfo:='switch'
 else if value='FR' then FInfo:= 'l´interrupteur'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;
end;


// einde TjanSimsensor


{ TjanSimWarm }
procedure TjanSimWarm.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

procedure TjanSimWarm.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
   FMouseOver := False;
   if Assigned(FOnStatus) then
   begin
     FOnStatus(Self, '', 0);
     FOnStatus(Self, '', 1);
     FOnStatus(Self, '', 2);
     FOnStatus(Self, '', 3);
   end;

    if Assigned(FOnExit) then
    FOnExit(Self);

   if not FLock then
   begin
     select:=false;
     invalidate;
   end;
end;

procedure TjanSimWarm.CMMouseEnter(var Msg: TMessage);
var
 s:String;
begin
  inherited;
   UpdateHintText;


  // laat Naam van object verschijnen in Main statusBar Panel 0
     FOnStatus(Self, Fnaam +'>>', 0);
  // laat status en x,y van object verschijnen in Main StatusBar Panel 1
  FMouseOver := True;
  SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;

  end;
end;

constructor TjanSimWarm.Create(AOwner: TComponent);
var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatTemp := stTempStop;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'WSENS_UIT');
   for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;//:= KnopUp.canvas.pixels[0,0];

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'WSENS_IN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];
  FTaal:='NL';
  FNaam:='Temperatuursensor';
  FInfo:= 'Temperatuursensor';
  ShowHint:=true;
  FSoort:='Invoer';
end;

destructor TjanSimWarm.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimWarm.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  // Rechtsklik: popup tonen
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(49,13,57,21);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 14;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(1,1,21,14);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimWarm.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(1,1,21,14);

  if PtInRect(R, p) then
    Down := not Down;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimWarm.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanSimWarm.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);


          // --- Selecteer voor verwijdering
           miSelect := TMenuItem.Create(PopupMenu);
           miSelect.Name := 'miSelect';
           miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miSelect);
       end;

procedure TjanSimWarm.UpdatePopupCaptions;
       var
        miLock, miName, miInfo, miSelect: TMenuItem;
        s: string;
       begin
        if not Assigned(PopupMenu) then Exit;

        miLock := TMenuItem(PopupMenu.FindComponent('miLock'));
        miName := TMenuItem(PopupMenu.FindComponent('miName'));
        miInfo := TMenuItem(PopupMenu.FindComponent('miInfo'));
        miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

        if Assigned(miLock) then
         begin
          if BTaal = 'NL' then
          begin
           if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
          end
          else if BTaal = 'FR' then
          begin
           if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
          end
		  else if BTaal = 'DU' then
          begin
           if FLock then s := 'Déverrouiller' else s := 'Sperren';
          end
          else
          begin
           if FLock then s := 'Unbolt' else s := 'Bolt';
         end;
         miLock.Caption := s;
        end;

        if Assigned(miName) then
         begin
          if BTaal = 'NL' then s := 'Wijzig Naam'
          else if BTaal = 'FR' then s := 'Changer le nom'
		   else if BTaal = 'DU' then s := 'Namen ändern'
          else s := 'Change name';
          miName.Caption := s;
         end;

         // --- Select / Deselect (TOGGLE)
        if Assigned(miSelect) then
         begin
          if not Selected then
           begin
            if BTaal = 'NL' then s := 'Selecteer object'
            else if BTaal = 'FR' then s := 'Sélectionner un objet'
            else if BTaal = 'DU' then s := 'Objekt auswählen'
            else s := 'Select object';
           end
          else
          begin
           if BTaal = 'NL' then s := 'Deselecteer object'
           else if BTaal = 'FR' then s := 'Désélectionner l''objet'
           else if BTaal = 'DU' then s := 'Objekt abwählen'
           else s := 'Deselect object';
          end;
          miSelect.Caption := s;
         end;

        if Assigned(miInfo) then
         begin
          if ShowHint then
           begin
            if BTaal = 'NL' then s := 'Info uit'
            else if BTaal = 'FR' then s := 'Infos off'
			else if BTaal = 'DU' then s := 'Infos raus'
            else s := 'Information off';
           end
           else
         begin
          if BTaal = 'NL' then s := 'Info aan'
          else if BTaal = 'FR' then s := 'Infos on'
		  else if BTaal = 'DU' then s := 'Infos zu'
          else s := 'Information on';
         end;
    miInfo.Caption := s;
  end;
end;



procedure TjanSimWarm.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimWarm.Paint;
var p:Tpoint;
    R:TRect;
begin
 knopDown.Transparent:=true;
 knopUp.Transparent:=true;
 with canvas do
   begin
     Lock;
     R:=ClientRect;
     if FDepressed or FDown then
       Begin
        draw(0,0,knopDown);
        brush.style:=bsclear;
        Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
        Font.Color:=clRed;
        TextOut(50,20,'1');
       end
       else
       begin
        draw(0,0,knopUp);
        brush.style:=bsclear;
        Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
        Font.Color:=clNavy;
        TextOut(50,20,'0');
       end;
     brush.style:=bsclear;
     Font.Style:= [];Font.Color:=clBlack;
     If BTaal='NL' then begin If Down=false then TextOut(1,20,'koud') else TextOut(1,20,'warm');end;
     If BTaal='ENG' then begin If Down=false then TextOut(1,20,'cold') else TextOut(1,20,'hot');end;
     If BTaal='FR' then begin If Down=false then TextOut(1,20,'froid') else TextOut(1,20,'chauffer');end;
     If BTaal='DU' then begin If Down=false then TextOut(1,20,'kalt') else TextOut(1,20,'heiß');end;
     Unlock;
  end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
    if Selected then   //kader voor selectie delete
     begin
      R := ClientRect;
      // InflateRect(R, -1, -1);         // binnen de rand tekenen
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
      // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;

end;

procedure TjanSimWarm.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do
   begin
    lock;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimWarm.Resize;
begin
  width:=58;
  height:=32;
end;



//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;
//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
end;

procedure TjanSimWarm.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimWarm.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls:=1;
    if FDown=true then FStatTemp := stTempStart else FStatTemp := stTempStop;
    invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
  if Assigned(OnTempChange) then OnTempChange(Self, StatTemp);
end;

procedure TjanSimWarm.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;
procedure TjanSimWarm.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimWarm.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

//nieuwe TOEGEVOEGD event
procedure TjanSimWarm.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;

procedure TjanSimWarm.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

// NIEUW Setnaam
procedure TjanSimWarm.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimWarm.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Temperatuursensor'
 else if value='ENG' then FInfo:='Temperature sensor'
 else if value='FR' then FInfo:= 'Le capteur de température'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;
// einde TjanSimWarm

procedure TjanSimLight.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanSimLight.Create(AOwner: TComponent);
var
XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=69;
  height:=23;
  connectors:=TList.create;

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'L_UIT');
  for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lUit.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'L_AAN');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAan.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := lAan.canvas.pixels[0,0];


  FDown:=false; //xxx
  FInfo:= 'Lamp';//xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Lamp';//xxx
end;

destructor TjanSimLight.Destroy;
begin
  inherited;
  lUit.Free;
  lAan.Free;
  connectors.free;
end;

procedure TjanSimLight.SendStatusToBar;
var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Uitvoer','Export','Exporter','Export');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanSimLight.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimLight.SetTaal(const Value: String);
begin
if value<>FTaal then
 begin
   FTaal:= Value;
end;
// ✅ Onmiddellijke refresh als muis erboven staat
   if FMouseOver then
     SendStatusToBar;
   UpdateHintText;
   invalidate;
end;

procedure TjanSimLight.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimLight.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;



procedure TjanSimLight.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimLight.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
 UpdateHintText;
if Assigned(FOnEnter) then
   FOnEnter(Self);


// ✅ statusbar meteen vullen
 FMouseOver := True;
 SendStatusToBar;  // vult panel 0/1/2


 BringToFront;
 if not FLock then
 begin
   Select := True;
   Invalidate;
 end;
end;





procedure TjanSimLight.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
p : TPoint;

S:String;
begin
   inherited;
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp:=point(x,y);
  doMove:= true;
  oldp:=point(x,y);
  AnchorConnectors;
       // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimLight.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
inherited;
   if FLock=true then exit;
   if FDepressed then exit;
   if Parent = nil then Exit;

   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);

   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;
     Left:=newleft;
     Top:=newtop;

     MoveConnectors;

     if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
  SendStatusToBar;
     end
   end;

end;

procedure TjanSimLight.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
  var R:TRect;
      p:Tpoint;
  begin
   inherited;
    if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;
    movecursor;
    FDepressed:=false;
    p:=point(x,y);
    R:=Rect(13,66,37,75);

    if ptinrect(R,p) then Down:=not FDown;

    FMouseOver := True;
    SendStatusToBar;
  end;

  procedure TjanSimLight.BuildPopup;
  var
    miLock, miName, miInfo, miSelect: TMenuItem;
  begin
    if not Assigned(PopupMenu) then
      PopupMenu := TPopupMenu.Create(Self)
    else
      PopupMenu.Items.Clear;

    // --- Lock / Unlock
    miLock := TMenuItem.Create(PopupMenu);
    miLock.Name := 'miLock';
    miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miLock);

    // --- Naam wijzigen
    miName := TMenuItem.Create(PopupMenu);
    miName.Name := 'miName';
    miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miName);

    // --- Info aan/uit
    miInfo := TMenuItem.Create(PopupMenu);
    miInfo.Name := 'miInfo';
    miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miInfo);

    // --- Selecteer voor verwijdering
    miSelect := TMenuItem.Create(PopupMenu);
    miSelect.Name := 'miSelect';
    miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miSelect);
  end;

  procedure TjanSimLight.UpdatePopupCaptions;
         var
           miLock, miName, miInfo, miSelect: TMenuItem;
           s: string;
         begin
           if not Assigned(PopupMenu) then Exit;

           miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
           miName   := TMenuItem(PopupMenu.FindComponent('miName'));
           miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
           miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

           // --- Lock / Unlock
           if Assigned(miLock) then
           begin
             if BTaal = 'NL' then
             begin
               if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
             end
             else if BTaal = 'FR' then
             begin
               if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
             end
             else if BTaal = 'DU' then
             begin
               if FLock then s := 'Entsperren' else s := 'Sperren';
             end
             else
             begin
               if FLock then s := 'Unlock' else s := 'lock';
             end;
             miLock.Caption := s;
           end;

           // --- Naam wijzigen
           if Assigned(miName) then
           begin
             if BTaal = 'NL' then s := 'Wijzig Naam'
             else if BTaal = 'FR' then s := 'Changer le nom'
             else if BTaal = 'DU' then s := 'Namen ändern'
             else s := 'Change name';
             miName.Caption := s;
           end;

           // --- Select / Deselect (TOGGLE)
           if Assigned(miSelect) then
           begin
             if not Selected then
             begin
               if BTaal = 'NL' then s := 'Selecteer object'
               else if BTaal = 'FR' then s := 'Sélectionner un objet'
               else if BTaal = 'DU' then s := 'Objekt auswählen'
               else s := 'Select object';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Deselecteer object'
               else if BTaal = 'FR' then s := 'Désélectionner l''objet'
               else if BTaal = 'DU' then s := 'Objekt abwählen'
               else s := 'Deselect object';
             end;
             miSelect.Caption := s;
           end;

           // --- Info aan/uit
           if Assigned(miInfo) then
           begin
             if ShowHint then
             begin
               if BTaal = 'NL' then s := 'Info uit'
               else if BTaal = 'FR' then s := 'Infos off'
               else if BTaal = 'DU' then s := 'Infos aus'
               else s := 'Information off';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Info aan'
               else if BTaal = 'FR' then s := 'Infos on'
               else if BTaal = 'DU' then s := 'Infos an'
               else s := 'Information on';
             end;
             miInfo.Caption := s;
           end;
         end;

procedure TjanSimLight.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimLight.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimLight.Paint;
var
R:TRect;
begin
 With canvas do
 begin
   Lock;
   lUit.Transparent:=true; lAan.Transparent:=true;
   If FLit=false then
     draw(0,0,lUit)
     else
     draw(0,0,lAan);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,11,'La');
   UnLock;
 end;
 if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
 // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
     R := ClientRect;
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
     // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;
end;

procedure TjanSimLight.Resize;
begin
  width:=69;
  height:=23;
end;

//old
{
procedure TjanSimLight.LampClick(sender:TObject);
Begin
If FLit=true then
     FLit:=false else FLit:=true;
invalidate;
end;

procedure TjanSimLight.LampClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimLight.LampClick2(sender:TObject);
Begin
free;
end;

procedure TjanSimLight.LampClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;
}
// einde old

procedure TjanSimLight.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimLight.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimLight.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimLight.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimLight.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimLight.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimLight.SetLit(const Value: boolean);
begin
 if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;

{TjanSimRelais}

procedure TjanSimRelais.SendStatusToBar;//xxxx
var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Uitvoer','Export','Exporter','Export');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

procedure TjanSimRelais.SetNaam(const Value: String);
 begin
    if FNaam <> Value then
   begin
     FNaam := Value;
     Invalidate;
     // ✅ Onmiddellijke refresh als muis erboven staat
     if FMouseOver then
       SendStatusToBar;
   end;
 end;

 procedure TjanSimRelais.SetTaal(const Value: String);
 begin
 if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
    UpdateHintText;
    invalidate;
 end;

 procedure TjanSimRelais.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimRelais.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanSimRelais.Create(AOwner: TComponent);
 var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=80;
  height:=62;
  connectors:=TList.create;

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'R_UIT');
   for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lUit.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;// lUit.canvas.pixels[0,0];

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'R_AAN');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := clFuchsia;// lAan.canvas.pixels[0,0];

  FDown:=false; //xxxx
  FNaam:='Relais'; //xxxx
  FSoort:='Uitvoer';  //xxxx
  FInfo:= 'Relais';  //xxxx
  ShowHint:=true;
end;

destructor TjanSimRelais.Destroy;
begin
  inherited;
  lUit.Free;
  lAan.Free;

  connectors.free;
end;

procedure TjanSimRelais.CMMouseLeave(var Msg: TMessage); //xxxx
begin
  inherited;
  if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimRelais.CMMouseEnter(var Msg: TMessage);//xxxx
begin
   inherited;
 UpdateHintText;
if Assigned(FOnEnter) then
   FOnEnter(Self);


// ✅ statusbar meteen vullen
 FMouseOver := True;
 SendStatusToBar;  // vult panel 0/1/2


 BringToFront;
 if not FLock then
 begin
   Select := True;
   Invalidate;
 end;
end;

procedure TjanSimRelais.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;

procedure TjanSimRelais.MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer);//xxxx
var
p : TPoint;

S:String;
begin
   inherited;
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;
  mdp:=point(x,y);
  doMove:= true;
  oldp:=point(x,y);
  AnchorConnectors;

     // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimRelais.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock then exit;
   if FDepressed then exit;
   if Parent = nil then Exit;


   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);

   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;
     Left:=newleft;
     Top:=newtop;

     MoveConnectors;

     if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
  SendStatusToBar;
     end
  end;

end;

procedure TjanSimRelais.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);

var R:TRect;
      p:Tpoint;
  begin
   inherited;
    if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;
    movecursor;
    FDepressed:=false;
    p:=point(x,y);
    R:=Rect(13,66,37,75);

    if ptinrect(R,p) then Down:=not FDown;

    FMouseOver := True;
    SendStatusToBar;
  end;

 procedure TjanSimRelais.BuildPopup;
  var
    miLock, miName, miInfo, miSelect: TMenuItem;
  begin
    if not Assigned(PopupMenu) then
      PopupMenu := TPopupMenu.Create(Self)
    else
      PopupMenu.Items.Clear;

    // --- Lock / Unlock
    miLock := TMenuItem.Create(PopupMenu);
    miLock.Name := 'miLock';
    miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miLock);

    // --- Naam wijzigen
    miName := TMenuItem.Create(PopupMenu);
    miName.Name := 'miName';
    miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miName);

    // --- Info aan/uit
    miInfo := TMenuItem.Create(PopupMenu);
    miInfo.Name := 'miInfo';
    miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miInfo);

    // --- Selecteer voor verwijdering
    miSelect := TMenuItem.Create(PopupMenu);
    miSelect.Name := 'miSelect';
    miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miSelect);
  end;

  procedure TjanSimRelais.UpdatePopupCaptions;
         var
           miLock, miName, miInfo, miSelect: TMenuItem;
           s: string;
         begin
           if not Assigned(PopupMenu) then Exit;

           miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
           miName   := TMenuItem(PopupMenu.FindComponent('miName'));
           miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
           miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

           // --- Lock / Unlock
           if Assigned(miLock) then
           begin
             if BTaal = 'NL' then
             begin
               if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
             end
             else if BTaal = 'FR' then
             begin
               if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
             end
             else if BTaal = 'DU' then
             begin
               if FLock then s := 'Entsperren' else s := 'Sperren';
             end
             else
             begin
               if FLock then s := 'Unlock' else s := 'lock';
             end;
             miLock.Caption := s;
           end;

           // --- Naam wijzigen
           if Assigned(miName) then
           begin
             if BTaal = 'NL' then s := 'Wijzig Naam'
             else if BTaal = 'FR' then s := 'Changer le nom'
             else if BTaal = 'DU' then s := 'Namen ändern'
             else s := 'Change name';
             miName.Caption := s;
           end;

           // --- Select / Deselect (TOGGLE)
           if Assigned(miSelect) then
           begin
             if not Selected then
             begin
               if BTaal = 'NL' then s := 'Selecteer object'
               else if BTaal = 'FR' then s := 'Sélectionner un objet'
               else if BTaal = 'DU' then s := 'Objekt auswählen'
               else s := 'Select object';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Deselecteer object'
               else if BTaal = 'FR' then s := 'Désélectionner l''objet'
               else if BTaal = 'DU' then s := 'Objekt abwählen'
               else s := 'Deselect object';
             end;
             miSelect.Caption := s;
           end;

           // --- Info aan/uit
           if Assigned(miInfo) then
           begin
             if ShowHint then
             begin
               if BTaal = 'NL' then s := 'Info uit'
               else if BTaal = 'FR' then s := 'Infos off'
               else if BTaal = 'DU' then s := 'Infos aus'
               else s := 'Information off';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Info aan'
               else if BTaal = 'FR' then s := 'Infos on'
               else if BTaal = 'DU' then s := 'Infos an'
               else s := 'Information on';
             end;
             miInfo.Caption := s;
           end;
         end;

procedure TjanSimRelais.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;


procedure TjanSimRelais.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimRelais.Paint;
var
R:TRect;
begin
lAan.Transparent:=true;
lUit.Transparent:=true;
with canvas do
 begin
   Lock;
   If FLit=false then
     draw(0,0,lUit)
     else draw(0,0,lAan);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,35,'R');
     TextOut(48,-2,'R1');
     TextOut(48,50,'R2');
   Unlock;
 end;
 if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
  // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
     R := ClientRect;
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
     // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;

end;

procedure TjanSimRelais.Resize;
begin
  width:=80;
  height:=62;
end;



procedure TjanSimRelais.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimRelais.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;



procedure TjanSimRelais.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimRelais.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimRelais.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimRelais.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimRelais.SetLit(const Value: boolean);
begin
  if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;


{TjanSimBuzzer}

procedure TjanSimBuzzer.SendStatusToBar;
var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Uitvoer','Export','Exporter','Export');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanSimBuzzer.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimBuzzer.SetTaal(const Value: String);
begin
if value<>FTaal then
 begin
   FTaal:= Value;
end;
// ✅ Onmiddellijke refresh als muis erboven staat
   if FMouseOver then
     SendStatusToBar;
   UpdateHintText;
   invalidate;
end;

procedure TjanSimBuzzer.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimBuzzer.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimBuzzer.BuildPopup;
  var
    miLock, miName, miInfo, miSelect: TMenuItem;
  begin
    if not Assigned(PopupMenu) then
      PopupMenu := TPopupMenu.Create(Self)
    else
      PopupMenu.Items.Clear;

    // --- Lock / Unlock
    miLock := TMenuItem.Create(PopupMenu);
    miLock.Name := 'miLock';
    miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miLock);

    // --- Naam wijzigen
    miName := TMenuItem.Create(PopupMenu);
    miName.Name := 'miName';
    miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miName);

    // --- Info aan/uit
    miInfo := TMenuItem.Create(PopupMenu);
    miInfo.Name := 'miInfo';
    miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miInfo);

    // --- Selecteer voor verwijdering
    miSelect := TMenuItem.Create(PopupMenu);
    miSelect.Name := 'miSelect';
    miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
    PopupMenu.Items.Add(miSelect);
  end;

  procedure TjanSimBuzzer.UpdatePopupCaptions;
         var
           miLock, miName, miInfo, miSelect: TMenuItem;
           s: string;
         begin
           if not Assigned(PopupMenu) then Exit;

           miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
           miName   := TMenuItem(PopupMenu.FindComponent('miName'));
           miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
           miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

           // --- Lock / Unlock
           if Assigned(miLock) then
           begin
             if BTaal = 'NL' then
             begin
               if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
             end
             else if BTaal = 'FR' then
             begin
               if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
             end
             else if BTaal = 'DU' then
             begin
               if FLock then s := 'Entsperren' else s := 'Sperren';
             end
             else
             begin
               if FLock then s := 'Unlock' else s := 'lock';
             end;
             miLock.Caption := s;
           end;

           // --- Naam wijzigen
           if Assigned(miName) then
           begin
             if BTaal = 'NL' then s := 'Wijzig Naam'
             else if BTaal = 'FR' then s := 'Changer le nom'
             else if BTaal = 'DU' then s := 'Namen ändern'
             else s := 'Change name';
             miName.Caption := s;
           end;

           // --- Select / Deselect (TOGGLE)
           if Assigned(miSelect) then
           begin
             if not Selected then
             begin
               if BTaal = 'NL' then s := 'Selecteer object'
               else if BTaal = 'FR' then s := 'Sélectionner un objet'
               else if BTaal = 'DU' then s := 'Objekt auswählen'
               else s := 'Select object';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Deselecteer object'
               else if BTaal = 'FR' then s := 'Désélectionner l''objet'
               else if BTaal = 'DU' then s := 'Objekt abwählen'
               else s := 'Deselect object';
             end;
             miSelect.Caption := s;
           end;

           // --- Info aan/uit
           if Assigned(miInfo) then
           begin
             if ShowHint then
             begin
               if BTaal = 'NL' then s := 'Info uit'
               else if BTaal = 'FR' then s := 'Infos off'
               else if BTaal = 'DU' then s := 'Infos aus'
               else s := 'Information off';
             end
             else
             begin
               if BTaal = 'NL' then s := 'Info aan'
               else if BTaal = 'FR' then s := 'Infos on'
               else if BTaal = 'DU' then s := 'Infos an'
               else s := 'Information on';
             end;
             miInfo.Caption := s;
           end;
         end;

procedure TjanSimBuzzer.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R,Rc:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // check for corners in bounds
      Rc:=con.BoundsRect;
      // TL
      if ptinrect(R,point(Rc.left,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTL);
      end
      // TR
      else if ptinrect(R,point(Rc.right,Rc.top)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmTR);
      end
      // BR
      else if ptinrect(R,point(Rc.right,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBR);
      end
      // BL
      else if ptinrect(R,point(Rc.left,Rc.bottom)) then
      begin
        connectors.Add(con);
        con.AnchorCorner(p,jcmBL);
      end
    end;
end;

constructor TjanSimBuzzer.Create(AOwner: TComponent);
  var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=80;
  height:=44;
  connectors:=TList.create;

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'BA');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAan.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := clFuchsia;//lAan.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'BU');
  for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;//:= lUit.canvas.pixels[0,0];

  FDown:=false; //xxx
  FInfo:= 'Zoemer';//xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Zoemer';//xxx
  ShowHint:=true;
end;

destructor TjanSimBuzzer.Destroy;
begin
  inherited;
  lUit.Free;
  lAan.Free;
  connectors.free;
end;

procedure TjanSimBuzzer.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimBuzzer.CMMouseEnter(var Msg: TMessage);
begin
   inherited;
 UpdateHintText;
if Assigned(FOnEnter) then
   FOnEnter(Self);


// ✅ statusbar meteen vullen
 FMouseOver := True;
 SendStatusToBar;  // vult panel 0/1/2


 BringToFront;
 if not FLock then
 begin
   Select := True;
   Invalidate;
 end;
end;


procedure TjanSimBuzzer.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;

procedure TjanSimBuzzer.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
p : TPoint;

S:String;
begin
  inherited;
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;
  mdp:=point(x,y);
  doMove:= true;
  oldp:=point(x,y);
  AnchorConnectors;

    // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);

end;

procedure TjanSimBuzzer.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock then exit;
   if FDepressed then exit;
   if Parent = nil then Exit;

   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);

   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;
     Left:=newleft;
     Top:=newtop;

     MoveConnectors;

     if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
  SendStatusToBar;
     end
   end;

end;


procedure TjanSimBuzzer.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
  var R:TRect;
       p:Tpoint;
   begin
    inherited;
     if Parent is TjanGridS then
            TjanGridS(Parent).EndGuideLines;
     movecursor;
     FDepressed:=false;
     p:=point(x,y);
     R:=Rect(13,66,37,75);

     if ptinrect(R,p) then Down:=not FDown;

     FMouseOver := True;
     SendStatusToBar;
   end;

procedure TjanSimBuzzer.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimBuzzer.Paint;
var
R:TRect;

begin
lAan.Transparent:=true;
lUit.Transparent:=true;
  With canvas do
  begin
   Lock;
   If FLit=false then
     draw(0,0,lUit)
     else draw(0,0,lAan);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,25,'Z');
  Unlock;
  end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
  // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
      R := ClientRect;
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
     // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;
end;

procedure TjanSimBuzzer.Resize;
begin
  width:=80;
  height:=44;
end;


procedure TjanSimBuzzer.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimBuzzer.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimBuzzer.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimBuzzer.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimBuzzer.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimBuzzer.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimBuzzer.SetLit(const Value: boolean);
begin
  if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;

{ TjanSimLogicBox }

procedure TjanSimLogicBox.cpuOnTimer(sender: TObject);
var wc:TWinControl;
    i:integer;
begin
  wc:=parent;
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
      TjanConnector(wc.controls[i]).connect;

end;

constructor TjanSimLogicBox.create(AOwner: Tcomponent);
begin
  inherited Create(AOwner);
  // Init Hint verschijning bij knoppen
  ShowHint := True;
  ParentShowHint := False;
  FLastHintText := '';

  // InitTools;




   // ⬇️ Deze box als globale referentie onthouden
  GlobalSimBox := Self;

  if (Align=(alTop)) or (Align=(alBottom))then
  begin
  height:=45;
  FKnopLeft:=2;FKnopTop:=4;FSpatie:=2;
  end;
  if (Align=(alLeft)) or (Align=(alRight))then
    begin
    width:=35;
    FKnopLeft:=9;
    FKnopTop:=25;
    FSpatie:=2;
    end;
  FOpen:=true;
  FFirst:=false;
  FNew:=false;
  FDraden:=false;
  FImputColor:=clSilver;// clgreen;
  FOutputColor:=clSilver;//clBlue;
  FBoxTaal:= stDutch;
  FVerwerkingColor:=clSilver;//clRed;
  FFilterLijst:= TStringList.Create;
  templijst:=TStringList.Create;
  tempFile:=TStringList.Create;
  // opladen van speciale cursors
  Screen.Cursors[crDrukknop]    := LoadCursor(hInstance,  'DRUKKNOP');
  Screen.Cursors[crSchakelaar]    := LoadCursor(hInstance,  'SCHAKELAAR');
  Screen.Cursors[crSensor]    := LoadCursor(hInstance,  'SENSOR');
  Screen.Cursors[crWarm]    := LoadCursor(hInstance,  'WARM');
  Screen.Cursors[crPuls]    := LoadCursor(hInstance,  'PULS');
  Screen.Cursors[crDip]    := LoadCursor(hInstance,  'DIP');
  Screen.Cursors[crAnd]    := LoadCursor(hInstance,  'AND');
  Screen.Cursors[crOr]    := LoadCursor(hInstance,  'OR');
  Screen.Cursors[crNot]    := LoadCursor(hInstance,  'NOT');
  Screen.Cursors[crTeller]    := LoadCursor(hInstance,  'TELLER');
  Screen.Cursors[crGeheugen]    := LoadCursor(hInstance,  'GEHEUGEN');
  Screen.Cursors[crLamp]    := LoadCursor(hInstance,  'LAMP');
  Screen.Cursors[crRelais]    := LoadCursor(hInstance,  'RELAIS');
  Screen.Cursors[crZoemer]    := LoadCursor(hInstance,  'ZOEMER');
  Screen.Cursors[crDisplay]    := LoadCursor(hInstance,  'DISPLAY');
  Screen.Cursors[crDraad]    := LoadCursor(hInstance,  'DRAAD');
  Screen.Cursors[crMeter]    := LoadCursor(hInstance,  'VOLT');

  //aanmaken bitmaps in het geheugen
  bmCon:=TBitmap.create;//bmCon2:=TBitmap.Create;
  bmLogicAnd:=TBitmap.create;bmLogicOr:=TBitmap.create;
  bmButton:=TBitmap.create;bmLogicNot:=TBitmap.create;
  bmLight:=TBitmap.create;bmRelais:=TBitmap.create;
  bmKnop:=TBitmap.Create; bmPuls:=TBitmap.Create;
  bmBuzzer:=TBitmap.Create;bmSensor:=TBitmap.Create;bmWarm:=TBitmap.Create;
  bmTeller:=TBitmap.Create;bmMemory:=TBitmap.Create;bmDisplay:=TBitmap.Create;
  bmDipSwitsh:=TBitmap.Create;bmMeter:=TBitmap.Create;


 { bmCon2.LoadFromResourceName(HInstance,'RCON2');
  bmCon2.Transparent := True;
  bmCon2.TransParentColor := bmCon2.canvas.pixels[0,0];}

  bmButton.LoadFromResourceName(HInstance,'RBUTTON');
  bmMeter.LoadFromResourceName(HInstance,'VOLT');


  bmKnop.LoadFromResourceName(HInstance,'RKNOP');
  bmPuls.LoadFromResourceName(HInstance,'RPULS');
  bmCon.LoadFromResourceName(HInstance,'RCON2');

  bmLogicAnd.LoadFromResourceName(HInstance,'L_AND');
  bmLogicAnd.Transparent := True;
  bmLogicAnd.TransParentColor := bmLogicAnd.canvas.pixels[0,0];

  bmLogicOr.LoadFromResourceName(HInstance,'L_OR');
  bmLogicOr.Transparent := True;
  bmLogicOr.TransParentColor := bmLogicAnd.canvas.pixels[0,0];

  bmLogicNot.LoadFromResourceName(HInstance,'L_NOT');
  bmLogicNot.Transparent := True;
  bmLogicNot.TransParentColor := bmLogicNot.canvas.pixels[0,0];

  bmLight.LoadFromResourceName(HInstance,'RLIGHT');
  bmRelais.LoadFromResourceName(HInstance,'RRELAIS');
  bmRelais.Transparent := True;
  bmRelais.TransParentColor := bmRelais.canvas.pixels[0,0];

  bmDipSwitsh.LoadFromResourceName(HInstance,'RDIPSW');
  bmDipSwitsh.Transparent := True;
  bmDipSwitsh.TransParentColor := bmDipSwitsh.canvas.pixels[0,0];

  bmTeller.LoadFromResourceName(HInstance,'RTELLER');
  bmTeller.Transparent := True;
  bmTeller.TransParentColor := bmTeller.canvas.pixels[0,0];

  bmMemory.LoadFromResourceName(HInstance,'RMEMORY');
  bmMemory.Transparent := True;
  bmMemory.TransParentColor := bmMemory.canvas.pixels[0,0];

  bmBuzzer.LoadFromResourceName(HInstance,'RBUZZER');
  bmBuzzer.Transparent := True;
  bmBuzzer.TransParentColor := bmBuzzer.canvas.pixels[0,0];

  bmSensor.LoadFromResourceName(HInstance,'RSENSOR');
  bmSensor.Transparent := True;
  bmSensor.TransParentColor := bmSensor.canvas.pixels[0,0];

  bmWarm.LoadFromResourceName(HInstance,'RWARM');
  bmWarm.Transparent := True;
  bmWarm.TransParentColor := bmWarm.canvas.pixels[0,0];

  bmDisplay.LoadFromResourceName(HInstance,'RDISPLAY');
  bmDisplay.Transparent := True;
  bmDisplay.TransParentColor := bmDisplay.canvas.pixels[0,0];
  // opzetten van knoppen (imputobjecten)
  FDrukknop:=True;FSchakelaar:=True;FPuls:=True;FSensor:=True;FWarm:=True;FTeller:=true;
  // aantal imputobjecten
  FImputAantal:=6;
  // opzetten van knoppen (Verwerkingsobjecten)
  FLogicAnd:=True;FMemory:=true;FTeller:=true;FLogicOr:=True;FLogicNot:=True;
  // aantal Verwerkingobjecten
  FVerwerkingAantal:=5;
  // opzetten van knoppen (Uitvoerobjecten)
  FLamp:=True;FRelais:=True;FBuzzer:=True;FDisplay:=true;
  FOutputAantal:=4;

  FDraad:=True;FGrid:=true;//FSave:=true;

  //DReset:=false;
  DRelais:=false;DBuzzer:=false;DSensor:=false;DWarm:=false;
  DCon:=false;DLogicAnd:=false;DLogicOr:=false;DLogicNot:=false;
  DButton:=false;DLight:=false;DKnop:=false;DPuls:=false;
  DTeller:=false;DMemory:=false;DDisplay:=false;DGrid:=false;//DSave:=false;

  cpu:=TTimer.Create(self);
  cpu.Enabled:=false;
  cpu.OnTimer:=cpuOnTimer;
  cpu.Interval:=50;
  FBColor:=clSilver;
  Align:=(alTop);


end;

procedure TjanSimLogicBox.Encode(tekst:TStringList);
var
  e,d: String;
  temp:TStringList;
  i: integer;
begin
  d:='';temp:=TStringlist.Create;
  for i:= 0 to tekst.count-1 do
    begin
    d:= tekst.Strings[i];
    e:=SZFullEncodeBase64(d);
    temp.Add(e)
    end;
    tekst.Clear;
    tekst.Assign(temp);
  temp.Free;
end;

procedure TjanSimLogicBox.decode(tekst:TStringList);
var
  e,d: string;
  i: integer;
  temp:TStringList;
begin
  d:='';temp:=TStringlist.Create;
  for i:= 0 to tekst.count-1 do
    Begin
    d:= tekst.Strings[i];
    e:=SZDecodeBase64(d);
    temp.Add(e)
    end;
    tekst.Clear;
    tekst.Assign(temp);
  temp.Free;
end;

destructor TjanSimLogicBox.Destroy;
begin
 // FreeTools;
  cpu.free;
  bmBuzzer.Free;bmSensor.Free;bmWarm.Free;bmGrid.Free;bmCon.free;
  bmLogicAnd.free;bmLogicOr.free;bmLogicNot.free;
  bmButton.free;bmKnop.Free;bmPuls.Free;bmLight.free;bmRelais.Free;
  bmTeller.Free;bmMemory.Free;bmDisplay.Free;bmDipSwitsh.Free;
  FFilterLijst.Free;templijst.Free;tempFile.Free;

  inherited Destroy;
end;

//nieuw voor save
FUNCTION TjanSimLogicBox.InFilterL (aCompClassName, aPropName: STRING): BOOLEAN;
// Returns TRUE, if a property is in the filterlist
VAR i: INTEGER;
BEGIN
 Result:= TRUE;
 IF FFilterLijst.Find (aPropName, i) then EXIT;
 IF FFilterLijst.Find (aCompClassName + '.' + aPropName, i) then EXIT;
 Result:= false;
END; // InfilterList

PROCEDURE TjanSimLogicBox.SetDefaultFilt;
// Initialize the filterlist
BEGIN
 WITH FFilterLijst DO
 BEGIN
  // properties that should be saved from ALL components
  Add ('Text');          // for TEdits, TCombos etc.
  Add ('Checked');       // for TCombos, TMenuItems etc.
  Add ('Position');      // for TRackBars
  Add ('InitialDir');    // for TOpENDialog, TSaveDialog etc
  Add ('FileName');      // for TOpENDialog, TSaveDialog etc
  Sort;
  Add ('TjanConnector.Left');
  Add ('TjanConnector.Top');
  Add ('TjanConnector.Width');
  Add ('TjanConnector.Height');
  Add ('TjanConnector.W_ConMode');
  Add ('TjanConnector.W_ConPos');
  Add ('TjanConnector.W_ConShape');
  Add ('TjanConnector.W_Edge');
   // *** NIEUW: logische poorten altijd volledig opslaan ***
    Add('TjanLogic.Left');
    Add('TjanLogic.Top');
    Add('TjanLogic.Width');
    Add('TjanLogic.Height');
    Add('TjanLogic.L_Type');   // => EN/OF/NIET
 END;
END; // SetDefaultFilter

procedure TjanSimLogicBox.SetPropFromStringe(obj: TObject; info: PPropInfo; const str: string);
var
  vFloat: Extended;
  fs: TFormatSettings;
  vInt: Integer;
begin
  // Veiligheid
  if (info = nil) or (info^.PropType = nil) then
    Exit;

  with info^ do
  begin
    case PropType^.Kind of

      // Enumeraties (inclusief Boolean)
      tkEnumeration:
        begin
          if SameText(str, 'True') then
            SetOrdProp(obj, info, 1)
          else if SameText(str, 'False') then
            SetOrdProp(obj, info, 0)
          else
          begin
            vInt := GetEnumValue(PropType, str);
            if vInt >= 0 then
              SetOrdProp(obj, info, vInt);
          end;
        end;

      // Integers
      tkInteger:
        begin
          if str <> '' then
            SetOrdProp(obj, info, StrToIntDef(str, 0));
        end;

      // >>> Belangrijk: Floats tolerant inlezen ("0,5" én "0.5") <<<
      tkFloat:
        begin
          fs := DefaultFormatSettings;

          // 1) proberen met huidige locale
          if not TryStrToFloat(str, vFloat, fs) then
          begin
            // 2) met punt als decimal
            fs.DecimalSeparator := '.';
            if not TryStrToFloat(str, vFloat, fs) then
            begin
              // 3) met komma als decimal
              fs.DecimalSeparator := ',';
              if not TryStrToFloat(str, vFloat, fs) then
                Exit; // totaal onleesbaar → niks zetten
            end;
          end;

          SetFloatProp(obj, info, vFloat);
        end;

      // Characters
      tkChar:
        begin
          if str <> '' then
            SetOrdProp(obj, info, Ord(str[1]));
        end;

      // Strings (Delphi én FPC-varianten)
      tkString,
      tkLString
      {$IFDEF FPC}
      , tkAString, tkWString, tkUString
      {$ENDIF}
      :
        begin
          SetStrProp(obj, info, str);
        end;

      // Andere types laten we gewoon met rust
    else
      ; // niets doen
    end;
  end;
end;


FUNCTION TjanSimLogicBox.GetPropAsStringe (obj: TObject; info: PPropInfo): STRING;
// Builds from the properties of a component a string
VAR i: LONGINT;
BEGIN
 Result:= '';
 IF info^.PropType^.Kind = tkUnknown THEN EXIT;
 WITH info^ DO BEGIN
  CASE PropType^.Kind OF
   tkEnumeration: IF PropType^.Name = 'Boolean' then BEGIN
                   IF LONGINT (GetOrdProp (obj, info)) = 0 THEN  Result:= 'FALSE'
                                                           ELSE  Result:= 'TRUE';
                   EXIT;
                  END;
   tkInteger:     BEGIN
                   i:= LONGINT (GetOrdProp(Obj,Info));
                   {IF (PropType^.Name = 'TColor') OR (PropType^.Name = 'TCursor') THEN
                    BEGIN
                    ColorToIdent (i, Result);
                    EXIT;
                    END;}
                   Result:= IntToStr (i);
                  END;
   {  WAS
   tkChar:        Result:= CHR (GetOrdProp (obj, info));
   tkString,
   tkLString:     Result:= GetStrProp (obj, info); }
   // NU
   tkChar:
     Result := Chr(GetOrdProp(obj, info));
   tkString,
   tkLString
   {$IFDEF FPC}
   , tkAString, tkWString, tkUString
   {$ENDIF}
   :
     Result := GetStrProp(obj, info);
  END; // case
 END; // WITH
END; // GetPropAsString


PROCEDURE TjanSimLogicBox.AddFilter (s: STRING);
// Adds a filter to the filterlist
BEGIN
 FFilterLijst.Add (s);
END; // AddFilter

procedure TjanSimLogicBox.SavePanel(waar: string; Paneel: TjanGridS; codec: Boolean);
var
  wc: TWinControl;
  i: Integer;
  c: TControl;
  SFile: TStringList;
  lijn, modeStr, posStr, shapeStr, edgeStr, ltypeStr: string;
begin
  wc := FParent;

  SFile := TStringList.Create;
  try
    // Alle controls serialiseren
    for i := 0 to wc.ControlCount - 1 do
    begin
      c := wc.Controls[i];

      // --- TjanConnector ---
      if c is TjanConnector then
      with TjanConnector(c) do
      begin
        case V_ConMode of
          jcmTL: modeStr := 'jcmTL';
          jcmTR: modeStr := 'jcmTR';
          jcmBL: modeStr := 'jcmBL';
          jcmBR: modeStr := 'jcmBR';
        end;

        case V_ConPos of
          jcpTL: posStr := 'jcpTL';
          jcpTR: posStr := 'jcpTR';
          jcpBL: posStr := 'jcpBL';
          jcpBR: posStr := 'jcpBR';
        end;

        case V_ConShape of
          jcsTLBR: shapeStr := 'jcsTLBR';
          jcsTRBL: shapeStr := 'jcsTRBL';
        end;

        // edge met komma in file (maar loader kan beide)
        edgeStr := FloatToStr(V_Edge);
        edgeStr := StringReplace(edgeStr, DecimalSeparator, ',', [rfReplaceAll]);

        lijn := Format(
          'TjanConnector;%d;%d;%d;%d;%s;%s;%s;%s;%d;',
          [Height, Left, Top, Width,
           modeStr, posStr, shapeStr, edgeStr, FObjectID]
        );
        SFile.Add(lijn);
      end
      else
      // --- TjanLogic ---
      if c is TjanLogic then
      with TjanLogic(c) do
      begin
        case logicFunc of
          jlfNOT: ltypeStr := 'NIET';
          jlfAND: ltypeStr := 'EN';
          jlfOR:  ltypeStr := 'OF';
        end;

        lijn := Format(
          'TjanLogic;%d;%d;%s;%d;%d;',
          [Height, Left, ltypeStr, Top, Width]
        );
        SFile.Add(lijn);
      end
      else
      // --- Alle overige (simpele) componenten ---
      if c is TjanTeller then
      begin
        with TjanTeller(c) do
          lijn := Format('TjanTeller;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimButton then
      begin
        with TjanSimButton(c) do
          lijn := Format('TjanSimButton;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimKnop then
      begin
        with TjanSimKnop(c) do
          lijn := Format('TjanSimKnop;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimSensor then
      begin
        with TjanSimSensor(c) do
          lijn := Format('TjanSimSensor;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimWarm then
      begin
        with TjanSimWarm(c) do
          lijn := Format('TjanSimWarm;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimPuls then
      begin
        with TjanSimPuls(c) do
          lijn := Format('TjanSimPuls;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanDipSwitsh then
      begin
        with TjanDipSwitsh(c) do
          lijn := Format('TjanDipSwitsh;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanMemory then
      begin
        with TjanMemory(c) do
          lijn := Format('TjanMemory;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimLight then
      begin
        with TjanSimLight(c) do
          lijn := Format('TjanSimLight;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimRelais then
      begin
        with TjanSimRelais(c) do
          lijn := Format('TjanSimRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimBuzzer then
      begin
        with TjanSimBuzzer(c) do
          lijn := Format('TjanSimBuzzer;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanDisplay then
      begin
        with TjanDisplay(c) do
          lijn := Format('TjanDisplay;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end;
    end;

    // Paneel-instellingen achteraan
    SFile.Add(Format('Paneelkleur;%d;', [Paneel.Color]));
    SFile.Add(Format('Dotkleur;%d;', [Paneel.DotColor]));
    if Paneel.ShowGrid then
      SFile.Add('Grid;True;')
    else
      SFile.Add('Grid;False;');

    if codec then
      Decode(SFile); // of Encode, afhankelijk van jouw implementatie

    SFile.SaveToFile(waar);
  finally
    SFile.Free;
  end;
end;


procedure TjanSimLogicBox.SavePanelTemp(Paneel: TjanGridS);
var
  wc: TWinControl;
  i: Integer;
  c: TControl;
  lijn, modeStr, posStr, shapeStr, edgeStr, ltypeStr: string;
begin
  wc := FParent;
  TempFile.Clear;

  // Alle controls serialiseren
  for i := 0 to wc.ControlCount - 1 do
  begin
    c := wc.Controls[i];

    // --- TjanConnector ---
    if c is TjanConnector then
    with TjanConnector(c) do
    begin
      case V_ConMode of
        jcmTL: modeStr := 'jcmTL';
        jcmTR: modeStr := 'jcmTR';
        jcmBL: modeStr := 'jcmBL';
        jcmBR: modeStr := 'jcmBR';
      end;

      case V_ConPos of
        jcpTL: posStr := 'jcpTL';
        jcpTR: posStr := 'jcpTR';
        jcpBL: posStr := 'jcpBL';
        jcpBR: posStr := 'jcpBR';
      end;

      case V_ConShape of
        jcsTLBR: shapeStr := 'jcsTLBR';
        jcsTRBL: shapeStr := 'jcsTRBL';
      end;

      edgeStr := FloatToStr(V_Edge);
      edgeStr := StringReplace(edgeStr, DecimalSeparator, ',', [rfReplaceAll]);

      lijn := Format(
        'TjanConnector;%d;%d;%d;%d;%s;%s;%s;%s;%d;',
        [Height, Left, Top, Width,
         modeStr, posStr, shapeStr, edgeStr, FObjectID]
      );
      TempFile.Add(lijn);
    end
    else
    // --- TjanLogic ---
    if c is TjanLogic then
    with TjanLogic(c) do
    begin
      case logicFunc of
        jlfNOT: ltypeStr := 'NIET';
        jlfAND: ltypeStr := 'EN';
        jlfOR:  ltypeStr := 'OF';
      end;

      lijn := Format(
        'TjanLogic;%d;%d;%s;%d;%d;',
        [Height, Left, ltypeStr, Top, Width]
      );
      TempFile.Add(lijn);
    end
    else
    // --- overige ---
    if c is TjanTeller then
    begin
      with TjanTeller(c) do
        lijn := Format('TjanTeller;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimButton then
    begin
      with TjanSimButton(c) do
        lijn := Format('TjanSimButton;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimKnop then
    begin
      with TjanSimKnop(c) do
        lijn := Format('TjanSimKnop;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimSensor then
    begin
      with TjanSimSensor(c) do
        lijn := Format('TjanSimSensor;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimWarm then
    begin
      with TjanSimWarm(c) do
        lijn := Format('TjanSimWarm;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimPuls then
    begin
      with TjanSimPuls(c) do
        lijn := Format('TjanSimPuls;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanDipSwitsh then
    begin
      with TjanDipSwitsh(c) do
        lijn := Format('TjanDipSwitsh;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanMemory then
    begin
      with TjanMemory(c) do
        lijn := Format('TjanMemory;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimLight then
    begin
      with TjanSimLight(c) do
        lijn := Format('TjanSimLight;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimRelais then
    begin
      with TjanSimRelais(c) do
        lijn := Format('TjanSimRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimBuzzer then
    begin
      with TjanSimBuzzer(c) do
        lijn := Format('TjanSimBuzzer;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanDisplay then
    begin
      with TjanDisplay(c) do
        lijn := Format('TjanDisplay;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end;
  end;

  // Paneel-instellingen
  TempFile.Add(Format('Paneelkleur;%d;', [Paneel.Color]));
  TempFile.Add(Format('Dotkleur;%d;', [Paneel.DotColor]));
  if Paneel.ShowGrid then
    TempFile.Add('Grid;True;')
  else
    TempFile.Add('Grid;False;');
end;

procedure TjanSimLogicBox.InternalLoadFromList(AList: TStrings; Paneel: TjanGridS);
var
  i, positie: Integer;
  S: string;
  obj: array[1..10] of string;
  wc: TWinControl;

  procedure AddCommonSimProps(const AClassName: string);
  var
    s: string;
  begin
    s := AClassName + '.Left';   AddFilter(s);
    s := AClassName + '.Top';    AddFilter(s);
    s := AClassName + '.width';  AddFilter(s);
    s := AClassName + '.Height'; AddFilter(s);
  end;

begin
  KillPanel;
  wc := FParent;
  FFilterLijst.Clear;

  for i := 0 to AList.Count - 1 do
  begin
    S := Trim(AList.Strings[i]);
    if S = '' then
      Continue;

    // eerste token: soort (TjanTeller, TjanConnector, Paneelkleur, ...)
    positie := Pos(';', S);
    if positie = 0 then
      Continue;

    obj[1] := Copy(S, 1, positie - 1);
    Delete(S, 1, positie);
    {
    // ---------- Paneel-instellingen ----------
    if obj[1] = 'Paneelkleur' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // kleur
      Paneel.Color := StrToInt(Trim(obj[2]));
      Continue;
    end;

    if obj[1] = 'Dotkleur' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // dotkleur
      Paneel.DotColor := StrToInt(Trim(obj[2]));
      Continue;
    end;

    if obj[1] = 'Grid' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // True / False
      Paneel.ShowGrid := (Trim(obj[2]) = 'True');
      Continue;
    end;}
    if obj[1] = 'Paneelkleur' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // kleur
      if Assigned(Paneel) then
      Paneel.Color := StrToInt(Trim(obj[2]));
      Continue;
      end;

    if obj[1] = 'Dotkleur' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // dotkleur
      if Assigned(Paneel) then
       Paneel.DotColor := StrToInt(Trim(obj[2]));
      Continue;
      end;

    if obj[1] = 'Grid' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // True / False
      if Assigned(Paneel) then
         Paneel.ShowGrid := (Trim(obj[2]) = 'True');
      Continue;
    end;

    // ---------- TjanConnector ----------
    // Formaat:
    // TjanConnector;height;left;top;width;mode;pos;shape;edge;ID;
    if obj[1] = 'TjanConnector' then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[5] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // mode
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[6] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // pos
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[7] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // shape
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[8] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // edge
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[9] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // ID (optioneel, nu nog niet gebruikt)
      if Pos(';', S) > 0 then
      begin
        positie := Pos(';', S);
        obj[10] := Copy(S, 1, positie - 1);
      end
      else
        obj[10] := S;

      with TjanConnector.Create(self) do
      begin
        Parent := wc;
        Tag    := wc.ControlCount;

        Left   := StrToInt(Trim(obj[3]));
        Top    := StrToInt(Trim(obj[4]));
        Height := StrToInt(Trim(obj[2]));
        Width  := StrToInt(Trim(obj[5]));  // **echte** width uit file

        // mode
        if obj[6] = 'jcmTL' then V_ConMode := jcmTL else
        if obj[6] = 'jcmTR' then V_ConMode := jcmTR else
        if obj[6] = 'jcmBL' then V_ConMode := jcmBL else
        if obj[6] = 'jcmBR' then V_ConMode := jcmBR;

        // pos
        if obj[7] = 'jcpTL' then V_ConPos := jcpTL else
        if obj[7] = 'jcpTR' then V_ConPos := jcpTR else
        if obj[7] = 'jcpBL' then V_ConPos := jcpBL else
        if obj[7] = 'jcpBR' then V_ConPos := jcpBR;

        // shape
        if obj[8] = 'jcsTLBR' then V_ConShape := jcsTLBR else
        if obj[8] = 'jcsTRBL' then V_ConShape := jcsTRBL;

        // edge (met komma/punt fix)
      //  V_Edge := StrToFloatSmart(obj[9]);

        FObjectID := wc.ControlCount;

        AddFilter('TjanConnector.Left');
        AddFilter('TjanConnector.Top');
        AddFilter('TjanConnector.width');
        AddFilter('TjanConnector.Height');
        AddFilter('TjanConnector.W_ConMode');
        AddFilter('TjanConnector.W_ConPos');
        AddFilter('TjanConnector.W_ConShape');
        AddFilter('TjanConnector.W_Edge');
      end;

      Continue;
    end;

    // ---------- TjanLogic ----------
    // Formaat: TjanLogic;height;left;L_Type;top;width;
    if obj[1] = 'TjanLogic' then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // L_Type (NIET/EN/OF)
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[5] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S);
      if positie > 0 then
        obj[6] := Copy(S, 1, positie - 1)
      else
        obj[6] := S;

      with TjanLogic.Create(self) do
      begin
        Parent := wc;
        Tag    := wc.ControlCount;

        Left   := StrToInt(Trim(obj[3]));
        Top    := StrToInt(Trim(obj[5]));
        Height := StrToInt(Trim(obj[2]));
        Width  := StrToInt(Trim(obj[6]));

        FObjectID := wc.ControlCount;
        Lock      := True;

        if obj[4] = 'NIET' then logicFunc := jlfNOT;
        if obj[4] = 'EN'   then logicFunc := jlfAND;
        if obj[4] = 'OF'   then logicFunc := jlfOR;

        AddFilter('TjanLogic.Left');
        AddFilter('TjanLogic.Top');
        AddFilter('TjanLogic.width');
        AddFilter('TjanLogic.Height');
        AddFilter('TjanLogic.L_Type');
      end;

      Continue;
    end;

    // ---------- Overige componenten ----------
    // Formaat: Type;height;left;top;width;
    if (obj[1] <> 'TjanLogic') and (obj[1] <> 'TjanConnector') then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S);
      if positie > 0 then
        obj[5] := Copy(S, 1, positie - 1)
      else
        obj[5] := S;

      // ---- TjanTeller ----
      if obj[1] = 'TjanTeller' then
      begin
        with TjanTeller.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

          AddCommonSimProps('TjanTeller');
        end;
        Continue;
      end;

      // ---- TjanSimButton ----
      if obj[1] = 'TjanSimButton' then
      begin
        with TjanSimButton.Create(self) do   //xxxx
        begin
          Parent := wc;
          Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount;

          Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimButton');
        end;
        Continue;
      end;

      // ---- TjanSimKnop ----
      if obj[1] = 'TjanSimKnop' then
      begin
        with TjanSimKnop.Create(self) do
        begin
          Parent := wc;
          Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimKnop');
        end;
        Continue;
      end;

      // ---- TjanSimSensor ----
      if obj[1] = 'TjanSimSensor' then
      begin
        with TjanSimSensor.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimSensor');
        end;
        Continue;
      end;

      // ---- TjanSimWarm ----
      if obj[1] = 'TjanSimWarm' then
      begin
        with TjanSimWarm.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimWarm');
        end;
        Continue;
      end;

      // ---- TjanSimPuls ----
      if obj[1] = 'TjanSimPuls' then
      begin
        with TjanSimPuls.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimPuls');
        end;
        Continue;
      end;

      // ---- TjanDipSwitsh ----
      if obj[1] = 'TjanDipSwitsh' then
      begin
        with TjanDipSwitsh.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanDipSwitsh');
        end;
        Continue;
      end;

      // ---- TjanMemory ----
      if obj[1] = 'TjanMemory' then
      begin
        with TjanMemory.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanMemory');
        end;
        Continue;
      end;

      // ---- TjanSimLight ----
      if obj[1] = 'TjanSimLight' then
      begin
        with TjanSimLight.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimLight');
        end;
        Continue;
      end;

      // ---- TjanSimRelais ----
      if obj[1] = 'TjanSimRelais' then
      begin
        with TjanSimRelais.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimRelais');
        end;
        Continue;
      end;

      // ---- TjanSimBuzzer ----
      if obj[1] = 'TjanSimBuzzer' then
      begin
        with TjanSimBuzzer.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
            //aanpassen
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimBuzzer');
        end;
        Continue;
      end;

      // ---- TjanDisplay ----
      if obj[1] = 'TjanDisplay' then
      begin
        with TjanDisplay.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
            //aanpassen
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanDisplay');
        end;
        Continue;
      end;

      // Onbekend type → negeren
    end;
  end;
  BlokkeerObjecten(False);
end;

procedure TjanSimLogicBox.LoadPanel(welke: string; Paneel: TjanGridS; codec: Boolean);
begin
  templijst.Clear;
  templijst.LoadFromFile(welke);
  if codec then
    Decode(templijst);
  InternalLoadFromList(templijst, Paneel);
end;

procedure TjanSimLogicBox.LoadPanelTemp(Paneel: TjanGridS);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Assign(TempFile);
    InternalLoadFromList(L, Paneel);
  finally
    L.Free;
  end;
end;

procedure TjanSimLogicBox.LoadStreamNew(welke: TStream; Paneel: TjanGridS; Inf: Boolean);
var
  L: TStringList;
  i: Integer;
  c: TControl;
begin
  // Zelfde start als LoadPanel / LoadPanelTemp
  KillPanel;
  FFilterLijst.Clear;
  L := TStringList.Create;
  try
    // hele stream als tekst inlezen
    L.LoadFromStream(welke);

    // nieuwe parser gebruiken (zelfde formaat als SavePanel)
    InternalLoadFromList(L, Paneel);



    // Optioneel: Inf gebruiken zoals je oude LoadStream deed
    // (bijvoorbeeld hints activeren op connectors)
    if Inf then
    begin
      for i := 0 to FParent.ControlCount - 1 do
      begin
        c := FParent.Controls[i];
        if c is TjanConnector then
          TjanConnector(c).ShowHint := True;
      end;
    end;
  finally
    L.Free;
  end;
end;


PROCEDURE TjanSimLogicBox.LoadStream(welke:TStream;Inf:Boolean); //xxxx
VAR
i,positie:integer;
S:string;
templijst:TStringlist;
obj:array[1..10] of string;
wc:TWinControl;
BEGIN
killpanel;
wc:=FParent;
FFilterLijst.Clear;
templijst:=TStringList.Create;
templijst.LoadFromStream(welke);
 for i:= 0 to templijst.Count -1 do
  begin
   S:=Templijst.Strings[i];
   // uitlezen van welk component we gaan genereren
   positie:= Pos(';',S);obj[1]:=copy(S,1,positie-1);delete(S,1,positie);
   If obj[1] = 'TjanConnector' then
        begin
        //
        positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
        positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
        positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // top
        positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1);delete(S,1,positie); // width
        //
        positie:= Pos(';',S);obj[6]:=copy(S,1,positie-1);delete(S,1,positie); // mode
        positie:= Pos(';',S);obj[7]:=copy(S,1,positie-1);delete(S,1,positie); // pos
        positie:= Pos(';',S);obj[8]:=copy(S,1,positie-1); // shape
          with TjanConnector.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             if (Inf=true) then showhint:=true else showhint:=false;
             if obj[6]='jcmTL' then V_ConMode:=jcmTL;
             if obj[6]='jcmTR' then V_ConMode:=jcmTR;
             if obj[6]='jcmBL' then V_ConMode:=jcmBL;
             if obj[6]='jcmBR' then V_ConMode:=jcmBR;

             if obj[7]='jcpTL' then V_ConPos:=jcpTL;
             if obj[7]='jcpTR' then V_ConPos:=jcpTR;
             if obj[7]='jcpBL' then V_ConPos:=jcpBL;
             if obj[7]='jcpBR' then V_ConPos:=jcpBR;

             if obj[8]='jcsTLBR' then V_ConShape:=jcsTLBR;
             if obj[8]='jcsTRBL' then V_ConShape:=jcsTRBL;

             FObjectID:= wc.ControlCount;
             s:='TjanConnector.Left';AddFilter (s);s:='TjanConnector.Top';AddFilter (s);
             s:='TjanConnector.width';AddFilter (s);s:='TjanConnector.Height';AddFilter (s);
             s:='TjanConnector.W_ConMode';AddFilter (s);s:='TjanConnector.W_ConPos';AddFilter (s);
             s:='TjanConnector.W_ConShape';AddFilter (s);
            end;
        end;
   If obj[1] <> 'TjanLogic' then
     begin
     positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
     positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
     positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // top
     positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1); // width
     If obj[1] = 'TjanSimButton' then
        begin
          with TjanSimButton.create(self) do  ///xxxx
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;


             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;

             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimButton.Left';AddFilter (s);s:='TjanSimButton.Top';AddFilter (s);
             s:='TjanSimButton.width';AddFilter (s);s:='TjanSimButton.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimKnop' then
        begin
          with TjanSimKnop.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimKnop.Left';AddFilter (s);s:='TjanSimKnop.Top';AddFilter (s);
             s:='TjanSimKnop.width';AddFilter (s);s:='TjanSimKnop.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimSensor' then
        begin
          with TjanSimSensor.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimSensor.Left';AddFilter (s);s:='TjanSimSensor.Top';AddFilter (s);
             s:='TjanSimSensor.width';AddFilter (s);s:='TjanSimSensor.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimWarm' then
        begin
          with TjanSimWarm.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;


             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimWarm.Left';AddFilter (s);s:='TjanSimWarm.Top';AddFilter (s);
             s:='TjanSimWarm.width';AddFilter (s);s:='TjanSimWarm.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimPuls' then
        begin
          with TjanSimPuls.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
                if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimPuls.Left';AddFilter (s);s:='TjanSimPuls.Top';AddFilter (s);
             s:='TjanSimPuls.width';AddFilter (s);s:='TjanSimPuls.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanDipSwitsh' then
        begin
          with TjanDipSwitsh.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanDipSwitsh.Left';AddFilter (s);s:='TjanDipSwitsh.Top';AddFilter (s);
             s:='TjanDipSwitsh.width';AddFilter (s);s:='TjanDipSwitsh.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanTeller' then
        begin
          with TjanTeller.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
           // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;
            OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanTeller.Left';AddFilter (s);s:='TjanTeller.Top';AddFilter (s);
             s:='TjanTeller.width';AddFilter (s);s:='TjanTeller.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanMemory' then
        begin
          with TjanMemory.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanMemory.Left';AddFilter (s);s:='TjanMemory.Top';AddFilter (s);
             s:='TjanMemory.width';AddFilter (s);s:='TjanMemory.Height';AddFilter (s);

            end;
        end;
     If obj[1] = 'TjanSimLight' then
        begin
          with TjanSimLight.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimLight.Left';AddFilter (s);s:='TjanSimLight.Top';AddFilter (s);
             s:='TjanSimLight.width';AddFilter (s);s:='TjanSimLight.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimRelais' then
        begin
          with TjanSimRelais.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;

               //aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimRelais.Left';AddFilter (s);s:='TjanSimRelais.Top';AddFilter (s);
             s:='TjanSimRelais.width';AddFilter (s);s:='TjanSimRelais.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimBuzzer' then
        begin
          with TjanSimBuzzer.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
               // aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimBuzzer.Left';AddFilter (s);s:='TjanSimBuzzer.Top';AddFilter (s);
             s:='TjanSimBuzzer.width';AddFilter (s);s:='TjanSimBuzzer.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanDisplay' then
        begin
          with TjanDisplay.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
               // aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanDisplay.Left';AddFilter (s);s:='TjanDisplay.Top';AddFilter (s);
             s:='TjanDisplay.width';AddFilter (s);s:='TjanDisplay.Height';AddFilter (s);
            end;
        end;
     end;

     If obj[1] = 'TjanLogic' then
     begin
     positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
     positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
     positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // L_Type(string)
     positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1);delete(S,1,positie); // Top
     positie:= Pos(';',S);obj[6]:=copy(S,1,positie-1); // Width
      with TjanLogic.create(self) do
            begin
             parent:=wc;
             tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);
             top:=StrToInt(obj[5]);
             Height:=StrToInt(obj[2]);
             width:=StrToInt(obj[6]);
             FObjectID:= wc.ControlCount;Lock:=true;
             If obj[4]='NIET' then logicFunc:=jlfNOT;
             If obj[4]='EN' then logicFunc:=jlfAND;
             If obj[4]='OF' then logicFunc:=jlfOR;
              FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;


             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanLogic.Left';AddFilter (s);s:='TjanLogic.Top';AddFilter (s);
             s:='TjanLogic.width';AddFilter (s);s:='TjanLogic.Height';AddFilter (s);
             s:='TjanLogic.L_Type';AddFilter (s);
            end;
      end;
  end;
templijst.Free;
END;

procedure TjanSimLogicBox.CMMouseEnter(var Msg:TMessage);
 var
 p:TPoint;
begin
  inherited;
  if Assigned (FOnEnter) then FOnEnter(Self);
end;

procedure TjanSimLogicBox.CMMouseLeave(var Msg:TMessage);
begin
  inherited;
  if Assigned (FOnLeave) then FOnLeave(Self);
  DoStatusText('',0);
end;

procedure TjanSimLogicBox.Loaded;
begin
  inherited;
  cpu.Enabled:=true;
end;

procedure TjanSimLogicBox.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var p:TPoint;
begin
  p:=point(x,y);
  DSquare:=false;
  DCon:=false;DLogicAnd:=false;DLogicOr:=false;DLogicNot:=false;
  DButton:=false;DLight:=false;DKnop:=false;DPuls:=false;
  DBuzzer:=false;DSensor:=false;DTeller:=false;DMemory:=false;DDisplay:=false;
  DDipSwitsh:=false;DGrid:=false;

  if PtInRect(RSquare, P) then DSquare := True
  else if ptinrect(RCon,p) then Dcon:=true
  else if ptinrect(RLogicAnd,p)and (KLogicAnd=true) then DLogicAnd:=true
  else if ptinrect(RLogicOr,p)and (KLogicOr=true) then DLogicOr:=true
  else if ptinrect(RLogicNot,p)and (KLogicNot=true) then DLogicNot:=true
  else if ptinrect(RButton,p) and (KDrukknop=true) then DButton:=true
  else if ptinrect(RLight,p) and (KLamp=true) then DLight:=true
  else if ptinrect(RRelais,p) and (KRelais=true) then DRelais:=true
  else if ptinrect(RBuzzer,p) and (KBuzzer=true) then DBuzzer:=true
  else if ptinrect(RSensor,p) and (KSensor=true) then DSensor:=true
  else if ptinrect(RWarm,p) and (KWarm=true) then DWarm:=true
  else if ptinrect(RKnop,p) and (KSchakelaar=true) then DKnop:=true
  else if ptinrect(RPuls,p) and (KPuls=true) then DPuls:=true
  else if ptinrect(RDisplay,p) and (KDisplay=true)then DDisplay:=true
  else if ptinrect(RTeller,p) and (KTeller=true)then DTeller:=true
  else if ptinrect(RMemory,p) and (KMemory=true)then DMemory:=true
  else if ptinrect(RDipSwitsh,p) and (KDipSwitsh=true)then DDipSwitsh:=true
  else if ptinrect(RMeter,p) and (KMeter=true)then DMeter:=true
  else if ptinrect(RGrid,p) and (KGrid=true) then DGrid:=true;
  invalidate;
end;

procedure TjanSimLogicBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  NewHint: string;
begin
  inherited;

  P := Point(X, Y);
//  Fx := X;
//  Fy := Y;
  NewHint := '';

  if PtInRect(RCon, P) then NewHint := FHDraad
  else if PtInRect(RLogicAnd, P) then NewHint := FHLogicAnd
  else if PtInRect(RLogicOr, P) then NewHint := FHLogicOr
  else if PtInRect(RLogicNot, P) then NewHint := FHLogicNot
  else if PtInRect(RButton, P) then NewHint := FHDrukknop
  else if PtInRect(RLight, P) then NewHint := FHLamp
  else if PtInRect(RRelais, P) then NewHint := FHRelais
  else if PtInRect(RBuzzer, P) then NewHint := FHBuzzer
  else if PtInRect(RSensor, P) then NewHint := FHSensor
  else if PtInRect(RWarm, P) then NewHint := FHWarm
  else if PtInRect(RKnop, P) then NewHint := FHSchakelaar
  else if PtInRect(RPuls, P) then NewHint := FHPuls
  else if PtInRect(RDisplay, P) then NewHint := FHDisplay
  else if PtInRect(RTeller, P) then NewHint := FHTeller
  else if PtInRect(RMemory, P) then NewHint := FHMemory
  else if PtInRect(RDipSwitsh, P) then NewHint := FHDipSwitsh
  else if PtInRect(RGrid, P) then NewHint := FHGrid;

  if FLastHintText <> NewHint then
  begin
    FLastHintText := NewHint;
    Hint := NewHint;
    Application.CancelHint;

    if NewHint <> '' then
      Application.ActivateHint(ClientToScreen(Point(X, Y)));
  end;
end;
{
procedure TjanSimLogicBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
 p:TPoint;
begin
  inherited;
  p:=point(x,y);
  Fx:=x;Fy:=y;

{  if ptinrect(RCon,p) then DoStatusText(FHDraad , 0)
  else if ptinrect(RLogicAnd,p)then DoStatusText(FHLogicAnd , 0)
  else if ptinrect(RLogicOr,p) then DoStatusText(FHLogicOr , 0)
  else if ptinrect(RLogicNot,p) then DoStatusText(FHLogicNot , 0)
  else if ptinrect(RButton,p) then DoStatusText(FHDrukknop , 0)
  else if ptinrect(RSquare,p) then DoStatusText(FHKader , 0)
  else if ptinrect(RLight,p) then DoStatusText(FHLamp , 0)
  else if ptinrect(RRelais,p) then DoStatusText(FHRelais , 0)
  else if ptinrect(RBuzzer,p) then DoStatusText(FHBuzzer , 0)
  else if ptinrect(RSensor,p) then DoStatusText(FHSensor , 0)

  else if ptinrect(RWarm,p) then DoStatusText(FHWarm , 0)
  else if ptinrect(RKnop,p) then DoStatusText(FHSchakelaar , 0)
  else if ptinrect(RPuls,p) then DoStatusText(FHPuls , 0)
  else if ptinrect(RDisplay,p) then DoStatusText(FHDisplay , 0)
  else if ptinrect(RTeller,p) then DoStatusText(FHTeller , 0)
  else if ptinrect(RMemory,p) then DoStatusText(FHMemory , 0)
  else if ptinrect(RDipSwitsh,p)then DoStatusText(FHDipSwitsh , 0)
  else if ptinrect(RGrid,p) then DoStatusText(FHGrid , 0)
  else if ptinrect(RMeter,p) then DoStatusText(FHMeter, 0)
  else DoStatusText('', 0);


end;}

procedure TjanSimLogicBox.maakpanel;
var
wc:TWinControl;
Y,X1,X2,X3:integer;
begin
  Y:= 0;
  X1:= 140;
  X2:= 380;
  X3:= 620;
  wc:=parent;
 // INVOER
  with TjanSimButton.create(self) do  //xxxx
  Begin
    parent:=wc;left:=X1;top:=80 + y;
    FLock:=true;tag:= wc.ControlCount;Hint:='Invoer --> Drukknop';
      OnStatus := StatusFromChild;
  end;
  with TjanSimKnop.create(self) do
  Begin
    parent:=wc;left:=X1+5;top:=140+ y;
    FLock:=true;tag:= wc.ControlCount;
      OnStatus := StatusFromChild;
  end;
  with TjanSimSensor.create(self) do
  begin
    parent:=wc;left:=X1;top:=220+ y;
    FLock:=true;tag:= wc.ControlCount;
     OnStatus := StatusFromChild;
  end;
  with TjanSimWarm.create(self) do
  Begin
    parent:=wc;left:=X1;top:=290 + y;
    FLock:=true;tag:= wc.ControlCount;
     OnStatus := StatusFromChild;
  end;
 // VERWERKING
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=65 + y;LogicFunc:=(jlfAnd);
    tag:= wc.ControlCount;FLock:=true;
  end;
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=165 + y;LogicFunc:=(jlfOR);
    tag:= wc.ControlCount;FLock:=true;
  end;
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=265 + y;LogicFunc:=(jlfNOT);
    tag:= wc.ControlCount;FLock:=true;
  end;
 // UITVOER
  with TjanSimBuzzer.create(self) do
  begin
    parent:=wc;
    left:=X3; top:=90 + y;
    FLock:=true;tag:= wc.ControlCount;
  end;
  with TjanSimRelais.create(self) do
  begin
    parent:=wc;
    left:=X3;top:=169 + y;
    FLock:=true;tag:= wc.ControlCount;
  end;
  with TjanSimLight.create(self) do
  begin
    parent:=wc;
    left:=X3;top:=284 + y;
    FLock:=true;tag:= wc.ControlCount;
    Info:='Uitvoer --> Lamp';
  end;
end;

Procedure TjanSimLogicBox.kontrolconnectors;
var
wc:TWinControl;
i:integer;
begin
wc:=Fparent;
 for i := wc.ControlCount - 1 downto 0 do
  if (wc.controls[i] is TjanConnector) then
   begin
       FDraden:=true;
   end;
end;

PROCEDURE TjanSimLogicBox.BlokkeerObjecten(blokkeer:Boolean);
var
wc:TWinControl;
i:integer;
begin
   wc:=Fparent;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimLight) then
       begin
       (wc.Controls[i] as TjanSimLight).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimLight).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimRelais) then
       begin
       (wc.Controls[i] as TjanSimRelais).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimRelais).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Lock := blokkeer;
       (wc.Controls[i] as TjanConnector).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogic) then
       begin
       (wc.Controls[i] as TjanLogic).Lock:=blokkeer;
       (wc.Controls[i] as TjanLogic).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimButton) then
       begin
       (wc.Controls[i] as TjanSimButton).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimButton).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimKnop) then
       begin
       (wc.Controls[i] as TjanSimKnop).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimKnop).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPuls) then
       begin
       (wc.Controls[i] as TjanSimPuls).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimPuls).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanTeller) then
       begin
       (wc.Controls[i] as TjanTeller).Lock:=blokkeer;
       (wc.Controls[i] as TjanTeller).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDisplay) then
      begin
      (wc.Controls[i] as Tjandisplay).Lock:=blokkeer;
      (wc.Controls[i] as Tjandisplay).BringToFront;
      end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimBuzzer) then
       begin
       (wc.Controls[i] as TjanSimBuzzer).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimBuzzer).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimSensor) then
      begin
      (wc.Controls[i] as TjanSimSensor).Lock:=blokkeer;
      (wc.Controls[i] as TjanSimSensor).BringToFront;
      end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimWarm) then
       begin
       (wc.Controls[i] as TjanSimWarm).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimWarm).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDipSwitsh) then
       begin
       (wc.Controls[i] as TjanDipSwitsh).Lock:=blokkeer;
       (wc.Controls[i] as TjanDipSwitsh).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMemory) then
       begin
       (wc.Controls[i] as TjanMemory).Lock:=blokkeer;
       (wc.Controls[i] as TjanMemory).BringToFront;
       end;
end;

procedure TjanSimLogicBox.Killpanel;
var
wc:TWinControl;
i:integer;
begin
   wc:=Fparent;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimLight) then
       begin
       (wc.Controls[i] as TjanSimLight).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimRelais) then
       begin
       (wc.Controls[i] as TjanSimRelais).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogic) then
       begin
       (wc.Controls[i] as TjanLogic).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimButton) then
       begin
       (wc.Controls[i] as TjanSimButton).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimKnop) then
       begin
       (wc.Controls[i] as TjanSimKnop).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPuls) then
       begin
       (wc.Controls[i] as TjanSimPuls).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanTeller) then
       begin
       (wc.Controls[i] as TjanTeller).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDisplay) then
       begin
       (wc.Controls[i] as Tjandisplay).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimBuzzer) then
       begin
       (wc.Controls[i] as TjanSimBuzzer).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimSensor) then
       begin
       (wc.Controls[i] as TjanSimSensor).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimWarm) then
       begin
       (wc.Controls[i] as TjanSimWarm).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDipSwitsh) then
       begin
       (wc.Controls[i] as TjanDipSwitsh).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMemory) then
       begin
       (wc.Controls[i] as TjanMemory).Free;
       end;

   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMeter) then
       begin
       (wc.Controls[i] as TjanMeter).Free;
       end;
end;

procedure TjanSimLogicBox.ZetTaal;
var
  wc: TWinControl;
  i: Integer;
begin
  wc := FParent;
  if not Assigned(wc) then Exit;

  case Language of
    stDutch  : Taal := 'NL';
    stEnglish: Taal := 'ENG';
    stFrench : Taal := 'FR';
    stGerman : Taal := 'DU';
  else
    Taal := 'NL';
  end;

  case Language of
    stDutch  : FHSchakelaar := 'maak Schakelaar';
    stEnglish: FHSchakelaar := 'create Switch';
    stFrench : FHSchakelaar := 'créer interrupteur';
    stGerman : FHSchakelaar := 'Schalter erstellen';
  end;

  for i := wc.ControlCount - 1 downto 0 do
    ApplyLanguageToSimObj(wc.Controls[i]);

  RefreshStatusBarLanguage;
end;


procedure TjanSimLogicBox.KillConnectors;
var
wc:TWinControl;
i:integer;
begin
 wc:=Fparent;
  for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Free;
       end;
end;

procedure TjanSimLogicBox.MoveObjekten(hoeveel:Integer);
var
wc:TWinControl;
i:integer;
templeft:integer;
begin
  wc:=Fparent;
  for i := wc.ControlCount - 1 downto 0 do
       begin
       templeft:=wc.Controls[i].Left;
       if (Fopen=true) then
          begin
          wc.Controls[i].Left:= (templeft + hoeveel);
          end
          else
          begin
          wc.Controls[i].Left:= (templeft - hoeveel);
          end;
       end;
end;
 procedure TjanSimLogicBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  wc: TWinControl;
  a: Integer;
  s: string;

  procedure AddF(const PropName: string);
  begin
    AddFilter(PropName);
  end;

  procedure ResetDownStates;
  begin
    Dgrid := False;
    DButton := False; DKnop := False; DPuls := False; DWarm := False; DSensor := False;
    DCon := False;
    DLogicAnd := False; DLogicOr := False; DLogicNot := False; DTeller := False; DMemory := False; DDipSwitsh := False;
    DLight := False; DRelais := False; DBuzzer := False; DDisplay := False;

    // nieuw
    DSquare := False;
  end;

begin
  inherited;

  if (Screen.Cursor = crHandPoint) then Exit;

  wc := FParent;
  if not Assigned(wc) then
  begin
    ResetDownStates;
    Exit;
  end;

  // ------------------------------------------------------------
  // Connector mode toggle + Z-order
  // ------------------------------------------------------------
  if Dcon then
  begin
    // eerst logic naar voren
    for a := wc.ControlCount - 1 downto 0 do
      if (wc.Controls[a] is TjanLogic) then
        (wc.Controls[a] as TjanLogic).BringToFront;

    // dan connectors naar voren
    for a := wc.ControlCount - 1 downto 0 do
      if (wc.Controls[a] is TjanConnector) then
        (wc.Controls[a] as TjanConnector).BringToFront;

    if Screen.Cursor = crDefault then
      Screen.Cursor := crDraad
    else
      Screen.Cursor := crDefault;
  end
  // ------------------------------------------------------------
  // Grid toggle (Kill connectors)
  // ------------------------------------------------------------
  else if DGrid then
  begin
    KillConnectors;
    Draden := False;
  end

  // ------------------------------------------------------------
  // Verwerking: Logic blocks
  // ------------------------------------------------------------
  else if DLogicAnd then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfAND;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crAnd;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DLogicOr then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfOR;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crOr;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DLogicNot then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfNOT;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crNot;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DTeller then
  with TjanTeller.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crTeller;

    AddF('TjanTeller.Left');  AddF('TjanTeller.Top');
    AddF('TjanTeller.Width'); AddF('TjanTeller.Height');
  end
  else if DMemory then
  with TjanMemory.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crGeheugen;

    AddF('TjanMemory.Left');  AddF('TjanMemory.Top');
    AddF('TjanMemory.Width'); AddF('TjanMemory.Height');
    AddF('TjanMemory.LogicFunc');
  end
  else if DDipSwitsh then
  with TjanDipSwitsh.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crDip;

    AddF('TjanDipSwitsh.Left');  AddF('TjanDipSwitsh.Top');
    AddF('TjanDipSwitsh.Width'); AddF('TjanDipSwitsh.Height');
  end

  // ------------------------------------------------------------
  // Invoer: Buttons/Knoppen/Sensoren
  // ------------------------------------------------------------
  else if DButton then
  with TjanSimButton.Create(self) do   //xxxx
  begin
    OnStatus := StatusFromChild;
    Parent := wc; FNew := True;
    Tag := wc.ControlCount;
    Left := -100;
    FObjectID := wc.ControlCount; Visible := False;
    Screen.Cursor := crDrukknop;

    if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

          OnStatus := StatusFromChild;

    AddF('TjanSimButton.Left');  AddF('TjanSimButton.Top');
    AddF('TjanSimButton.Width'); AddF('TjanSimButton.Height');

  end
  else if DKnop then
  with TjanSimKnop.Create(self) do
  begin

    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crSchakelaar;

    if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

      OnStatus := StatusFromChild;

    AddF('TjanSimKnop.Left');  AddF('TjanSimKnop.Top');
    AddF('TjanSimKnop.Width'); AddF('TjanSimKnop.Height');
  end
  else if DPuls then
  with TjanSimPuls.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crPuls;

    AddF('TjanSimPuls.Left');  AddF('TjanSimPuls.Top');
    AddF('TjanSimPuls.Width'); AddF('TjanSimPuls.Height');
  end
  else if DLight then
  with TjanSimLight.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crLamp;

    AddF('TjanSimLight.Left');  AddF('TjanSimLight.Top');
    AddF('TjanSimLight.Width'); AddF('TjanSimLight.Height');
  end
  else if DDisplay then
  with TjanDisplay.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crDisplay;

    AddF('TjanDisplay.Left');  AddF('TjanDisplay.Top');
    AddF('TjanDisplay.Width'); AddF('TjanDisplay.Height');
  end
  else if DMeter then
  with TjanMeter.Create(wc) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crMeter;

    AddF('TjanMeter.Left');  AddF('TjanMeter.Top');
    AddF('TjanMeter.Width'); AddF('TjanMeter.Height');
  end
  else if DBuzzer then
  with TjanSimBuzzer.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crZoemer;

    AddF('TjanSimBuzzer.Left');  AddF('TjanSimBuzzer.Top');
    AddF('TjanSimBuzzer.Width'); AddF('TjanSimBuzzer.Height');
  end
  else if DSensor then
  with TjanSimSensor.Create(self) do
  begin

    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crSensor;
      if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR'
    else if Language = stGerman then BTaal := 'DU';
      OnStatus := StatusFromChild;
    AddF('TjanSimSensor.Left');  AddF('TjanSimSensor.Top');
    AddF('TjanSimSensor.Width'); AddF('TjanSimSensor.Height');

  end
  else if DWarm then
  with TjanSimWarm.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crWarm;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR'
    else if Language = stGerman then BTaal := 'DU';
      OnStatus := StatusFromChild;
    AddF('TjanSimWarm.Left');  AddF('TjanSimWarm.Top');
    AddF('TjanSimWarm.Width'); AddF('TjanSimWarm.Height');
  end
  else if DRelais then
  with TjanSimRelais.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crRelais;

    AddF('TjanSimRelais.Left');  AddF('TjanSimRelais.Top');
    AddF('TjanSimRelais.Width'); AddF('TjanSimRelais.Height');
  end;

  ResetDownStates;
  Invalidate;
end;



{LogicBox}

procedure TjanSimLogicBox.SetHDrukknop(const Value: String);
begin
  if value<>FHDrukknop then FHDrukknop := Value;
end;
procedure TjanSimLogicBox.SetHBuzzer(const Value: String);
begin
  if value<>FHBuzzer then FHBuzzer := Value;
end;
procedure TjanSimLogicBox.SetHDipSwitsh(const Value: String);
begin
  if value<>FHDipSwitsh then FHDipSwitsh := Value;
end;
procedure TjanSimLogicBox.SetHSensor(const Value: String);
begin
  if value<>FHSensor then FHSensor := Value;
end;
procedure TjanSimLogicBox.SetHWarm(const Value: String);
begin
  if value<>FHWarm then FHWarm := Value;
end;
procedure TjanSimLogicBox.SetHDisplay(const Value: String);
begin
  if value<>FHDisplay then FHDisplay := Value;
end;
procedure TjanSimLogicBox.SetHDraad(const Value: String);
begin
  if value<>FHDraad then FHDraad := Value;
end;
procedure TjanSimLogicBox.SetHLamp(const Value: String);
begin
  if value<>FHLamp then FHLamp := Value;
end;
procedure TjanSimLogicBox.SetHGrid(const Value: String);
begin
  if value<>FHGrid then FHGrid := Value;
end;

procedure TjanSimLogicBox.SetHMeter(const Value: String);
begin
  if value<>FHMeter then FHMeter := Value;
end;

procedure TjanSimLogicBox.SetHLock(const Value: String);
begin
  if value<>FHLock then FHLock := Value;
end;
procedure TjanSimLogicBox.SetHLogicAnd(const Value: String);
begin
  if value<>FHLogicAnd then FHLogicAnd := Value;
end;
procedure TjanSimLogicBox.SetHLogicNot(const Value: String);
begin
  if value<>FHLogicNot then FHLogicNot := Value;
end;
procedure TjanSimLogicBox.SetHLogicOr(const Value: String);
begin
  if value<>FHLogicOr then FHLogicOr := Value;
end;
procedure TjanSimLogicBox.SetHTeller(const Value: String);
begin
  if value<>FHTeller then FHTeller := Value;
end;
procedure TjanSimLogicBox.SetHMemory(const Value: String);
begin
  if value<>FHMemory then FHMemory := Value;
end;
procedure TjanSimLogicBox.SetHRelais(const Value: String);
begin
  if value<>FHRelais then FHRelais := Value;
end;

procedure TjanSimLogicBox.SetHSchakelaar(const Value: String);
begin
  if value<>FHSchakelaar then FHSchakelaar := Value;
end;

{procedure TjanSimLogicBox.SetHKader(const Value: String);
begin
  if value<>FHKader then FHKader := Value;
end;}

procedure TjanSimLogicBox.SetHPuls(const Value: String);
begin
  if value<>FHPuls then FHPuls := Value;
end;
procedure TjanSimLogicBox.SetDrukknop(const Value: Boolean);
begin
  if value<>FDrukknop then
  begin
    FDrukknop := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopLeft(const Value: Integer);
begin
  if value<>FKnopLeft then
  begin
    FKnopLeft := Value;
  end;
  invalidate;
end;





procedure TjanSimLogicBox.SetGrid(const Value: Boolean);
begin
  if value <> FGrid then
  begin
    FGrid := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetFx(const Value: integer);
begin
  if value <> Fx then
  begin
    Fx := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetFy(const Value: integer);
begin
  if value <> Fy then
  begin
    Fy := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDraden (const Value: Boolean);
begin
  if value <> FDraden then
  begin
    Fdraden:=value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetImputAantal(const Value: Integer);
begin
  if value<>FImputAantal then
  begin
    FImputAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetImputColor(const Value: TColor);
begin
  if value<>FImputColor then
  begin
    FImputColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetOutputColor(const Value: TColor);
begin
  if value<>FOutputColor then
  begin
    FOutputColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetVerwerkingColor(const Value: TColor);
begin
  if value<>FVerwerkingColor then
  begin
    FVerwerkingColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetOutputAantal(const Value: Integer);
begin
  if value<>FOutputAantal then
  begin
    FOutputAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetVerwerkingAantal(const Value: Integer);
begin
  if value<>FVerwerkingAantal then
  begin
    FVerwerkingAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopSpatie(const Value: Integer);
begin
  if value<>FSpatie then
  begin
    FSpatie := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopTop(const Value: Integer);
begin
  if value<>FKnopTop then
  begin
    FKnopTop := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDraad(const Value: Boolean);
begin
  if value<>FDraad then
  begin
    FDraad:= Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetBuzzer(const Value: Boolean);
begin
  if value<>FBuzzer then
  begin
    FBuzzer:= Value;
    if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetBColor(const Value: TColor);
begin
  if value<>FBColor then
  begin
    FBColor:= Value;
    invalidate;
  end;
end;




procedure TjanSimLogicBox.DoStatusText(const AText: string; APanel: Integer);
begin
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, AText, APanel);
end;

procedure TjanSimLogicBox.PushStatus(ASource: TObject;const AText: string; APanel: Integer);
begin
  // oude event blijft werken
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, AText, APanel);

  // nieuwe event met bronobject
  if Assigned(FOnStatusEx) then
    FOnStatusEx(Self, ASource, AText, APanel);
end;


procedure TjanSimLogicBox.RefreshStatusBarLanguage; // xxxx
begin
  if not Assigned(FLastStatusSender) then Exit;

  if FLastStatusSender is TjanSimButton then
    TjanSimButton(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimKnop then
    TjanSimKnop(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimSensor then
    TjanSimSensor(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimWarm then
    TjanSimWarm(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimPuls then
    TjanSimPuls(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanDipSwitsh then
    TjanDipSwitsh(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanLogic then
    TjanLogic(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanTeller then
    TjanTeller(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanMemory then
    TjanMemory(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimLight then
    TjanSimLight(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimRelais then
    TjanSimRelais(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimBuzzer then
    TjanSimBuzzer(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanDisplay then
    TjanDisplay(FLastStatusSender).SendStatusToBar;
    // aanpassen voor volgend object
    //voeg hier je andere sim-types toe
end;

procedure TjanSimLogicBox.SelectObject(AObj: TObject);


  procedure SetSelectedFlag(Obj: TObject; AValue: Boolean);
  begin

    if Obj is TjanSimButton then TjanSimButton(Obj).Selected := AValue
    else if Obj is TjanSimKnop then TjanSimKnop(Obj).Selected := AValue
    else if Obj is TjanSimSensor then TjanSimSensor(Obj).Selected := AValue
    else if Obj is TjanSimWarm then TjanSimWarm(Obj).Selected := AValue
    else if Obj is TjanSimPuls then TjanSimPuls(Obj).Selected := AValue
    else if Obj is TjanDipSwitsh then TjanDipSwitsh(Obj).Selected := AValue
    else if Obj is TjanLogic then TjanLogic(Obj).Selected := AValue
    else if Obj is TjanTeller then TjanTeller(Obj).Selected := AValue
    else if Obj is TjanMemory then TjanMemory(Obj).Selected := AValue
    else if Obj is TjanSimLight then TjanSimLight(Obj).Selected := AValue
    else if Obj is TjanSimRelais then TjanSimRelais(Obj).Selected := AValue
    else if Obj is TjanSimBuzzer then TjanSimBuzzer(Obj).Selected := AValue
    else if Obj is TjanDisplay then TjanDisplay(Obj).Selected := AValue;
    // aanpassen voor volgend object
  end;

  procedure InvalidateIfControl(Obj: TObject);
  begin
    if Obj is TControl then
      TControl(Obj).Invalidate;
  end;
begin

  // --- TOGGLE: zelfde object opnieuw => deselect ---
  if Assigned(FSelectedSender) and (FSelectedSender = AObj) then
  begin
    SetSelectedFlag(FSelectedSender, False);
    InvalidateIfControl(FSelectedSender);

    FSelectedSender := nil;

    if Assigned(FOnSelected) then
      FOnSelected(Self, nil);

    Exit;
  end;

  // 1) vorige selectie uit
  if Assigned(FSelectedSender) then
  begin
    SetSelectedFlag(FSelectedSender, False);
    InvalidateIfControl(FSelectedSender);
  end;

  // 2) nieuwe selectie zetten
  FSelectedSender := AObj;

  if Assigned(FSelectedSender) then
  begin
    SetSelectedFlag(FSelectedSender, True);
    InvalidateIfControl(FSelectedSender);
  end;

  // 3) event naar mainform (btDelCurObject enable + hint)
  if Assigned(FOnSelected) then
    FOnSelected(Self, FSelectedSender);
end;

procedure TjanSimLogicBox.ApplyLanguageToGridChildren(const NewBTaal: TStatTaal; AGrid: TWinControl);
var
  i: Integer;
  c: TControl;
  s: string;
begin
  if not Assigned(AGrid) then Exit;

  s := StatTaalToBTaal(NewBTaal);

  for i := 0 to AGrid.ControlCount - 1 do
  begin
    c := AGrid.Controls[i];

    if c is TjanSimButton then
      TjanSimButton(c).BTaal := s
    else if c is TjanSimKnop then
      TjanSimKnop(c).BTaal := s
    else if c is TjanSimSensor then
      TjanSimSensor(c).BTaal := s
    else if c is TjanSimWarm then
      TjanSimWarm(c).BTaal := s
    else if c is TjanSimPuls then
      TjanSimPuls(c).BTaal := s
    else if c is TjanDipSwitsh then
      TjanDipSwitsh(c).BTaal := s
    else if c is TjanLogic then
      TjanLogic(c).BTaal := s
    else if c is TjanTeller then
      TjanTeller(c).BTaal := s
    else if c is TjanMemory then
      TjanMemory(c).BTaal := s
    else if c is TjanSimLight then
      TjanSimLight(c).BTaal := s
    else if c is TjanSimRelais then
      TjanSimRelais(c).BTaal := s
    else if c is TjanSimBuzzer then
      TjanSimBuzzer(c).BTaal := s
    else if c is TjanDisplay then
      TjanDisplay(c).BTaal := s;
    // voeg hier je andere sim-types toe  aanpassen
  end;
end;

procedure TjanSimLogicBox.SetBoxTaal(const Value:TStatTaal);
begin
  if value<>FBoxTaal then
  begin
    FBoxTaal := Value;
  end;
if FBoxTaal=stDutch then
 Begin
  Taal:='NL';
  HBuzzer:='maak Zoemer';
  HDipSwitsh:='maak DipSwitsh';
  HDisplay:='maak 7 segmentdisplay';
  HDraad:='maak Vebinding';
  HDrukknop:='maak Drukknop';
  HLamp:='maak Lamp';
  HLogicAnd:='maak EN-poort';
  HLogicNot:='maak Niet-poort';
  HLogicOr:='maak OF-poort';
  HMemory:='maak Geheugenblok';
  HPuls:='maak Impulsgenerator';
  HRelais:='maak Relais';
  HSchakelaar:='maak Schakelaar';
  HSensor:='maak Lichtsensor';
  HTeller:='maak Tellerblok';
  HWarm:='maak WarmteSensor';
 end;

if FBoxTaal=stEnglish then
 Begin
  Taal:='ENG';
  HBuzzer:='create Buzzer';
  HDipSwitsh:='create DipSwitsh';
  HDisplay:='create 7 segment display';
  HDraad:='create Connection';
  HDrukknop:='create Push button';
  HLamp:='create Lamp';
  HLogicAnd:='create AND-Logic gate';
  HLogicNot:='create NOT-Logic gate';
  HLogicOr:='create OR-Logic gate';
  HMemory:='create Memory block';
  HPuls:='create Impuls generator';
  HRelais:='create Relay';
  HSchakelaar:='create Switsh';
  HSensor:='create Light sensor';
  HTeller:='create Counter block';
  HWarm:='create HeatSensor';
  end ;
if FBoxTaal=stFrench then
 Begin
  Taal:='FR' ;
  HBuzzer:='faire Ronfleur';
  HDipSwitsh:='faire DipSwitsh';
  HDisplay:='faire Affichage à 7 segments';
  HDraad:='faire Connexion';
  HDrukknop:='faire Bouton poussoir';
  HLamp:='faire Lampe';
  HLogicAnd:='faire ET-La porte logique';
  HLogicNot:='faire Pas-La porte logique';
  HLogicOr:='faire OU-La porte logique';
  HMemory:='faire Bloc mémoire';
  HPuls:='faire Générateur d"impulsions';
  HRelais:='faire Relais';
  HSchakelaar:='faire un changement';
  HSensor:='faire Capteur de lumière';
  HTeller:='faire Bloc compteur';
  HWarm:='faire Capteur de chaleur';
 end;

 if FBoxTaal=stGerman then
  Begin
  Taal:='DU';
  HBuzzer:='Buzzer erstellen';
  HDipSwitsh:='DipSwitsh erstellen';
  HDisplay:='Erstellen Sie eine 7-Segment-Anzeige';
  HDraad:='Verbindung herstellen';
  HDrukknop:='Erstellen Sie einen Druckknopf';
  HLamp:='Lampe herstellen';
  HLogicAnd:='UND-Gatter erstellen';
  HLogicNot:='Erstellen Sie keinen Port';
  HLogicOr:='ODER-Gatter erstellen';
  HMemory:='Speicherblock erstellen';
  HPuls:='Impulsgenerator herstellen';
  HRelais:='Relais erstellen';
  HSchakelaar:='Schalter machen';
  HSensor:='Lichtsensor herstellen';
  HTeller:='Gegenblock erstellen';
  HWarm:='HeatSensor erstellen';
  end;
  invalidate;
 // willy
end;


procedure TjanSimLogicBox.SetLamp(const Value: Boolean);
begin
  if value<>FLamp then
  begin
    FLamp := Value;
  if Value=true then FOutputAantal:= FOutputAantal + 1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLijst(Value:TstringList);
begin
  if value<>templijst then
  begin
    templijst := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDisplay(const Value: Boolean);
begin
  if value<>FDisplay then
  begin
    FDisplay := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetMeter(const Value: Boolean);
begin
  if value<>FMeter then
  begin
    FMeter := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDipSwitsh(const Value: Boolean);
begin
  if value<>FDipSwitsh then
  begin
    FDipSwitsh := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLogicAnd(const Value: Boolean);
begin
  if value<>FLogicAnd then
  begin
    FLogicAnd := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;
procedure TjanSimLogicBox.SetLogicNot(const Value: Boolean);
begin
  if value<>FLogicNot then
  begin
    FLogicNot := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLogicOr(const Value: Boolean);
begin
  if value<>FLogicOr then
  begin
    FLogicOr := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetTeller(const Value: Boolean);
begin
  if value<>FTeller then
  begin
    FTeller := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetMemory(const Value: Boolean);
begin
  if value<>FMemory then
  begin
    FMemory := Value;
    if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetNewObject(const Value: Boolean);
begin
  if value<>FNew then
  begin
    FNew := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetRelais(const Value: Boolean);
begin
  if value<>FRelais then
  begin
    FRelais := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetSensor(const Value: Boolean);
begin
  if value<>FSensor then
  begin
    FSensor := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetWarm(const Value: Boolean);
begin
  if value<>FWarm then
  begin
    FWarm := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetSchakelaar(const Value: Boolean);
begin
  if value<>FSchakelaar then
  begin
    FSchakelaar := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetPuls(const Value: Boolean);
begin
  if value<>FPuls then
  begin
    FPuls := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetParent(const Value: TWinControl);
begin
  if value<>FParent then
  begin
    FParent := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetObjectID(const Value: Integer);
begin
  if value<>FObjectID then
  begin
    FObjectID := Value;
  end;
  invalidate;
end;



procedure TjanSimLogicBox.SetOpen(const Value: Boolean);
begin
  if value <> FOpen then
  begin
    FOpen := Value;
  end;
  If FOpen=true then
    begin
    width:=45;
    //MoveObjekten(45);
    end
    else
    begin
    width:=0 ;
    //MoveObjekten(-45);
    end;
 //invalidate;
end;

procedure TjanSimLogicBox.SetStart(const Value: Boolean);
begin
  if value <> FStart then
  begin
    FStart := Value;
  end;
  If FStart=true then maakpanel ;
  invalidate;
end;

procedure TjanSimLogicBox.DoObjectMove(Obj: TControl; X, Y: Integer);
begin
  if Assigned(FOnObjectMove) then
    FOnObjectMove(Self, Obj, X, Y);
end;

procedure TjanSimLogicBox.StatusFromChild(Sender: TObject; const AText: string; APanel: Integer);
begin
  FLastStatusSender := Sender;
  DoStatusText(AText, APanel);
end;

Procedure TjanSimLogicBox.PaintBoxLeft;
var
B,H,LK,TOP,BK,HK,SPATIE:Integer;
RC,RB:TRect;
Bmp:TBitmap;

X1,Y1,X2,Y2:integer;
begin
   if (align = alLeft) then
  begin
    SPATIE := FSpatie;
    B := 26;                 // Breedte knop
    H := 26;                 // hoogte knop
    LK := FKnopLeft;         // X1
    TOP := FKnopTop;         // Y1
    BK := LK + B;            // X2
    HK := TOP + H;           // Y2

    RC := self.ClientRect;
    // teken een soort van TBevel
    Canvas.Brush.Style := bsClear;
    Canvas.FillRect(RC);

    // Tekenen van verhoogd effect (raised bevel)
    Canvas.Pen.Color := clWhite;
    Canvas.MoveTo(RC.Left, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Top);

    Canvas.Pen.Color := clGray;
    Canvas.MoveTo(RC.Right - 1, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Bottom - 1);

    // Optioneel: Binnenste rand voor diepte-effect
    InflateRect(RC, -2, -2);
    Canvas.Pen.Color := clSilver;
    Canvas.Rectangle(RC);

    with canvas do
    begin
      bmp := TBitmap.Create;
      bmp.Canvas.Brush.Color := FBColor;   /// achtergrond kleur LogicBox met property BColor
      bmp.Width := Width;
      bmp.Height := Height;
      RB := ClientRect;
      bmp.Canvas.FillRect(RB);
      frame3D(RB, clbtnhighlight, clbtnshadow, 1);
      frame3D(RB, clbtnshadow, clbtnhighlight, 2);
      Draw(0, 0, bmp);
      bmp.Free;

       // teken een soort van TBevel
      brush.Style :=bsClear;
      FillRect(Rb);
      frame3D(Rb, clbtnshadow, clbtnhighlight, 1);
      brush.color := FBColor;

      brush.color := clSilver;



      // ===========================================================
      // Connector (BESTAAND)
      // ===========================================================
      If FDraad=true then
      Begin
        RCon:= rect(LK-3,TOP,BK+3,HK);
        Rb:=RCon;
        if not DCon then
           frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
           frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+2,top+3,bmCon);
        TOP:=TOP+ H -15 +SPATIE+10;
        HK:= H+TOP;
      end;

      if A_Imput > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color :=  FBColor;//clGreen;//FImputColor;
        bmp.Width := (BK);
        bmp.Height := ((A_Imput * H)+((A_Imput-1) * Knopspatie)+ 7-28);
        Rb:=Rect(0, 0, bmp.Width, bmp.Height);
        bmp.Canvas.FillRect(Rb);
        Draw(LK-4,TOP-4, bmp);
        bmp.Free;
        brush.color:=clSilver;
      end;

      // Begin invoer
      If FDrukknop=true then
      Begin
       // brush.color:=clRed;

        RButton:= rect(LK,TOP,BK,HK);
        Rb:=RButton;
        if not DButton then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(LK+1,TOP+2,bmButton);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FSchakelaar=true then
      Begin
        RKnop:= rect(LK,TOP,BK,HK);
        Rb:=RKnop;
        if not DKnop then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(LK+1,TOP+2,bmKnop);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FSensor=true then
      Begin
        RSensor:= rect(LK,TOP,BK,HK);
        Rb:=RSensor;
        if not DSensor then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmSensor);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FWarm=true then
      Begin
        RWarm:= rect(LK,TOP,BK,HK);
        Rb:=RWarm;
        if not DWarm then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmWarm);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FPuls=true then
      Begin
        RPuls:= rect(LK,TOP,BK,HK);
        Rb:=RPuls;
        if not DPuls then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmPuls);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FDipSwitsh=true then
      Begin
        RDipSwitsh:= rect(LK,TOP,BK,HK);
        Rb:=RDipSwitsh;
        if not DDipSwitsh then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmDipSwitsh);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      TOP:=TOP+20; HK:=HK+20;
      //einde invoer

      //begin verwerking
      If A_Verwerking > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;//clRed;
        bmp.Width := (BK);
        bmp.Height := ((A_Verwerking * H)+((A_Verwerking-1) * Knopspatie)+ 7);
        Rb:=rect(LK-5,TOP-5,BK+5,Top+(A_Verwerking * H)+((A_Verwerking-1) * Knopspatie)+ 5);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4,TOP-4, bmp);//kader Verwerken
        bmp.Free;
      end;

      brush.color:=clSilver;

      If FLogicAnd=true then
      Begin
        RLogicAnd:= rect(LK,TOP,BK,HK);
        Rb:=RLogicAnd;
        if not DLogicAnd then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmLogicAnd);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FLogicOr=true then
      Begin
        RLogicOr:= rect(LK,TOP,BK,HK);
        Rb:=RLogicOr;
        if not DLogicOr then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmLogicOr);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FLogicNot=true then
      Begin
        RLogicNot:= rect(LK,TOP,BK,HK);
        Rb:=RLogicNot;
        if not DLogicNot then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmLogicNot);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FTeller=true then
      Begin
        RTeller:= rect(LK,TOP,BK,HK);
        Rb:=RTeller;
        if not DTeller then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmTeller);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FMemory=true then
      Begin
        RMemory:= rect(LK,TOP,BK,HK);
        Rb:=RMemory;
        if not DMemory then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmMemory);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      Top:=Top+20; HK:=HK+20;
      // einde verwerking

      //uitvoer
      If A_Output > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;//clBlue;// FOutputColor;
        bmp.Width := (BK);
        bmp.Height := ((A_Output * H)+((A_Output-1) * Knopspatie)+ 7);
        Rb:=rect(LK-3,TOP-5,BK+5,Top+(A_Output * H)+((A_Output-1) * Knopspatie)+ 5);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4,TOP-4, bmp);
        bmp.Free;
      end;

      brush.color:=clSilver;

      If FLamp=true then
      Begin
        RLight:= rect(LK,TOP,BK,HK);
        Rb:=RLight;
        if not DLight then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmLight);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FRelais=true then
      Begin
        RRelais:= rect(LK,TOP,BK,HK);
        Rb:=RRelais;
        if not DRelais then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmRelais);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FBuzzer=true then
      Begin
        RBuzzer:= rect(LK,TOP,BK,HK);
        Rb:=RBuzzer;
        if not DBuzzer then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmBuzzer);
        TOP:=TOP+H+SPATIE;
        HK:= H+TOP;
      end;

      If FDisplay=true then
      Begin
        RDisplay:= rect(LK,TOP,BK,HK);
        Rb:=RDisplay;
        if not DDisplay then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top+2,bmDisplay);
        TOP:=TOP+H+6; // 6 in de plaats van SPATIE
        HK:= H+TOP;
      end;

       brush.color:=clSilver;

      If FMeter=true then
      Begin
        RMeter:= rect(LK,TOP,BK,HK);
        Rb:=RMeter;
        if not DMeter then
          frame3D(Rb,clbtnhighlight,clbtnshadow,1)
        else
          frame3D(Rb,clbtnshadow,clbtnhighlight,1);
        fillrect(Rb);
        draw(Lk+1,top + 2,bmMeter);
      end;
    end;
  end;

end;



PROCEDURE TjanSimLogicBox.PaintBoxTop;
var
  B,H,LK,TOP,BK,HK,SPATIE: Integer;
  RC,RB: TRect;
  Bmp: TBitmap;

  // helper om de volgende "slot" horizontaal te zetten
  procedure NextX(Delta: Integer);
  begin
    LK := LK + Delta;
    BK := LK + B;
  end;

begin
  if (Align = alTop) then
  begin
    SPATIE := FSpatie;
    B := 26;                 // Breedte knop
    H := 26;                 // Hoogte knop
    LK := FKnopLeft;         // X1
    TOP := FKnopTop;         // Y1
    BK := LK + B;            // X2
    HK := TOP + H;           // Y2

    RC := Self.ClientRect;



    // teken een soort van TBevel
    Canvas.Brush.Style := bsClear;
    Canvas.FillRect(RC);

    // Tekenen van verhoogd effect (raised bevel)
    Canvas.Pen.Color := clWhite;
    Canvas.MoveTo(RC.Left, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Top);

    Canvas.Pen.Color := clGray;
    Canvas.MoveTo(RC.Right - 1, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Bottom - 1);

    // Optioneel: Binnenste rand voor diepte-effect
    InflateRect(RC, -2, -2);
    Canvas.Pen.Color := clSilver;
    Canvas.Rectangle(RC);

    with Canvas do
    begin
      bmp := TBitmap.Create;
      bmp.Canvas.Brush.Color := FBColor;   /// achtergrond kleur LogicBox met property BColor
      bmp.Width := Width;
      bmp.Height := Height;
      RB := ClientRect;
      bmp.Canvas.FillRect(RB);
      Frame3D(RB, clBtnHighlight, clBtnShadow, 1);
      Frame3D(RB, clBtnShadow, clBtnHighlight, 2);
      Draw(0, 0, bmp);
      bmp.Free;

      Brush.Color := clSilver;


       Brush.Color := clSilver;
      // ===========================================================
      // Connector (BESTAAND)
      // ===========================================================
      if FDraad = True then
      begin
        RCon := Rect(LK, TOP,36, 32);
        Rb := RCon;

        FHoverRect := RCon;
        FHoverText := 'Connector tool – verbindt componenten';

        DoStatusText('Connector tool',0);
       if not DCon then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+4, TOP+4, bmCon);

        // was: TOP := TOP + H -15 +SPATIE+10;
        NextX(B  + SPATIE + 10);
        HK := TOP + H;
      end;

      // ===========================================================
      // GROEP: INPUT achtergrond (horizontale balk)
      // ===========================================================
      if A_Imput > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        // breedte = aantal knoppen * B + spacing ertussen + kleine marge
        bmp.Width  := (A_Imput * B) + ((A_Imput-1) * Knopspatie) + 7;
        bmp.Height := H + 7;  // 1 rij hoog + marge

        Rb := Rect(0, 0, bmp.Width, bmp.Height);
        bmp.Canvas.FillRect(Rb);

        Draw(LK-4, TOP-4, bmp);
        bmp.Free;

        Brush.Color := clSilver;
      end;

      // Begin invoer (nu horizontaal)
      if FDrukknop = True then
      begin
        RButton := Rect(LK, TOP, BK, HK);
        Rb := RButton;

        if not DButton then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmButton);

        // was: TOP := TOP + H + SPATIE;
        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FSchakelaar = True then
      begin
        RKnop := Rect(LK, TOP, BK, HK);
        Rb := RKnop;

        if not DKnop then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmKnop);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FSensor = True then
      begin
        RSensor := Rect(LK, TOP, BK, HK);
        Rb := RSensor;

        if not DSensor then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmSensor);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FWarm = True then
      begin
        RWarm := Rect(LK, TOP, BK, HK);
        Rb := RWarm;

        if not DWarm then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmWarm);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FPuls = True then
      begin
        RPuls := Rect(LK, TOP, BK, HK);
        Rb := RPuls;

        if not DPuls then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmPuls);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FDipSwitsh = True then
      begin
        RDipSwitsh := Rect(LK, TOP, BK, HK);
        Rb := RDipSwitsh;

        if not DDipSwitsh then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmDipSwitsh);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      // was: TOP := TOP + 20;
      NextX(20);

      // ===========================================================
      // GROEP: VERWERKING achtergrond (horizontale balk)
      // ===========================================================
      if A_Verwerking > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        bmp.Width  := (A_Verwerking * B) + ((A_Verwerking-1) * Knopspatie) + 7;
        bmp.Height := H + 7;

        // kader rond de groep (zoals je deed met rect(LK-5,...))
        Rb := Rect(LK-5, TOP-5, LK-5 + bmp.Width + 10, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      if FLogicAnd = True then
      begin
        RLogicAnd := Rect(LK, TOP, BK, HK);
        Rb := RLogicAnd;
        if not DLogicAnd then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicAnd);
        NextX(B + SPATIE);
      end;

      if FLogicOr = True then
      begin
        RLogicOr := Rect(LK, TOP, BK, HK);
        Rb := RLogicOr;
        if not DLogicOr then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicOr);
        NextX(B + SPATIE);
      end;

      if FLogicNot = True then
      begin
        RLogicNot := Rect(LK, TOP, BK, HK);
        Rb := RLogicNot;
        if not DLogicNot then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicNot);
        NextX(B + SPATIE);
      end;

      if FTeller = True then
      begin
        RTeller := Rect(LK, TOP, BK, HK);
        Rb := RTeller;
        if not DTeller then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmTeller);
        NextX(B + SPATIE);
      end;

      if FMemory = True then
      begin
        RMemory := Rect(LK, TOP, BK, HK);
        Rb := RMemory;
        if not DMemory then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmMemory);
        NextX(B + SPATIE);
      end;

      NextX(20);

      // ===========================================================
      // GROEP: OUTPUT achtergrond (horizontale balk)
      // ===========================================================
      if A_Output > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        bmp.Width  := (A_Output * B) + ((A_Output-1) * Knopspatie) + 7;
        bmp.Height := H + 7;

        Rb := Rect(LK-3, TOP-5, LK-3 + bmp.Width + 8, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      if FLamp = True then
      begin
        RLight := Rect(LK, TOP, BK, HK);
        Rb := RLight;
        if not DLight then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLight);
        NextX(B + SPATIE);
      end;

      if FRelais = True then
      begin
        RRelais := Rect(LK, TOP, BK, HK);
        Rb := RRelais;
        if not DRelais then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmRelais);
        NextX(B + SPATIE);
      end;

      if FBuzzer = True then
      begin
        RBuzzer := Rect(LK, TOP, BK, HK);
        Rb := RBuzzer;
        if not DBuzzer then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmBuzzer);
        NextX(B + SPATIE);
      end;

      if FDisplay = True then
      begin
        RDisplay := Rect(LK, TOP, BK, HK);
        Rb := RDisplay;
        if not DDisplay then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmDisplay);

        // was: TOP := TOP + H + 6;
        NextX(B + 6);
      end;

      Brush.Color := clSilver;

      if FMeter = True then
      begin
        RMeter := Rect(LK, TOP, BK, HK);
        Rb := RMeter;
        if not DMeter then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP + 2, bmMeter);
      end;
    end;
  end;
end;

PROCEDURE TjanSimLogicBox.PaintBoxBottom;
var
  B,H,LK,TOP,BK,HK,SPATIE: Integer;
  RC,RB: TRect;
  Bmp: TBitmap;

  // helper om de volgende "slot" horizontaal te zetten
  procedure NextX(Delta: Integer);
  begin
    LK := LK + Delta;
    BK := LK + B;
  end;

begin
  if (Align = alBottom) then
  begin
    SPATIE := FSpatie;
    B := 26;                 // Breedte knop
    H := 26;                 // Hoogte knop
    LK := FKnopLeft;         // X1
    TOP := FKnopTop;         // Y1
    BK := LK + B;            // X2
    HK := TOP + H;           // Y2

    RC := Self.ClientRect;



    // teken een soort van TBevel
    Canvas.Brush.Style := bsClear;
    Canvas.FillRect(RC);

    // Tekenen van verhoogd effect (raised bevel)
    Canvas.Pen.Color := clWhite;
    Canvas.MoveTo(RC.Left, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Top);

    Canvas.Pen.Color := clGray;
    Canvas.MoveTo(RC.Right - 1, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Bottom - 1);

    // Optioneel: Binnenste rand voor diepte-effect
    InflateRect(RC, -2, -2);
    Canvas.Pen.Color := clSilver;
    Canvas.Rectangle(RC);

    with Canvas do
    begin
      bmp := TBitmap.Create;
      bmp.Canvas.Brush.Color := FBColor;   /// achtergrond kleur LogicBox met property BColor
      bmp.Width := Width;
      bmp.Height := Height;
      RB := ClientRect;
      bmp.Canvas.FillRect(RB);
      Frame3D(RB, clBtnHighlight, clBtnShadow, 1);
      Frame3D(RB, clBtnShadow, clBtnHighlight, 2);
      Draw(0, 0, bmp);
      bmp.Free;

      Brush.Color := clSilver;



      // ===========================================================
      // Connector (BESTAAND)
      // ===========================================================
      if FDraad = True then
      begin
        RCon := Rect(LK, TOP,36, 32);
        Rb := RCon;

        FHoverRect := RCon;
        FHoverText := 'Connector tool – verbindt componenten';

        DoStatusText('Connector tool',0);
       if not DCon then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+4, TOP+4, bmCon);

        // was: TOP := TOP + H -15 +SPATIE+10;
        NextX(B  + SPATIE + 10);
        HK := TOP + H;
      end;

      // ===========================================================
      // GROEP: INPUT achtergrond (horizontale balk)
      // ===========================================================
      if A_Imput > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        // breedte = aantal knoppen * B + spacing ertussen + kleine marge
        bmp.Width  := (A_Imput * B) + ((A_Imput-1) * Knopspatie) + 7;
        bmp.Height := H + 7;  // 1 rij hoog + marge

        Rb := Rect(0, 0, bmp.Width, bmp.Height);
        bmp.Canvas.FillRect(Rb);

        Draw(LK-4, TOP-4, bmp);
        bmp.Free;

        Brush.Color := clSilver;
      end;

      // Begin invoer (nu horizontaal)
      if FDrukknop = True then
      begin
        RButton := Rect(LK, TOP, BK, HK);
        Rb := RButton;

        if not DButton then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmButton);

        // was: TOP := TOP + H + SPATIE;
        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FSchakelaar = True then
      begin
        RKnop := Rect(LK, TOP, BK, HK);
        Rb := RKnop;

        if not DKnop then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmKnop);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FSensor = True then
      begin
        RSensor := Rect(LK, TOP, BK, HK);
        Rb := RSensor;

        if not DSensor then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmSensor);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FWarm = True then
      begin
        RWarm := Rect(LK, TOP, BK, HK);
        Rb := RWarm;

        if not DWarm then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmWarm);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FPuls = True then
      begin
        RPuls := Rect(LK, TOP, BK, HK);
        Rb := RPuls;

        if not DPuls then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmPuls);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if FDipSwitsh = True then
      begin
        RDipSwitsh := Rect(LK, TOP, BK, HK);
        Rb := RDipSwitsh;

        if not DDipSwitsh then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        Draw(LK+1, TOP+2, bmDipSwitsh);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      // was: TOP := TOP + 20;
      NextX(20);

      // ===========================================================
      // GROEP: VERWERKING achtergrond (horizontale balk)
      // ===========================================================
      if A_Verwerking > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        bmp.Width  := (A_Verwerking * B) + ((A_Verwerking-1) * Knopspatie) + 7;
        bmp.Height := H + 7;

        // kader rond de groep (zoals je deed met rect(LK-5,...))
        Rb := Rect(LK-5, TOP-5, LK-5 + bmp.Width + 10, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      if FLogicAnd = True then
      begin
        RLogicAnd := Rect(LK, TOP, BK, HK);
        Rb := RLogicAnd;
        if not DLogicAnd then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicAnd);
        NextX(B + SPATIE);
      end;

      if FLogicOr = True then
      begin
        RLogicOr := Rect(LK, TOP, BK, HK);
        Rb := RLogicOr;
        if not DLogicOr then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicOr);
        NextX(B + SPATIE);
      end;

      if FLogicNot = True then
      begin
        RLogicNot := Rect(LK, TOP, BK, HK);
        Rb := RLogicNot;
        if not DLogicNot then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLogicNot);
        NextX(B + SPATIE);
      end;

      if FTeller = True then
      begin
        RTeller := Rect(LK, TOP, BK, HK);
        Rb := RTeller;
        if not DTeller then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmTeller);
        NextX(B + SPATIE);
      end;

      if FMemory = True then
      begin
        RMemory := Rect(LK, TOP, BK, HK);
        Rb := RMemory;
        if not DMemory then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmMemory);
        NextX(B + SPATIE);
      end;

      NextX(20);

      // ===========================================================
      // GROEP: OUTPUT achtergrond (horizontale balk)
      // ===========================================================
      if A_Output > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        bmp.Width  := (A_Output * B) + ((A_Output-1) * Knopspatie) + 7;
        bmp.Height := H + 7;

        Rb := Rect(LK-3, TOP-5, LK-3 + bmp.Width + 8, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      if FLamp = True then
      begin
        RLight := Rect(LK, TOP, BK, HK);
        Rb := RLight;
        if not DLight then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmLight);
        NextX(B + SPATIE);
      end;

      if FRelais = True then
      begin
        RRelais := Rect(LK, TOP, BK, HK);
        Rb := RRelais;
        if not DRelais then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmRelais);
        NextX(B + SPATIE);
      end;

      if FBuzzer = True then
      begin
        RBuzzer := Rect(LK, TOP, BK, HK);
        Rb := RBuzzer;
        if not DBuzzer then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmBuzzer);
        NextX(B + SPATIE);
      end;

      if FDisplay = True then
      begin
        RDisplay := Rect(LK, TOP, BK, HK);
        Rb := RDisplay;
        if not DDisplay then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP+2, bmDisplay);

        // was: TOP := TOP + H + 6;
        NextX(B + 6);
      end;

      Brush.Color := clSilver;

      if FMeter = True then
      begin
        RMeter := Rect(LK, TOP, BK, HK);
        Rb := RMeter;
        if not DMeter then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        Draw(LK+1, TOP + 2, bmMeter);
      end;
    end;
  end;
end;

// willy paint box
procedure TjanSimLogicBox.Paint;
var
  R, Rb, RC: TRect;
  w, top, Lk, Rk, Bk, HK, v, SPATIE, B, H: integer;
  Bmp: TBitmap;
begin
  if visible = false then exit;
  ControlStyle := ControlStyle + [csOpaque];

  if (align = alLeft) then PaintBoxLeft; // apparte procedure
  if (align = alTop) then PaintBoxTop; // apparte procedure
  if (align = alBottom) then PaintBoxBottom; // apparte procedure
end;

procedure TjanSimLogicBox.resize;
begin
if (Align=(alTop)) or (Align=(alBottom))then height:=36;
if (Align=(alLeft)) or (Align=(alRight)) then width:=45;
FFirst:=false;
end;

procedure TjanSimLogicBox.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TjanSimLogicBox.ChildMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   // niets doen: selectie enkel via popup
end;

procedure TjanSimLogicBox.ClearSelectedSender;
begin
  FSelectedSender := nil;
  // optioneel: ook hover sender wissen
  if FLastStatusSender <> nil then
    FLastStatusSender := nil;
end;

procedure TjanSimLogicBox.ApplyLanguageToSimObj(AComponent: TComponent);
begin
  if AComponent is TjanSimButton then
  begin
    TjanSimButton(AComponent).BTaal := Taal;
    TjanSimButton(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimKnop then
  begin
    TjanSimKnop(AComponent).BTaal := Taal;
    TjanSimKnop(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimSensor then
  begin
    TjanSimSensor(AComponent).BTaal := Taal;
    TjanSimSensor(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimWarm then
  begin
    TjanSimWarm(AComponent).BTaal := Taal;
    TjanSimWarm(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimPuls then
  begin
    TjanSimPuls(AComponent).BTaal := Taal;
    TjanSimPuls(AComponent).UpdateHintText;
  end
  else if AComponent is TjanDipSwitsh then
  begin
    TjanDipSwitsh(AComponent).BTaal := Taal;
    TjanDipSwitsh(AComponent).UpdateHintText;
  end
  else if AComponent is TjanLogic then
  begin
    TjanLogic(AComponent).BTaal := Taal;
    TjanLogic(AComponent).UpdateHintText;
  end
  else if AComponent is TjanTeller then
  begin
    TjanTeller(AComponent).BTaal := Taal;
    TjanTeller(AComponent).UpdateHintText;
  end
  else if AComponent is TjanMemory then
  begin
    TjanMemory(AComponent).BTaal := Taal;
    TjanMemory(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimLight then
  begin
    TjanSimLight(AComponent).BTaal := Taal;
    TjanSimLight(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimRelais then
  begin
    TjanSimRelais(AComponent).BTaal := Taal;
    TjanSimRelais(AComponent).UpdateHintText;
  end
 else if AComponent is TjanSimBuzzer then
  begin
    TjanSimBuzzer(AComponent).BTaal := Taal;
    TjanSimBuzzer(AComponent).UpdateHintText;
  end
  else if AComponent is TjanDisplay then
  begin
    TjanDisplay(AComponent).BTaal := Taal;
    TjanDisplay(AComponent).UpdateHintText;
  end;

  // aanpassen /uitbreiden
end;


procedure TjanSimLogicBox.Notification(AComponent: TComponent; Operation: TOperation);

  procedure HookSimObj(AObj: TObject);
  begin

    // Button
    if AObj is TjanSimButton then
    begin
      with TjanSimButton(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Knop
    if AObj is TjanSimKnop then
    begin
      with TjanSimKnop(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Sensor
    if AObj is TjanSimSensor then
    begin
      with TjanSimSensor(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Warm
    if AObj is TjanSimWarm then
    begin
      with TjanSimWarm(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // DipSwitch
    if AObj is TjanDipSwitsh then
    begin
      with TjanDipSwitsh(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Puls
    if AObj is TjanSimPuls then
    begin
      with TjanSimPuls(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Logic
    if AObj is TjanLogic then
    begin
      with TjanLogic(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // Tellerblok
    if AObj is TjanTeller then
    begin
      with TjanTeller(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // Geheugenblok
    if AObj is TjanMemory then
    begin
      with TjanMemory(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimLight
    if AObj is TjanSimLight then
    begin
      with TjanSimLight(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimRelais
    if AObj is TjanSimRelais then
    begin
      with TjanSimRelais(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimBuzzer
    if AObj is TjanSimBuzzer then
    begin
      with TjanSimBuzzer(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // TjanDisplay
    if AObj is TjanDisplay then
    begin
      with TjanDisplay(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;
  end;

begin
  inherited Notification(AComponent, Operation);

  case Operation of
    opInsert:
      Begin
      HookSimObj(AComponent);
      ApplyLanguageToSimObj(AComponent);
      end;
    opRemove:
      begin
        if (FLastStatusSender = AComponent) then
          FLastStatusSender := nil;
        if (FSelectedSender = AComponent) then
          FSelectedSender := nil;
      end;
  end;
end;

procedure TjanSimLogicBox.ChildMouseEnter(Sender: TObject);
var
  s: string;
begin
  inherited;

  FLastStatusSender := Sender;

  s := '';
  if Sender is TjanSimButton then
    s := TjanSimButton(Sender).Naam
  else if Sender is TjanSimKnop then
    s := TjanSimKnop(Sender).Naam
  else if Sender is TjanSimSensor then
    s := TjanSimSensor(Sender).Naam
  else if Sender is TjanSimWarm then
    s := TjanSimWarm(Sender).Naam
  else if Sender is TjanDipSwitsh then
    s := TjanDipSwitsh(Sender).Naam
  else if Sender is TjanSimPuls then
    s := TjanSimPuls(Sender).Naam
  else if Sender is TjanTeller then
    s := TjanTeller(Sender).Naam
  else if Sender is TjanMemory then
    s := TjanMemory(Sender).Naam
  else if Sender is TjanSimLight then
    s := TjanSimLight(Sender).Naam
  else if Sender is TjanSimRelais then
    s := TjanSimRelais(Sender).Naam
  else if Sender is TjanSimBuzzer then
    s := TjanSimBuzzer(Sender).Naam
  else if Sender is TjanDisplay then
    s := TjanDisplay(Sender).Naam;
  // panel 0 = naam (kleurblok doet mainform nu obv FCurrentSender/Soort)
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, s, 0);
    // aanpassen
  // panel 3 NIET meer hier doen (MainForm vult dat centraal)
end;

procedure TjanSimLogicBox.ChildMouseExit(Sender: TObject);
begin
  FLastStatusSender := nil;
   if Assigned(FOnStatusText) then
    FOnStatusText(Self, '', 0);
end;

{ TjanGroupSelect }

function GroupNormRect(const R: TRect): TRect;
begin
  Result := R;
  if R.Left > R.Right then
  begin
    Result.Left := R.Right;
    Result.Right := R.Left;
  end;
  if R.Top > R.Bottom then
  begin
    Result.Top := R.Bottom;
    Result.Bottom := R.Top;
  end;
end;

constructor TjanGroupSelect.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList.Create;
  FBTaal := 'NL';
  Visible := False;
  ShowHint := True;
  SetBounds(0, 0, 1, 1);
end;

destructor TjanGroupSelect.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TjanGroupSelect.IsGroupable(C: TControl): Boolean;
begin
  Result := (C <> Self) and C.Visible and
    ((C is TjanLogic) or (C is TjanTeller) or (C is TjanMemory) or
     (C is TjanSimButton) or (C is TjanSimKnop) or (C is TjanSimSensor) or
     (C is TjanSimWarm) or (C is TjanSimPuls) or (C is TjanDipSwitsh) or
     (C is TjanSimLight) or (C is TjanSimRelais) or (C is TjanSimBuzzer) or
     (C is TjanDisplay) or (C is TjanMeter));
  // vergrendelde objecten blijven staan
  if Result and IsPublishedProp(C, 'Lock') then
    Result := GetOrdProp(C, 'Lock') = 0;
end;

function TjanGroupSelect.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TjanGroupSelect.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FItems) and (FItems.IndexOf(AComponent) >= 0) then
  begin
    FItems.Remove(AComponent);
    if not FBanding then
      UpdateFrame;
  end;
end;

procedure TjanGroupSelect.Clear;
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TComponent(FItems[i]).RemoveFreeNotification(Self);
  FItems.Clear;
  FBanding := False;
  FDragging := False;
  Visible := False;
end;

procedure TjanGroupSelect.UpdateFrame;
var
  i: Integer;
  R, U: TRect;
begin
  if FItems.Count = 0 then
  begin
    Visible := False;
    Exit;
  end;
  U := TControl(FItems[0]).BoundsRect;
  for i := 1 to FItems.Count - 1 do
  begin
    R := TControl(FItems[i]).BoundsRect;
    UnionRect(U, U, R);
  end;
  InflateRect(U, 6, 6);
  BoundsRect := U;
  Hint := Tr(FBTaal,
    Format('%d objecten geselecteerd'#13#10'Sleep om ze samen te verplaatsen, Esc of klik ernaast om te deselecteren', [FItems.Count]),
    Format('%d objects selected'#13#10'Drag to move them together, Esc or click outside to deselect', [FItems.Count]),
    Format('%d objets sélectionnés'#13#10'Faites glisser pour les déplacer ensemble, Échap ou clic à côté pour désélectionner', [FItems.Count]),
    Format('%d Objekte ausgewählt'#13#10'Ziehen, um sie gemeinsam zu verschieben, Esc oder daneben klicken zum Abwählen', [FItems.Count]));
  Visible := True;
  BringToFront;
  Invalidate;
end;

procedure TjanGroupSelect.SelectRect(R: TRect);
var
  i: Integer;
  C: TControl;
  RC: TRect;
begin
  Clear;
  if Parent = nil then Exit;
  R := GroupNormRect(R);
  for i := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[i];
    if not IsGroupable(C) then Continue;
    RC := C.BoundsRect;
    // object moet volledig binnen de rechthoek liggen
    if (RC.Left >= R.Left) and (RC.Top >= R.Top) and
       (RC.Right <= R.Right) and (RC.Bottom <= R.Bottom) then
    begin
      FItems.Add(C);
      C.FreeNotification(Self);
    end;
  end;
  UpdateFrame;
end;

procedure TjanGroupSelect.SelectAll;
begin
  SelectRect(Rect(-MaxInt div 2, -MaxInt div 2, MaxInt div 2, MaxInt div 2));
end;

procedure TjanGroupSelect.BeginBand(X, Y: Integer);
begin
  Clear;
  FBanding := True;
  FBandStart := Point(X, Y);
  SetBounds(X, Y, 1, 1);
  Visible := True;
  BringToFront;
end;

procedure TjanGroupSelect.MoveBand(X, Y: Integer);
begin
  if not FBanding then Exit;
  BoundsRect := GroupNormRect(Rect(FBandStart.X, FBandStart.Y, X, Y));
  Invalidate;
end;

procedure TjanGroupSelect.EndBand(X, Y: Integer);
var
  R: TRect;
begin
  if not FBanding then Exit;
  FBanding := False;
  R := GroupNormRect(Rect(FBandStart.X, FBandStart.Y, X, Y));
  // gewoon klikken (geen echte rechthoek) = alleen deselecteren
  if (R.Right - R.Left < 4) and (R.Bottom - R.Top < 4) then
    Clear
  else
    SelectRect(R);
end;

procedure TjanGroupSelect.Paint;
begin
  // Alleen de rand tekenen: de objecten eronder blijven zichtbaar.
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psDash;
  if FBanding then
    Canvas.Pen.Color := clGray
  else
    Canvas.Pen.Color := clBlue;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TjanGroupSelect.PrepareDrag;
var
  i, j, n: Integer;
  C: TControl;
  Con: TjanConnector;
  Rc: TRect;
  EndA, EndB: TPoint;
  ModeA, ModeB: TjanConMode;
  InA, InB: Boolean;

  function InGroup(const P: TPoint): Boolean;
  var
    k: Integer;
    R: TRect;
  begin
    Result := False;
    for k := 0 to FItems.Count - 1 do
    begin
      R := TControl(FItems[k]).BoundsRect;
      InflateRect(R, 8, 8);   // zelfde marge als AnchorConnectors
      if PtInRect(R, P) then
        Exit(True);
    end;
  end;

begin
  SetLength(FItemStart, FItems.Count);
  for i := 0 to FItems.Count - 1 do
    FItemStart[i] := Point(TControl(FItems[i]).Left, TControl(FItems[i]).Top);
  FFrameStart := Point(Left, Top);

  // draden: welke uiteinden liggen op een geselecteerd object?
  SetLength(FCons, 0);
  SetLength(FConMove, 0);
  SetLength(FConStart, 0);
  n := 0;
  for j := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[j];
    if not (C is TjanConnector) then Continue;
    Con := TjanConnector(C);
    Rc := Con.BoundsRect;
    if Con.Shape = jcsTLBR then
    begin
      EndA := Point(Rc.Left, Rc.Top);      ModeA := jcmTL;
      EndB := Point(Rc.Right, Rc.Bottom);  ModeB := jcmBR;
    end
    else
    begin
      EndA := Point(Rc.Right, Rc.Top);     ModeA := jcmTR;
      EndB := Point(Rc.Left, Rc.Bottom);   ModeB := jcmBL;
    end;
    InA := InGroup(EndA);
    InB := InGroup(EndB);
    if not (InA or InB) then Continue;

    SetLength(FCons, n + 1);
    SetLength(FConMove, n + 1);
    SetLength(FConStart, n + 1);
    FCons[n] := Con;
    FConStart[n] := Point(Con.Left, Con.Top);
    if InA and InB then
      FConMove[n] := 1                 // beide uiteinden mee: draad verschuiven
    else
    begin
      FConMove[n] := 2;                // één uiteinde mee: draad uitrekken
      // ankerpunt (0,0): MoveConnector(delta) verplaatst dan dat uiteinde
      if InA then
        Con.AnchorCorner(Point(0, 0), ModeA)
      else
        Con.AnchorCorner(Point(0, 0), ModeB);
    end;
    Inc(n);
  end;
end;

procedure TjanGroupSelect.ApplyDelta(DX, DY: Integer);
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    if i <= High(FItemStart) then
      TControl(FItems[i]).SetBounds(FItemStart[i].X + DX, FItemStart[i].Y + DY,
        TControl(FItems[i]).Width, TControl(FItems[i]).Height);
  for i := 0 to High(FCons) do
    if FConMove[i] = 1 then
      FCons[i].SetBounds(FConStart[i].X + DX, FConStart[i].Y + DY,
        FCons[i].Width, FCons[i].Height)
    else
      FCons[i].MoveConnector(Point(DX, DY));
  SetBounds(FFrameStart.X + DX, FFrameStart.Y + DY, Width, Height);
end;

procedure TjanGroupSelect.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FBanding then Exit;
  if Button = mbRight then
  begin
    Clear;
    Exit;
  end;
  if (Button = mbLeft) and (FItems.Count > 0) then
  begin
    FDragStart := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
    PrepareDrag;
    FDragging := True;
  end;
end;

procedure TjanGroupSelect.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, C0, Snapped: TPoint;
  DX, DY: Integer;
  WorkR: TRect;
  Ref: TControl;
begin
  inherited MouseMove(Shift, X, Y);
  if not (FDragging and (ssLeft in Shift)) then Exit;
  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  DX := P.X - FDragStart.X;
  DY := P.Y - FDragStart.Y;

  if Parent is TjanGridS then
  begin
    WorkR := TjanGridS(Parent).GetWorkAreaRect;
    // groep binnen het werkgebied houden
    if FFrameStart.X + DX < WorkR.Left then DX := WorkR.Left - FFrameStart.X;
    if FFrameStart.Y + DY < WorkR.Top then DY := WorkR.Top - FFrameStart.Y;
    // snappen zoals bij één object: op het midden van het eerste object
    Ref := TControl(FItems[0]);
    C0 := Point(FItemStart[0].X + Ref.Width div 2 + DX,
                FItemStart[0].Y + Ref.Height div 2 + DY);
    Snapped := TjanGridS(Parent).SnapPointToRuler(C0, WorkR);
    DX := DX + (Snapped.X - C0.X);
    DY := DY + (Snapped.Y - C0.Y);
  end;

  ApplyDelta(DX, DY);
end;

procedure TjanGroupSelect.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FDragging := False;
  if Assigned(Parent) then
    Parent.Invalidate;
end;


end.
