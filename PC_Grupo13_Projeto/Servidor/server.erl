-module(server).
-export([start/0, stop/1]).
-import(login_manager,[start_login/0]).
-import(user_manager,[userAuten/1]).


start() -> spawn(fun() -> server(4001) end).
stop(Server) -> Server ! stop.

server(Port) ->
    %inicializa os processos necessarios
    register(match_manager, spawn(fun() -> roomMatch([],[],2) end)),
    register(login_manager, start_login()),
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    io:format("Servidor pronto ~p.~n", [self()]),
    spawn(fun() -> acceptor(LSock) end),
    receive
    	stop -> ok
    end.

acceptor(LSock) ->
    Res = gen_tcp:accept(LSock),
    case Res of
        {ok, Sock} ->
            spawn(fun() -> acceptor(LSock) end),
            io:format("Alguem entrou.~n", []),
            userAuten(Sock);
        {error, closed} ->
            ok
    end.

roomMatch(ActivePlayers, WaitingQueue, MaxPlayers) ->
    receive
        {newPlayer, _, _} ->
            roomMatch(ActivePlayers, WaitingQueue, MaxPlayers);

        {logout, User, Pid} ->
            io:format("Logout...~n", []),
            PlayerCheck = {Pid, User},
            C1 = lists:member(PlayerCheck, ActivePlayers),
            C2 = lists:member(PlayerCheck, WaitingQueue),
            if 
                C1 ->
                    AP = lists:delete(PlayerCheck, ActivePlayers),
                    WQ = WaitingQueue,
                    roomMatch(AP, WQ, MaxPlayers);
                C2 ->
                    AP = ActivePlayers,
                    WQ = lists:delete(PlayerCheck, WaitingQueue),
                    roomMatch(AP, WQ, MaxPlayers);
                true ->
                    AP = ActivePlayers,
                    WQ = WaitingQueue,
                    roomMatch(AP, WQ, MaxPlayers)
            end;
            
        {jogar, User, Pid} ->
            io:format("Jogar...~n", []),
            PlayerCheck = {Pid, User},
            %io:format("ActivePlayers ~p~n", [ActivePlayers]),
            Condition2 = lists:member(PlayerCheck, ActivePlayers), % ve se {Pid, User} pertence a ActivePlayers
            if
                Condition2 ->
                    WaitingQueue1 = WaitingQueue;  %se está nao faz nada
                true ->
                    WaitingQueue1 = WaitingQueue ++ [{Pid, User}] %se nao está coloca {Pid, User} na WaitingQueue
                    %io:format("WaitingQueue1 ~p~n", [WaitingQueue1])
            end,

            if
                length(ActivePlayers) < MaxPlayers ->
                    io:format("User ~s wants to play, Waiting for opponent...~n", [User]),
                    if
                        length(WaitingQueue1) < 1 ->
                            roomMatch(ActivePlayers, WaitingQueue1, MaxPlayers);  %ninguem está na waitingQueue
                        true -> %ha players na waiting queue
                            Player = lists:nth(1,WaitingQueue1),  % extrair o primeiro player {Pid, User} de WaitingQueue1
                            WaitingQueue2 = lists:delete(Player, WaitingQueue1), % retiro o player da WaitingQueue
                            Condition = lists:member(Player, ActivePlayers), % ver se o player {Pid, User} pertence à ActivePlayer list
                            %io:format("ActivePlayers ~p~n", [ActivePlayers]),
                            if
                                Condition ->
                                    ActivePlayers1 = ActivePlayers; %se está lá nao fazemos nada
                                true ->
                                    ActivePlayers1 = [Player | ActivePlayers] % otherwise Player {Pid, User} é adicionado à lista
                                    %io:format("ActivePlayers ~p~n", [ActivePlayers1])
                            end,
                            if
                                length(ActivePlayers1) == MaxPlayers ->  %vemos se a lista de ActivePlayers1 atingiu o limite : 1 para já
                                    io:format("Opponent found~n", []),
                                    %io:format("Active Players ~p~n", [ActivePlayers1]),
                                    % tendo os jogadores necessários para uma partida, chama a função matchinitialize
                                    spawn(fun () -> matchInitialize(ActivePlayers1, maps:new(), [], maps:new()) end),
                                    % e volta a chamar roomMatch para os jogadores que nao foram macthed nesta partida
                                    %io:format("WaitingQueue2 ~p~n", [WaitingQueue2]),
                                    roomMatch([], WaitingQueue2, MaxPlayers);
                                true ->
                                    roomMatch(ActivePlayers1, WaitingQueue2, MaxPlayers)  %se ainda nao atingiu o limite chama o roomMatch again com o Activeplayers e WaitingQueue atualizados
                            end
                    end;
                true ->
                    roomMatch(ActivePlayers, WaitingQueue1, MaxPlayers)
            end;

        {continue} ->
            roomMatch(ActivePlayers, WaitingQueue, MaxPlayers);

        {leaveWaitMatch, User, _} ->
            %caso o jogador saia do Lobby/Server
            io:format("User ~s left the server~n", [User]),
            %io:format("ActivePlayers ~p~n", [ActivePlayers]),
            roomMatch(ActivePlayers, WaitingQueue, MaxPlayers)
    end.

