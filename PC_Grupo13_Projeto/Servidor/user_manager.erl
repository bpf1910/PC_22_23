-module(user_manager).
-export([userAuten/1]).
-import(login_manager,[create_account/2,
        close_account/2,
        login/2,
        logout/1,
        online/0]).

userAuten(Sock) ->
  	receive
	    {tcp, _, Data} ->
	      	Info_without_newline = re:replace(Data,"\\n|\\r", "",[global,{return,list}]),
	      	Info = string:split(Info_without_newline,",",all),
	      	%("~p~n", [Info]),

	      	case Info of
		        ["create_account", User, Pass] ->
		          	Res = create_account(User, Pass),
		          	case Res of
		            	account_created ->
		              		gen_tcp:send(Sock, io_lib:format("Registered~n", [])),
		              		userAuten(Sock);

		            	user_exists ->
							io:format("User ~s ~s exists", [User, Pass]),
		              		gen_tcp:send(Sock, io_lib:format("UserExists~n", [])),
		              		userAuten(Sock)
		          	end;

		        ["close_account", User, Pass] ->
		          	Res = close_account(User,Pass),
		          	case Res of
		            	account_closed ->
		              		gen_tcp:send(Sock, io_lib:format("AccountClosed~n", [])),
		              		userAuten(Sock);
		            	_ ->
		              		gen_tcp:send(Sock, io_lib:format("CloseAccountGoneWrong~n", [])),
		              		userAuten(Sock)
		          	end;

		        ["login", User, Pass] ->
		          	Res = login(User, Pass),
		          	case Res of
		            	login_done ->
		              		gen_tcp:send(Sock, io_lib:format("LoginDone~n", [])),
		              		match_manager ! {newPlayer, User, self()},
		              		userAuten(Sock);

		              	already_logged_in ->
		              		gen_tcp:send(Sock, io_lib:format("AlreadyLoggedIn~n", [])),
		              		userAuten(Sock);

		            	login_invalid ->
		              		gen_tcp:send(Sock, io_lib:format("LoginInvalid~n", [])),
		              		userAuten(Sock)
		          	end;

		        ["logout", User] ->
		          	Res = logout(User),
		          	case Res of
		            	logout_done ->
		              		gen_tcp:send(Sock, io_lib:format("LogoutDone~n", [])),
							Res1 = online(),
							io:format("~p~n",[Res1]),
							match_manager ! {logout, User, self()},
							userAuten(Sock);

		            	logout_invalid ->
		              		gen_tcp:send(Sock, io_lib:format("LogoutInvalid~n", []))
		          	end;

		        ["online"] ->
		          	Res = online(),
		            gen_tcp:send(Sock, io_lib:format("~p~n", [Res])),
		            userAuten(Sock);

		        ["jogar", User] ->
		        	%io:format("jogar~n",[]),
		        	userInGame(Sock, User, newGame(Sock, User));

		        _ ->
		          	self() ! gen_tcp:send(Sock, io_lib:format("InvalidCommand~n", []))
		      	end;

	    _ -> userAuten(Sock)

	end.

newGame(Sock, User) ->
	match_manager ! {jogar, User, self()},
	receive
		{initialMatch, MatchInfo, PidMatch, match_manager} ->
			initialInfo(Sock, MatchInfo),
			PidMatch;

		{tcp_closed, _} ->
      		io:format("User ~s disconnected~n", [User]),
      		logout(User),
      		match_manager ! {leaveWaitMatch, User, self()};

    	{tcp_error, _, _} ->
      		io:format("User ~s disconnected with error~n", [User]),
      		logout(User),
      		match_manager ! {leaveWaitMatch, User, self()}
  	end.

userInGame(Sock, User, PidMatch) ->
 	receive
 		{matchOver, Scores, PidMatch} ->
			matchOver(Sock, Scores, User)

 	after 0 ->
 		receive
 			{matchOver, Scores, PidMatch} ->
				%io:format("~p~n",[Scores]),
				matchOver(Sock, Scores, User);				

 			{updateMatch, UpdateInfo, PidMatch} ->
				%io:format("update user manager~n", []),
          		sendUpdateInfo(Sock, UpdateInfo),
          		userInGame(Sock, User, PidMatch);

          	{tcp, _, Data} ->
          		Info_without_newline = re:replace(Data,"\\n|\\r", "",[global,{return,list}]),
          		Info = string:split(Info_without_newline,",",all),
				%io:format("~p",[Info]),
          		case Info of
          			["KeyChanged", Key, "True"] ->
          				%io:format("~s pressedKey~n", [User]),
          				PidMatch ! {keyChanged, Key, true, self()};
          			["KeyChanged", Key, "False"] -> 
          				%io:format("~s releasedKey~n", [User]),
          				PidMatch ! {keyChanged, Key, false, self()}
          		end,
          		userInGame(Sock,User,PidMatch);

          	{tcp_closed, _} ->
          		io:format("~s has disconnected~n", [User]),
          		logout(User),
          		match_manager ! {leave, User, self()};

        	{tcp_error, _, _} ->
          		io:format("~s left due to error~n", [User]),
          		logout(User),
          		match_manager ! {leave, User, self()}
        end
    end.

