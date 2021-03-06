unit fpcupdeluxemainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil,
  Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Types,
  SynEdit, SynEditPopup, Buttons, Menus, installerManager;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button7: TButton;
    Button8: TButton;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    StatusMessage: TEdit;
    TrunkBtn: TBitBtn;
    NPBtn: TBitBtn;
    FixesBtn: TBitBtn;
    StableBtn: TBitBtn;
    OldBtn: TBitBtn;
    DinoBtn: TBitBtn;
    FeaturesBtn: TBitBtn;
    mORMotBtn: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    CheckVerbosity: TCheckBox;
    Edit1: TEdit;
    Panel1: TPanel;
    RealFPCURL: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    ListBox3: TListBox;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RealLazURL: TEdit;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SynEdit1: TSynEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure SynEdit1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure SynEdit1SpecialLineColors(Sender: TObject; Line: integer;
      var Special: boolean; var FG, BG: TColor);
    procedure QuickBtnClick(Sender: TObject);
  private
    { private declarations }
    FPCupManager:TFPCupManager;
    oldoutput: TextFile;
    sInstallDir:string;
    sStatus:string;
    procedure DisEnable(Sender: TObject;value:boolean);
    procedure Edit1Change(Sender: TObject);
    procedure PrepareRun;
    function RealRun:boolean;
    function GetFPCUPSettings(IniFile:string):boolean;
    function SetFPCUPSettings(IniFile:string):boolean;
    procedure AddMessage(aMessage:string);
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  AboutFrm,
  extrasettings,
  IniFiles,
  StrUtils,
  installerUniversal,
  fpcuputil,
  {$ifdef MSWINDOWS}
  processutils,
  {$endif}
  synedittext;

Const
  DELUXEFILENAME='fpcupdeluxe.ini';
  NEWPASCALGITREPO='https://github.com/newpascal';
  FPCUPGITREPO=NEWPASCALGITREPO+'/fpcupdeluxe';
  FPCUPWINBINSURL=FPCUPGITREPO+'/releases/download/wincrossbins_v1.0';
  FPCUPLIBSURL=FPCUPGITREPO+'/releases/download/crosslibs_v1.0';
  FPCUPDELUXEVERSION='1.00a';

resourcestring
  CrossGCCMsg =
       '{$ifdef Linux}'+ sLineBreak +
       '  {$ifdef FPC_CROSSCOMPILING}'+ sLineBreak +
       '    {$linklib libc_nonshared.a}'+ sLineBreak +
       '  {$endif}'+ sLineBreak +
       '{$endif}';

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  SortedModules: TStringList;
  i:integer;
  s:string;
begin
  Self.Caption:='Lazarus and FPC installer and updater V'+FPCUPDELUXEVERSION+' based on fpcup'+RevisionStr+' ('+VersionDate+') for '+
                lowercase({$i %FPCTARGETCPU%})+'-'+lowercase({$i %FPCTARGETOS%});

  sStatus:='Sitting and waiting';

  oldoutput := System.Output;
  AssignSynEdit(System.Output, SynEdit1);
  Reset(System.Input);
  Rewrite(System.Output);

  AddMessage('Welcome @ fpclupdeluxe.');
  AddMessage('');

  FPCupManager:=TFPCupManager.Create;

  {$IFDEF MSWINDOWS}
  sInstallDir:='C:\fpcupdeluxe';
  {$ELSE}
  sInstallDir:='~/fpcupdeluxe';
  {$ENDIF}

  {$ifdef DARWIN}
  // we could have started from with an .app , so goto the basedir ... not sure if realy needed, but to be sure.
  SetCurrentDir(ExcludeTrailingPathDelimiter(SafeGetApplicationPath));
  {$endif}

  // get last used install directory, proxy and visual settings
  with TIniFile.Create(SafeGetApplicationPath+DELUXEFILENAME) do
  try
    sInstallDir:=ReadString('General','InstallDirectory',sInstallDir);
    CheckVerbosity.Checked:=ReadBool('General','Verbose',True);
    FPCupManager.HTTPProxyHost:=ReadString('ProxySettings','HTTPProxyURL','');
    FPCupManager.HTTPProxyPort:=ReadInteger('ProxySettings','HTTPProxyPort',8080);
    FPCupManager.HTTPProxyUser:=ReadString('ProxySettings','HTTPProxyUser','');
    FPCupManager.HTTPProxyPassword:=ReadString('ProxySettings','HTTPProxyPass','');
    SynEdit1.Font.Size := ReadInteger('General','CommandFontSize',SynEdit1.Font.Size);
    if ReadBool('General','Maximized',False) then
    begin
      Self.WindowState:=wsMaximized;
    end
    else
    begin
      Self.WindowState:=wsNormal;
      Self.Top := ReadInteger('General','Top',Self.Top);
      Self.Left := ReadInteger('General','Left',Self.Left);
      Self.Width := ReadInteger('General','Width',Self.Width);
      Self.Height := ReadInteger('General','Height',Self.Height);
    end;
  finally
    Free;
  end;

  sInstallDir:=ExcludeTrailingPathDelimiter(SafeExpandFileName(sInstallDir));

  FPCupManager.ConfigFile:=SafeGetApplicationPath+installerUniversal.CONFIGFILENAME;

  SaveInisFromResource(SafeGetApplicationPath+installerUniversal.SETTTINGSFILENAME,'settings_ini');
  SaveInisFromResource(SafeGetApplicationPath+installerUniversal.CONFIGFILENAME,'fpcup_ini');

  FPCupManager.LoadFPCUPConfig;

  FPCupManager.FPCURL:='default';
  FPCupManager.LazarusURL:='default';
  FPCupManager.Verbose:=true;

  {$IF defined(BSD) and not defined(DARWIN)}
  FPCupManager.PatchCmd:='gpatch';
  {$ELSE}
  FPCupManager.PatchCmd:='patch';
  {$ENDIF MSWINDOWS}

  SortedModules:=TStringList.Create;
  try
    for i:=0 to FPCupManager.ModulePublishedList.Count-1 do
    begin
      s:=FPCupManager.ModulePublishedList[i];
      // tricky ... get out the modules that are packages only
      // not nice, but needed to keep list clean of internal commands
      if (FPCupManager.ModulePublishedList.IndexOf(s+'clean')<>-1)
          AND (FPCupManager.ModulePublishedList.IndexOf(s+'uninstall')<>-1)
          AND (s<>'FPC')
          AND (s<>'lazarus')
          AND (FPCupManager.ModuleEnabledList.IndexOf(s)=-1)
          then
      begin
        SortedModules.Add(s);
      end;
    end;
    listbox3.Items.AddStrings(SortedModules);

  finally
    SortedModules.Free;
  end;

  listbox1.Items.CommaText:=installerUniversal.GetAlias('fpcURL','list');
  listbox2.Items.CommaText:=installerUniversal.GetAlias('lazURL','list');

  Edit1.Text:=sInstallDir;
  // set change here, to prevent early firing
  Edit1.OnChange:=@Edit1Change;

  // localize FPCUPSettings if possible
  if (NOT GetFPCUPSettings(IncludeTrailingPathDelimiter(sInstallDir)+DELUXEFILENAME))
     then GetFPCUPSettings(SafeGetApplicationPath+DELUXEFILENAME);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPCupManager);
  (* using CloseFile will ensure that all pending output is flushed *)
  CloseFile(System.Output);
  System.Output := oldoutput;
