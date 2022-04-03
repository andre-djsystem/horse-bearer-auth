# horse-bearer-auth
<b>horse-bearer-auth</b> is a middleware for working with bearer authentication in APIs developed with the <a href="https://github.com/HashLoad/horse">Horse</a> framework.

## ⚙️ Installation
Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
boss install https://github.com/andre-djsystem/horse-bearer-auth
```
If you choose to install manually, simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../horse-bearer-auth/src
```

## ✔️ Compatibility
This middleware is compatible with projects developed in:
- [X] Delphi
- [X] Lazarus

## ⚡️ Quickstart Delphi
```delphi
uses 
  Horse, 
  Horse.BearerAuthentication, // It's necessary to use the unit
  System.SysUtils;

begin
  // It's necessary to add the middleware in the Horse:
  THorse.Use(HorseBearerAuthentication(
    function(const AToken: string): Boolean
    begin
      // Here inside you can access your database and validate if username and password are valid
      Result := AToken.Equals('token');
    end));
    
  // The default header for receiving credentials is "Authorization".
  // You can change, if necessary:
  // THorse.Use(HorseBearerAuthentication(MyCallbackValidation, THorseBearerAuthenticationConfig.New.Header('X-My-Header-Authorization')));

  // You can also ignore routes:
  // THorse.Use(HorseBearerAuthentication(MyCallbackValidation, THorseBearerAuthenticationConfig.New.SkipRoutes(['/ping'])));

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end;
```

## ⚡️ Quickstart Lazarus
```delphi
{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.BearerAuthentication, // It's necessary to use the unit
  SysUtils;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('Pong');
end;

function CheckToken(const AToken: string): Boolean;
begin
  // Here inside you can access your database and validate if token is valid
  Result := AToken.Equals('token');
end;

begin
  // It's necessary to add the middleware in the Horse:
  THorse.Use(HorseBearerAuthentication(CheckToken));

  // The default header for receiving credentials is "Authorization".
  // You can change, if necessary:
  // THorse.Use(HorseBearerAuthentication(MyCallbackValidation, THorseBearerAuthenticationConfig.New.Header('X-My-Header-Authorization')));

  // You can also ignore routes:
  // THorse.Use(HorseBearerAuthentication(MyCallbackValidation, THorseBearerAuthenticationConfig.New.SkipRoutes(['/ping'])));

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000);
end.
```

## 📌 Status Code
This middleware can return the following status code:
* [401](https://httpstatuses.com/401) - Unauthorized
* [500](https://httpstatuses.com/500) - InternalServerError

## ⚠️ License
`horse-bearer-auth` is free and open-source middleware licensed under the [MIT License](https://github.com/andre-djsystem/horse-bearer-auth/blob/master/LICENSE). 

 