checkPosition(_, _, []) ->
   true;

checkPosition(X, Y, [{_,Player} | Players]) ->
   {ok, X2} = maps:find(x, Player),
   {ok, Y2} = maps:find(y, Player),
   Dist = math:sqrt(math:pow(X2 - X, 2) + math:pow(Y2 - Y, 2)),
   if
        Dist < 20 + 20 ->
            false;
        true ->
            checkPosition(X, Y, Players)
   end.

createBonus(_, 0, _, Res) ->
    Res;
createBonus(Type, N, Players, Res) ->
    X = rand:uniform(480) + 10,
    Y = rand:uniform(480) + 10,
    Bool = checkPosition(X, Y, Players),
    if
        not Bool ->
            createBonus(Type, N, Players, Res);
        true ->
            Bonus = maps:new(),
            Bonus2 = maps:put(type, Type, Bonus),
            Bonus3 = maps:put(x, X, Bonus2),
            Bonus4 = maps:put(y, Y, Bonus3),
            Res1 = [Bonus4 | Res],
            createBonus(Type, N-1, Players, Res1)
    end.

% Função que cria um jogador
createPlayer(Username, Players, PressedKeys, Score) ->
    X = 50,
    Y = 450,
    Accel = 3,
    Rot = 0.0166666667*math:pi(),
    Bool = checkPosition(X, Y, Players),
    if
        not Bool ->
            Angle = math:pi()*5/4,
            Player = maps:new(),
            Player2 = maps:put(username, Username, Player),  %Player6 = {username: Username, x: X, y: Y, angle: Angle, pressedKeys: {up: false, right: false, left: false}}
            Player3 = maps:put(x, Y, Player2),
            Player4 = maps:put(y, X, Player3),
            Player5 = maps:put(angle, Angle, Player4),
            Player6 = maps:put(accel, Accel, Player5),
            Player7 = maps:put(rot, Rot, Player6),
            Player8 = maps:put(pressedKeys, PressedKeys, Player7),
            Player9 = maps:put(score, Score, Player8),
            Player9;
        true ->
            Angle = math:pi()/4,
            Player = maps:new(),
            Player2 = maps:put(username, Username, Player),  %Player6 = {username: Username, x: X, y: Y, angle: Angle, pressedKeys: {up: false, right: false, left: false}}
            Player3 = maps:put(x, X, Player2),
            Player4 = maps:put(y, Y, Player3),
            Player5 = maps:put(angle, Angle, Player4),
            Player6 = maps:put(accel, Accel, Player5),
            Player7 = maps:put(rot, Rot, Player6),
            Player8 = maps:put(pressedKeys, PressedKeys, Player7),
            Player9 = maps:put(score, Score, Player8),
            Player9
    end.

