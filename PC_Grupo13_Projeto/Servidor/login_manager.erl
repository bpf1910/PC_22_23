-module(login_manager).
-export([start_login/0, 
        create_account/2,
        close_account/2,
        login/2,
        logout/1,
        online/0]).

%Consideremos User ->{Passwd, Online}

start_login() -> spawn(fun()-> loop(#{}) end).


create_account(User, Pass) -> 
        ?MODULE ! {{create_account, User, Pass}, self()}, 
        receive {Res,?MODULE} -> Res end.


close_account(User, Pass) -> 
        ?MODULE ! {{close_account, User, Pass}, self()}, 
        receive{Res, ?MODULE} -> Res end. 

login(User, Pass) -> 
        ?MODULE ! {{login, User, Pass}, self()}, 
        receive{Res, ?MODULE} -> Res end. 

% Assumindo que o logout só é invocado se alguém já estiver feito login
logout(User) -> 
        ?MODULE ! {{logout, User}, self()}, 
        receive{Res, ?MODULE} -> Res end.

online() -> 
        ?MODULE ! {online, self()}, 
        receive{Res, ?MODULE} -> Res end.

loop(Map) ->
        receive
                {Request, From} ->
                        {Res, NewMap} = handle(Request, Map),
                        From ! {Res, ?MODULE},
                        loop(NewMap)
        end.

handle({create_account, User, Pass}, Map) ->
        case maps:is_key(User, Map) of
                true -> 
                        {user_exists, Map};
                false -> 
                        {account_created, maps:put(User, {Pass, false}, Map)}
        end;

handle({close_account, User, Pass}, Map) ->
          case maps:find(User,Map) of
                {ok,{Pass, _}} -> 
                        {account_closed, maps:remove(User,Map)}; 
                _ -> 
                        {close_invalid, Map}
          end;

handle({login, User, Pass}, Map) ->
        case maps:find(User, Map) of
                {ok, {Pass, false}} -> {login_done, maps:update(User, {Pass, true}, Map)};
                {ok, {Pass, true}} -> {already_logged_in, Map};
                _ -> {login_invalid, Map}
        end;

handle({logout, User}, Map) ->
        case maps:find(User, Map) of
                {ok, {Pass, true}} -> {logout_done, maps:update(User, {Pass, false}, Map)};
                _ -> {logout_invalid, Map}
        end;

handle(online, Map)->
        Res = [ User || {User, {_,true}} <- maps:to_list(Map)],
        {Res, Map}.