end;

procedure TForm1.FormResize(Sender: TObject);
var
  w:integer;
begin
  w:=(SynEdit1.Width DIV 2);
  RealFPCURL.Width:=(w-4);
  RealLazURL.Width:=RealFPCURL.Width;
  RealLazURL.Left:=RealFPCURL.Left+(w+4);
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  ShowAboutForm;
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  if (RadioGroup1.ItemIndex<>-1) AND (RadioGroup1.Items[RadioGroup1.ItemIndex]='jvm') then
  begin
    RadioGroup2.ItemIndex:=-1;
    RadioGroup2.Enabled:=false;
  end
  else RadioGroup2.Enabled:=true;
end;

procedure TForm1.RadioGroup2Click(Sender: TObject);
begin
  if (RadioGroup2.ItemIndex<>-1) AND (RadioGroup2.Items[RadioGroup2.ItemIndex]='java') then
  begin
    RadioGroup1.ItemIndex:=-1;
    RadioGroup1.Enabled:=false;
  end
  else RadioGroup1.Enabled:=true;
end;

procedure TForm1.SynEdit1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ssCtrl in Shift then
  begin
    if (WheelDelta>0) AND (SynEdit1.Font.Size<48) then SynEdit1.Font.Size:=SynEdit1.Font.Size+1;
    if (WheelDelta<0)  AND (SynEdit1.Font.Size>2) then SynEdit1.Font.Size:=SynEdit1.Font.Size-1;
  end;
end;


procedure TForm1.SynEdit1SpecialLineColors(Sender: TObject; Line: integer;
  var Special: boolean; var FG, BG: TColor);
function ExistWordInString(aString:pchar;aSearchString:string;aSearchOptions: TStringSearchOptions): Boolean;
var
  Size : Integer;
begin
  Size:=StrLen(aString);
  Result := SearchBuf(aString, Size, 0, 0, aSearchString, aSearchOptions)<>nil;
end;
var
  s:string;
  x:integer;