eatingBonus(Player, Bonus) ->
    {ok, XP} = maps:find(x, Player),
    {ok, YP} = maps:find(y, Player),
    {ok, Accel} = maps:find(accel, Player),
    {ok, Rot} = maps:find(rot, Player),
    {ok, XB} = maps:find(x, Bonus),
    {ok, YB} = maps:find(y, Bonus),
    {ok, Type} = maps:find(type, Bonus),
    Dist = math:sqrt(math:pow(XB - XP, 2) + math:pow(YB - YP, 2)),
    case Type of
        acel ->
            if
                Dist < 15 ->
                    Accel2 = Accel + 2,
                    Res = min(Accel2, 7),
                    {true, acel, Res};
                true ->
                    false     
            end;
        direc ->
            if
                Dist < 15 ->
                    Rot2 = Rot + 0.0166666667*math:pi(),
                    Res = min(Rot2, 0.05*math:pi()),
                    {true, direc, Res};
                true ->
                    false
            end;
        remove ->
            if
                Dist < 25 ->
                    Accel2 = 3,
                    Rot2 = 0.0166666667*math:pi(),
                    {true, remove, Accel2, Rot2};
                true ->
                    false
        end
    end.


bonusEaten(_, [], _, {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus}) ->
    {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus};
bonusEaten(Player, [empty | Bonuses], Index, {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus}) ->
    bonusEaten(Player, Bonuses, Index+1, {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus});
bonusEaten(Player, [Bonus | Bonuses], Index, {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus}) ->
    case eatingBonus(Player, Bonus) of
        {true, acel, NewAccel} ->
            NewBonus1 = lists:sublist(NewBonus, Index - 1) ++ [empty] ++ lists:nthtail(Index, NewBonus),
            bonusEaten(Player, Bonuses, Index+1, {[Index | IndexAccel], NewAccel, IndexDirec, DirecChange, IndexRemove, NewBonus1});

        {true, direc, NewRot} ->
            NewBonus2 = lists:sublist(NewBonus, Index - 1) ++ [empty] ++ lists:nthtail(Index, NewBonus),
            bonusEaten(Player, Bonuses, Index+1, {IndexAccel, AccelChange, [Index | IndexDirec], NewRot, IndexRemove, NewBonus2});
        
        {true, remove, NewAccel, NewRot} ->
            NewBonus2 = lists:sublist(NewBonus, Index - 1) ++ [empty] ++ lists:nthtail(Index, NewBonus),
            bonusEaten(Player, Bonuses, Index+1, {IndexAccel, NewAccel, IndexDirec, NewRot, [Index | IndexRemove], NewBonus2});

        false ->
            bonusEaten(Player, Bonuses, Index+1, {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus})
    end.

verifyBonusEaten([], _, Res) ->
    Res;
verifyBonusEaten([{Pid, Player} | T], Bonuses, {AccelIdx, AccelBonus, DirecIdx, DirecBonus, RemoveIdx}) ->
    {ok, Accel} = maps:find(accel, Player),
    {ok, Direc} = maps:find(rot, Player),
    DirecMin = 0.0166666667*math:pi(),
    {IndexAccel, AccelChange, IndexDirec, DirecChange, IndexRemove, NewBonus} = bonusEaten(Player, Bonuses, 1, {[], 0, [], 0, [], Bonuses}),
    if 
        AccelChange > Accel  ->
            verifyBonusEaten(T, NewBonus, {IndexAccel ++ AccelIdx, [{Pid, AccelChange, acel} | AccelBonus], DirecIdx, DirecBonus, RemoveIdx});
        DirecChange > Direc  ->
            verifyBonusEaten(T, NewBonus, {AccelIdx, AccelBonus, IndexDirec ++ DirecIdx, [{Pid, DirecChange, direc} | DirecBonus], RemoveIdx});
        AccelChange == 3 andalso DirecChange == DirecMin andalso (AccelChange /= Accel orelse DirecChange /= Direc) ->
            verifyBonusEaten(T, NewBonus, {AccelIdx, [{Pid, AccelChange, acel} | AccelBonus], IndexDirec, [{Pid, DirecChange, direc} | DirecBonus], IndexRemove ++ RemoveIdx});
        true ->
            verifyBonusEaten(T, NewBonus, {AccelIdx, AccelBonus, DirecIdx, DirecBonus, RemoveIdx})
    end.
    
    

