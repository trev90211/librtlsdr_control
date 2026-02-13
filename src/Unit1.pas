unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, lNetComponents, lNet;
//{  ILUDPServer};

const
  sep = ' '#9;

type

  { TForm1 }
 
  TForm1 = class(TForm)
    BitBtn2: TBitBtn;
    Memo1: TMemo;
    Vga_gain: TTrackBar;
    Lna_gain: TTrackBar;
    Mix_Gain: TTrackBar;
    LPF: TTrackBar;
    LPNF: TTrackBar;
    HPF: TTrackBar;
    FILT: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    m_reg: TEdit;
    m_value: TEdit;
    m_mask: TEdit;
    BitBtn1: TBitBtn;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    LUDPComponent1: TLUDPComponent;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Vga_gainChange(Sender: TObject);
    procedure Lna_gainChange(Sender: TObject);
    procedure Mix_GainChange(Sender: TObject);
    procedure LPFChange(Sender: TObject);
    procedure LPNFChange(Sender: TObject);
    procedure HPFChange(Sender: TObject);
    procedure FILTChange(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure LUDPComponent1Error(const msg: string; aSocket: TLSocket);
    procedure LUDPComponent1Receive(aSocket: TLSocket);
  private                
    MessageInd: Integer;
    FAddress: String;
    FPort: Word;
    procedure GetSliderPositions;
    procedure GetRegister(Reg: Integer);
    procedure GetRegister(Reg: String);
    procedure SendMessage(Message: String);
    { Private declarations }
  public
    { Public declarations }
  end;

const
  UDP_BUFFER_SIZE = 128;

var
  Form1: TForm1;
  aData:pointer;
// aData := @data[0];
// aSize := length(data);

implementation

{$R *.lfm}

procedure TForm1.SendMessage(Message: String);
var
  MessageLength: Integer;
  PMsg: PChar;
  Msg: String;
begin
  Msg := Message + LineEnding;  
  memo1.Lines.Add('u'#09 + Msg);
//  if (LUDPComponent1.Connect(FAddress, FPort)) then
    LUDPComponent1.SendMessage(Msg);
end;

(*
 *  Example message received: ! 130 = x82 = b1000'0010
 *)

function ExtractRegisterDetails(input: String): Integer;
var
  i: Integer;
  S: String;
  B: Integer;
begin
  S := trim(input);
  i := length(s);  
  if ((i > 2) and (LeftStr(S, 1) = '!')) then
  begin
//    B := StrToInt(RightStr(S, i - 1)) and not 240;
    B:=2;
  end
  else
    B := 0;
  result := B;
end;

procedure TForm1.LUDPComponent1Receive(aSocket: TLSocket);
var
  s: String;
begin
  if aSocket.GetMessage(s) > 0 then // if we received anything (will be in s)
  begin
//    Writeln(s);                           // write the message received
//    Writeln('Host at: ', aSocket.PeerAddress); // and the address of sender
    memo1.Lines.Add('<'#09 + s);
    case MessageInd of
      5:
        begin
          Lna_gain.Position := ExtractRegisterDetails(s);
          Lna_gain.enabled := True;
          GetRegister(7);
        end;
      7:
        begin
          Mix_Gain.Position := ExtractRegisterDetails(s);
          Mix_Gain.enabled := True;
          GetRegister(12);
        end;
      12:
        begin
          Vga_gain.Position := ExtractRegisterDetails(s);
          Vga_gain.enabled := True;
          GetRegister(11);
        end;
      11:
        begin
          LPF.Position := ExtractRegisterDetails(s);
          LPF.enabled := True;
          GetRegister(27);
        end;
      27:
        begin
          LPNF.Position := 15 - (ExtractRegisterDetails(s) and (15 shr 4));
          LPNF.enabled := True;
          HPF.Position := 15 - ExtractRegisterDetails(s);
          HPF.enabled := True;
          GetRegister(10);
        end;
      15:
        begin
          FILT.Position := 15 - ExtractRegisterDetails(s);
          FILT.enabled := True;
          MessageInd := 0;
        end;
      else
      begin
        memo1.Lines.Add('u'#09 + s);
      end;
    end;
  end
    else
    begin
        memo1.Lines.Add('n'#09 + s);
    end;
end;

procedure TForm1.LUDPComponent1Error(const msg: string; aSocket: TLSocket);
begin
    memo1.Lines.Add('e'#09#09 + msg);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//  LUDPComponent1.Timeout := 100;
//##  LUDPComponent1.Active := True;
  FAddress := '127.0.0.1';
  FPort := 32323;
  LUDPComponent1.Host := FAddress;
  LUDPComponent1.Port := FPort; 
  LUDPComponent1.Connect(FAddress, FPort);
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  SendMessage('g '#09 + m_reg.Text);
end;

procedure TForm1.FormShow(Sender: TObject);
begin  
  FAddress := '127.0.0.1';
  FPort := 32323;
  LUDPComponent1.Host := FAddress;
  LUDPComponent1.Port := FPort;
  GetSliderPositions();
end;                                     

procedure TForm1.GetRegister(Reg: String);
begin
  GetRegister(StrToInt(Reg));
end;

procedure TForm1.GetRegister(Reg: Integer);
var
  B: Byte;
  i: Integer;
  received_data: shortString;
  S: Array [0..UDP_BUFFER_SIZE] of Char;
begin
//  SetLength(received_data, UDP_BUFFER_SIZE);
  MessageInd := Reg;
  SendMessage('g '#9 + IntToStr(Reg));
end;

procedure TForm1.GetSliderPositions();
begin
  GetRegister(5);
// results and remaining sliders are set in asynchronous response
end;

procedure TForm1.Lna_gainChange(Sender: TObject);
begin
  SendMessage('s '#9'5 '#9 + IntToStr(Lna_gain.Position) + ' 15');
end;

procedure TForm1.Mix_GainChange(Sender: TObject);
begin
  SendMessage('s 7 ' + IntToStr(Mix_Gain.Position) + ' 15');
end;

procedure TForm1.Vga_gainChange(Sender: TObject);
begin
  SendMessage('s 12 ' + IntToStr(Vga_gain.Position) + ' 159');
end;

procedure TForm1.LPFChange(Sender: TObject);
begin
  SendMessage('s 11 ' + IntToStr(LPF.Position) + ' 15');
end;

procedure TForm1.LPNFChange(Sender: TObject);
begin
  SendMessage('s 27 ' + IntToStr((15 - LPNF.Position) shl 4) + ' ' +
    IntToStr(15 shl 4));
end;

procedure TForm1.HPFChange(Sender: TObject);
begin
  SendMessage('s 27 ' + IntToStr(15 - HPF.Position) + ' 15');
end;

procedure TForm1.FILTChange(Sender: TObject);
begin
  SendMessage('s 10 ' + IntToStr(15 - FILT.Position) + ' 15');
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  SendMessage('s ' + m_reg.Text + ' ' + m_value.Text + ' ' + m_mask.Text);
end;

end.