begin
  s:=SynEdit1.Lines[Line-1];

  if (ExistWordInString(PChar(s),'checkout',[soWholeWord,soDown])) AND (ExistWordInString(PChar(s),'--quiet',[soWholeWord,soDown])) then
  begin
    Memo1.Lines.Append('Performing a checkout ... please wait, could take some time.');
  end;

  // github error
  if (ExistWordInString(PChar(s),'429 too many requests',[soDown])) then
  begin
    FG      := clRed;   //Text Color
    BG      := clNavy;  //BackGround
    Special := True;    //Must be true
    // add help into summary memo
    Memo1.Lines.Append('GitHub blocked us due to too many download requests.');
    Memo1.Lines.Append('This will last for an hour, so please wait and be patient.');
    Memo1.Lines.Append('After this period, please re-run fpcupdeluxe.');
  end;

  // svn connection error
  if (ExistWordInString(PChar(s),'unable to connect to a repository at url',[soDown])) then
  begin
    FG      := clRed;   //Text Color
    BG      := clNavy;  //BackGround
    Special := True;    //Must be true
    // add help into summary memo
    Memo1.Lines.Append('SVN could not connect to the desired repository. URL:');
    Memo1.Lines.Append(FPCupManager.FPCURL);
    Memo1.Lines.Append('Please check your connection. Or run the command to try yourself:');
    Memo1.Lines.Append(SynEdit1.Lines[Line-2]);
  end;

  if ExistWordInString(PChar(s),'svn: e',[soDown]) then
  begin
    FG      := clFuchsia;
    BG      := clBlack;
    Special := True;
  end;

  if ExistWordInString(PChar(s),'Executing :',[soWholeWord,soDown]) then
  begin
    FG      := clAqua;
    BG      := clBlack;
    Special := True;
  end;

  if (ExistWordInString(PChar(s),'A',[soWholeWord])) OR (ExistWordInString(PChar(s),'U',[soWholeWord])) then
  begin
    FG      := clSkyBlue;
    BG      := clBlack;
    Special := True;
  end;

  if ExistWordInString(PChar(s),'info:',[soWholeWord,soDown]) then
  begin
    FG      := clYellow;
    BG      := clBlack;
    Special := True;
  end;

  if ExistWordInString(PChar(s),'Please wait:',[soWholeWord,soDown]) then
  begin
    FG      := clBlue;
    BG      := clWhite;
    Special := True;
  end;


  if (ExistWordInString(PChar(s),'warning:',[soWholeWord,soDown])) OR (ExistWordInString(PChar(s),'hint:',[soWholeWord,soDown])) then
  begin
    FG      := clGreen;
    BG      := clBlack;
    Special := True;
  end;

  if (ExistWordInString(PChar(s),'error:',[soWholeWord,soDown])) OR  (ExistWordInString(PChar(s),'fatal:',[soWholeWord,soDown])) then
  begin
    // skip git fatal messages ... they are not that fatal !
    if (Pos('fatal: not a git repository',lowercase(s))=0) then
    begin
      FG      := clRed;
      BG      := clBlue;
      Special := True;
      // filter on fatal
      if (Pos('fatal:',lowercase(s))>0) then
      begin
        Memo1.Lines.Append(s);
        Memo1.Lines.Append(SynEdit1.Lines[Line-2]);
      end;
      if (Pos('error: 256',lowercase(s))>0) AND (Pos('svn',lowercase(s))>0) then
      begin
        Memo1.Lines.Append('We have had a SVN connection failure. Just start again !');
        Memo1.Lines.Append(SynEdit1.Lines[Line-2]);
      end;
    end;
  end;

  // linker error
  if (ExistWordInString(PChar(s),'/usr/bin/ld: cannot find',[])) then
  begin
    FG      := clRed;
    BG      := clNavy;
    Special := True;
    x:=Pos('-l',s);
    if x>0 then
    begin
      // add help into summary memo
      Memo1.Lines.Append('Missing library: lib'+Copy(s,x+2,MaxInt));
    end;
  end;

  // diskspace error
  if (ExistWordInString(PChar(s),'Stream write error',[])) then
  begin
    FG      := clRed;
    BG      := clNavy;
    Special := True;
    // add help into summary memo
    Memo1.Lines.Append('There is not enough diskspace to finish this operation.');
    Memo1.Lines.Append('Please free some space and re-run fpcupdeluxe.');
  end;


end;

procedure TForm1.QuickBtnClick(Sender: TObject);
var
  s,FPCURL,LazarusURL:string;
  i:integer;
  Revision,Branch:string;
begin
  DisEnable(Sender,False);
  try
    PrepareRun;

    Revision:='';
    Branch:='';

    if Sender=TrunkBtn then
    begin
      s:='Going to install both FPC trunk and Lazarus trunk';
      FPCURL:='trunk';
      LazarusURL:='trunk';
    end;

    if Sender=NPBtn then
    begin
      s:='Going to install NewPascal';
      FPCURL:='newpascal';
      LazarusURL:='newpascal';
      //Revision:='69e7216e7be1f42045a70a6f1c453f685da8b84b';
      Branch:='release';
      //FPCupManager.IncludeModules:='mORMotFPC,zeos';
    end;

    if Sender=FixesBtn then
    begin
      s:='Going to install FPC fixes and Lazarus fixes';
      FPCURL:='fixes';
      LazarusURL:='fixes';
    end;

    if Sender=StableBtn then
    begin
      s:='Going to install FPC stable and Lazarus stable';
      FPCURL:='stable';
      LazarusURL:='stable';
    end;

    if Sender=OldBtn then
    begin
      s:='Going to install FPC 2.6.4 and Lazarus 1.4 ';
      FPCURL:='2.6.4';
      LazarusURL:='1.4';
    end;

    if Sender=DinoBtn then
    begin
      s:='Going to install FPC 2.0.2 and Lazarus 0.9.16 ';
      FPCURL:='2.0.2';
      //LazarusURL:='0.9.4';
      LazarusURL:='0.9.16';
      FPCupManager.OnlyModules:='fpc,oldlazarus';
    end;

    if Sender=FeaturesBtn then
    begin
      ShowMessage('Not yet working ... too many included packages will give fatal errors.');
      exit;
      {
      s:='Going to install FPC trunk and Lazarus trunk with extras ';
      FPCURL:='trunk';
      LazarusURL:='trunk';
      FPCupManager.IncludeModules:='mORMotFPC,lazgoogleapis,virtualtreeview,lazpaint,bgracontrols,uecontrols,ECControls,zeos,cudatext,indy,lnet,lamw,mupdf,tiopf,abbrevia,uos,wst,anchordocking,simplegraph,cm630commons,turbobird';
      }
    end;

    if Sender=mORMotBtn then
    begin
      s:='Going to install de special version of mORMot for FPC ';
      FPCURL:='skip';
      LazarusURL:='skip';
      FPCupManager.OnlyModules:='mORMotFPC';
      //FPCupManager.OnlyModules:='mORMotFPC,zeos';
    end;

    i:=ListBox1.Items.IndexOf(FPCURL);
    if i<>-1 then ListBox1.Selected[i]:=true;
    i:=ListBox2.Items.IndexOf(LazarusURL);
    if i<>-1 then ListBox2.Selected[i]:=true;

    FPCupManager.FPCURL:=FPCURL;
    FPCupManager.LazarusURL:=LazarusURL;

    if NOT Form2.IncludeHelp then
    begin
      FPCupManager.SkipModules:='helpfpc,helplazarus';
    end;

    AddMessage(s+'.');

    sStatus:=s;

    RealRun;

  finally
    DisEnable(Sender,True);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  FModuleList: TStringList;
  i:integer;