killingPlayer(Player1, Player2) ->
    {ok, XP1} = maps:find(x, Player1),
    {ok, YP1} = maps:find(y, Player1),
    {ok, AngleP1} = maps:find(angle, Player1),
    {ok, XP2} = maps:find(x, Player2),
    {ok, YP2} = maps:find(y, Player2),
    {ok, AngleP2} = maps:find(angle, Player2),
    Dist = math:sqrt(math:pow(XP2 - XP1, 2) + math:pow(YP2 - YP1, 2)),
    {VectorX, VectorY} = {(XP2 - XP1)/20 , (YP2 - YP1)/20},
    {PointPX, PointPY} = {XP1 + VectorX, YP1 + VectorY}, 
    AngleDiff = abs(AngleP1 - AngleP2),
    Condition = AngleDiff < math:pi()/2,
    Alpha = AngleP2 - math:pi()/2,
    {DiamX, DiamY} = {XP2 + 20 * math:cos(Alpha), YP2 - 20 * math:sin(Alpha)},
    Condition2 = ((PointPY - DiamY) * (DiamX - XP2) - (DiamY - YP2) * (PointPX - DiamX)) >= 0,
    Condition3 = 20 >= math:sqrt(math:pow(XP2 - PointPX, 2) + math:pow(YP2 - PointPY, 2)),
    if 
        Dist > 0 andalso Dist < 40 andalso Condition andalso Condition2 andalso Condition3 ->
            true;
        true ->
            false
    end.

verifyPlayersEaten([{Pid1, Player1} | [{Pid2, Player2} | _]]) ->
    Condition1 = killingPlayer(Player1, Player2),
    Condition2 = killingPlayer(Player2, Player1),
    if
        Condition1 ->
            {[Pid1], [Pid2]};
        Condition2 ->
            {[Pid2], [Pid1]};
        true ->
            {[], []}
    end.

isOutsideBoard(Player) ->
    {ok, X} = maps:find(x, Player),
    {ok, Y} = maps:find(y, Player),
    if
        X < 0 orelse X > 500 orelse Y < 0 orelse Y > 500 ->
            true;
        true ->
            false
    end.

verifyBounds([{Pid1, Player1} | [{Pid2, Player2} | _]]) ->
    Condition1 = isOutsideBoard(Player1),
    Condition2 = isOutsideBoard(Player2),
    if
        Condition1 ->
            {[Pid2],[Pid1],true};
        Condition2 ->
            {[Pid1],[Pid2],true};
        true ->
            {[], [], false}
    end.
        
updatePlayers(Players, [], [], [], Res, _) ->
    Size = maps:size(Res),
    if 
        Size == 0 ->
            Res1 = Players;
        true ->
            Res1 = Res
    end,
    Res1;
updatePlayers(Players, [], [], [PidDead|T], Res, GameOverBounds) ->
    {ok, Player} = maps:find(PidDead, Players),
    {ok, Username} = maps:find(username, Player),
    Keys = maps:new(),
    Keys1 = maps:put(up, false ,Keys),
    Keys2 = maps:put(left, false ,Keys1),
    Keys3 = maps:put(right, false ,Keys2),
    if 
        GameOverBounds ->
            Score1 = 0;
        true ->
            {ok, Score} = maps:find(score, Player),
            Score1 = Score
    end,
    NewPlayer = createPlayer(Username, maps:to_list(Res), Keys3, Score1),
    Res1 = maps:put(PidDead, NewPlayer, Res),
    updatePlayers(Players, [], [], T, Res1, GameOverBounds);
