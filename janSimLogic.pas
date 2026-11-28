{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is JvSimLogic.pas (Project JEDI, JVCL), released in 2002.
The Initial Developer of the Original Code is Jan Verhoeven.
Portions created by Jan Verhoeven are Copyright (C) 2002 Jan Verhoeven.
All Rights Reserved.

Contributor(s): Willy Jansen (willem750-win), 2026: port to Lazarus and
extensions for the Logic circuit simulator.
-----------------------------------------------------------------------------}

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
  TjanRail = class;         // forward (voedingsrail)
  TjanVoedingsDeel = class; // forward (bron, zekering, milliampèremeter)
  TjanLogicRun = class;     // forward (programmeermodule)


  // Event doorgeven van Strings naar TStatusBar panels in main
  TSimStatusEvent = procedure(Sender: TObject; const AText: string; APanel: Integer) of object;
  TSimStatusEventEx = procedure(Sender: TObject; ASource: TObject;const AText: string; APanel: Integer) of object;

  TjanLogic=class;
  TjanTeller=class;
  TjanMemory=class;

  TjanGateStyle=(jgsDI,jgsDO);
  // nieuwe soorten achteraan: de volgorde (Ord) mag niet veranderen
  TjanLogicFunc=(jlfAND,jlfOR,jlfNOT,jlfNAND,jlfNOR,jlfXOR);
  // tekenwijze van de onderdelen: Afbeelding (plaatjes, poorten als woord in een
  // rechthoek), IEC 60617 of ANSI/IEEE 91 (schemasymbolen; verschillen bij de poorten)
  TjanSymbolen=(Afbeelding,IEC,ANSI);
  // uitvoer TjanSimLight: een gewone lamp of een led in een kleur
  TLampKleur=(lkLamp,lkRood,lkGroen,lkOranje);
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
    FBcd        : array[0..3] of Boolean;   // ingangen 1, 2, 4, 8 (van boven naar onder)
    FBcdGebruikt: Boolean;                   // er hangt iets aan een van die ingangen
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
    // ingangen 1-2-4-8 links (0..3, van boven naar onder), anders -1
    function BcdIndexAt(const P: TPoint): Integer;
    procedure ZetBcd(AIndex: Integer; AAan: Boolean);
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
    FSelected: Boolean;  // geselecteerd (rood kader), voor de knop Verwijderen
    FPopup: TPopupMenu;  // rechtsklikmenu (selecteren, verwijderen)
    FKlikSelect: Boolean; // linkse klik heeft de draad (de)geselecteerd
    FStroomA: Double;   // stroom van het begin naar het einde van de draad (A), voor de elektronen
    FStroomNieuw: Double; // nieuwe stroom tijdens UpdateSupply, pas op het einde toegepast
    FLogicBron: Boolean;  // van een logische uitgang naar een klem van de voedingskring:
                          // de uitgang is dan een bron van 5 V (hoog) of 0 V (laag)
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
    // rechtsklik op de draad: selecteren (voor de knop Verwijderen) of meteen
    // verwijderen
    procedure DraadSelectClick(Sender: TObject);
    procedure DraadVerwijderClick(Sender: TObject);
    procedure SetSelected(const Value: Boolean);
    function InLijnStrook(X, Y: Integer): Boolean;
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
    // met de knop Verbinding op een klem van de voedingskring: nieuwe draad
    function StartWireOnPin(const P: TPoint): Boolean;
    procedure SetStroomA(AI: Double);
    procedure PaintElektronen;
    procedure ElektronWeg(out Pt: array of TPoint);
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
    destructor Destroy; override;
    procedure paint; override;
    // stroom door de draad (A, van begin naar einde) zoals de elektronen hem tonen
    property StroomA: Double read FStroomA;
    // logische uitgang die een klem van de voedingskring voedt
    property LogicBron: Boolean read FLogicBron;
    // de ingang aan het einde van de draad uitzetten, vlak voor de draad
    // verwijderd wordt
    procedure Losmaken;
    property Selected: Boolean read FSelected write SetSelected;
    // alleen smalle stroken langs de draad hertekenen (de elektronen)
    procedure InvalidateElektronen;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoMouseDown(x, y: integer);
    procedure DoMouseMove(dx, dy: integer);
    procedure AnchorCorner(logTL:TPoint;ACorner:TjanConMode);
    function AnchorToRect(const R: TRect; logTL: TPoint): Boolean;
    function StraightenDelta(logTL: TPoint; out dX, dY: Integer): Boolean;
    procedure EndCenters(out APi, APo: TPoint);
    procedure PlaceEnds(const APi, APo: TPoint);
    procedure SnapEndToInput;
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
    FResetRonde: Cardinal;  // simulatieronde waarin Re laatst hoog was
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
    FDin: array[0..3] of Boolean;   // data-ingangen 8, 4, 2, 1
    FSchrijfIn: Boolean;            // schrijfingang S (schrijft bij de stijgende flank)
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
    property Connector:boolean read FConnector write SetConnector default false;
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
    // data-ingangen 8-4-2-1 en schrijfingang S links (0..3 = data, 4 = S, -1 = geen)
    function DataIndexAt(const P: TPoint): Integer;
    procedure ZetData(AIndex: Integer; AAan: Boolean);
    // inhoud van de 32 laatjes als 32 hexadecimale tekens (voor het paneelbestand)
    function InhoudTekst: string;
    procedure ZetInhoudUitRest(const ARest: string);
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
    // spanning die via een draad op + en - binnenkomt (volt)
    FPlusVolt: Double;
    FMinVolt: Double;
    FSelected: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FOnStatus: TSimStatusEvent;
    function  GetGate(Index: Integer): TjanGate;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure PaintLed(index:integer);
    procedure MeterClick(sender:TObject);
    procedure MeterClick1(sender:TObject);
    procedure MeterClick2(sender:TObject);
    procedure MeterSelectClick(Sender: TObject);
    procedure SetPlusVolt(const Value: Double);
    function GetOutPut2: Boolean;
    procedure SetMinVolt(const Value: Double);
    procedure SendStatusToBar;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
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
    // gemeten spanning U(+) - U(-) in volt. + en - komen van een draad of
    // van een rail: + ingeplugd op een + rail, - ingeplugd op een - rail (0 V)
    function Reading: Double;
    procedure UpdateHintText;
    property PlusVolt: Double read FPlusVolt write SetPlusVolt;
    property MinVolt: Double read FMinVolt write SetMinVolt;
  published
    property Input1:boolean read FInput1 write SetInput1;
    property Input3:boolean read FInput3 write SetInput3;
    property OutPut2:boolean read GetOutPut2 write SetOutPut2;
    property LogicFunc:TjanMeterFunc read FLogicAndFunc write SetLogicFunc;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write FTaal;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
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
    procedure FrequentieClick(Sender: TObject);
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
    FKleur: TLampKleur;      // lamp of led (rood, groen, oranje)
    FDimBmp: TBitmap;        // gedimde lamp, één keer gemengd (pixel per pixel is traag onder Linux)
    FDimKey: string;
    FDimPos: TPoint;         // waar FDimBmp (alleen het stuk dat aan en uit verschilt) komt

    procedure SendStatusToBar;//xxx
    procedure SetNaam(const Value: String);//xxx
    procedure SetTaal(const Value: String);//xxx
    procedure SetDown(const Value: boolean);//xxx
    procedure UpdateHintText; //xxxx
    procedure SetKleur(const Value: TLampKleur);
    procedure KleurClick(Sender: TObject);

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
    // lkLamp: gewone lamp; anders een led in die kleur (rechtsklikmenu Kleur)
    property Kleur:TLampKleur read FKleur write SetKleur default lkLamp;
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

  // Schakelrelais: relais met een bruikbaar maakcontact. De spoel (R+ onderaan,
  // R- rechts naar de - rail) bedient het contact bovenaan: R2 geeft het signaal
  // (en de spanning) van R1 door zolang de spoel bekrachtigd is (Lit).
  TjanSchakelRelais = class (TjanSimRelais)
  private
    FContactIn: Boolean;     // signaal op R1
    FContactVolt: Double;    // spanning op R1
    procedure SetContactIn(const Value: Boolean);
    // ingang van het contact: draad op R1, of links op een gevoede + rail
    function EffIn(out AVolt: Double): Boolean;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    // R1 krijgt een signaal met spanning AVolt
    procedure SetContact(AOn: Boolean; AVolt: Double);
    function ContactOut: Boolean;        // signaal op R2
    function ContactVolt: Double;        // spanning op R2
    // ligt punt P (paneelcoordinaten) bij de ingang R1 van het contact?
    function IsContactInput(const P: TPoint): Boolean;
    property ContactIn: Boolean read FContactIn write SetContactIn;
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
    // telt hoe vaak het paneel leeggemaakt werd (laden, nieuw paneel)
    FKillCount: Integer;
    templijst:TStringlist;
    FFilterLijst: TStringList;
    FSaveOnly: TList;      // bij kopiëren: alleen deze objecten bewaren
    FAppend: Boolean;      // bij plakken: het paneel niet eerst leegmaken
    FOefening: TStringList; // regels Titel/Opdracht/Verwacht/Verboden van een oefening
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
    FLogicNand, FLogicNor, FLogicXor: Boolean;  // knoppen NEN, NOF, EX-OF
    FLogicNot:Boolean;
    FDraad:Boolean;
    FRelais:Boolean;
    FSchakelRelais:Boolean;   // knop schakelrelais in de balk
    FGrid:Boolean;
    FBuzzer:Boolean;
    FMotor:Boolean;
    FTeller:Boolean;
    FMemory:Boolean;
    FStappen:Boolean;
    FFlipFlopK: Boolean;   // knop Flipflop
    FStopwatch:Boolean;
    FDipSwitsh:Boolean;
    FKnopLeft:Integer;
    FSpatie:Integer;
    FSensor:Boolean;
    FWarm:Boolean;
    FDisplay:Boolean;
    cpu:TTimer;
    Fdraden:Boolean;
    FMeter:Boolean;
    FPersoon:Boolean;
    FWagen:Boolean;
    FMuziek:Boolean;
    FVerkeer:Boolean;
    FSlagboom:Boolean;
    FVoeding:Boolean;   // knoppen + en - rail in de balk tonen
    // knoppen van de voedingskring in de balk tonen (Instellingen > Schakelelementen)
    FBronK, FZekeringK, FAmpMeterK, FWeerstandK, FLamp2K, FSchak2K, FVolt2K, FLed2K, FCondK, FWattMeterK, FPotK, FDiodeK, FWisselK, FScoopK, FTransK, FLdrK, FNtcK, FWschK, FPuls2K, FDip2K, FMagK, FBoardK, FMotorenK: Boolean;
    FSymbolen:TjanSymbolen; // tekenwijze van de poorten
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
    RLogicNand, RLogicNor, RLogicXor: TRect;
    DLogicNand, DLogicNor, DLogicXor: Boolean;

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
    RSchakel:TRect;
    DSchakel:boolean;

    bmBuzzer:Tbitmap;
    RBuzzer:TRect;
    DBuzzer:boolean;
    RMotor:TRect;
    DMotor:boolean;
    DPersoon:boolean;
    DWagen:boolean;
    DMuziek:boolean;
    DVerkeer:boolean;
    DSlagboom:boolean;

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
    RStappen:TRect;
    DStappen:boolean;
    RFlipFlop: TRect;
    DFlipFlop: Boolean;
    RStopwatch:TRect;
    DStopwatch:boolean;

    bmDisplay:TBitmap;
    RDisplay:TRect;
    DDisplay:boolean;

    bmMeter:TBitmap; //icon voor V-Meter
    RMeter:TRect;
    RPersoon:TRect;
    RWagen:TRect;
    RMuziek:TRect;
    RVerkeer:TRect;
    RSlagboom:TRect;
    DMeter:boolean;

    // voedingsrails (+ en - naast elkaar)
    RRailPlus, RRailMin: TRect;
    DRailPlus, DRailMin: Boolean;
    // voedingskring: bron (accu), zekering, milliampèremeter (bij KVoeding)
    RBron, RZekering, RAmpMeter, RWattMeter, RWeerstand: TRect;
    RLamp2, RSchak2, RVolt2: TRect;           // lamp, schakelaar, voltmeter met 2 klemmen
    RLed2, RCond, RPot, RDiode, RWissel, RScoop, RTrans, RLdr, RNtc, RWsch, RPuls2, RDip2, RMagneet, RKompas, RVeldplaat, RSpoel, RIJzer, RRelaisM, RSchommel, RMotorM, RNulmeter, RDraaiM, RTrafo, RZoemer2, RRelais2, RBoardIn, RBoardUit, RStapM, RServo, RVent, RK8055In, RK8055Uit: TRect;                      // led en condensator met 2 klemmen
    DBron, DZekering, DAmpMeter, DWattMeter, DWeerstand: Boolean;
    DLamp2, DSchak2, DVolt2: Boolean;
    DLed2, DCond, DPot, DDiode, DWissel, DScoop, DTrans, DLdr, DNtc, DWsch, DPuls2, DDip2, DMagneet, DKompas, DVeldplaat, DSpoel, DIJzer, DRelaisM, DSchommel, DMotorM, DNulmeter, DDraaiM, DTrafo, DZoemer2, DRelais2, DBoardIn, DBoardUit, DStapM, DServo, DVent, DK8055In, DK8055Uit: Boolean;
    FSupplyTimer: TTimer;   // rekent de voeding ook buiten de simulatie uit

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
    FHLogicNand, FHLogicNor, FHLogicXor: String;
    FHLogicNot:String;
    FHDraad:String;
    FHRelais:String;
    FHSchakel:String;
    FHBuzzer:String;
    FHMotor:String;
    FHSensor:String;
    FHWarm:String;
    FHLock:String;
    FHTeller:String;
    FHMemory:String;
    FHStappen:String;
    FHFlipFlop: String;
    FHStopwatch:String;
    FHDipSwitsh:String;
    FHDisplay:String;
    FBColor:TColor;
    FKnopTop:Integer;
    FHGrid:String;
    FHMeter:String;
    FHPersoon:String;
    FHWagen:String;
    FHMuziek:String;
    FHVerkeer:String;
    FHSlagboom:String;
    FHRailPlus: string;   // hint van de knop + rail
    FHRailMin: string;    // hint van de knop - rail
    FHBron, FHZekering, FHAmpMeter, FHWeerstand, FHLamp2, FHSchak2, FHVolt2, FHLed2, FHCond, FHWattMeter, FHPot, FHDiode, FHWissel, FHScoop, FHTrans, FHLdr, FHNtc, FHWsch, FHPuls2, FHDip2, FHMagneet, FHKompas, FHVeldplaat, FHSpoel, FHIJzer, FHRelaisM, FHSchommel, FHMotorM, FHNulmeter, FHDraaiM, FHTrafo, FHBoardIn, FHBoardUit, FHStapM, FHServo, FHVent, FHK8055In, FHK8055Uit: string;
    FVoedingBottom: Integer;  // onderkant van de laatste rij knoppen (PlaatsVoeding)
    FRijFix: Boolean;         // bezig met de hoogte van de balk aan te passen
    FBalkHoogte: Integer;     // hoogte van de balk boven/onder (1 of meer rijen)
    FBalkBreedte: Integer;    // breedte van de balk links/rechts (1 of meer kolommen)
    FVoedingRight: Integer;   // rechterkant van de laatste kolom knoppen (PlaatsVoeding)
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
    PROCEDURE SetHMotor(const Value: String);
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
    PROCEDURE SetLogicNand(const Value: Boolean);
    PROCEDURE SetLogicNor(const Value: Boolean);
    PROCEDURE SetLogicXor(const Value: Boolean);
    PROCEDURE SetLogicNot(const Value: Boolean);
    PROCEDURE SetDraad(const Value: Boolean);
    PROCEDURE SetRelais(const Value: Boolean);
    procedure SetSchakelRelais(const Value: Boolean);
    PROCEDURE SetNewObject(const Value: Boolean);
    PROCEDURE SetTeller(const Value: Boolean);
    PROCEDURE SetMemory(const Value: Boolean);
    PROCEDURE SetStappen(const Value: Boolean);
    PROCEDURE SetFlipFlopK(const Value: Boolean);
    PROCEDURE SetStopwatch(const Value: Boolean);
    PROCEDURE SetDipSwitsh(const Value: Boolean);
    PROCEDURE SetBuzzer(const Value: Boolean);
    PROCEDURE SetMotor(const Value: Boolean);
    PROCEDURE SetPersoon(const Value: Boolean);
    PROCEDURE SetWagen(const Value: Boolean);
    PROCEDURE SetMuziek(const Value: Boolean);
    PROCEDURE SetVerkeer(const Value: Boolean);
    PROCEDURE SetSlagboom(const Value: Boolean);
    PROCEDURE SetSensor(const Value: Boolean);
    PROCEDURE SetWarm(const Value: Boolean);
    PROCEDURE SetDisplay(const Value: Boolean);
    PROCEDURE SetMeter(const Value: Boolean);
    procedure SetVoeding(const Value: Boolean);
    procedure SetVoedingKnop(var F: Boolean; const Value: Boolean);
    procedure SetKBron(const Value: Boolean);
    procedure SetKZekering(const Value: Boolean);
    procedure SetKAmpMeter(const Value: Boolean);
    procedure SetKWattMeter(const Value: Boolean);
    procedure SetKWeerstand(const Value: Boolean);
    procedure SetKLamp2(const Value: Boolean);
    procedure SetKSchakelaar2(const Value: Boolean);
    procedure SetKWisselschakelaar(const Value: Boolean);
    procedure SetKPuls2(const Value: Boolean);
    procedure SetKDip2(const Value: Boolean);
    procedure SetKMagnetisme(const Value: Boolean);
    procedure SetKBoard(const Value: Boolean);
    procedure SetKMotoren(const Value: Boolean);
    procedure SetKVoltmeter2(const Value: Boolean);
    procedure SetKLed2(const Value: Boolean);
    procedure SetKCondensator(const Value: Boolean);
    procedure SetKPotmeter(const Value: Boolean);
    procedure SetKDiode(const Value: Boolean);
    procedure SetKWisselbron(const Value: Boolean);
    procedure SetKScoop(const Value: Boolean);
    procedure SetKTransistor(const Value: Boolean);
    procedure SetKLDR(const Value: Boolean);
    procedure SetKNTC(const Value: Boolean);
    procedure PlaatsVoeding(LK, TOP, H, SPATIE: Integer; Vertikaal: Boolean;
      MaxX: Integer = 0; StartX: Integer = 0);
    procedure SetSymbolen(const Value: TjanSymbolen);
    procedure DrawGateIcon(AFunc: TjanLogicFunc; Bm: TBitmap; X, Y: Integer);
    procedure DrawInputIcon(Kind: Integer; Bm: TBitmap; X, Y: Integer);
    procedure DrawPlainIcon(Bm: TBitmap; BL, BT, X, Y: Integer);
    procedure DrawOutputIcon(Kind: Integer; Bm: TBitmap; X, Y: Integer);
    PROCEDURE SetKnopLeft(const Value: Integer);
    PROCEDURE SetKnopTop(const Value: Integer);
    PROCEDURE SetKnopSpatie(const Value: Integer);
    PROCEDURE SetImputColor(const Value:TColor);
    PROCEDURE SetOutputColor(const Value:TColor);
    PROCEDURE SetVerwerkingColor(const Value:TColor);
    PROCEDURE cpuOnTimer(sender:TObject);
    procedure SupplyOnTimer(Sender: TObject);
    procedure DrawVoedingButton(const R: TRect; AKind: Integer; ADown: Boolean);
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
    procedure HertekenLater(Data: PtrInt);
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
    procedure DrawRailButton(const R: TRect; APlus, ADown: Boolean);
    procedure DrawHalfKnop(const R: TRect; ADown: Boolean; Kind: Integer);
    procedure DrawStappenIcon(X, Y: Integer);
    procedure DrawFlipFlopIcon(X, Y: Integer);
    procedure DrawStopwatchIcon(X, Y: Integer);
    // tekent de balk boven, onder, links of rechts (met overloop)
    PROCEDURE PaintBoxTop;
    // kontrole of er connectors zijn gemaakt
    PROCEDURE MoveObjekten(hoeveel:Integer);
    PROCEDURE kontrolconnectors;
    PROCEDURE maakpanel;
    PROCEDURE Zettaal;
    PROCEDURE BlokkeerObjecten(blokkeer:Boolean);
    // de simulatieklok starten (gebeurt anders alleen bij het laden uit een .lfm,
    // zie Loaded); voor programma's die de box zelf aanmaken, zoals de viewer
    procedure StartKlok;
    PROCEDURE Killpanel;
    PROCEDURE KillConnectors;
    PROCEDURE SavePanelTemp(Paneel:TjanGridS);

    procedure ClearSelectedSender;

    procedure InternalLoadFromList(AList: TStrings; Paneel: TjanGridS);
    PROCEDURE SavePanel(waar:String; paneel:TjanGridS; codec:Boolean);
    // De inhoud van het paneel als regels (zelfde als een .lpl-bestand), en
    // zo'n tekst weer laden. Gebruikt voor ongedaan maken / opnieuw.
    procedure SavePanelToList(SFile: TStrings; Paneel: TjanGridS);
    // Kopiëren en plakken: alleen de objecten in Only bewaren (zonder de
    // paneelinstellingen), en zo'n lijst bij het paneel voegen, DX/DY
    // verschoven. Nieuw krijgt de geplakte objecten.
    procedure SaveSelectionToList(SFile: TStrings; Paneel: TjanGridS; Only: TList);
    // AtPos: DX,DY is de plaats (linksboven) waar het stuk moet komen,
    // anders een verschuiving
    procedure AddFromList(AList: TStrings; Paneel: TjanGridS; DX, DY: Integer; Nieuw: TList;
      AtPos: Boolean = False);
    // Panelen bewaren de plaatsen zoals bij de balk links. Staat de balk
    // boven of onder, dan schuift alles bij het laden met LayoutShift op
    // (en bij het bewaren even terug).
    function LayoutShift: TPoint;
    procedure ShiftPanelObjects(DX, DY: Integer);
    // het onderdeel dat nog aan de muis hangt (gekozen in de balk, nog niet op
    // het paneel gezet) weghalen
    procedure AnnuleerNieuwObject;
    function PanelText(Paneel: TjanGridS): string;
    procedure LoadPanelText(const AText: string; Paneel: TjanGridS);
    // Waarheidstabel: zet de schakelaars en drukknoppen (Ins, van boven naar
    // onder) in elke stand en leest de lampen en zoemers (Outs). Elke rij in
    // Rijen is een reeks '0'/'1': eerst de ingangen, dan de uitgangen.
    // Resultaat: 0 = goed, 1 = geen ingangen, 2 = geen uitgangen,
    // 3 = te veel ingangen (meer dan MaxIn). Geheugen wordt True als er
    // onderdelen met een geheugen op het paneel staan (flipflop, teller ...).
    function Waarheidstabel(Ins, Outs: TList; Rijen: TStrings;
      out Geheugen: Boolean; MaxIn: Integer = 6): Integer;
    // De vorm van het paneel: welke onderdelen en draden er staan en waar,
    // zonder de stand van de schakelaars. Verandert de vorm, dan moet de
    // waarheidstabel opnieuw berekend worden.
    function Paneelvorm: string;
    // Hulp voor de waarheidstabel: is C een ingang (schakelaar, drukknop,
    // dipswitch, lichtsensor, warmtesensor) of een uitgang (lamp, LED,
    // zoemer, relais, schakelrelais, motor, display)?
    class function IsInvoer(C: TControl): Boolean;
    class function IsUitvoer(C: TControl): Boolean;
    class function InvoerAan(C: TControl): Boolean;
    class procedure ZetInvoer(C: TControl; V: Boolean);
    // '0' of '1'; een motor geeft 'L', 'R' of '0', een display zijn cijfer
    class function UitvoerTeken(C: TControl): Char;
    // Oefening: de regels Titel;taal;tekst  Opdracht;taal;tekst
    // Verwacht;ingangen;uitgangen;rij;rij;...  Verboden;code;code;...
    // uit het paneelbestand (leeg = geen oefening). Ze worden mee bewaard.
    property Oefening: TStringList read FOefening;
    // hoeveel poorten met deze code (EN, OF, NIET, NEN, NOF, EXOF) staan er?
    function TelPoort(const Code: string): Integer;
    // het woord voor die poort in de taal BTaal (EN / AND / ET / UND ...)
    class function PoortWoord(const Code, BTaal: string): string;
    // telt hoe vaak het paneel leeggemaakt werd (laden, nieuw paneel)
    property KillCount: Integer read FKillCount;
    // Samenvatting van de inhoud van het paneel (objecten, draden en de
    // paneelinstellingen die SavePanel bewaart), los van de volgorde.
    // Verschilt ze van een eerdere samenvatting, dan is het paneel gewijzigd.
    function PanelSignature(Paneel: TjanGridS): string;

    // ophalen van paneel uit tempFile
    PROCEDURE LoadPanelTemp(Paneel:TjanGridS);
    // ophalen van opgeslagen Paneel uit bestand
    PROCEDURE LoadPanel(welke:String;Paneel:TjanGridS;codec:Boolean);
    // voedingsrail op het paneel zetten (laden)
    function AddRail(ALeft, ATop, AHeight: Integer; APlus: Boolean; AVolt: Double): TjanRail;
    // nieuwe rail aan de muis hangen om te plaatsen (zoals een component uit de balk)
    procedure NewRail(APlus: Boolean);
    procedure NewVoedingsDeel(AKind: Integer);   // 0 = bron, 1 = zekering, 2 = mA-meter
    procedure SetupVoedingsDeel(D: TjanVoedingsDeel);
    // oud paneel met rails maar zonder bron: een bron met draden toevoegen
    procedure EnsureBron;
    // nieuw LogicRun-blok aan de muis hangen (alleen als er nog geen is)
    procedure NewLogicRun;
    // nieuwe persoon (met vloer en eindschakelaars) aan de muis hangen
    procedure NewPersoon;
    procedure NewWagen;
    procedure NewMuziek;
    procedure NewPersoonVan(AKlasse: TComponentClass);
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
    property KLogicNand:Boolean read FLogicNand write SetLogicNand;
    property KLogicNor:Boolean read FLogicNor write SetLogicNor;
    property KLogicXor:Boolean read FLogicXor write SetLogicXor;
    property KLogicNot:Boolean read FLogicNot write SetLogicNot;
    property KDraad:Boolean read FDraad write SetDraad;
    property KRelais:Boolean read Frelais write Setrelais;
    property KSchakelRelais:Boolean read FSchakelRelais write SetSchakelRelais;
    property KGrid:Boolean read FGrid write SetGrid;
    property KBuzzer:Boolean read FBuzzer write SetBuzzer;
    property KMotor:Boolean read FMotor write SetMotor default True;
    property KSensor:Boolean read FSensor write SetSensor;
    property KWarm:Boolean read FWarm write SetWarm;
    property KTeller:Boolean read FTeller write SetTeller;
    property KMemory:Boolean read FMemory write SetMemory;
    property KStappen:Boolean read FStappen write SetStappen default True;
    property KFlipFlop: Boolean read FFlipFlopK write SetFlipFlopK default True;
    property KStopwatch:Boolean read FStopwatch write SetStopwatch default True;
    property KDipSwitsh:Boolean read FDipSwitsh write SetDipSwitsh;
    property KDisplay:Boolean read FDisplay write SetDisplay;
    property KMeter:Boolean read FMeter write SetMeter;
    property KPersoon:Boolean read FPersoon write SetPersoon default True;
    property KWagen:Boolean read FWagen write SetWagen default True;
    property KMuziek:Boolean read FMuziek write SetMuziek default True;
    property KVerkeer:Boolean read FVerkeer write SetVerkeer default True;
    property KSlagboom:Boolean read FSlagboom write SetSlagboom default True;
    // knoppen voor de voedingsrails (+ en -) in de balk tonen
    property KVoeding: Boolean read FVoeding write SetVoeding default True;
    // knoppen van de voedingskring
    property KBron: Boolean read FBronK write SetKBron default True;
    property KZekering: Boolean read FZekeringK write SetKZekering default True;
    property KAmpMeter: Boolean read FAmpMeterK write SetKAmpMeter default True;
    property KWattMeter: Boolean read FWattMeterK write SetKWattMeter default True;
    property KWeerstand: Boolean read FWeerstandK write SetKWeerstand default True;
    property KLamp2: Boolean read FLamp2K write SetKLamp2 default True;
    property KSchakelaar2: Boolean read FSchak2K write SetKSchakelaar2 default True;
    property KWisselschakelaar: Boolean read FWschK write SetKWisselschakelaar default True;
    property KPuls2: Boolean read FPuls2K write SetKPuls2 default True;
    property KDip2: Boolean read FDip2K write SetKDip2 default True;
    property KMagnetisme: Boolean read FMagK write SetKMagnetisme default True;
    // de twee knoppen van het Arduino-board (ingang en uitgang)
    property KBoard: Boolean read FBoardK write SetKBoard default True;
    // stappenmotor, servomotor en ventilator
    property KMotoren: Boolean read FMotorenK write SetKMotoren default True;
    property KVoltmeter2: Boolean read FVolt2K write SetKVoltmeter2 default True;
    property KLed2: Boolean read FLed2K write SetKLed2 default True;
    property KCondensator: Boolean read FCondK write SetKCondensator default True;
    property KPotmeter: Boolean read FPotK write SetKPotmeter default True;
    property KDiode: Boolean read FDiodeK write SetKDiode default True;
    property KWisselbron: Boolean read FWisselK write SetKWisselbron default True;
    property KScoop: Boolean read FScoopK write SetKScoop default True;
    property KTransistor: Boolean read FTransK write SetKTransistor default True;
    property KLDR: Boolean read FLdrK write SetKLDR default True;
    property KNTC: Boolean read FNtcK write SetKNTC default True;
    // symbolen van de EN-, OF- en NIET-poort (paneel en knoppenbalk)
    // Afbeelding (plaatjes) bestaat niet meer: wordt IEC (oude instellingen)
    property KSymbolen: TjanSymbolen read FSymbolen write SetSymbolen default IEC;
    property PStandaard:Boolean read FStart write SetStart;
    property NewObject:Boolean read FNew write SetNewObject stored False;   // tijdelijke toestand: nooit in een formulier bewaren
    property HDrukknop:String read FHDrukknop write SetHDrukknop;

    property HSchakelaar:String read FHSchakelaar write SetHSchakelaar;
    property HGrid:String read FHGrid write SetHgrid;
    property HMeter:String read FHMeter write SetHMeter;
    property HRailPlus: string read FHRailPlus write FHRailPlus;
    property HRailMin: string read FHRailMin write FHRailMin;
    property HBron: string read FHBron write FHBron;
    property HZekering: string read FHZekering write FHZekering;
    property HAmpMeter: string read FHAmpMeter write FHAmpMeter;
    property HWattMeter: string read FHWattMeter write FHWattMeter;
    property HWeerstand: string read FHWeerstand write FHWeerstand;
    property HLamp2: string read FHLamp2 write FHLamp2;
    property HSchakelaar2: string read FHSchak2 write FHSchak2;
    property HWisselschakelaar: string read FHWsch write FHWsch;
    property HPuls2: string read FHPuls2 write FHPuls2;
    property HDip2: string read FHDip2 write FHDip2;
    property HMagneet: string read FHMagneet write FHMagneet;
    property HKompas: string read FHKompas write FHKompas;
    property HVeldplaat: string read FHVeldplaat write FHVeldplaat;
    property HSpoel: string read FHSpoel write FHSpoel;
    property HIJzer: string read FHIJzer write FHIJzer;
    property HRelaisModel: string read FHRelaisM write FHRelaisM;
    property HSchommel: string read FHSchommel write FHSchommel;
    property HElektromotor: string read FHMotorM write FHMotorM;
    property HNulmeter: string read FHNulmeter write FHNulmeter;
    property HDraaimagneet: string read FHDraaiM write FHDraaiM;
    property HTransformator: string read FHTrafo write FHTrafo;
    property HStappenmotor: string read FHStapM write FHStapM;
    property HServo: string read FHServo write FHServo;
    property HVentilator: string read FHVent write FHVent;
    property HBoardIn: string read FHBoardIn write FHBoardIn;
    property HBoardUit: string read FHBoardUit write FHBoardUit;
    property HK8055In: string read FHK8055In write FHK8055In;
    property HK8055Uit: string read FHK8055Uit write FHK8055Uit;
    property HVoltmeter2: string read FHVolt2 write FHVolt2;
    property HLed2: string read FHLed2 write FHLed2;
    property HCondensator: string read FHCond write FHCond;
    property HPotmeter: string read FHPot write FHPot;
    property HDiode: string read FHDiode write FHDiode;
    property HWisselbron: string read FHWissel write FHWissel;
    property HScoop: string read FHScoop write FHScoop;
    property HTransistor: string read FHTrans write FHTrans;
    property HLDR: string read FHLdr write FHLdr;
    property HNTC: string read FHNtc write FHNtc;
    property HPuls:String read FHPuls write SetHPuls;
    property HLamp:String read FHLamp write SetHLamp;
    property HLogicAnd:String read FHLogicAnd write SetHLogicAnd;
    property HLogicOr:String read FHLogicOr write SetHLogicOr;
    property HLogicNand:String read FHLogicNand write FHLogicNand;
    property HLogicNor:String read FHLogicNor write FHLogicNor;
    property HLogicXor:String read FHLogicXor write FHLogicXor;
    property HLogicNot:String read FHLogicNot write SetHLogicNot;
    property HDraad:String read FHDraad write SetHDraad;
    property HRelais:String read FHrelais write SetHrelais;
    property HSchakelRelais: string read FHSchakel write FHSchakel;
    property HBuzzer:String read FHBuzzer write SetHBuzzer;
    property HMotor:String read FHMotor write SetHMotor;
    property HPersoon:String read FHPersoon write FHPersoon;
    property HWagen:String read FHWagen write FHWagen;
    property HMuziek:String read FHMuziek write FHMuziek;
    property HVerkeer:String read FHVerkeer write FHVerkeer;
    property HSlagboom:String read FHSlagboom write FHSlagboom;
    property HWarm:String read FHWarm write SetHWarm;
    property HSensor:String read FHSensor write SetHSensor;
    property HLock:String read FHLock write SetHlock;
    property HTeller:String read FHTeller write SetHTeller;
    property HMemory:String read FHMemory write SetHMemory;
    property HStappen:String read FHStappen write FHStappen;
    property HFlipFlop: String read FHFlipFlop write FHFlipFlop;
    property HStopwatch:String read FHStopwatch write FHStopwatch;
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

  { TjanSimMotor: motor met twee ingangen, L (linksom) en R (rechtsom). De
    rotor draait zichtbaar zolang precies één ingang aan is; staan ze allebei
    aan, dan draait hij niet en toont hij een rood uitroepteken (in het echt
    kortsluiting). Voeding zoals andere uitvoer: rechts op een - rail. }
  TjanSimMotor = class(TGraphicControl)
  private
    FIn: array[0..1] of Boolean;   // 0 = L (linksom), 1 = R (rechtsom)
    FAngle: Integer;               // stand van de rotor in graden
    FTimer: TTimer;
    FLock: Boolean;
    FSelected: Boolean;
    FSelect: Boolean;
    FMouseOver: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FNaam: string;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStatus: TSimStatusEvent;
    Connectors: TList;
    doMove: Boolean;
    mdp: TPoint;
    newLeft, newTop: Integer;
    function GetInput(I: Integer): Boolean;
    procedure SetTaal(const Value: string);
    procedure TimerTick(Sender: TObject);
    procedure UpdateTimer;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SendStatusToBar;
    function StatusText: string;
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure BuildPopup;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText;
    // ingang 0 (L) of 1 (R) aan/uit, door de draden (Connect)
    procedure SetInput(I: Integer; Value: Boolean);
    // index van de ingang bij punt P (paneel), anders -1
    function InputPinAt(const P: TPoint): Integer;
    // Y van het aansluitvierkantje (7x7) van ingang I binnen het blok
    class function InputPinY(I: Integer): Integer;
    // -1 linksom, 1 rechtsom, 0 stil (ook als L en R samen aan zijn)
    function Direction: Integer;
    function Fault: Boolean;       // L en R tegelijk aan
    property Inputs[I: Integer]: Boolean read GetInput;
    property Angle: Integer read FAngle;
  published
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property Naam: string read FNaam write FNaam;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanSimPersoon: een persoon die over een vloer heen en weer loopt.
    Ingangen L (naar links) en R (naar rechts), links op het blok; staan ze
    allebei aan, dan blijft hij staan en toont hij een rood uitroepteken. Aan
    beide uiteinden staat een eindschakelaar: S1 is aan als hij links staat,
    S2 als hij rechts staat. Die standen lees je met TjanSimEindschakelaar in
    de invoer (bv. naar een ingang van LogicRun). Uitvoer: op een paneel met
    rails hangt hij aan de - rail. }
  TjanSimPersoon = class(TGraphicControl)
  private
    FIn: array[0..7] of Boolean;   // 0 = L (naar links), 1 = R (naar rechts); muziekdoos: 8 noten
    FPos: Integer;                 // afstand vanaf de linker eindschakelaar (px)
    FFrame: Integer;               // stand van de benen tijdens het lopen
    FKijk: Integer;                // -1 kijkt naar links, 1 naar rechts
    FUitMask: Integer;             // standen (S1, S2...) als bits, bij de laatste melding
    FTimer: TTimer;
    FLock: Boolean;
    FSelected: Boolean;
    FSelect: Boolean;
    FMouseOver: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FNaam: string;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStatus: TSimStatusEvent;
    Connectors: TList;
    doMove: Boolean;
    mdp: TPoint;
    newLeft, newTop: Integer;
    function GetInput(I: Integer): Boolean;
    function GetOutput(I: Integer): Boolean; virtual;
    function Range: Integer; virtual;
    procedure SetTaal(const Value: string);
    procedure TimerTick(Sender: TObject);
    procedure UpdateTimer;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SendStatusToBar;
    function StatusText: string; virtual;
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure EindClick(Sender: TObject);
    procedure MeldEindschakelaars;
    procedure BuildPopup; virtual;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText; virtual;
    // ingang 0 (L) of 1 (R) aan/uit, door de draden (Connect)
    procedure SetInput(I: Integer; Value: Boolean); virtual;
    // aantal ingangen (2; 8 bij de muziekdoos) en de Y van ingang I in het blok
    function InputCount: Integer; virtual;
    function InPinY(I: Integer): Integer; virtual;
    // index van de ingang/uitgang bij punt P (paneel), anders -1
    function InputPinAt(const P: TPoint): Integer;
    // aantal standen voor eindschakelaars: 2 bij de persoon, 3 bij het wagentje
    function OutputCount: Integer; virtual;
    function OutputName(I: Integer): string; virtual;
    // bij een pulsstand (Tel van het wagentje): hoeveel pulsen er al waren, anders -1
    function PulsTeller(I: Integer): Integer; virtual;
    // voor elke stand een eindschakelaar links in de invoer zetten
    procedure PlaatsEindschakelaars;
    // Y van het aansluitvierkantje (7x7) van ingang/uitgang I binnen het blok
    class function PinY(I: Integer): Integer;
    // -1 naar links, 1 naar rechts, 0 stil (ook als L en R samen aan zijn)
    function Direction: Integer; virtual;
    function Fault: Boolean;       // L en R tegelijk aan
    // terug naar de linker eindschakelaar
    procedure ToStart;
    // een stap verder (zoals de timer); voor testen
    procedure Tick; virtual;
    property Inputs[I: Integer]: Boolean read GetInput;
    property Outputs[I: Integer]: Boolean read GetOutput;   // 0 = S1, 1 = S2
    property Position: Integer read FPos;
  published
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property Naam: string read FNaam write FNaam;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanSimWagen: een wagentje (bovenaanzicht) dat over een kronkelweg rijdt,
    van START naar FINISH. Ingangen V (vooruit) en A (achteruit) links.
    Eindschakelaars (TjanSimEindschakelaar, in de invoer) lezen Start (staat
    aan de start), Tel (een puls bij elk van de 5 paaltjes langs de weg) en
    Finish (staat aan de finish). Met "N x DIN" in LogicRun rijdt het tot het
    N-de paaltje. Alles wat met draden, bewaren en de balk te maken heeft,
    erft het van TjanSimPersoon. }
  TjanSimPersoonClass = class of TjanSimPersoon;

  TjanSimWagen = class(TjanSimPersoon)
  private
    FTelTeller: Integer;           // aantal keer dat hij bij een paaltje aankwam
    FOpPaaltje: Boolean;
    function GetOutput(I: Integer): Boolean; override;
    function Range: Integer; override;
    function StatusText: string; override;
    function PointAt(D: Integer; out Dx, Dy: Integer): TPoint;
    function PaaltjeBij: Integer;    // nummer (1..5) van het paaltje waar hij staat, anders 0
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    function OutputCount: Integer; override;
    function OutputName(I: Integer): string; override;
    function PulsTeller(I: Integer): Integer; override;
    // 1 vooruit (naar de finish), -1 achteruit, 0 stil
    function Direction: Integer; override;
    procedure Tick; override;
    // afstand langs de weg van paaltje N (1..5)
    class function PaaltjePos(N: Integer): Integer;
  end;

  { TjanSimMuziek: muziekdoos, een klavier met 8 witte toetsen (do re mi fa
    sol la si do'). De ingangen zitten links, op dezelfde hoogte als UIT0..UIT7
    van LogicRun: staat een ingang aan, dan licht de toets op en klinkt de
    noot zolang hij aan is (meer ingangen samen: een akkoord). Een melodie is
    een LogicRun-programma: een stap per noot, de staptijd is de lengte. Twee
    keer na elkaar dezelfde noot: er een korte rust (stap zonder uitgangen)
    tussen zetten. Uitvoer: aan de - rail. Draden, bewaren en de balk erft hij
    van TjanSimPersoon. }
  TjanSimMuziek = class(TjanSimPersoon)
  private
    FGeluid: Boolean;
    FSpeelt: Integer;              // noten (bits) die nu klinken
    FKlankTimer: TTimer;
    function StatusText: string; override;
    procedure BuildPopup; override;
    procedure GeluidClick(Sender: TObject);
    procedure KlankTick(Sender: TObject);
    procedure Klink;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    procedure SetInput(I: Integer; Value: Boolean); override;
    function InputCount: Integer; override;
    function InPinY(I: Integer): Integer; override;
    function OutputCount: Integer; override;
    function Direction: Integer; override;
    // de ingangen die aan zijn, als bits (bit 0 = do)
    function Noten: Integer;
    // naam van noot I: do re mi (in alle talen) en de letter C D E
    function NootNaam(I: Integer): string;
    function NootLetter(I: Integer): string;
    // geluid aan (standaard) of alleen de toetsen laten oplichten
    property Geluid: Boolean read FGeluid write FGeluid;
  end;

  { TjanSimVerkeerslicht: verkeerslicht voor auto's (rood, oranje, groen) en
    een voetgangerslicht (rood mannetje, groen mannetje). Vijf ingangen links,
    op dezelfde hoogte als UIT0..UIT4 van LogicRun: R, O, G, VR en VG. Staan
    groen voor de auto's en groen voor de voetgangers samen aan, dan toont
    hij een rood uitroepteken (gevaarlijk). Uitvoer: aan de - rail. Draden,
    bewaren en de balk erft hij van TjanSimPersoon. }
  TjanSimVerkeerslicht = class(TjanSimPersoon)
  private
    function StatusText: string; override;
    procedure BuildPopup; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    function InputCount: Integer; override;
    function InPinY(I: Integer): Integer; override;
    function OutputCount: Integer; override;
    function Direction: Integer; override;
    // groen voor de auto's en voor de voetgangers tegelijk
    function Gevaar: Boolean;
  end;

  { TjanSimSlagboom: slagboom van een parking. Eén ingang O links: aan = de
    boom gaat open (omhoog), uit = de boom gaat dicht. Twee standen voor
    eindschakelaars: Dicht en Open. Zo kan een geheugenblok en een stopwatch
    de boom na een tijd weer laten sluiten. Draden, bewaren en de balk erft
    hij van TjanSimPersoon. }
  TjanSimSlagboom = class(TjanSimPersoon)
  private
    function Range: Integer; override;
    function StatusText: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    function InputCount: Integer; override;
    function OutputName(I: Integer): string; override;
    // 1 omhoog, -1 omlaag, 0 als hij helemaal open of dicht staat
    function Direction: Integer; override;
    procedure Tick; override;
  end;

  { TjanSimEindschakelaar: eindschakelaar in de invoer. Hij volgt zonder
    draad een uitgang van de persoon of het wagentje op het paneel (Kanaal:
    S1/S2 of Start/Tel/Finish) en zet die rechts op zijn uitgang, naar een
    DIN van LogicRun. Zoals bij een PLC: de machine staat in de uitvoer, haar
    eindschakelaars zijn ingangen. Op een paneel met rails hangt hij aan de
    + rail (ingeplugd of met een voedingsdraad). }
  TjanSimEindschakelaar = class(TGraphicControl)
  private
    FKanaal: Integer;
    FGetekend: Boolean;            // stand bij de laatste keer tekenen
    FRonde: Cardinal;              // simulatieronde van de laatste SimUitgang
    FGezien: Integer;              // pulsen die al op de uitgang gezet zijn (-1: nog niet)
    FUit: Boolean;                 // uitgang in deze simulatieronde
    FTimer: TTimer;
    FLock: Boolean;
    FSelected: Boolean;
    FSelect: Boolean;
    FMouseOver: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FNaam: string;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStatus: TSimStatusEvent;
    Connectors: TList;
    doMove: Boolean;
    mdp: TPoint;
    newLeft, newTop: Integer;
    procedure SetTaal(const Value: string);
    procedure SetKanaal(Value: Integer);
    procedure TimerTick(Sender: TObject);
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SendStatusToBar;
    function StatusText: string;
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure KanaalClick(Sender: TObject);
    procedure BuildPopup;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText;
    // de persoon of het wagentje op hetzelfde paneel (de eerste), anders nil
    function Bron: TjanSimPersoon;
    function KanaalNaam: string;
    // de gevolgde uitgang staat aan (zonder rekening te houden met de rail)
    function Aan: Boolean;
    // wat de draad in deze simulatieronde krijgt: bij Tel elke puls minstens
    // een ronde aan en daarna een ronde uit, zodat LogicRun er geen mist
    function SimUitgang: Boolean;
    // ligt P (paneel) op de uitgang rechts?
    function OutputPinAt(const P: TPoint): Boolean;
    // Y van het aansluitvierkantje (7x7) van de uitgang binnen het blok
    class function PinY: Integer;
    property Getekend: Boolean read FGetekend;   // stand bij de laatste keer tekenen
  published
    property Kanaal: Integer read FKanaal write SetKanaal;
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property Naam: string read FNaam write FNaam;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanSimStappenteller: decimale teller met een display van 4 cijfers.
    Links de ingangen T (elke puls +1) en R (terug naar 0; gaat voor T),
    rechts de uitgang Q: aan zolang de eindwaarde bereikt is. Bij de
    eindwaarde blijft de teller staan, of (Herhalen) begint hij bij de
    volgende puls weer bij 1. Verwerking: geen voeding nodig. }
  TjanSimStappenteller = class(TGraphicControl)
  private
    FIn: array[0..1] of Boolean;   // 0 = T (tellen), 1 = R (reset)
    FStand: Integer;
    FEind: Integer;
    FHerhalen: Boolean;
    FResetRonde: Cardinal;         // simulatieronde waarin R laatst aan ging
    FLock: Boolean;
    FSelected: Boolean;
    FSelect: Boolean;
    FMouseOver: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FNaam: string;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStatus: TSimStatusEvent;
    Connectors: TList;
    doMove: Boolean;
    mdp: TPoint;
    newLeft, newTop: Integer;
    procedure SetTaal(const Value: string);
    procedure SetEind(Value: Integer);
    procedure SetHerhalen(Value: Boolean);
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SendStatusToBar;
    function StatusText: string; virtual;
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure EindClick(Sender: TObject);
    procedure EindAnderClick(Sender: TObject);
    procedure HerhalenClick(Sender: TObject);
    procedure NulClick(Sender: TObject);
    procedure BuildPopup; virtual;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText; virtual;
    // ingang 0 (T) of 1 (R) aan/uit, door de draden (Connect)
    procedure SetInput(I: Integer; Value: Boolean); virtual;
    // index van de ingang bij punt P (paneel), anders -1
    function InputPinAt(const P: TPoint): Integer; virtual;
    // ligt P (paneel) op de uitgang Q rechts?
    function OutputPinAt(const P: TPoint): Boolean; virtual;
    // waarde van de uitgang bij punt P (paneel); False = daar geen uitgang
    function OutValueAt(const P: TPoint; out V: Boolean): Boolean; virtual;
    // Y (in het blok) van het aansluitvierkantje van de uitgang bij P, of -1
    function OutPinYAt(const P: TPoint): Integer; virtual;
    // Y van het aansluitvierkantje (7x7) van ingang I, en van de uitgang
    class function InputPinY(I: Integer): Integer;
    class function OutputPinY: Integer;
    function Bereikt: Boolean; virtual;     // uitgang Q
    property Stand: Integer read FStand;
  published
    property Eindwaarde: Integer read FEind write SetEind default 1000;
    property Herhalen: Boolean read FHerhalen write SetHerhalen default False;
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property Naam: string read FNaam write FNaam;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanSimStopwatch: stopwatch met een display MM:SS. Links de ingangen
    S (de tijd loopt zolang S aan is) en R (terug naar 00:00; gaat voor S),
    rechts de uitgang Q: aan als de eindtijd bereikt is. Bij de eindtijd
    blijft hij staan, of (Herhalen) begint hij weer bij 00:01. De eindtijd
    (Eindwaarde) is in seconden. Alles wat met draden, bewaren en de balk
    te maken heeft, erft hij van de stappenteller. }
  TjanSimStopwatch = class(TjanSimStappenteller)
  private
    FMs: Int64;                    // verstreken tijd in milliseconden
    FLaatst: QWord;                // GetTickCount64 van de vorige tik
    FTimer: TTimer;
    procedure TimerTick(Sender: TObject);
    procedure EindTijdClick(Sender: TObject);
    procedure EindTijdAnderClick(Sender: TObject);
    procedure NulTijdClick(Sender: TObject);
    function StatusText: string; override;
    procedure BuildPopup; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    procedure SetInput(I: Integer; Value: Boolean); override;
  end;

  { TjanSimFlipFlop: flipflop (geheugen van 1 bit), soort SR, D, JK of T
    (rechtsklik). Links de ingangen, rechts de uitgangen Q (boven) en niet-Q
    (onder).
      SR: S zet Q op 1, R zet Q op 0; S en R samen (verboden): R gaat voor.
      D : bij het aangaan van de klok C neemt Q de waarde van D over.
      JK: bij het aangaan van C: J=K=0 houden, J=1 zetten, K=1 wissen,
          J=K=1 omschakelen.
      T : elke keer dat T aangaat, wisselt Q.
    Erft draden, bewaren, vergrendelen en de balk van de stappenteller; de
    soort staat in Eindwaarde (1 = SR, 2 = D, 3 = JK, 4 = T). }
  TjanFlipFlopSoort = (ffSR, ffD, ffJK, ffT);
  TjanSimFlipFlop = class(TjanSimStappenteller)
  private
    FQ: Boolean;
    FIn3: array[0..2] of Boolean; // ingangen (tot 3)
    FStartRonde: Cardinal;        // simulatieronde bij het maken of laden
    function GetSoort: TjanFlipFlopSoort;
    procedure SetSoort(Value: TjanFlipFlopSoort);
    procedure SoortClick(Sender: TObject);
    procedure NulQClick(Sender: TObject);
    function StatusText: string; override;
    procedure BuildPopup; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    procedure SetInput(I: Integer; Value: Boolean); override;
    function InputPinAt(const P: TPoint): Integer; override;
    function OutputPinAt(const P: TPoint): Boolean; override;
    function OutValueAt(const P: TPoint; out V: Boolean): Boolean; override;
    function OutPinYAt(const P: TPoint): Integer; override;
    function Bereikt: Boolean; override;      // = Q
    function InputCount: Integer;
    function InPinY(I: Integer): Integer;     // Y van ingang I in het blok
    function InLabel(I: Integer): string;     // S, R, D, C, J, K, T
    class function QPinY(I: Integer): Integer; // 0 = Q, 1 = niet-Q
    property Q: Boolean read FQ;
    property Soort: TjanFlipFlopSoort read GetSoort write SetSoort;
  end;

  { TjanLogicRun: programmeermodule met een stappenprogramma (LogicRun).
    Links 4 ingangen (DIN1-DIN4), rechts 8 uitgangen (UIT0-UIT7). Elke stap
    zet een bitpatroon op de uitgangen en duurt Tijd x StapDuur ms. Een
    ingang kan het programma starten/stoppen, op stap 0 zetten of een stap
    verder zetten (bij het aanzetten). Er staat er hoogstens één op een
    paneel; het programma wordt bewerkt in het LogicRun-venster. }
  // lrdStartStop wisselt bij elk aanzetten (drukknop); lrdAanUit loopt zolang
  // de ingang aan is en stopt als hij uit gaat (schakelaar)
  TLogicRunDin = (lrdGeen, lrdStartStop, lrdReset, lrdStap, lrdAanUit);
  // voorwaarde van een stap: geen (de stap duurt Tijd x StapDuur), wachten tot
  // een ingang aan of uit is, of tot er N pulsen op een ingang geweest zijn
  TLogicRunWacht = (lrwGeen, lrwAan, lrwUit, lrwPulsen);
  TLogicRunStep = record
    Bits: Byte;      // bit i = uitgang UITi
    Tijd: Integer;   // aantal keer de stapduur (als Wacht = lrwGeen)
    Wacht: TLogicRunWacht;
    WachtDin: Integer;   // 0..3 = DIN1..DIN4
    WachtN: Integer;     // aantal pulsen (lrwPulsen)
  end;

  TjanLogicRun = class(TGraphicControl)
  private
    FSteps: array of TLogicRunStep;
    FStapDuur: Integer;
    FHerhalen: Boolean;
    FDin: array[0..3] of TLogicRunDin;
    FIn: array[0..3] of Boolean;
    FStep: Integer;            // huidige stap, -1 = gestopt (uitgangen uit)
    FCount: Integer;           // tikken in de huidige stap
    FPulses: Integer;          // pulsen in de huidige stap (voorwaarde lrwPulsen)
    FRunning: Boolean;
    FTimer: TTimer;
    FLock: Boolean;
    FSelected: Boolean;
    FSelect: Boolean;          // muis erboven: dikkere rand
    FMouseOver: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FNaam: string;
    FOnEnter: TNotifyEvent;
    FOnExit: TNotifyEvent;
    FOnStatus: TSimStatusEvent;
    FOnChange: TNotifyEvent;
    Connectors: TList;
    doMove: Boolean;
    mdp: TPoint;
    newLeft, newTop: Integer;
    function GetStepCount: Integer;
    function GetStep(I: Integer): TLogicRunStep;
    procedure SetStep(I: Integer; const Value: TLogicRunStep);
    function GetDin(I: Integer): TLogicRunDin;
    procedure SetDin(I: Integer; Value: TLogicRunDin);
    function GetInput(I: Integer): Boolean;
    function GetOutput(I: Integer): Boolean;
    procedure SetStapDuur(Value: Integer);
    procedure SetHerhalen(Value: Boolean);
    procedure SetTaal(const Value: string);
    procedure TimerTick(Sender: TObject);
    procedure Changed;
    procedure NextStep;
    function ConditionMet: Boolean;
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure SendStatusToBar;
    procedure EditClick(Sender: TObject);
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure BuildPopup;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    destructor Destroy; override;
    procedure UpdateHintText;
    // programma
    procedure ClearSteps;
    procedure AddStep(ABits: Byte; ATijd: Integer);
    procedure InsertStep(AIndex: Integer; ABits: Byte; ATijd: Integer);
    procedure DeleteStep(AIndex: Integer);
    // het hele programma als tekst (zoals in het paneelbestand) en terug
    function ProgramText: string;
    procedure SetProgramText(const S: string);
    // uitvoeren
    procedure Start;
    procedure Pause;
    procedure StopRun;     // stoppen en terug naar het begin (uitgangen uit)
    procedure StepOnce;    // één stap verder (ook als het programma stilstaat)
    procedure ResetRun;    // naar stap 0
    // ingang i (0..3) aan/uit, door de draden (Connect); reageert op het aanzetten
    procedure SetInput(I: Integer; Value: Boolean);
    // aansluitingen: index van de uitgang/ingang bij punt P (paneel), anders -1;
    // uitgang 8 = T1 en 9 = T2 (display-uitgangen, zie DisplayChar)
    function OutputPinAt(const P: TPoint): Integer;
    function InputPinAt(const P: TPoint): Integer;
    // Y van het aansluitvierkantje (7x7) binnen het blok
    class function InputPinY(I: Integer): Integer;
    class function OutputPinY(I: Integer): Integer;
    // cijfer voor een display: T1 (I=0) = UIT0..UIT3, T2 (I=1) = UIT4..UIT7,
    // als 0..9 en A..F
    function DisplayChar(I: Integer): Char;
    property StepCount: Integer read GetStepCount;
    property Steps[I: Integer]: TLogicRunStep read GetStep write SetStep;
    property Din[I: Integer]: TLogicRunDin read GetDin write SetDin;
    property Inputs[I: Integer]: Boolean read GetInput;
    property Outputs[I: Integer]: Boolean read GetOutput;
    property CurrentStep: Integer read FStep;
    // pulsen geteld in de huidige stap (voor een stap die op pulsen wacht)
    property Pulses: Integer read FPulses;
    property Running: Boolean read FRunning;
    // na elke wijziging van programma of toestand (het LogicRun-venster)
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property StapDuur: Integer read FStapDuur write SetStapDuur;
    property Herhalen: Boolean read FHerhalen write SetHerhalen;
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property Naam: string read FNaam write FNaam;
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanRail: verticale voedingsrail. Een + rail (rood, instelbare spanning)
    voedt de invoer die er rechts op ingeplugd is, een - rail (blauw, massa)
    de uitvoer die er links op ingeplugd is. Staat er minstens een rail op het
    paneel, dan werken invoer en uitvoer alleen als ze ingeplugd zijn.
    De rail zelf is de lijn op LineX; het besturingselement is breder zodat de
    stekkers en bolletjes van de ingeplugde componenten erin vallen. }
  TjanRail = class(TGraphicControl)
  private
    FPlus: Boolean;
    FVolt: Double;               // bewaarde spanning (oude panelen, zonder bron)
    FCalcVolt: Double;           // spanning van de bron (UpdateSupply)
    FLock: Boolean;
    FSelected: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FOnStatus: TSimStatusEvent;
    FDragMode: Integer;          // 0 = niet, 1 = verplaatsen, 2 = bovenkant, 3 = onderkant
    FDragStart: TPoint;          // muis bij begin slepen (paneel-coördinaten)
    FStartRect: TRect;
    FMover: TObject;             // TjanGroupSelect: ingeplugde componenten schuiven mee
    FElekY: array of Integer;    // elektronen: grenzen van de stukken rail (paneel-Y)
    FElekI: array of Double;     // stroom naar beneden in elk stuk (A)
    procedure SetPlus(const Value: Boolean);
    procedure SetVolt(const Value: Double);
    function GetVolt: Double;
    procedure SetTaal(const Value: string);
    function GetLineX: Integer;
    function GetSpanTop: Integer;
    function GetSpanBottom: Integer;
    function HitMode(Y: Integer): Integer;
    procedure SendStatusToBar;
    procedure BuildPopup;
    procedure VoltClick(Sender: TObject);
    procedure LockClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure UpdateHintText;
    // werkt een ingeplugde invoer? (+ rail met minstens RailMinVolt)
    function Powered: Boolean;
    function RailColor: TColor;
    // elektronen: stukken rail tussen AY[k] en AY[k+1] met stroom AI[k] naar beneden
    procedure SetElektronen(const AY: array of Integer; const AI: array of Double);
    procedure PaintElektronen;
    procedure InvalidateElektronen;
    property LineX: Integer read GetLineX;          // X van de 2 px lijn in het paneel
    property SpanTop: Integer read GetSpanTop;      // getekend stuk rail, in het paneel
    property SpanBottom: Integer read GetSpanBottom;
  published
    property Plus: Boolean read FPlus write SetPlus;
    // + rail: de spanning die de bron levert (0 V zonder bron); schrijven
    // zet de bewaarde spanning van een oud paneel (zie EnsureBron)
    property Volt: Double read GetVolt write SetVolt;
    property SavedVolt: Double read FVolt;
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
  end;

  { TjanVoedingsDeel: gemeenschappelijke basis van de onderdelen van de
    voedingskring: bron (accu), zekering en milliampèremeter. Ze hebben
    aansluitklemmen (pinnen) waar een draad op begint of eindigt; de kring
    bron -> zekering/meter -> + rail en - rail -> bron wordt uitgerekend in
    UpdateSupply. Pinnen: linkerbovenhoek van het 7x7-vierkantje, relatief. }
  TjanVoedingsDeel = class(TGraphicControl)
  private
    FLock: Boolean;
    FSelected: Boolean;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FOnStatus: TSimStatusEvent;
    FDoMove: Boolean;
    FMdp: TPoint;
    FNewLeft, FNewTop: Integer;
    FConnectors: TList;
    FEntryPin: Integer;    // klem aan de kant van de bron (UpdateSupply)
    procedure AnchorConnectors;
    procedure MoveConnectors;
    procedure LockClick(Sender: TObject);
    procedure InfoClick(Sender: TObject);
    procedure SelectClick(Sender: TObject);
    procedure SetTaal(const Value: string);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
  protected
    FPinV: array[0..7] of Double;  // spanning op de klemmen t.o.v. de - klem van de bron (UpdateSupply; hoogstens 8 klemmen)
    FAmp: Double;                  // stroom van klem 0 naar klem 1, in A (UpdateSupply)
  private
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure DraaiClick(Sender: TObject);
    procedure SetGedraaid(const Value: Boolean);
  protected
    FGedraaid: Boolean;           // een kwartslag gedraaid (rechtsklik > Draaien): x en y gespiegeld
    // mag dit onderdeel gedraaid worden? (dan ook StdMaat en ExtraBreedte geven)
    function KanDraaien: Boolean; virtual;
    // maat in de gewone stand (Width, Height)
    function StdMaat: TPoint; virtual;
    // gedraaid: extra breedte rechts voor de tekst
    function ExtraBreedte: Integer; virtual;
    // staan de klemmen boven en onder in de gewone stand? (zekering)
    function StdRechtop: Boolean; virtual;
    // Width/Height zetten voor de huidige stand (FGedraaid)
    procedure PasMaatAan; virtual;
    // tekenhulp: coördinaten van de tekening in de gewone stand, gespiegeld
    // over de diagonaal als het onderdeel gedraaid is (x <-> y)
    function TP(X, Y: Integer): TPoint;
    function TRc(L, T, R, B: Integer): TRect;
    procedure TLijn(X1, Y1, X2, Y2: Integer);
    // eigen menu-items voor het rechtsklikmenu (vóór vergrendelen e.d.)
    procedure AddMenuItems(APop: TPopupMenu); virtual;
    // muisklik op het onderdeel zelf (bv. de schuifregelaar); True = afgehandeld
    function HandleClick(X, Y: Integer): Boolean; virtual;
    procedure PaintPin(X, Y: Integer; AOn: Boolean);
    procedure PaintSelection;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PinCount: Integer; virtual; abstract;
    function PinPos(I: Integer): TPoint; virtual; abstract;
    // pin op punt P (paneel-coördinaten), anders -1
    function PinAt(const P: TPoint): Integer;
    // middelpunt van pin I in paneel-coördinaten
    function PinCenter(I: Integer): TPoint;
    procedure UpdateHintText; virtual; abstract;
    procedure SendStatusToBar; virtual; abstract;
    // een kwartslag draaien rond het midden; de draden aan de klemmen gaan mee
    procedure Draai;
    // stand zetten zonder draden te verplaatsen (bij het laden)
    property Gedraaid: Boolean read FGedraaid write SetGedraaid;
  published
    property Lock: Boolean read FLock write FLock;
    property Selected: Boolean read FSelected write FSelected;
    property Box: TjanSimLogicBox read FBox write FBox;
    property BTaal: string read FTaal write SetTaal;
    property OnStatus: TSimStatusEvent read FOnStatus write FOnStatus;
    property ShowHint;
    property HelpKeyword;
  end;

  { TjanBron: accu met instelbare spanning (0 tot 12 V, schuifregelaar) en
    inwendige weerstand. Pin 0 = +, pin 1 = - (allebei rechts). }
  TjanBron = class(TjanVoedingsDeel)
  private
    FVolt: Double;         // bronspanning E
    FRiIdx: Integer;       // index in BronRi
    FKlem: Double;         // klemspanning (na de spanningsval over Ri)
    FStroom: Double;       // stroom in A
    FSliding: Boolean;
    FElektronen: Boolean;  // elektronen in de draden tonen
    procedure SetVolt(const Value: Double);
    procedure SetElektronen(const Value: Boolean);
    procedure ElektronenClick(Sender: TObject);
    procedure SetRiIdx(const Value: Integer);
    procedure RiClick(Sender: TObject);
    function SliderRect: TRect;
    procedure SlideTo(X: Integer);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Ri: Double;
    function Emk: Double; virtual;   // bronspanning nu (bij een wisselbron: de sinus)
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Klem: Double read FKlem;
    property Stroom: Double read FStroom;
  published
    property Volt: Double read FVolt write SetVolt;
    property RiIdx: Integer read FRiIdx write SetRiIdx;
    property Elektronen: Boolean read FElektronen write SetElektronen;
  end;

  { TjanWisselbron: wisselspanningsbron. Zoals de bron, maar de bronspanning
    is een sinus: e(t) = Volt x sin(2 pi f t). Volt is de topwaarde (de
    schuifregelaar), f een vertraagde frequentie (0,5, 1 of 2 Hz) zodat je
    het verloop op het scherm ziet; de tijd loopt tijdens de simulatie.
    Pin 0 en pin 1 wisselen om de beurt van + en -. }
  TjanWisselbron = class(TjanBron)
  private
    FFreqIdx: Integer;     // index in WisselHz
    procedure SetFreqIdx(const Value: Integer);
    procedure FreqClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function Emk: Double; override;
    function Hz: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property FreqIdx: Integer read FFreqIdx write SetFreqIdx;
  end;

  { TjanZekering: smeltzekering in de voedingsleiding. Pin 0 = ingang
    (links), pin 1 = uitgang (rechts). Wordt de stroom groter dan de
    nominale stroom, dan smelt ze (Doorgebrand) tot ze vervangen wordt. }
  TjanZekering = class(TjanVoedingsDeel)
  private
    FNomIdx: Integer;      // index in ZekeringMA
    FDoorgebrand: Boolean;
    FInVolt, FUitVolt: Double;
    procedure SetNomIdx(const Value: Integer);
    procedure SetDoorgebrand(const Value: Boolean);
    procedure NomClick(Sender: TObject);
    procedure VervangClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    function StdRechtop: Boolean; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function NominaalA: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property NomIdx: Integer read FNomIdx write SetNomIdx;
    property Doorgebrand: Boolean read FDoorgebrand write SetDoorgebrand;
  end;

  { TjanAmpMeter: milliampèremeter, in serie in de voedingsleiding. Pin 0 =
    ingang (links), pin 1 = uitgang (rechts). Toont de stroom in mA. }
  TjanAmpMeter = class(TjanVoedingsDeel)
  private
    FStroom: Double;       // A
    FInVolt, FUitVolt: Double;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Stroom: Double read FStroom;
  end;

  { TjanWattMeter: vermogensmeter met twee klemmen, zoals een
    stekker-energiemeter. Staat in serie zoals de milliampèremeter (de
    voedingskring rekent hem als een meter van bijna 0 ohm) en toont het
    vermogen van alles wat achter hem hangt: P = U x I, met I de stroom door
    de meter en U de spanning van zijn uitgang tot de - klem van de bron. }
  TjanWattMeter = class(TjanAmpMeter)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function Spanning: Double;   // V achter de meter (t.o.v. de - van de bron)
    function Watt: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  end;

  { TjanPotmeter: potentiometer met drie klemmen. Pin 0 = uiteinde A (links),
    pin 1 = uiteinde B (rechts), pin 2 = loper L (onderaan). Tussen A en B
    staat de hele weerstand; de loper verdeelt die in R(A-L) = R x stand en
    R(L-B) = R x (1 - stand). Sleep de loper met de muis (0 tot 100 %);
    rechtsklik: waarde kiezen (zie PotOhm). }
  TjanPotmeter = class(TjanVoedingsDeel)
  private
    FSoort: Integer;       // index in PotOhm
    FProcent: Integer;     // stand van de loper, 0 (bij A) tot 100 (bij B)
    FIa, FIb: Double;      // stroom van A naar de loper en van de loper naar B (A)
    FSliding: Boolean;
    procedure SetSoort(const Value: Integer);
    procedure SetProcent(const Value: Integer);
    procedure SoortClick(Sender: TObject);
    function SliderRect: TRect;
    procedure SlideTo(X: Integer);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double;        // hele weerstand A-B
    function OhmAL: Double;      // A tot de loper
    function OhmLB: Double;      // de loper tot B
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property StroomAL: Double read FIa;
    property StroomLB: Double read FIb;
  published
    property Soort: Integer read FSoort write SetSoort;
    property Procent: Integer read FProcent write SetProcent;
  end;

  { TjanWeerstand: weerstand of contact in de voedingsleiding. Er staat een
    kleine spanning over (U = I x R) en het wordt warm (P = I x I x R).
    Pin 0 = links, pin 1 = rechts. Soort: goed contact, lange dunne draad,
    slecht contact of verbrand contact (zie WeerstandOhm). }
  TjanWeerstand = class(TjanVoedingsDeel)
  private
    FSoort: Integer;       // index in WeerstandOhm
    FStroom: Double;       // A
    FInVolt, FUitVolt: Double;
    FDeler: Boolean;       // vormt met een LDR of NTC een spanningsdeler
    procedure SetSoort(const Value: Integer);
    procedure SoortClick(Sender: TObject);
    procedure SetDeler(const Value: Boolean);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; virtual;
    function Vermogen: Double;   // W
    function Naam: string;       // soort, of "spanningsdeler" naast een LDR of NTC
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Stroom: Double read FStroom;
    property Deler: Boolean read FDeler write SetDeler;
  published
    property Soort: Integer read FSoort write SetSoort;
  end;

  { TjanLamp2: gloeilamp met twee klemmen (standaard 120 ohm: 100 mA bij 12 V;
    rechtsklik: lamp voor 5 of 12 V en andere weerstand, zie Lamp2Ohm).
    Je zet ze vrij in de voedingskring, ook in serie of parallel. Ze brandt
    feller naarmate er meer vermogen door gaat (P = U x I, vol bij het vermogen
    op haar eigen spanning). Een lamp voor 5 V telt mee in de waarheidstabel. }
  TjanLamp2 = class(TjanVoedingsDeel)
  private
    FSoort: Integer;       // index in Lamp2Ohm
    FKleur: TLampKleur;    // gewone lamp of een gekleurde lamp (rood, groen, oranje)
    procedure SetKleur(const Value: TLampKleur);
    procedure KleurClick(Sender: TObject);
    procedure SetSoort(const Value: Integer);
    procedure SoortClick(Sender: TObject);
    procedure VoltClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double;
    function Volt: Double;       // spanning waarvoor de lamp gemaakt is: 5 of 12 V
    function LampLabel: string; virtual;   // tekst onder de lamp
    function Is5V: Boolean;
    function Aan: Boolean;       // brandt (minstens een kwart van haar vermogen)
    function Spanning: Double;   // V over de lamp
    function Vermogen: Double;   // W
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Soort: Integer read FSoort write SetSoort;
    property Kleur: TLampKleur read FKleur write SetKleur;
  end;

  { TjanSchakelaar2: schakelaar met twee klemmen in de voedingskring.
    Klik op de hendel: open of dicht (ook tijdens de simulatie).
    Met rechtsklik Soort > Drukknop: dicht zolang je de muisknop indrukt.
    Soort > Wisselschakelaar: drie klemmen; het midden (klem 2, onderaan) is
    verbonden met A (klem 0, Aan = False) of B (klem 1, Aan = True). }
  TjanSchakelaar2 = class(TjanVoedingsDeel)
  private
    FAan: Boolean;
    FSoort: Integer;       // 0 = schakelaar, 1 = drukknop, 2 = wisselschakelaar
    procedure SetAan(const Value: Boolean);
    procedure SetSoort(const Value: Integer);
    function GetDruk: Boolean;
    procedure SetDruk(const Value: Boolean);
    function GetWissel: Boolean;
    procedure SoortClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Aan: Boolean read FAan write SetAan;
    property Soort: Integer read FSoort write SetSoort;
    property Druk: Boolean read GetDruk write SetDruk;
    property Wissel: Boolean read GetWissel;
  end;

  { TjanWissel2: wisselschakelaar (eigen knop in de balk). Drie klemmen: het
    midden (onderaan) is verbonden met A of met B; zie TjanSchakelaar2 met Soort 2. }
  TjanWissel2 = class(TjanSchakelaar2)
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TjanPuls2: impulsgenerator met twee klemmen in de voedingskring. Een
    schakelaar die vanzelf opent en sluit (zoals een knipperrelais); de
    frequentie kies je met rechtsklik. Tussen de + rail en een ingang geeft
    hij pulsen van de volle spanning. }
  TjanPuls2 = class(TjanVoedingsDeel)
  private
    FAan: Boolean;
    FLoopt: Boolean;       // aangezet met een klik op het kastje
    FInterval: Integer;    // halve periode in ms
    FKlok: TTimer;
    procedure Tik(Sender: TObject);
    procedure SetInterval(const Value: Integer);
    procedure SetLoopt(const Value: Boolean);
    procedure FreqClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function HandleClick(X, Y: Integer): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Aan: Boolean read FAan;
  published
    property Interval: Integer read FInterval write SetInterval;
    property Loopt: Boolean read FLoopt write SetLoopt;
  end;

  { TjanDip2: dipschakelaar met vijf klemmen: links de gemeenschappelijke
    klem (naar de + rail), rechts de uitgangen 8, 4, 2 en 1. Staat een
    schuifje aan, dan is die uitgang met de linkse klem verbonden. }
  TjanDip2 = class(TjanVoedingsDeel)
  private
    FWaarde: Integer;      // 0..15; bit 3 = uitgang 8 (klem 1) ... bit 0 = uitgang 1 (klem 4)
    FIs: array[1..4] of Double;   // stroom van de linkse klem naar elke uitgang
    procedure SetWaarde(const Value: Integer);
  protected
    function HandleClick(X, Y: Integer): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function BitAan(APin: Integer): Boolean;   // APin = 1..4
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Waarde: Integer read FWaarde write SetWaarde;
  end;

  { TjanVoltmeter2: voltmeter met twee klemmen (+ links, - rechts) die je
    over een lamp, weerstand of bron zet. Neemt geen stroom. }
  TjanVoltmeter2 = class(TjanVoedingsDeel)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Spanning: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  end;

  { TjanScoop: oscilloscoop met twee klemmen (+ links, - rechts onderaan),
    zoals de voltmeter (neemt geen stroom). Tekent de spanning tussen de
    klemmen in de tijd: bij elke stap van de simulatietijd een meetpunt.
    Rechtsklik: bereik (+/- 5 of 12 V), tijdbasis (2, 4 of 8 s), wissen. }
  TjanScoop = class(TjanVoltmeter2)
  private
    FT, FU: array of Double;   // ringbuffer: tijd en spanning
    FN, FKop: Integer;         // aantal punten en de plaats van het volgende
    FBereikIdx, FTijdIdx: Integer;
    procedure SetBereikIdx(const Value: Integer);
    procedure SetTijdIdx(const Value: Integer);
    procedure BereikClick(Sender: TObject);
    procedure TijdClick(Sender: TObject);
    procedure WisClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    procedure Meet(AU: Double);   // meetpunt op de huidige simulatietijd
    procedure Wis;
    // hoogste en laagste meting van de laatste ASec seconden
    function MaxLaatste(ASec: Double): Double;
    function MinLaatste(ASec: Double): Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Aantal: Integer read FN;
  published
    property BereikIdx: Integer read FBereikIdx write SetBereikIdx;
    property TijdIdx: Integer read FTijdIdx write SetTijdIdx;
  end;

  { TjanTransistor: bipolaire transistor met drie klemmen. Pin 0 = collector C
    (boven), pin 1 = basis B (links), pin 2 = emitter E (onder). NPN: een
    stroom van B naar E (vanaf 0,7 V) laat een stroom van C naar E toe die
    beta keer groter is; PNP: hetzelfde met alle stromen en spanningen
    omgekeerd. Toestanden: spert (geen basisstroom), versterkt (Ic = beta x Ib)
    en verzadigd (Ic wordt door de rest van de kring beperkt, Uce = 0,2 V).
    Rechtsklik: NPN/PNP, versterking (TrBeta), vervangen als hij kapot is. }
  TjanTransistor = class(TjanVoedingsDeel)
  private
    FPNP: Boolean;
    FBetaIdx: Integer;     // index in TrBeta
    FDoorgebrand: Boolean;
    FBeAan: Boolean;       // toestand in UpdateSupply: basis-emitter geleidt
    FVerzadigd: Boolean;   // toestand in UpdateSupply: verzadigd
    FIb, FIc: Double;      // basisstroom en collectorstroom (A, altijd >= 0)
    procedure SetPNP(const Value: Boolean);
    procedure SetBetaIdx(const Value: Integer);
    procedure SetDoorgebrand(const Value: Boolean);
    procedure SoortClick(Sender: TObject);
    procedure BetaClick(Sender: TObject);
    procedure VervangClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Beta: Double;
    // 'spert', 'versterkt', 'verzadigd' of 'kapot'
    function ToestandTekst: string;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Ib: Double read FIb;
    property Ic: Double read FIc;
    property BeAan: Boolean read FBeAan;
    property Verzadigd: Boolean read FVerzadigd;
  published
    property PNP: Boolean read FPNP write SetPNP;
    property BetaIdx: Integer read FBetaIdx write SetBetaIdx;
    property Doorgebrand: Boolean read FDoorgebrand write SetDoorgebrand;
  end;

  { TjanSensorR: weerstand met twee klemmen (pin 0 links, pin 1 rechts) die
    afhangt van een stand 0..100, ingesteld met een schuifregelaar onderaan:
    het licht (LDR) of de temperatuur (NTC). }
  TjanSensorR = class(TjanVoedingsDeel)
  private
    FStand: Integer;
    FSliding: Boolean;
    FDragX, FDragStand: Integer;   // muis en stand bij het begin van het slepen
    procedure SetStand(const Value: Integer);
    function SliderRect: TRect;
    procedure SlideTo(X: Integer);
  protected
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    // het symbool in het blokje R (pijlen, schuine streep ...)
    procedure PaintSymbool(const R: TRect); virtual; abstract;
    function KnopKleur: TColor; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; virtual; abstract;
    // de stand in woorden: 'licht 50 %', '25 °C'
    function StandTekst: string; virtual; abstract;
    // eenheid op het schermpje: '%' (licht) of '°C'
    function Eenheid: string; virtual; abstract;
    function Naam: string; virtual; abstract;
    procedure SendStatusToBar; override;
  published
    property Stand: Integer read FStand write SetStand;
  end;

  { TjanLDR: lichtgevoelige weerstand. Stand = licht in %: 1 Mohm in het
    donker (0 %) tot 100 ohm in fel licht (100 %), logaritmisch. }
  TjanLDR = class(TjanSensorR)
  protected
    procedure PaintSymbool(const R: TRect); override;
    function KnopKleur: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    function Ohm: Double; override;
    function StandTekst: string; override;
    function Eenheid: string; override;
    function Naam: string; override;
    procedure UpdateHintText; override;
  end;

  { TjanNTC: temperatuurgevoelige weerstand (NTC: Negatieve TemperatuurCoëfficiënt).
    Stand = temperatuur in °C (0 tot 100); 10 kohm bij 25 °C, B = 3950 K:
    hoe warmer, hoe kleiner de weerstand. }
  TjanNTC = class(TjanSensorR)
  protected
    procedure PaintSymbool(const R: TRect); override;
    function KnopKleur: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    function Ohm: Double; override;
    function StandTekst: string; override;
    function Eenheid: string; override;
    function Naam: string; override;
    procedure UpdateHintText; override;
  end;

  { TjanLed2: led met twee klemmen in de voedingskring. Pin 0 = anode (+,
    links), pin 1 = kathode (-, rechts). Geleidt alleen van + naar - en pas
    boven de drempelspanning (rood 1,8 V ... blauw 3,0 V); brandt vol bij
    20 mA en gaat kapot boven 30 mA (dan: rechtsklik, vervangen). Daarom
    hoort er een voorschakelweerstand bij. }
  TjanLed2 = class(TjanVoedingsDeel)
  private
    FKleur: Integer;       // index in LedVolt
    FGeleidt: Boolean;     // toestand in UpdateSupply (boven de drempel)
    FDoorgebrand: Boolean;
    procedure SetKleur(const Value: Integer);
    procedure SetDoorgebrand(const Value: Boolean);
    procedure KleurClick(Sender: TObject);
    procedure VervangClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Drempel: Double; virtual;    // V
    function Rd: Double; virtual;         // ohm boven de drempel
    function MaxA: Double; virtual;       // A: daarboven kapot
    function Spanning: Double;   // V over de led
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Kleur: Integer read FKleur write SetKleur;
    property Doorgebrand: Boolean read FDoorgebrand write SetDoorgebrand;
  end;

  { TjanDiode: gelijkrichtdiode (zoals een 1N4007). Werkt in de voedingskring
    als een led zonder licht: geleidt alleen van anode (pin 0, links) naar
    kathode (pin 1, rechts), boven 0,7 V, met een heel kleine weerstand; kapot
    boven 1 A (rechtsklik: vervangen). }
  TjanDiode = class(TjanLed2)
  private
    FOmgekeerd: Boolean;   // anode rechts en kathode links (omgedraaid)
    procedure SetOmgekeerd(const Value: Boolean);
    procedure VervangDiodeClick(Sender: TObject);
    procedure OmdraaiClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    property Omgekeerd: Boolean read FOmgekeerd write SetOmgekeerd;
    function Drempel: Double; override;
    function Rd: Double; override;
    function MaxA: Double; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  end;

  { TjanCondensator: elektrolytische condensator met twee klemmen. Pin 0 =
    + (links), pin 1 = - (rechts). Laadt op en ontlaadt in de tijd (de
    voedingskring rekent elke tik van de cpu-timer verder): I = C x dU/dt,
    tijdconstante tau = R x C. }
  TjanCondensator = class(TjanVoedingsDeel)
  private
    FSoort: Integer;       // index in CondUF
    FU: Double;            // spanning over de condensator (pin 0 - pin 1)
    procedure SetSoort(const Value: Integer);
    procedure SoortClick(Sender: TObject);
    procedure OntlaadClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Farad: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property U: Double read FU;
  published
    property Soort: Integer read FSoort write SetSoort;
  end;

  { Magnetisme (zonder klemmen). Het veld rekent met twee polen per magneet:
    B = som van q x (r - r_pool) / |r - r_pool|^3, met q = +1 in de
    noordpool en -1 in de zuidpool. De veldlijnen lopen buiten de magneet
    van N naar Z, en de noordpool van een kompasnaald wijst langs het veld. }
  TMagVec = record
    X, Y: Double;
  end;

  { TjanMagneet: staafmagneet met een rode noordpool en een blauwe zuidpool.
    Liggend staat de noordpool rechts (omgedraaid links), rechtop onderaan
    (omgedraaid boven). Komt een andere magneet dichtbij, dan toont een gele
    pijl de kracht: ongelijke polen trekken aan, gelijke polen stoten af. }
  TjanMagneet = class(TjanVoedingsDeel)
  private
    FOmgekeerd: Boolean;
    procedure CMVisibleChanged(var Msg: TLMessage); message CM_VISIBLECHANGED;
    procedure SetOmgekeerd(const Value: Boolean);
    procedure OmdraaiClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    // noordpool en zuidpool in paneelcoördinaten
    procedure Polen(out PN, PZ: TMagVec);
    // kracht van de andere magneten op deze magneet
    function Kracht: TMagVec;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Omgekeerd: Boolean read FOmgekeerd write SetOmgekeerd;
  end;

  { TjanKompas: een naald die draait naar het veld op haar plaats. Zonder
    magneet in de buurt wijst ze naar het noorden (boven op het paneel). }
  TjanKompas = class(TjanVoedingsDeel)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  end;

  { TjanVeldplaat: een blad onder de magneten waarop de veldlijnen getekend
    worden, zoals ijzervijlsel op papier. Ligt altijd achteraan. }
  TjanVeldplaat = class(TjanVoedingsDeel)
  private
    FMaat: Integer;        // 0 klein, 1 middel, 2 groot
    procedure SetMaat(const Value: Integer);
    procedure MaatClick(Sender: TObject);
    procedure CMVisibleChanged(var Msg: TLMessage); message CM_VISIBLECHANGED;
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Maat: Integer read FMaat write SetMaat;
  end;

  { TjanSpoel: een spoel (solenoïde) met twee klemmen in de stroomkring.
    Elektrisch een kleine weerstand; loopt er stroom door, dan wordt ze een
    magneet: de stroom van klem 0 (links) naar klem 1 (rechts) maakt rechts
    een noordpool. Sterker met meer stroom, meer windingen en een ijzeren
    kern. Omgekeerd = andersom gewikkeld: dan wisselen N en Z. }
  TjanSpoel = class(TjanWeerstand)
  private
    FWindIdx: Integer;     // index in SpoelWindingen
    FKern: Boolean;        // ijzeren kern
    FOmgekeerd: Boolean;
    FTimer: TTimer;
    FPhiOud: Double;       // flux bij de vorige tik (inductie)
    FTijdOud: QWord;
    FHeeftPhi: Boolean;
    FEmf: Double;          // geïnduceerde spanning (V), + = klem 1 wordt de + kant
    FEmfInKring: Double;   // de spanning waarmee de voedingskring rekent
    procedure Tik(Sender: TObject);
    procedure SetWindIdx(const Value: Integer);
    procedure SetKern(const Value: Boolean);
    procedure SetOmgekeerd(const Value: Boolean);
    procedure WindClick(Sender: TObject);
    procedure KernClick(Sender: TObject);
    procedure OmdraaiClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    function Windingen: Integer;
    // magnetische sterkte (+ = noordpool rechts/onder), zoals q van een magneet
    function Sterkte: Double;
    // noordkant en zuidkant in paneelcoördinaten (de pool met + sterkte is PN)
    procedure Polen(out PN, PZ: TMagVec);
    // magnetische flux door de spoel van de andere magneten (windingen x veld langs de as)
    function Flux: Double;
    property Emf: Double read FEmfInKring;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property WindIdx: Integer read FWindIdx write SetWindIdx;
    property Kern: Boolean read FKern write SetKern;
    property Omgekeerd: Boolean read FOmgekeerd write SetOmgekeerd;
  end;

  { TjanIJzer: een ijzeren spijker zonder klemmen. Ijzer wordt aangetrokken
    waar het veld sterker wordt: de kracht volgt de helling van B². Is ze
    groot genoeg (Trekkracht >= 1), dan schuift de spijker naar de magneet of
    de spoel tot hij een pool of een andere spijker raakt, en blijft daar.
    Rechtsklik: terugleggen op de plaats waar je hem neerlegde. }
  TjanIJzer = class(TjanVoedingsDeel)
  private
    FTimer: TTimer;
    FThuis: TPoint;        // waar de gebruiker hem neerlegde
    FTrekt: Boolean;       // schuift nu naar de magneet
    FVast: Boolean;        // raakt een pool of een andere spijker
    FV: Double;            // snelheid (pixels per tik)
    FX, FY: Double;        // plaats tijdens het schuiven (paneel)
    procedure Tik(Sender: TObject);
    procedure TerugClick(Sender: TObject);
    function Krachtvector: TMagVec;
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    // kracht op de spijker gedeeld door wat nodig is om hem te verschuiven
    function Trekkracht: Double;
    procedure Terugleggen;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Vast: Boolean read FVast;
  end;

  { TjanRelaisModel: een open relais om te zien hoe het werkt. Een spoel op
    een ijzeren kern (klemmen 0 en 1, onderaan), een anker op een scharnier
    met een veer, en drie contacten: het gemeenschappelijke contact C (klem 2,
    rechts, via het anker), het maakcontact (klem 3, links onder) en het
    verbreekcontact (klem 4, links boven). Loopt er genoeg stroom door de
    spoel, dan trekt de kern het anker aan: het verbreekcontact gaat open en
    daarna het maakcontact dicht. In serie met het eigen verbreekcontact
    trilt het anker: een elektrische bel. }
  TjanRelaisModel = class(TjanVoedingsDeel)
  private
    FTimer: TTimer;
    FPos: Double;          // 0 = anker rust (tegen het verbreekcontact), 1 = aangetrokken
    FV: Double;            // snelheid van het anker
    FIc: Double;           // stroom door het gesloten contact (van C naar het contact)
    FTrilt: Integer;       // tikken sinds het anker nog heen en weer ging
    procedure Tik(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function MaakDicht: Boolean; virtual;
    function VerbreekDicht: Boolean; virtual;
    function SpoelOhm: Double; virtual;
    // magnetische sterkte (+ = noordpool boven) en de polen van de kern
    function Sterkte: Double;
    procedure Polen(out PN, PZ: TMagVec);
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Ankerstand: Double read FPos;
  end;

  { TjanSchommel: stroomschommel om de Lorentzkracht te zien. Van opzij
    gezien hangt een koperen staafje tussen de polen van een U-magneet
    (noordpool boven, zuidpool onder; omgedraaid andersom). De stroom van
    klem 0 naar klem 1 loopt het scherm in (kruisje); dan duwt de kracht
    het staafje naar links (linkerhandregel). Het zwaait verder uit naarmate
    de stroom groter is, en met een sterke magneet twee keer zo ver. }
  TjanSchommel = class(TjanWeerstand)
  private
    FTimer: TTimer;
    FOmgekeerd: Boolean;   // zuidpool boven
    FSterk: Boolean;       // sterke magneet
    FHoek, FHoekV: Double; // uitslag (radialen, + = naar rechts) en hoeksnelheid
    procedure Tik(Sender: TObject);
    procedure SetOmgekeerd(const Value: Boolean);
    procedure SetSterk(const Value: Boolean);
    procedure OmdraaiClick(Sender: TObject);
    procedure SterkClick(Sender: TObject);
    procedure TekenSchuin;
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    // kracht naar rechts (+) of links (-), in willekeurige eenheden: B x I
    function Kracht: Double;
    // de uitslag waar het staafje naartoe zwaait
    function DoelHoek: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Hoek: Double read FHoek;
  published
    property Omgekeerd: Boolean read FOmgekeerd write SetOmgekeerd;
    property Sterk: Boolean read FSterk write SetSterk;
  end;

  { TjanElektromotor: model van een gelijkstroommotor. Links het vooraanzicht
    langs de as: een noordpool links en een zuidpool rechts, een spoeltje
    met twee draden die draaien, en in het midden de collector met twee
    borstels (klem 0 links, klem 1 rechts). Rechts een schuin tekeningetje.
    De Lorentzkracht duwt de ene draad omhoog en de andere omlaag; de
    collector keert de stroom in het spoeltje elke halve draai om, zodat het
    rond blijft draaien. Zonder collector (sleepringen) blijft het rechtop
    staan. Elektrisch een kleine weerstand (4 ohm). }
  TjanElektromotor = class(TjanWeerstand)
  private
    FTimer: TTimer;
    FOmgekeerd: Boolean;   // zuidpool links
    FGeenCollector: Boolean;
    FHoek, FOmega: Double; // stand van het spoeltje (radialen, tegen de klok in) en snelheid per tik
    procedure Tik(Sender: TObject);
    procedure SetOmgekeerd(const Value: Boolean);
    procedure SetGeenCollector(const Value: Boolean);
    procedure OmdraaiClick(Sender: TObject);
    procedure CollectorClick(Sender: TObject);
    procedure TekenSchuin;
    // stroom in draad A (+1 = het scherm in, -1 = eruit, 0 = geen)
    function StroomA: Integer;
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    // toerental in omwentelingen per minuut (+ = tegen de klok in)
    function Toeren: Double;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Hoek: Double read FHoek;
  published
    property Omgekeerd: Boolean read FOmgekeerd write SetOmgekeerd;
    property GeenCollector: Boolean read FGeenCollector write SetGeenCollector;
  end;

  { TjanNulmeter: nulpuntmeter (galvanometer) met de nul in het midden.
    In serie in de kring, elektrisch 1 ohm. Loopt de stroom van de linkse
    naar de rechtse klem, dan slaat de naald naar rechts uit, andersom naar
    links. De naald beweegt met wat traagheid, zodat je ook een korte
    stroomstoot ziet. Rechtsklik: bereik 10 mA, 100 mA of 1 A. }
  TjanNulmeter = class(TjanWeerstand)
  private
    FTimer: TTimer;
    FBereikIdx: Integer;
    FNaald, FNaaldV: Double;   // stand van de naald (-1 .. 1) en snelheid
    procedure Tik(Sender: TObject);
    procedure SetBereikIdx(const Value: Integer);
    procedure BereikClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    function Bereik: Double;   // A voor volle uitslag
    property Amp: Double read FAmp;   // stroom met teken (+ = van links naar rechts)
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property BereikIdx: Integer read FBereikIdx write SetBereikIdx;
  end;

  { TjanDraaimagneet: een staafmagneet die rond zijn midden draait, zoals in
    een dynamo. Zonder klemmen; leg er een spoel naast. Klik: draaien of
    stilstaan. Rechtsklik: toerental (30 tot 240 omw/min). }
  TjanDraaimagneet = class(TjanVoedingsDeel)
  private
    FTimer: TTimer;
    FHoek: Double;         // stand (radialen, tegen de klok in; 0 = noordpool rechts)
    FToerIdx: Integer;     // index in DraaiToeren
    FDraait: Boolean;
    FTijdOud: QWord;
    procedure Tik(Sender: TObject);
    procedure SetToerIdx(const Value: Integer);
    procedure SetDraait(const Value: Boolean);
    procedure ToerClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
    function HandleClick(X, Y: Integer): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function Toeren: Double;
    procedure Polen(out PN, PZ: TMagVec);
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property ToerIdx: Integer read FToerIdx write SetToerIdx;
    property Draait: Boolean read FDraait write SetDraait;
  end;

  { TjanTransformator: twee spoelen op een ijzeren kern. Links de primaire
    spoel (klemmen 0 boven en 1 onder), rechts de secundaire (klemmen 2 boven
    en 3 onder). Bij wisselspanning is U2 = (N2 / N1) x U1, en de primaire
    stroom volgt wat de secundaire kring vraagt (I1 = N2 / N1 x I2). Bij
    gelijkspanning verandert het veld niet: dan geeft de secundaire niets en
    is de primaire gewoon een weerstand van 40 ohm. De twee kringen zijn
    elektrisch gescheiden. }
  TjanTransformator = class(TjanVoedingsDeel)
  private
    FN1Idx, FN2Idx: Integer;   // index in TrafoWindingen
    FAc: Double;               // 1 = wisselspanning (koppeling), 0 = gelijkspanning
    FGem: Double;              // trage gemiddelde primaire spanning
    FTOud: Double;             // simulatietijd van de vorige meting
    FU1, FU2, FI1, FI2: Double;
    procedure SetN1Idx(const Value: Integer);
    procedure SetN2Idx(const Value: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function N1: Integer;
    function N2: Integer;
    function Verhouding: Double;    // N2 / N1
    function Koppeling: Double;     // FAc
    procedure Meet(AU1, AU2, AI1, AI2: Double);
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property U1: Double read FU1;
    property U2: Double read FU2;
    property I2: Double read FI2;
  published
    property N1Idx: Integer read FN1Idx write SetN1Idx;
    property N2Idx: Integer read FN2Idx write SetN2Idx;
  end;

  { TjanZoemer2: zoemer met twee klemmen in de voedingskring (links in,
    rechts uit), 200 ohm. Hij zoemt vanaf 10 mA, dus ook aan de uitgang van
    een poort (5 V). }
  TjanZoemer2 = class(TjanWeerstand)
  private
    FGeluid: Boolean;      // zoemt ook echt, via de luidsprekers
    procedure SetGeluid(const Value: Boolean);
    procedure GeluidClick(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    function Aan: Boolean;
    destructor Destroy; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Geluid: Boolean read FGeluid write SetGeluid default True;
  end;

  { TjanRelais2: relais in schemasymbool met een spoel met twee klemmen
    (onderaan: klem 0 links, klem 1 rechts, 70 ohm) en een wisselcontact
    (C links boven = klem 2, maakcontact rechts boven = klem 3,
    verbreekcontact rechts in het midden = klem 4). Vanaf 35 mA door de spoel
    trekt het aan, onder 20 mA valt het af; ook een poort (5 V) stuurt het.
    Het schakelt meteen in de berekening (de waarheidstabel klopt), het mesje
    beweegt zichtbaar mee. }
  TjanRelais2 = class(TjanRelaisModel)
  private
    FAan: Boolean;
    FGewisseld: Boolean;   // al eens omgeschakeld in deze berekening
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function MaakDicht: Boolean; override;
    function VerbreekDicht: Boolean; override;
    function SpoelOhm: Double; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property Aan: Boolean read FAan write FAan;
    property Gewisseld: Boolean read FGewisseld write FGewisseld;
  end;

  { TjanBoardIn: een ingang van een echt Arduino-board (via USB, Firmata). Hij
    werkt als een drukknop met twee klemmen in de voedingskring: dicht zolang
    de echte drukknop op de gekozen pin ingedrukt is (pin met interne
    pull-up: de knop gaat van de pin naar GND). Zonder board kun je er met de
    muis op drukken, zoals op een gewone drukknop. }
  TjanBoardIn = class(TjanSchakelaar2)
  private
    FPin: Integer;          // 2..13 = D2..D13, 14..19 = A0..A5
    procedure SetPin(const Value: Integer);
    procedure PinClick(Sender: TObject);
  protected
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Pin: Integer read FPin write SetPin;
  end;

  { TjanBoardUit: een uitgang van een echt Arduino-board. Hij werkt als een
    lamp van 5 V met twee klemmen: brandt hij (bv. aan de uitgang van een
    poort), dan zet Logic de gekozen pin van het board hoog, anders laag.
    Op de pin hangt dan bv. een led met een weerstand van 220 ohm naar GND. }
  TjanBoardUit = class(TjanLamp2)
  private
    FPin: Integer;          // 2..13 = D2..D13
    FGestuurd: Integer;     // laatst gestuurde toestand: -1 onbekend, 0 laag, 1 hoog
    procedure SetPin(const Value: Integer);
    procedure PinClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    function LampLabel: string; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    // de pin van het board bijwerken als de toestand veranderd is (na elke
    // berekening van de kring); AltijdSturen = ook als hij niet veranderd is
    procedure Stuur(AltijdSturen: Boolean = False);
  published
    property Pin: Integer read FPin write SetPin;
  end;

  { TjanK8055In: een ingang (1..5) van een Velleman K8055 (USB). Hij werkt als
    een drukknop met twee klemmen: dicht zolang de echte ingang aan is (de
    knopjes INP1..INP3 op het bordje, of een contact naar GND). Zonder bordje
    druk je er met de muis op. De verbinding zit in het programma (uK8055). }
  TjanK8055In = class(TjanSchakelaar2)
  private
    FNr: Integer;           // 1..5
    procedure SetNr(const Value: Integer);
    procedure NrClick(Sender: TObject);
  protected
    function HandleClick(X, Y: Integer): Boolean; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Nr: Integer read FNr write SetNr;
  end;

  { TjanK8055Uit: een uitgang (1..8) van een Velleman K8055. Hij werkt als een
    lamp van 5 V met twee klemmen: brandt hij, dan zet Logic de echte uitgang
    aan (het ledje op het bordje gaat aan). }
  TjanK8055Uit = class(TjanLamp2)
  private
    FNr: Integer;           // 1..8
    procedure SetNr(const Value: Integer);
    procedure NrClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    function LampLabel: string; override;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Nr: Integer read FNr write SetNr;
  end;

  { TjanStappenmotor: stappenmotor met vier spoelen A, B, C en D (klem 0..3,
    links) en een gemeenschappelijke klem (klem 4, linksonder). Elke spoel is
    100 ohm tussen haar klem en de gemeenschappelijke klem; vanaf 20 mA trekt
    ze de rotor (een magneetje) naar zich toe, dus ook aan de uitgang van een
    poort. A, B, C, D na elkaar: rechtsom; D, C, B, A: linksom. Twee spoelen
    naast elkaar samen: een halve stap. Twee spoelen tegenover elkaar: de
    rotor weet niet waarheen en blijft staan. Rechts de as met een wijzer, de
    hoek en het aantal stappen. Rechtsklik: stappen per omwenteling (4, 48,
    200) en teller op nul. }
  TjanStappenmotor = class(TjanVoedingsDeel)
  private
    FTimer: TTimer;
    FPos: Integer;          // stand van de rotor in halve stappen (+ = rechtsom), telt door
    FToon: Double;          // getekende stand (halve stappen), loopt FPos na
    FStapIdx: Integer;      // index in StapPerToer
    FTrilt: Boolean;        // twee spoelen tegenover elkaar
    FMasker: Integer;       // spoelen die stroom krijgen (bit 0 = A ... bit 3 = D)
    FRichting: Integer;     // laatste stap: 1 rechtsom, -1 linksom
    procedure Tik(Sender: TObject);
    procedure SetStapIdx(const Value: Integer);
    procedure StapClick(Sender: TObject);
    procedure NulClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function SpoelOhm: Double;
    // stroom door spoel I (0 = A .. 3 = D), in A
    function SpoelStroom(I: Integer): Double;
    function SpoelAan(I: Integer): Boolean;
    function StappenPerToer: Integer;
    // aantal stappen (halve stappen tellen voor 0,5), + = rechtsom
    function Stappen: Double;
    // hoek van de as in graden (+ = rechtsom), telt door voorbij 360
    function Hoek: Double;
    procedure NulZetten;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
    property HalveStappen: Integer read FPos write FPos;
    property Trilt: Boolean read FTrilt;
  published
    property StapIdx: Integer read FStapIdx write SetStapIdx;
  end;

  { TjanServo: servomotor met drie klemmen links: + (klem 0, rood), S (klem 2,
    het stuursignaal, oranje) en - (klem 1, zwart). Tussen + en - zit de
    motor (100 ohm), vanaf 4 V werkt hij. De stuurspanning op S (t.o.v. -) van
    0 tot 5 V geeft de hoek van 0 tot 180 graden; de arm draait er met een
    eindige snelheid naartoe. Bv. een potentiometer tussen + en - met de
    loper aan S, of de uitgang van een poort (0 of 180 graden). Rechtsklik:
    een pin van het Arduino-board kiezen: dan draait een echte servo mee. }
  TjanServo = class(TjanVoedingsDeel)
  private
    FTimer: TTimer;
    FHoek: Double;          // stand van de arm in graden (0..180)
    FPin: Integer;          // 0 = geen board, anders 2..13
    FGestuurd: Integer;     // laatst naar het board gestuurde hoek, -1 = nog niets
    procedure Tik(Sender: TObject);
    procedure SetPin(const Value: Integer);
    procedure SetHoek(const Value: Double);
    procedure PinClick(Sender: TObject);
  protected
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinCount: Integer; override;
    function PinPos(I: Integer): TPoint; override;
    function MotorOhm: Double;
    function Voeding: Double;      // spanning tussen + en -
    function Stuurspanning: Double; // spanning op S t.o.v. -
    function Werkt: Boolean;       // genoeg voeding
    function Doel: Double;         // gevraagde hoek (graden)
    procedure Stuur(AltijdSturen: Boolean = False);
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  published
    property Pin: Integer read FPin write SetPin;
    property Hoek: Double read FHoek write SetHoek;
  end;

  { TjanVentilator: een gewone gelijkstroommotor met een schoepenrad, twee
    klemmen onderaan (25 ohm). Hij draait zolang er stroom door gaat: sneller
    bij een hogere spanning, andersom als je + en - omwisselt. Ook aan de
    uitgang van een poort (traag). Telt mee in de waarheidstabel. }
  TjanVentilator = class(TjanWeerstand)
  private
    FTimer: TTimer;
    FHoek: Double;          // stand van de schoepen (graden)
    FToeren: Double;        // getekend toerental, loopt het echte na
    procedure Tik(Sender: TObject);
  protected
    function KanDraaien: Boolean; override;
    function StdMaat: TPoint; override;
    function ExtraBreedte: Integer; override;
    procedure AddMenuItems(APop: TPopupMenu); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function PinPos(I: Integer): TPoint; override;
    function Ohm: Double; override;
    // toerental bij de huidige spanning (omw/min, + = rechtsom)
    function Toeren: Double;
    function Aan: Boolean;
    procedure UpdateHintText; override;
    procedure SendStatusToBar; override;
  end;

  { TjanGroupSelect:meerdere objecten tegelijk selecteren en verplaatsen.
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
    FRailMoving: Boolean;
    function IsGroupable(C: TControl): Boolean;
    function EndInGroup(const P: TPoint): Boolean;
    function EndOnVoeding(const P: TPoint): Boolean;
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
    // Selectie (met draden) DX/DY pixels verschuiven, bv. met de pijltjestoetsen
    procedure Nudge(DX, DY: Integer);
    // rail verslepen: de ingeplugde componenten (met draden) schuiven mee
    procedure BeginRailMove(ARail: TControl);
    procedure RailMove(DX, DY: Integer);
    procedure EndRailMove;
    function Count: Integer;
    // de geselecteerde objecten
    procedure GetItems(L: TList);
    // de draden aan de selectie: Beide = met beide uiteinden op een
    // geselecteerd object (kopiëren), anders met minstens één (verwijderen)
    procedure GetWires(L: TList; Beide: Boolean);
    // de draden om te kopiëren: met beide uiteinden op een geselecteerd
    // object, of van een geselecteerd object naar een rail of bron
    procedure GetCopyWires(L: TList);
    // deze objecten selecteren (na plakken)
    procedure SelectList(L: TList);
    property Banding: Boolean read FBanding;
    property BTaal: string read FBTaal write FBTaal;
  end;

procedure Register;

// ------------------------------------------------------------
// Voedingsrails (TjanRail): invoer op een + rail, uitvoer op een - rail
// ------------------------------------------------------------
const
  RailGap = 12;        // afstand lijn van de rail -> component (stekker + bolletje)
  RailSnapTol = 12;    // binnen zoveel pixels springt een component op de rail
  // De oude invoer van de logica (schakelaar, drukknop, licht- en
  // warmtesensor, impulsgenerator en dipschakelaar zonder klemmen) staat niet
  // meer in de balk: in de plaats komen de onderdelen met klemmen van de
  // voedingskring. Oude panelen met die onderdelen werken nog.
  OudeInvoerTonen = False;
  LogicPoortH = 82;    // hoogte van een poort: symbool (68) plus de naam eronder
  RailMinVolt = 2.0;   // onder deze spanning geeft ingeplugde invoer geen signaal
  LogicLampVolt = 5.0; // de logische lamp (en een poort) werkt op 5 V
  RailMaxVolt = 5.0;   // signaal zonder rails
  BronMaxVolt = 12.0;  // hoogste spanning van de bron (accu)
  RailLineOfs = 11;    // X van de lijn binnen TjanRail
  RailWidth = 23;      // breedte van TjanRail (stekkers links en rechts van de lijn)
  RailLabelH = 14;     // bovenaan: spanning (+ rail) of 0V (- rail)
  RailMinLen = 40;     // kortste rail (getekende lijn)
  RailGrip = 6;        // zo dicht bij een uiteinde: rail langer/korter slepen
  RailFootH = 12;      // onderaan de - rail: massasymbool

function IsRailInput(C: TControl): Boolean;
function IsRailOutput(C: TControl): Boolean;
// staat er minstens een rail op het paneel?
function PanelHasRails(P: TWinControl): Boolean;
// de rail waarop C (invoer of uitvoer) ingeplugd is, anders nil
function RailOf(C: TControl): TjanRail;
// schakelrelais: de + rail links, waarop R1 (het contact) is ingeplugd
function SchakelPlusRail(C: TControl): TjanRail;
// voedingsdraad: midden van het voedingsbolletje van C (+ kant links,
// - kant rechts) en de rail die er met een draad op aangesloten is
function PowerDot(C: TControl; APlusSide: Boolean): TPoint;
function WiredRail(C: TControl; APlusSide: Boolean): TjanRail;
// de rail waarvan de lijn door Pt loopt, anders nil
function RailAtPoint(P: TWinControl; const Pt: TPoint): TjanRail;
// ligt Pt op een klem van een onderdeel van de voedingskring?
function VoedingsKlemOp(P: TWinControl; const Pt: TPoint): Boolean;
function RailPlugged(C: TControl): Boolean;
// mag C werken? (geen rails op het paneel, geen rail-component, of
// ingeplugd; invoer bovendien op een + rail met genoeg spanning)
function RailOK(C: TControl): Boolean;
// NewLeft van een gesleept component op de dichtstbijzijnde rail laten springen
procedure SnapToRail(C: TControl; var NewLeft: Integer; Tol: Integer = RailSnapTol);
// stekkers en bolletjes tekenen; voor TjanGridS.OnPaintOverlay
procedure DrawRailOverlay(Grid: TjanGridS);

// het LogicRun-blok op paneel P, anders nil (er is er hoogstens één)
function FindLogicRun(P: TWinControl): TjanLogicRun;

// simulatietijd van de voedingskring (s); loopt met de cpu-timer verder
function SimulatieTijd: Double;
procedure ZetSimulatieTijd(T: Double);
// de voedingskring van paneel P opnieuw uitrekenen (zonder de tijd te laten lopen)
procedure VoedingBijwerken(P: TWinControl);
// één stap van de simulatieklok: de tijd loopt ADt seconden verder en de
// condensatoren laden of ontladen mee (zoals de cpu-timer)
procedure SimulatieStap(P: TWinControl; ADt: Double);
// spanning op klem APin van een onderdeel van de voedingskring (t.o.v. de massa)
function VoedingsPinVolt(D: TjanVoedingsDeel; APin: Integer): Double;
// de uitgangen van een Velleman K8055 bijwerken naar de lampjes TjanK8055Uit
// (na elke berekening van de kring; AltijdSturen = ook als niets veranderde)
procedure K8055Bijwerken(P: TWinControl; AltijdSturen: Boolean = False);
// ingang ANr (1..5) uit de eerste databyte van een K8055-rapport
function K8055Ingang(AData: Byte; ANr: Integer): Boolean;

var
  // opent het LogicRun-venster voor het blok (Sender); gezet door het
  // programma, gebruikt bij dubbelklik en in het rechtsklikmenu van het blok
  LogicRunEditHook: TNotifyEvent = nil;
  // echt Arduino-board (TjanBoardIn / TjanBoardUit): gezet door het programma.
  // BoardSchrijf zet een pin hoog of laag; BoardVerbonden = er is een board.
  BoardSchrijf: procedure(APin: Integer; AHoog: Boolean) of object = nil;
  BoardVerbonden: Boolean = False;
  // BoardServo zet een pin in servomodus en stuurt de hoek (0..180 graden).
  BoardServo: procedure(APin, AHoek: Integer) of object = nil;
  // Velleman K8055 (uK8055): K8055Schrijf zet de 8 uitgangen (bit 0 = uitgang 1);
  // K8055Verbonden = er is een bordje.
  K8055Schrijf: procedure(AMasker: Byte) of object = nil;
  K8055Verbonden: Boolean = False;

implementation

{$IFDEF WINDOWS}
uses MMSystem;
{$ENDIF}
{$IFDEF UNIX}
uses Process;
{$ENDIF}

  {$R janSimImages.res}
  {$R Cursors.RES}

{$I jsl_basis.inc}
{$I jsl_display_geheugen.inc}
{$I jsl_draad.inc}
{$I jsl_rails_kring.inc}
{$I jsl_voedingsdelen.inc}
{$I jsl_draadlogica.inc}
{$I jsl_poorten_teller.inc}
{$I jsl_oude_invoer.inc}
{$I jsl_uitvoer.inc}
{$I jsl_box.inc}
{$I jsl_box_bediening.inc}
{$I jsl_balk.inc}
{$I jsl_groep_logicrun.inc}
{$I jsl_bewegend.inc}
{$I jsl_stappen_flipflop.inc}
{$I jsl_magnetisme.inc}
{$I jsl_board.inc}
{$I jsl_k8055.inc}
{$I jsl_motoren.inc}
end.