begin
  if (ListBox1.ItemIndex=-1) or (ListBox2.ItemIndex=-1) then
  begin
    ShowMessage('Please select a FPC and Lazarus version first');
    exit;
  end;
  DisEnable(Sender,False);
  try
    PrepareRun;
    AddMessage('Going to install/update FPC and Lazarus with given options.');
    sStatus:='Going to install/update FPC and Lazarus.';
    if Form2.UpdateOnly then
    begin
      FPCupManager.OnlyModules:='FPCCleanAndBuildOnly,LazCleanAndBuildOnly';
      FModuleList:=TStringList.Create;
      try
        GetModuleEnabledList(FModuleList);
        // also include enabled modules (packages) when rebuilding Lazarus
        if FModuleList.Count>0 then FPCupManager.OnlyModules:=FPCupManager.OnlyModules+','+FModuleList.CommaText;
      finally
        FModuleList.Free;
      end;
    end;
    RealRun;
  finally
    DisEnable(Sender,True);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i:integer;
  modules:string;
begin
  DisEnable(Sender,False);
  try
    PrepareRun;

    FPCupManager.ExportOnly:=(NOT Form2.CheckPackageRepo.Checked);

    modules:='';
    for i:=0 to ListBox3.Count-1 do
    begin
      if ListBox3.Selected[i] then modules:=modules+ListBox3.Items[i]+',';
    end;

    if Length(modules)>0 then
    begin
      // delete stale trailing comma
      Delete(modules,Length(modules),1);
      FPCupManager.OnlyModules:=modules;
      AddMessage('Limiting installation/update to '+FPCupManager.OnlyModules);
      AddMessage('');
      AddMessage('Going to install selected modules with given options.');
      sStatus:='Going to install/update selected modules.';
      RealRun;
    end;
  finally
    FPCupManager.ExportOnly:=(NOT Form2.CheckRepo.Checked);
    DisEnable(Sender,True);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  SelectDirectoryDialog1.InitialDir:=sInstallDir;
  if SelectDirectoryDialog1.Execute then
  begin
    sInstallDir:=SelectDirectoryDialog1.FileName;
    Edit1.Text:=sInstallDir;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ListBox3.ClearSelection;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  aDownLoader: TDownLoader;
  URL,DownloadURL,TargetFile,UnZipper:string;
  success:boolean;