updatePlayers(Players, [], [PidWinner | T], DeadPlayerPid, Res, GameOverBounds) ->
    {ok, Player} = maps:find(PidWinner, Players),
    {ok, Username} = maps:find(username, Player),
    Keys = maps:new(),
    Keys1 = maps:put(up, false, Keys),
    Keys2 = maps:put(left, false, Keys1),
    Keys3 = maps:put(right, false, Keys2),
    if 
        GameOverBounds ->
            Score1 = 1;
        true ->
            {ok, Score} = maps:find(score, Player),
            Score1 = Score + 1
    end,
    NewPlayer = createPlayer(Username, maps:to_list(Res), Keys3, Score1),
    Res1 = maps:put(PidWinner, NewPlayer, Res),
    updatePlayers(Players, [], T, DeadPlayerPid, Res1, GameOverBounds);
updatePlayers(Players, [{Pid, Change, Type} | T], Winner, Loser, Res, GameOverBounds) ->
    case Type of 
        acel ->
            {ok, Player} = maps:find(Pid, Players),
            NewPlayer = maps:update(accel, Change, Player),
            Players2 = maps:update(Pid, NewPlayer, Players),
            updatePlayers(Players2, T, Winner, Loser, Res, GameOverBounds);
        direc ->
            {ok, Player} = maps:find(Pid, Players),
            NewPlayer = maps:update(rot, Change, Player),
            Players2 = maps:update(Pid, NewPlayer, Players),
            updatePlayers(Players2, T, Winner, Loser, Res, GameOverBounds)
    end.

replaceBonus(Res, [], []) ->
    Res;
replaceBonus(Res, [Bonus | T], [Index | Indexes]) ->
    Res1 = lists:sublist(Res, Index - 1) ++ [Bonus] ++ lists:nthtail(Index, Res),
    replaceBonus(Res1, T, Indexes).

interactions(MatchInfo) ->
    {ok, Players} = maps:find(players, MatchInfo),
    {ok, Bonus} = maps:find(bonus, MatchInfo),
    %io:format("~p~n",[Bonus]),
    {WinnerPlayerPid, DeadPlayerPid, GameOverBounds} = verifyBounds(maps:to_list(Players)),
    if 
        GameOverBounds ->
            NewPlayers = updatePlayers(Players, [], WinnerPlayerPid, DeadPlayerPid, maps:new(), GameOverBounds),
            MatchInfo1 = maps:update(players, NewPlayers, MatchInfo),
            {MatchInfo1, WinnerPlayerPid ++ DeadPlayerPid, [], true};
        true ->
            {AccelIndices, PlayersAccelChanges, DirecIndices, PlayersDirecChanges, RemoveIndices} = verifyBonusEaten(maps:to_list(Players), Bonus, {[], [], [], [], []}),
            %io:format("~p~n~p~n",[AccelIndices, PlayersAccelChanges]),
            NewPlayers2 = updatePlayers(Players, PlayersAccelChanges ++ PlayersDirecChanges, [], [], maps:new(), GameOverBounds),
            {WinnerPlayerPid2, DeadPlayerPid2} = verifyPlayersEaten(maps:to_list(NewPlayers2)),
            NewPlayers1 = updatePlayers(NewPlayers2, [], WinnerPlayerPid2, DeadPlayerPid2, maps:new(), GameOverBounds),
            MatchInfo2 = maps:update(players, NewPlayers1, MatchInfo),
            NewBonus = createBonus(acel, length(AccelIndices), maps:to_list(NewPlayers1), []) ++ createBonus(direc, length(DirecIndices), maps:to_list(NewPlayers1), []) ++ createBonus(remove, length(RemoveIndices), maps:to_list(NewPlayers1), []),
            Bonus1 = replaceBonus(Bonus, NewBonus, AccelIndices ++ DirecIndices ++ RemoveIndices),
            MatchInfo3 = maps:update(bonus, Bonus1, MatchInfo2),
            {MatchInfo3, WinnerPlayerPid2 ++ DeadPlayerPid2, AccelIndices ++ DirecIndices ++ RemoveIndices, false}
    end.