matchOver(Sock, Scores, Username) ->
  	gen_tcp:send(Sock, io_lib:format("MatchOverBegin~n", [])),
	sendScores(Sock, Scores),
  	gen_tcp:send(Sock, io_lib:format("MatchOverEnd~n", [])),
  	match_manager ! {leaveWaitMatch, Username, self()},
  	matchOverUserResponse(Sock, Username).

matchOverUserResponse(Sock, Username) ->
  	receive
    	{tcp, _, Data} ->
      		Info_without_newline = re:replace(Data,"\\n|\\r", "",[global,{return,list}]),
      		Info = string:split(Info_without_newline,",",all),
      		case Info of
        		["continue"] ->
					match_manager ! {continue},
					userAuten(Sock);
        		["logout", Username] ->
          			Res = logout(Username),
		          	case Res of
		            	logout_done ->
		              		gen_tcp:send(Sock, io_lib:format("LogoutDone~n", [])),
							match_manager ! {logout, Username, self()},
							userAuten(Sock);

		            	logout_invalid ->
		              		gen_tcp:send(Sock, io_lib:format("LogoutInvalid~n", []))
		          	end;
        	_ ->
          		gen_tcp:send(Sock,io_lib:format("UnknownResponse~n", [])),
          		matchOverUserResponse(Sock,Username)
      		end;

    	{tcp_close, _} ->
      		logout(Username),
      		match_manager ! {leaveWaitMatch, Username, self()};
      		%login_manager ! {{logout, Username},self()};

    	{tcp_error, _, _} ->
      		logout(Username),
      		match_manager ! {leaveWaitMatch, Username, self()}
	end.

% envia a informação inicial para o cliente
initialInfo(Sock, MatchInfo) ->
  	gen_tcp:send(Sock, io_lib:format("StartInitialMatchInfo~n", [])),
  	sendPlayersInfo(Sock, MatchInfo),
	sendBonusesInfo(Sock, MatchInfo),
  	gen_tcp:send(Sock, io_lib:format("EndInitialMatchInfo~n", [])).

% envia a informação atualizada para o cliente
sendUpdateInfo(Sock, UpdateInfo) ->
  	gen_tcp:send(Sock, io_lib:format("StartMatchInfo~n", [])),
  	%io:format("~p~n",[UpdateInfo]),
  	sendPlayersInfo(Sock, UpdateInfo),
	sendBonusesInfo(Sock, UpdateInfo),
  	gen_tcp:send(Sock, io_lib:format("EndMatchInfo~n", [])).


sendPlayersInfo(Sock, MatchInfo) ->
  	case maps:find(players, MatchInfo) of
    {ok, Players} ->
      	PlayersList = [Player || {_, Player} <- maps:to_list(Players)],
      	sendPlayerInfo(Sock, PlayersList);
    error ->
      	nothingToSend
  	end.

sendPlayerInfo(_, []) ->
  	playerDone;
sendPlayerInfo(Sock, [H|T]) ->
  	{ok, Username} = maps:find(username, H),
  	{ok, X} = maps:find(x, H),
  	{ok, Y} = maps:find(y, H),
  	{ok, Angle} = maps:find(angle, H),
	{ok, Score} = maps:find(score, H),
	%io:format("~s,~w,~w,~w~n", [Username, X, Y, Angle]),
  	gen_tcp:send(Sock, io_lib:format("P,~s,~w,~w,~w,~w~n", [Username, X, Y, Angle, Score])),
  	sendPlayerInfo(Sock, T).

sendBonusesInfo(Sock, MatchInfo) ->
  	case maps:find(bonus, MatchInfo) of
    	{ok, Bonus} ->
      		sendBonusInfo(Sock, Bonus, 0);
    	error ->
      		nothingToSend
  	end.

sendBonusInfo(_, [], _) ->
  	bonusDone;
sendBonusInfo(Sock, [{Index, Bonus}|T], _) ->
  	{ok, Type} = maps:find(type, Bonus),
  	{ok, X} = maps:find(x, Bonus),
  	{ok, Y} = maps:find(y, Bonus),
	%io:format("B,~w,~w,~w,~w~n", [Type, X, Y, Index]),
  	gen_tcp:send(Sock, io_lib:format("B,~w,~w,~w,~w~n", [Type, X, Y, Index])),
  	sendBonusInfo(Sock, T, ok);
sendBonusInfo(Sock, [H|T], Index) ->
  	{ok, Type} = maps:find(type, H),
  	{ok, X} = maps:find(x, H),
  	{ok, Y} = maps:find(y, H),
	%io:format("B,~w,~w,~w,~w~n", [Type, X, Y, Index]),
  	gen_tcp:send(Sock, io_lib:format("B,~w,~w,~w,~w~n", [Type, X, Y, Index])),
  	sendBonusInfo(Sock, T, Index+1).

sendScores(_, []) ->
  	scoresDone;
sendScores(Sock, [{Username, Score}|T]) ->
	%io:format("S,~s,~p~n", [Username, Score]),
  	gen_tcp:send(Sock, io_lib:format("S,~s,~p~n", [Username, Score])),
  	sendScores(Sock, T).