begin
  if (RadioGroup1.ItemIndex=-1) and (RadioGroup2.ItemIndex=-1) then
  begin
    ShowMessage('Please select a CPU and OS target first');
    exit;
  end;

  PrepareRun;

  if RadioGroup1.ItemIndex<>-1 then FPCupManager.CrossCPU_Target:=RadioGroup1.Items[RadioGroup1.ItemIndex];
  if RadioGroup2.ItemIndex<>-1 then FPCupManager.CrossOS_Target:=RadioGroup2.Items[RadioGroup2.ItemIndex];

  {$ifndef FreeBSD}
  if (FPCupManager.CrossOS_Target='freebsd') then
  begin
    if (MessageDlg('Be forwarned: this will only work with FPC>=3.1.1 (trunk, NewPascal).' + sLineBreak +
               'See: http://bugs.freepascal.org/view.php?id=30908' + sLineBreak +
               'Do you want to continue ?'
               ,mtConfirmation,[mbYes, mbNo],0)<>mrYes) then
               begin
                 Memo1.Lines.Append('See: http://bugs.freepascal.org/view.php?id=30908');
                 exit;
               end;
  end;
  {$endif}

  {$ifdef MSWINDOWS}
  if (FPCupManager.CrossOS_Target='linux') then
  begin
    ShowMessage('Be forwarned: you need to add some extra linking when cross-compiling.' + sLineBreak + CrossGCCMsg);
    Memo1.Lines.Append(CrossGCCMsg);
  end;
  {$endif}

  if (FPCupManager.CrossCPU_Target='jvm') then FPCupManager.CrossOS_Target:='java';
  if (FPCupManager.CrossOS_Target='java') then FPCupManager.CrossCPU_Target:='jvm';

  if FPCupManager.CrossOS_Target='windows' then
  begin
    if FPCupManager.CrossCPU_Target='i386' then FPCupManager.CrossOS_Target:='win32';
    if FPCupManager.CrossCPU_Target='x86_64' then FPCupManager.CrossOS_Target:='win64';
  end;

  if (FPCupManager.CrossCPU_Target='') then
  begin
    ShowMessage('Please select a CPU target first');
    FPCupManager.CrossOS_Target:=''; // cleanup
    exit;
  end;

  if (FPCupManager.CrossOS_Target='') then
  begin
    ShowMessage('Please select an OS target first');
    FPCupManager.CrossCPU_Target:=''; // cleanup
    exit;
  end;

  DisEnable(Sender,False);

  try
    if (FPCupManager.CrossCPU_Target='arm') then
    begin
      if (FPCupManager.CrossOS_Target='wince') then
      begin
        //FPCupManager.CrossOPT:='-CpARMV6 -CfSoft ';
        FPCupManager.CrossOPT:='-CpARMV6 ';
      end
      else
      begin
        // default: armhf
        FPCupManager.FPCOPT:='-dFPC_ARMHF ';
        FPCupManager.CrossOPT:='-CpARMV7A -CfVFPV3 -OoFASTMATH -CaEABIHF ';
      end;
    end;

    // use the available source to build the cross-compiler ... change nothing about source and URL !!
    FPCupManager.OnlyModules:='FPCCleanOnly,FPCBuildOnly';

    if Form2.IncludeLCL then
    begin
      if (FPCupManager.CrossOS_Target<>'java') AND (FPCupManager.CrossOS_Target<>'android') then
      begin
        FPCupManager.OnlyModules:=FPCupManager.OnlyModules+',LCLCross';
      end;
    end;

    FPCupManager.FPCURL:='skip';
    FPCupManager.LazarusURL:='skip';

    FPCupManager.CrossLibraryDirectory:=Form2.GetLibraryDirectory(FPCupManager.CrossCPU_Target,FPCupManager.CrossOS_Target);
    FPCupManager.CrossToolsDirectory:=Form2.GetToolsDirectory(FPCupManager.CrossCPU_Target,FPCupManager.CrossOS_Target);

    AddMessage('Going to install a cross-compiler from current sources.');

    sStatus:='Going to build a cross-compiler for '+FPCupManager.CrossOS_Target+'-'+FPCupManager.CrossCPU_Target;
    if FPCupManager.FPCOPT<>'' then sStatus:=sStatus+' ('+FPCupManager.FPCOPT+')';
    sStatus:=sStatus+'.';

    if NOT RealRun then
    begin

      // perhaps there were no libraries and/or binutils ... download them (if available) from fpcup on GitHub
      // for the moment windows only ... will change in near future

      {$ifdef MSWINDOWS}

      URL:='';

      if FPCupManager.CrossOS_Target='linux' then
      begin
        if FPCupManager.CrossCPU_Target='arm' then URL:='LinuxARM.rar';
        if FPCupManager.CrossCPU_Target='aarch64' then URL:='LinuxAarch64.rar';
        if FPCupManager.CrossCPU_Target='i386' then URL:='Linuxi386.rar';
        if FPCupManager.CrossCPU_Target='x86_64' then URL:='Linuxx64.rar';
      end;
      if FPCupManager.CrossOS_Target='freebsd' then
      begin
        if FPCupManager.CrossCPU_Target='i386' then URL:='FreeBSDi386.rar';
        if FPCupManager.CrossCPU_Target='x86_64' then URL:='FreeBSDx64.rar';
      end;

      if FPCupManager.CrossOS_Target='wince' then
      begin
        if FPCupManager.CrossCPU_Target='arm' then URL:='WinceARM.rar';
      end;
      if FPCupManager.CrossOS_Target='android' then
      begin
        if FPCupManager.CrossCPU_Target='arm' then URL:='AndroidARM.rar';
      end;

      // tricky ... reset URL in case the binutils and libs are already there ... to exit this retry ... ;-)
      if (DirectoryExists(IncludeTrailingPathDelimiter(sInstallDir)+
                         'cross'+
                         DirectorySeparator+
                         'bin'+
                         DirectorySeparator+
                         FPCupManager.CrossCPU_Target+
                         '-'+
                         FPCupManager.CrossOS_Target))
          AND
          (DirectoryExists(IncludeTrailingPathDelimiter(sInstallDir)+
                                   'cross'+
                                   DirectorySeparator+
                                   'lib'+
                                   DirectorySeparator+
                                   FPCupManager.CrossCPU_Target+
                                   '-'+
                                   FPCupManager.CrossOS_Target))
          then URL:='';

      if URL<>'' then
      begin
        AddMessage('Please wait: Going to download the right cross-tools. Can (will) take some time !');
        DownloadURL:=FPCUPWINBINSURL+'/'+'WinCrossBins'+URL;
        AddMessage('Please wait: Going to download the binary-tools from '+DownloadURL);
        TargetFile := SysUtils.GetTempFileName;
        aDownLoader:=TDownLoader.Create;
        try
          success:=aDownLoader.getFile(DownloadURL,TargetFile);
          if (NOT success) then // try only once again in case of error
          begin
            AddMessage('Error while trying to download '+URL+'. Trying once again.');
            SysUtils.DeleteFile(TargetFile); // delete stale targetfile
            success:=aDownLoader.getFile(DownloadURL,TargetFile);
          end;
        finally
          aDownLoader.Destroy;
        end;
        if success then
        begin
          AddMessage('Successfully downloaded binary-tools.');
          AddMessage('Going to extract them into '+IncludeTrailingPathDelimiter(sInstallDir));
          success:=(ExecuteCommand('"C:\Program Files (x86)\WinRAR\WinRAR.exe" x '+TargetFile+' "'+IncludeTrailingPathDelimiter(sInstallDir)+'"',true)=0);
          if (NOT success) then
          begin
            UnZipper := IncludeTrailingPathDelimiter(FPCupManager.MakeDirectory) + 'unrar\bin\unrar.exe';
            success:=(ExecuteCommand(UnZipper + ' x "' + TargetFile + '" "' + IncludeTrailingPathDelimiter(sInstallDir) + '"',true)=0);
          end;
        end;
        SysUtils.DeleteFile(TargetFile);

        DownloadURL:=FPCUPLIBSURL+'/'+'CrossLibs'+URL;
        AddMessage('Please wait: Going to download the libraries from '+DownloadURL);
        TargetFile := SysUtils.GetTempFileName;
        aDownLoader:=TDownLoader.Create;
        try
          success:=aDownLoader.getFile(DownloadURL,TargetFile);
          if (NOT success) then // try only once again in case of error
          begin
            AddMessage('Error while trying to download '+URL+'. Trying once again.');
            SysUtils.DeleteFile(TargetFile); // delete stale targetfile
            success:=aDownLoader.getFile(DownloadURL,TargetFile);
          end;
        finally
          aDownLoader.Destroy;
        end;
        if success then
        begin
          AddMessage('Successfully downloaded the libraries.');
          AddMessage('Going to extract them into '+IncludeTrailingPathDelimiter(sInstallDir));
          success:=(ExecuteCommand('"C:\Program Files (x86)\WinRAR\WinRAR.exe" x '+TargetFile+' "'+IncludeTrailingPathDelimiter(sInstallDir)+'"',true)=0);
          if (NOT success) then
          begin
            UnZipper := IncludeTrailingPathDelimiter(FPCupManager.MakeDirectory) + 'unrar\bin\unrar.exe';
            success:=(ExecuteCommand(UnZipper + ' x "' + TargetFile + '" "' + IncludeTrailingPathDelimiter(sInstallDir) + '"',true)=0);
          end;
        end;

        if success then
        begin
          AddMessage('Successfully extracted cross-tools.');
          // run again with the correct libs and binutils
          label1.Font.Color:=clDefault;
          label2.Font.Color:=clDefault;
          sStatus:='Got all tools now. New try building a cross-compiler for '+FPCupManager.CrossOS_Target+'-'+FPCupManager.CrossCPU_Target;
          FPCupManager.Sequencer.ResetAllExecuted;
          RealRun;
        end;
        SysUtils.DeleteFile(TargetFile);

        if (NOT success) then AddMessage('No luck in getting then cross-tools ... aborting.');
      end
      else
      begin
        AddMessage('Building cross-tools failed ... ??? ... aborting.');
      end;

      {$endif}
    end;

  finally
    DisEnable(Sender,True);
  end;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  if (ListBox1.ItemIndex=-1) then
  begin
    ShowMessage('Please select a FPC version first');
    exit;
  end;
  DisEnable(Sender,False);
  try
    PrepareRun;

    FPCupManager.OnlyModules:='fpc';
    FPCupManager.LazarusURL:='skip';

    if NOT Form2.IncludeHelp then
    begin
      FPCupManager.SkipModules:='helpfpc';
    end;

    sStatus:='Going to install/update FPC only.';

    RealRun;
  finally
    DisEnable(Sender,True);
  end;