%recebe a lista com os activePlayers [{Pid, User}...], dicionario com a info dos players, lista com os Pids dos players, dicionarios com as pressedKeys dos players
matchInitialize([], Players, Pids, PressedKeys) ->
    PidMatch = self(),
    MatchSender = spawn(fun() ->
        Bonus = createBonus(acel, 2, maps:to_list(Players), []) ++ createBonus(direc, 2, maps:to_list(Players), []) ++ createBonus(remove, 2, maps:to_list(Players), []),
        Info = maps:new(),
        %coloca em Info na chave players o dicionario com a informacao dos players
        Info2 = maps:put(players, Players, Info),
        Match = maps:put(bonus, Bonus, Info2),
        %io:format("~p~n", [Match]),
        %envia a cada processo de cada player (newMatch vai receber) essa informaçao com o Pid do match, a dizer que vem do matchmanager
        [Pid ! {initialMatch, Match, PidMatch, match_manager} || Pid <- Pids],
        matchSender(Match, Pids, PidMatch, false, false)
                end),
    spawn(fun () -> receive after 120000 -> MatchSender ! timeout end end),
    match(PressedKeys, Pids, MatchSender);

matchInitialize([{Pid, Username}|T], Players, Pids, PressedKeys) ->
    Keys = maps:new(), %novo dicionario com as teclas pressionadas
    %coloca os varios inputs possiveis: iniciados a false : em frente, esquerda ou direita
    Keys1 = maps:put(up, false, Keys),
    Keys2 = maps:put(left, false, Keys1),
    Keys3 = maps:put(down, false, Keys2),
    PlayerPressedKeys = maps:put(right, false ,Keys3),  %{up: false, right: false, left: false}
    PlayerData = createPlayer(Username, maps:to_list(Players), PlayerPressedKeys, 0), %{username: Username, x: X, y: Y, angle: Angle, pressedKeys: {up: false, right: false, left: false}}
    NewPlayers = maps:put(Pid, PlayerData, Players),
    NewPressedKeys = maps:put(Pid, PlayerPressedKeys, PressedKeys), %PressedKeys = {Pid : {up: false, right: false, left: false}, Pid: {...}}
    %[{Pid,User}] , {Pid: {username: Username, x: X, y: Y, angle: Angle, pressedKeys: {up: false, right: false, left: false}}} , [Pid], {Pid : {up: false, right: false, left: false}}
    matchInitialize(T, NewPlayers, [Pid | Pids], NewPressedKeys).

% Função que gere as ações de premir e libertar teclas, bem como a saída de um jogador
match(PressedKeys, PlayersPids, MatchSender) ->
    receive
        {keyChanged, Key, Change, Pid} ->
            %io:format("~s ~p ~n", [Key, Pid]),
            {ok, PlayerKeys} = maps:find(Pid, PressedKeys),
            case Change of
                false ->
                    case Key of
                        "up" ->
                            PlayerKeys1 = maps:update(up, false, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender);
                        "left" ->
                            PlayerKeys1 = maps:update(left, false, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender);
                        "right" ->
                            PlayerKeys1 = maps:update(right, false, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender)
                    end;
                true ->
                    case Key of
                        "up" ->
                            PlayerKeys1 = maps:update(up, true, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender);
                        "left" ->
                            PlayerKeys1 = maps:update(left, true, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender);
                        "right" ->
                            PlayerKeys1 = maps:update(right, true, PlayerKeys),
                            PressedKeys1 = maps:update(Pid, PlayerKeys1, PressedKeys),
                            MatchSender ! {Pid, PlayerKeys1},
                            match(PressedKeys1, PlayersPids, MatchSender)
                    end
            end;

        {leave, User, Pid} ->
            MatchSender ! {exit, User, Pid}       
    end.


