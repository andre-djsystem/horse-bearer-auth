unit Horse.BearerAuthentication;

{$IF DEFINED(FPC)}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
{$IF DEFINED(FPC)}
  SysUtils, StrUtils, base64, Classes,
{$ELSE}
  System.SysUtils, System.NetEncoding, System.Classes, System.StrUtils,
{$ENDIF}
  Horse, Horse.Commons;

const
  AUTHORIZATION = 'Authorization';

type
  IHorseBearerAuthenticationConfig = interface
    ['{DB16765F-156C-4BC1-8EDE-183CA9FE1985}']
    function Header(const AValue: string): IHorseBearerAuthenticationConfig; overload;
    function Header: string; overload;
    function SkipRoutes(const AValues: TArray<string>): IHorseBearerAuthenticationConfig; overload;
    function SkipRoutes: TArray<string>; overload;
  end;

  THorseBearerAuthenticationConfig = class(TInterfacedObject, IHorseBearerAuthenticationConfig)
  private
    FHeader: string;
    FSkipRoutes: TArray<string>;
    function Header(const AValue: string): IHorseBearerAuthenticationConfig; overload;
    function Header: string; overload;
    function SkipRoutes(const AValues: TArray<string>): IHorseBearerAuthenticationConfig; overload;
    function SkipRoutes: TArray<string>; overload;
  public
    constructor Create;
    class function New: IHorseBearerAuthenticationConfig;
  end;

type
  THorseBearerAuthentication = {$IF NOT DEFINED(FPC)} reference to {$ENDIF} function(const AToken: string): Boolean;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)} TNextProc {$ELSE} TProc {$ENDIF});
function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication): THorseCallback; overload;
function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication; const AHeaderConfig: string): THorseCallback; overload;
function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication; const AConfig: IHorseBearerAuthenticationConfig): THorseCallback; overload;
function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication; const AConfig: IHorseBearerAuthenticationConfig; const AHeaderConfig: string): THorseCallback; overload;


implementation

var
  Config: IHorseBearerAuthenticationConfig;
  ValidToken: THorseBearerAuthentication;
  Header: string;

function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication): THorseCallback;
begin
  Result := HorseBearerAuthentication(AValidToken, THorseBearerAuthenticationConfig.New, AUTHORIZATION);
end;

function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication;
  const AHeaderConfig: string): THorseCallback;
begin
  Result := HorseBearerAuthentication(AValidToken, THorseBearerAuthenticationConfig.New, AHeaderConfig);
end;

function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication; const AConfig: IHorseBearerAuthenticationConfig): THorseCallback;
begin
  Result := HorseBearerAuthentication(AValidToken, AConfig, AUTHORIZATION);
end;

function HorseBearerAuthentication(const AValidToken: THorseBearerAuthentication;
  const AConfig: IHorseBearerAuthenticationConfig; const AHeaderConfig: string
  ): THorseCallback;
begin
  Config := AConfig;
  ValidToken := AValidToken;
  Header := AHeaderConfig;
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)} TNextProc {$ELSE} TProc {$ENDIF});
const
  BEARER_AUTH = 'bearer';
var
  LToken: string;
  LIsValid: Boolean;
  LPathInfo: string;
begin
  LPathInfo := Req.RawWebRequest.PathInfo;
  if LPathInfo = EmptyStr then
    LPathInfo := '/';
  if MatchText(LPathInfo, Config.SkipRoutes) then
  begin
    Next();
    Exit;
  end;

  LToken := Req.Headers[Header];
  if LToken.Trim.IsEmpty and not Req.Query.TryGetValue(Header, LToken) and not Req.Query.TryGetValue(AUTHORIZATION, LToken) then
  begin
    Res.Send('Token not found').Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

  if Pos(BEARER_AUTH, LowerCase(LToken)) = 0 then
  begin
    Res.Send('Invalid authorization type').Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

  LToken := Trim(LToken.Replace(BEARER_AUTH, '', [rfIgnoreCase]));

  try
    LIsValid := ValidToken(LToken);
  except
    on E: exception do
    begin
      Res.Send(E.Message).Status(THTTPStatus.InternalServerError);
      raise EHorseCallbackInterrupted.Create;
    end;
  end;

  if not LIsValid then
  begin
    Res.Send('Unauthorized').Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

  Next();
end;

{ THorseBearerAuthenticationConfig }

constructor THorseBearerAuthenticationConfig.Create;
begin
  FHeader := AUTHORIZATION;
  FSkipRoutes := [];
end;

function THorseBearerAuthenticationConfig.Header: string;
begin
  Result := FHeader;
end;

function THorseBearerAuthenticationConfig.Header(const AValue: string): IHorseBearerAuthenticationConfig;
begin
  FHeader := AValue;
  Result := Self;
end;

class function THorseBearerAuthenticationConfig.New: IHorseBearerAuthenticationConfig;
begin
  Result := THorseBearerAuthenticationConfig.Create;
end;

function THorseBearerAuthenticationConfig.SkipRoutes(const AValues: TArray<string>): IHorseBearerAuthenticationConfig;
var
  I: Integer;
begin
  FSkipRoutes := AValues;
  for I := 0 to Pred(Length(FSkipRoutes)) do
    if Copy(Trim(FSkipRoutes[I]), 1, 1) <> '/' then
      FSkipRoutes[I] := '/' + FSkipRoutes[I];
  Result := Self;
end;

function THorseBearerAuthenticationConfig.SkipRoutes: TArray<string>;
begin
  Result := FSkipRoutes;
end;

end.