end;

procedure TForm1.Button7Click(Sender: TObject);
var
  i:integer;
begin
  Form2.ShowModal;
  if Form2.ModalResult=mrOk then
  begin
    FPCupManager.ExportOnly:=(NOT Form2.Repo);
    FPCupManager.HTTPProxyPort:=Form2.HTTPProxyPort;
    FPCupManager.HTTPProxyHost:=Form2.HTTPProxyHost;
    FPCupManager.HTTPProxyUser:=Form2.HTTPProxyUser;
    FPCupManager.HTTPProxyPassword:=Form2.HTTPProxyPass;
  end;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  SynEdit1.ClearAll;
  Memo1.Clear;
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  sInstallDir:=Edit1.Text;
  if GetFPCUPSettings(IncludeTrailingPathDelimiter(sInstallDir)+DELUXEFILENAME) then
  begin
    AddMessage('Got settings from install directory');
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // set last used install directory
  with TIniFile.Create(SafeGetApplicationPath+DELUXEFILENAME) do
  try
    WriteString('General','InstallDirectory',sInstallDir);

    WriteBool('General','Verbose',CheckVerbosity.Checked);

    Application.MainForm.Cursor:=crHourGlass;

    WriteString('ProxySettings','HTTPProxyURL',FPCupManager.HTTPProxyHost);
    WriteInteger('ProxySettings','HTTPProxyPort',FPCupManager.HTTPProxyPort);
    WriteString('ProxySettings','HTTPProxyUser',FPCupManager.HTTPProxyUser);
    WriteString('ProxySettings','HTTPProxyPass',FPCupManager.HTTPProxyPassword);

    WriteInteger('General','CommandFontSize',SynEdit1.Font.Size);

    if Self.WindowState=wsNormal then
    begin
      WriteInteger('General','Top',Self.Top);
      WriteInteger('General','Left',Self.Left);
      WriteInteger('General','Width',Self.Width);
      WriteInteger('General','Height',Self.Height);
      WriteBool('General','Maximized',False);
    end
    else
    begin
      WriteBool('General','Maximized',True);
    end;

  finally
    Free;
  end;

  // localize FPCUPSettings if possible
  if (NOT SetFPCUPSettings(IncludeTrailingPathDelimiter(sInstallDir)+DELUXEFILENAME))
     then SetFPCUPSettings(SafeGetApplicationPath+DELUXEFILENAME);

  CloseAction:=caFree;
end;