% Função que atualiza a informação da partida e a envia aos clientes
matchSender(Match, PlayersPids, PidMatch, Timeout, OutOfBounds) ->
    %io:format("MatchSender: ~p~n",[Match]),
    {ok, Players} = maps:find(players, Match),
    Scores = scoreboard(maps:to_list(Players), []),
    Condition = scoreDifferent(Scores),
    case
        {Timeout, Condition, OutOfBounds} of
            {_, _, true} ->
                [Player ! {matchOver, Scores, PidMatch} || Player <- PlayersPids],
                done;
            {true, true, _} ->
                [Player ! {matchOver, Scores, PidMatch} || Player <- PlayersPids],
                done;
            {true, false, _} ->
                receive
                    {Pid, PressedKeys} ->
                        %io:format("pressed keys~n", []),
                        {ok, Players} = maps:find(players, Match),
                        {ok, Player} = maps:find(Pid, Players),
                        Player1 = maps:update(pressedKeys, PressedKeys, Player),
                        Players1 = maps:update(Pid, Player1, Players),
                        Match1 = maps:update(players, Players1, Match),
                        matchSender(Match1, PlayersPids, PidMatch, Timeout, OutOfBounds);

                    {exit, User, Pid} ->
                        {ok, Players} = maps:find(players, Match),
                        Scores = scoreboard(maps:to_list(Players), []),
                        %io:format("~p~n", [Scores]),
                        [Player ! {matchOver, Scores, PidMatch} || Player <- PlayersPids],
                        match_manager ! {leaveWaitMatch, User, Pid},
                        done

                after
                    30 ->
                    {Match1, OutOfBounds1} = sendSimulation(Match, PlayersPids, PidMatch),
                    matchSender(Match1, PlayersPids, PidMatch, Timeout, OutOfBounds1)
                end;

            {false, _, false} ->
                matchSenderAux(Match, PlayersPids, PidMatch, Timeout, OutOfBounds)
    end.

matchSenderAux(Match, PlayersPids, PidMatch, Timeout, OutOfBounds) ->
    receive
        {Pid, PressedKeys} ->
            %io:format("pressed keys~n", []),
            {ok, Players} = maps:find(players, Match),
            {ok, Player} = maps:find(Pid, Players),
            Player1 = maps:update(pressedKeys, PressedKeys, Player),
            Players1 = maps:update(Pid, Player1, Players),
            Match1 = maps:update(players, Players1, Match),
            matchSender(Match1, PlayersPids, PidMatch, Timeout, OutOfBounds);

        {exit, User, Pid} ->
            {ok, Players} = maps:find(players, Match),
            Scores = scoreboard(maps:to_list(Players), []),
            %io:format("~p~n", [Scores]),
            [Player ! {matchOver, Scores, PidMatch} || Player <- PlayersPids],
            match_manager ! {leaveWaitMatch, User, Pid},
            done;

        timeout -> 
            matchSender(Match, PlayersPids, PidMatch, true, OutOfBounds)

        after
            30 ->
            {Match1, OutOfBounds1} = sendSimulation(Match, PlayersPids, PidMatch),
            matchSender(Match1, PlayersPids, PidMatch, Timeout, OutOfBounds1)
    end.

scoreDifferent([{_, Score1} | [{_, Score2} | _]]) ->
    if 
        Score1 /= Score2 ->
            true;
        true ->
            false
    end.

% Função que atualiza a posição dos jogadores, tendo em conta as teclas pressionadas por estes
updatePosition(X, Y, Angle, _, _, []) ->
    {X, Y, Angle};

updatePosition(X, Y, Angle, Accel, Rot, [{K,true}|Keys]) ->
    case K of
        up ->
            X1 = X + Accel * math:cos(Angle),
            Y1 = Y - Accel * math:sin(Angle),
            Angle3 = Angle;
        left ->
            Angle2 = Angle + Rot, %5 graus de cada vez
            TwoPi = math:pi()*2,
            if
                Angle2 > TwoPi ->
                    Angle3 = 0;
                true ->
                    Angle3 = Angle2
            end,
            X1 = X,
            Y1 = Y;
        right ->
            Angle2 = Angle - Rot,
            TwoPi = math:pi()*2,
            if
                Angle2 < 0  ->
                    Angle3 = TwoPi;
                true ->
                    Angle3 = Angle2
            end,
            X1 = X,
            Y1 = Y
    end,
    updatePosition(X1, Y1, Angle3, Accel, Rot, Keys).


keyPressedEvent([], Res, UpdatedPlayers) ->
    {Res, UpdatedPlayers};

keyPressedEvent([{Pid,PlayerData}|Players], Res, UpdatedPlayers) ->
    {ok, PressedKeys} = maps:find(pressedKeys, PlayerData),
    {ok, Angle} = maps:find(angle, PlayerData),
    {ok, X} = maps:find(x, PlayerData),
    {ok, Y} = maps:find(y, PlayerData),
    {ok, Accel} = maps:find(accel, PlayerData),
    {ok, Rot} = maps:find(rot, PlayerData),
    TrueKeys = maps:filter(fun(_, V) ->
        case V of
            true ->
                true;
            _ ->
                false
        end end, PressedKeys),
    {X1, Y1, Angle1} = updatePosition(X, Y, Angle, Accel, Rot, maps:to_list(TrueKeys)),
    PD1 = maps:update(x, X1, PlayerData),
    PD2 = maps:update(y, Y1, PD1),
    PD3 = maps:update(angle, Angle1, PD2),
    Res1 = maps:put(Pid, PD3, Res),
    case {X1, Y1, Angle1} of
        {X, Y, Angle} ->
            PlayerWasUpdated = false; %nao ha movimento
        _ ->
            PlayerWasUpdated = true
    end,
    if
        PlayerWasUpdated ->
            UpdatedPlayers1 = [Pid|UpdatedPlayers];
        true ->
            UpdatedPlayers1 = UpdatedPlayers
    end,
    keyPressedEvent(Players, Res1, UpdatedPlayers1).


sendSimulation(Match, PlayersPids, PidMatch) ->
    UpdatedInfo = maps:new(),
    % Atualizar a posição dos jogadores
    {ok, Players} = maps:find(players, Match),
    {Players1, UpdatedPlayers} = keyPressedEvent(maps:to_list(Players), maps:new(), []),
    Match2 = maps:update(players, Players1, Match),
    {Match3, UpdatedPlayers2, IdxBonus, GameOverBounds} = interactions(Match2),
    L = sets:to_list(sets:from_list(lists:merge(UpdatedPlayers, UpdatedPlayers2))),
    UpdatedInfo2 = updatePlayersBonusInfo(Match3, UpdatedInfo, IdxBonus, L, [], maps:new()),
    %io:format("~p~n",[UpdatedInfo2]),
    Size = maps:size(UpdatedInfo2),
    if
        Size == 0 ->
            nothingToSend;
        true ->
            [Player ! {updateMatch, UpdatedInfo2, PidMatch} || Player <- PlayersPids]
    end,
    {Match3, GameOverBounds}.
    

updatePlayersBonusInfo(_, Res, [], [], TempBonus, TempPlayers) ->
    NumBonus = length(TempBonus),
    if
        NumBonus == 0 ->
            Res1 = Res;
        true ->
            Res1 = maps:put(bonus, TempBonus, Res)
    end,
    NumPlayers = maps:size(TempPlayers),
    if
        NumPlayers == 0 ->
            Res2 = Res1;
        true ->
            Res2 = maps:put(players, TempPlayers, Res1)
    end,
    Res2;
updatePlayersBonusInfo(MatchInfo, Res, [], [Pid|RemainingPids], TempBonus, TempPlayers) ->
    {ok, Players} = maps:find(players, MatchInfo),
    {ok, Player} = maps:find(Pid, Players),
    TempPlayers1 = maps:put(Pid, Player, TempPlayers),
    updatePlayersBonusInfo(MatchInfo, Res, [], RemainingPids, TempBonus, TempPlayers1);
updatePlayersBonusInfo(MatchInfo, Res, [I | RemainingBonus], UpdatedPlayers, TempBonus, TempPlayers) ->
    {ok, Bonus} = maps:find(bonus, MatchInfo),
    updatePlayersBonusInfo(MatchInfo, Res, RemainingBonus, UpdatedPlayers, [{I-1, lists:nth(I, Bonus)} | TempBonus], TempPlayers).

scoreboard([], Res) ->
    lists:sort(fun({_, Score1}, {_, Score2}) -> Score1 >= Score2 end, Res);
scoreboard([{_, Player}|T], Res) ->
    {ok, Username} = maps:find(username, Player),
    {ok, Score} = maps:find(score, Player),
    scoreboard(T, [{Username, Score}|Res]).