procedure TForm1.DisEnable(Sender: TObject;value:boolean);
begin
  //if Sender<>Button1 then
  Button1.Enabled:=value;
  //if Sender<>Button2 then
  Button2.Enabled:=value;
  Button3.Enabled:=value;
  Button4.Enabled:=value;
  Button5.Enabled:=value;
  Button6.Enabled:=value;
  Button7.Enabled:=value;
  Button8.Enabled:=value;

  ListBox1.Enabled:=value;
  ListBox2.Enabled:=value;
  ListBox3.Enabled:=value;

  Edit1.Enabled:=value;
  RadioGroup1.Enabled:=value;
  RadioGroup2.Enabled:=value;
  CheckVerbosity.Enabled:=value;

  TrunkBtn.Enabled:=value;
  NPBtn.Enabled:=value;
  FixesBtn.Enabled:=value;
  StableBtn.Enabled:=value;
  OldBtn.Enabled:=value;
  DinoBtn.Enabled:=value;
  FeaturesBtn.Enabled:=value;
  mORMotBtn.Enabled:=value;
end;

procedure TForm1.PrepareRun;
var
  s:string;
begin
  label1.Font.Color:=clDefault;
  label2.Font.Color:=clDefault;

  FPCupManager.Sequencer.ResetAllExecuted;

  FPCupManager.OnlyModules:='';
  FPCupManager.IncludeModules:='';
  FPCupManager.SkipModules:='';
  FPCupManager.CrossCPU_Target:='';
  FPCupManager.CrossOS_Target:='';
  FPCupManager.CrossOS_SubArch:='';

  FPCupManager.LazarusOpt:='';
  FPCupManager.FPCOPT:='';
  FPCupManager.CrossOPT:='';

  FPCupManager.LazarusDesiredRevision:='';
  FPCupManager.FPCDesiredRevision:='';

  FPCupManager.CrossLibraryDirectory:='';
  FPCupManager.CrossToolsDirectory:='';

  FPCupManager.Verbose:=CheckVerbosity.Checked;

  // set default values for FPC and Lazarus URL ... can still be changed inside the real run button onclicks
  FPCupManager.FPCURL:='default';
  FPCupManager.LazarusURL:='default';
  FPCupManager.FPCDesiredBranch:='';
  FPCupManager.LazarusDesiredBranch:='';

  sInstallDir:=ExcludeTrailingPathDelimiter(sInstallDir);

  FPCupManager.ShortCutNameFpcup:='fpcup_'+ExtractFileName(sInstallDir)+'_update';
  FPCupManager.ShortCutNameLazarus:='Lazarus_'+ExtractFileName(sInstallDir);

  sInstallDir:=sInstallDir+DirectorySeparator;

  {$IFDEF MSWINDOWS}
  FPCupManager.MakeDirectory:=sInstallDir+'fpcbootstrap';
  {$ELSE}
  FPCupManager.MakeDirectory:='';
  {$ENDIF MSWINDOWS}
  FPCupManager.BootstrapCompilerDirectory:=sInstallDir+'fpcbootstrap';
  FPCupManager.FPCDirectory:=sInstallDir+'fpc';
  FPCupManager.LazarusDirectory:=sInstallDir+'lazarus';

  FPCupManager.LazarusPrimaryConfigPath:=sInstallDir+'config_'+ExtractFileName(FPCupManager.LazarusDirectory);

  FPCupManager.ExportOnly:=(NOT Form2.CheckRepo.Checked);

  RealFPCURL.Text:='';
  RealLazURL.Text:='';

  sStatus:='Sitting and waiting';
  StatusMessage.Text:=sStatus;

  if (listbox1.ItemIndex<>-1) then
     FPCupManager.FPCURL:=listbox1.Items[listbox1.ItemIndex];

  if (listbox2.ItemIndex<>-1) then
     FPCupManager.LazarusURL:=listbox2.Items[listbox2.ItemIndex];

  Memo1.Lines.Clear;
end;

function TForm1.RealRun:boolean;
begin
  result:=false;

  StatusMessage.Text:=sStatus;

  AddMessage('FPCUP(deluxe) is starting up.');
  AddMessage('');
  {$IFDEF MSWINDOWS}
  AddMessage('Binutils/make dir:  '+FPCupManager.MakeDirectory);
  {$ENDIF MSWINDOWS}
  AddMessage('Bootstrap dir:      '+FPCupManager.BootstrapCompilerDirectory);

  {$IF (defined(BSD)) and (not defined(Darwin))}
  FPCupManager.FPCOpt:=FPCupManager.FPCOpt+' -Fl/usr/local/lib';
  FPCupManager.LazarusOpt:=FPCupManager.LazarusOpt+' -Fl/usr/local/lib -Fl/usr/X11R6/lib';
  {$endif}

  if FPCupManager.FPCURL<>'SKIP' then
  begin

    if (Pos('trunk',lowercase(FPCupManager.FPCURL))>0) AND (NOT Form2.UseFreePascalSVN) then
    begin
      FPCupManager.FPCURL:=NEWPASCALGITREPO+'/freepascal.git';
      FPCupManager.FPCDesiredBranch:='freepascal';
    end;

    AddMessage('FPC URL:            '+FPCupManager.FPCURL);
    AddMessage('FPC options:        '+FPCupManager.FPCOPT);
    AddMessage('FPC directory:      '+FPCupManager.FPCDirectory);
    RealFPCURL.Text:=FPCupManager.FPCURL;
  end else RealFPCURL.Text:='Skipping FPC';

  if FPCupManager.LazarusURL<>'SKIP' then
  begin

    if (Pos('trunk',lowercase(FPCupManager.LazarusURL))>0) AND (NOT Form2.UseFreePascalSVN) then
    begin
      FPCupManager.LazarusURL:=NEWPASCALGITREPO+'/lazarus.git';
      FPCupManager.LazarusDesiredBranch:='lazarus';
    end;

    AddMessage('Lazarus URL:        '+FPCupManager.LazarusURL);
    AddMessage('Lazarus options:    '+FPCupManager.LazarusOPT);
    AddMessage('Lazarus directory:  '+FPCupManager.LazarusDirectory);
    RealLazURL.Text:=FPCupManager.LazarusURL;
  end else RealLazURL.Text:='Skipping Lazarus';

  AddMessage('Please stand back and enjoy !');
  AddMessage('');

  Application.ProcessMessages;

  sleep(1000);

  try
    result:=FPCupManager.Run;
    if (NOT result) then
    begin
      AddMessage('');
      AddMessage('');
      AddMessage('ERROR: Fpcupdeluxe failed.');
      label1.Font.Color:=clRed;
      label2.Font.Color:=clRed;
      StatusMessage.Text:='Hmmm, something went wrong ... have a good look at the command screen !';
    end
    else
    begin
      AddMessage('');
      AddMessage('');
      AddMessage('SUCCESS: Fpcupdeluxe ended without errors.');
      AddMessage('');
      if (FPCupManager.LazarusURL<>'SKIP') then
      begin
        {$ifdef MSWINDOWS}
        AddMessage('Fpcupdeluxe has created a desktop shortcut to start Lazarus.');
        AddMessage('Shortcut-name: '+FPCupManager.ShortCutNameLazarus);
        AddMessage('Lazarus by fpcupdeluxe MUST be started with this shortcut !!');
        {$else}
        AddMessage('Fpcupdeluxe has created a shortcut link in your home-directory to start Lazarus.');
        AddMessage('Shortcut-link: '+FPCupManager.ShortCutNameLazarus);
        AddMessage('Lazarus MUST be started with this link !!');
        AddMessage('Fpcupdeluxe has also (tried to) create a desktop shortcut with the same name.');
        {$endif}
        AddMessage('');
      end;
      label1.Font.Color:=clLime;
      label2.Font.Color:=clLime;
      StatusMessage.Text:='That went well !!!';
    end;
  except
    // just swallow exceptions
    StatusMessage.Text:='Got an unexpected exception ... don''t know what to do unfortunately.';
  end;
end;

function TForm1.GetFPCUPSettings(IniFile:string):boolean;
var
  s:string;
  i,j:integer;
  SortedModules:TStringList;
begin
  result:=FileExists(IniFile);

  if result then with TIniFile.Create(IniFile) do
  try

    FPCupManager.ExportOnly:=(NOT ReadBool('General','GetRepo',True));

    s:=ReadString('URL','fpcURL','');
    if TryStrToInt(s,i) then
    begin
      listbox1.ItemIndex:=i;
    end
    else
    begin
      j:=-1;
      for i:=0 to listbox1.Items.Count-1 do
      begin
        j:=listbox1.Items.IndexOf(s);
        if j<>-1 then break;
      end;
      listbox1.ItemIndex:=j;
    end;

    s:=ReadString('URL','lazURL','');
    if TryStrToInt(s,i) then
    begin
      listbox2.ItemIndex:=i;
    end
    else
    begin
      j:=-1;
      for i:=0 to listbox2.Items.Count-1 do
      begin
        j:=listbox2.Items.IndexOf(s);
        if j<>-1 then break;
      end;
      listbox2.ItemIndex:=j;
    end;

    listbox3.ClearSelection;
    SortedModules:=TStringList.Create;
    try
      SortedModules.CommaText:=ReadString('General','Modules','');
      for i:=0 to SortedModules.Count-1 do
      begin
        j:=listbox3.Items.IndexOf(SortedModules[i]);
        if j<>-1 then listbox3.Selected[j]:=true;
      end;
    finally
      SortedModules.Free;
    end;

  finally
    Free;
  end;

end;

function TForm1.SetFPCUPSettings(IniFile:string):boolean;
var
  i:integer;
  modules:string;
begin
  result:=DirectoryExists(ExtractFileDir(IniFile));

  if result then with TIniFile.Create(IniFile) do
  try
    // mmm, is this correct ?  See extrasettings !!
    WriteBool('General','GetRepo',(NOT FPCupManager.ExportOnly));

    if ListBox1.ItemIndex<>-1 then WriteString('URL','fpcURL',ListBox1.Items[ListBox1.ItemIndex]);
    if ListBox2.ItemIndex<>-1 then WriteString('URL','lazURL',ListBox2.Items[ListBox2.ItemIndex]);

    modules:='';
    for i:=0 to ListBox3.Count-1 do
    begin
      if ListBox3.Selected[i] then modules:=modules+ListBox3.Items[i]+',';
    end;
    // delete stale trailing comma, if any
    if Length(modules)>0 then
    Delete(modules,Length(modules),1);
    WriteString('General','Modules',modules);

  finally
    Free;
  end;

end;

procedure TForm1.AddMessage(aMessage:string);
begin
  //SynEdit1.Append(aMessage);
  SynEdit1.InsertTextAtCaret(aMessage+sLineBreak,scamAdjust);
  SynEdit1.CaretX:=0;
  Application.ProcessMessages;
end;

end.

