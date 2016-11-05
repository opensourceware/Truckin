
set_agent_state(ToState):-
	retractall(agent_state(_)),
	asserta( agent_state(ToState) ).

find_max_pricediff( [], M):-
	needs_to_go_home,
	place(F_loc,_,_,_,_,finish),
	M = pppdiff(F_loc, F_loc, _, 0).

find_max_pricediff( [], M):-
	player(masm_agent,_,Cash,_,_,Where),
	closest_station(Where, FS),
	place(FS,_,_,Quantity,Price,_),
	place(F_Loc,_,_,_,_,finish),
	find_optimal_Q(Cash, Price, Quantity, Q),
	step_between(FS, F_Loc, S1),
	Q2 is min(Q, S1),
	M = pppdiff(FS, FS, _, Q2).

find_max_pricediff( PPList, MaxPriceDiff):-
	% Returns the member of PPList having max PriceDiff
	% pppdiff( Place1, Place2, PriceDiff, Quantity)
	% Added 4th element Q to pppdiff structure
	findall( PDiff, member(pppdiff(_,_,PDiff, _), PPList), PDList ),
	max_list(PDList, MaxPDiff),
	member( pppdiff(Place1, Place2, MaxPDiff, Q ), PPList ),
	MaxPDiff > 0,
	MaxPriceDiff = pppdiff(Place1,Place2, MaxPDiff,Q).

find_max_pricediff( PPList, MaxPriceDiff):-
	% Returns the member of PPList having max PriceDiff
	% pppdiff( Place1, Place2, PriceDiff, Quantity)
	% Added 4th element Q to pppdiff structure
	findall( PDiff, member(pppdiff(_,_,PDiff, _), PPList), PDList ),
	max_list(PDList, MaxPDiff),
	member( pppdiff(Place1, Place2, MaxPDiff, Q ), PPList ),
	MaxPDiff < 0,
	place(F_Loc,_,_,_,_,finish),
	MaxPriceDiff = pppdiff(F_Loc,F_Loc,_,0).

needs_to_go_home:-
	% If we can't make it home with the (turns-1)  or (fuel-8)
	place(F_loc,_,_,_,_,finish),
	player(masm_agent,_,_,_,Fuel, Where),
	moves_remaining(MRemaining),
	step_between(Where, F_loc, Step1),
	absol(Step1, S1),
	FReqd is S1+16,
	MReqd is FReqd/8,
	MReqd > MRemaining.

needs_to_fill_fuel(OptimalFuelStation):-
	player(masm_agent,_,Cash,_,Fuel,Where ),
	masm_choice( BestSeller, BestBuyer, _),
	step_between(Where, BestSeller, StepS),
	absol(StepS, Ss),
	step_between(BestSeller, BestBuyer, StepB1),
	absol(StepB1, Sb1),
	closest_station(BestBuyer, FS),
	step_between(BestBuyer, FS, Step1),
	absol(Step1, S1),
	FReqd is S1+Ss+Sb1,
	FReqd >= Fuel,
	findall(struct(Place,Price,Where, S2),
		(
			place(Place,_,'Fuel',Quantity,Price,_),
			moves_remaining(MRemaining),
			step_between(Place, BestSeller, StepFtoFinish),
		        absol(StepFtoFinish, SFF),
		    step_between(BestSeller, BestBuyer, StepB),
	absol(StepB, Sb),
		        FReqRef is S1+SFF+Sb,
			Quantity >= FReqRef,
		        format('Quantity: ~d Travel: ~d', [Quantity, FReqRef]),
			Cash > Price,
			format('Cash: ~d Price: ~d', [Cash, Price]),
		        step_between(Where, Place, Step2),
		        absol(Step2, S2),
		        ReqFuel is S2,
		        format('Fuel: ~d ReqFuel: ~d', [Fuel, ReqFuel]),
		        Fuel > ReqFuel
		),
		FuelStations
	),
	find_optimal_station(FuelStations, OptimalFuelStation).

closest_station(Src, ClosestFuelStation):-
	findall(struct(Place,Price,Place, S2),
		(
			place(Place,_,'Fuel',_,Price,_),
			step_between(Src, Place, Step2),
			absol(Step2, S2)
		),
		FuelStations
	),
	find_optimal_station(FuelStations, ClosestFuelStation).


find_optimal_station([], OptimalFuelStation):-
	place(OptimalFuelStation,_,_,_,_,finish).

find_optimal_station(FuelStations, OptimalFuelStation):-
	findall(S1, member(struct(_,_,_, S1), FuelStations), DistList),
	min_list(DistList, D),
	member(struct(OptimalFuelStation,_,_,D), FuelStations).

% step_to_go_to(Destination, MovesNeeded)
% Returns how many steps to move to go home
step_to_go_to( Dest, 0 ):-
	player(masm_agent,_,_,_,_, Where ),
	Where = Dest.

step_to_go_to(Dest, MoveQuantity):-
	player(masm_agent,_,_,_,_, Where ),
	Diff is ((Dest-Where+64) mod 64),
	Diff < 32,
	MoveQuantity is min(8, Diff).


step_to_go_to( Dest, MoveQuantity):-
	% Returns how many steps to move to go home
	player(masm_agent,_,_,_,_, Where ),
	Diff is ((Dest-Where+64) mod 64),
	Diff >= 32,
	MoveQuantity is max(-8, Diff-64).

step_between(Where, Dest, 0 ):-
	Where = Dest.

step_between(Where, Dest, MoveQuantity):-
	Diff is ((Dest-Where+64) mod 64),
	Diff < 32,
	MoveQuantity is Diff.

step_between(Where, Dest, MoveQuantity):-
	% Returns how many steps to move to go home
	Diff is ((Dest-Where+64) mod 64),
	Diff >= 32,
	MoveQuantity is Diff-64.

max_buy( Seller, MoveQuantity ):-
	% Returns max amount you can buy from Seller
	player(masm_agent, WL, Cash, VL, _, _),
	place(Seller, _, Item, SQ, Price, seller),
	item( Item, IW, IV),
	WLim is WL/IW,
	VLim is VL/IV,
	CLim is Cash/Price,
	min_list([WLim,VLim, CLim], OurLim),
	MoveQuantity is min(floor(OurLim), SQ).


max_sell( Buyer, MoveQuantity ):-
	% Returns max amount you can buy from Seller
	% Sell everything you're holding
	place(Buyer, _,Item,_,_,_),
	holding(masm_agent, Item, MoveQuantity).

find_optimal_Q(Cash, Price1, Quantity, Quantity):-
	Cash>=Price1*Quantity.

find_optimal_Q(Cash, Price1, Quantity, Q):-
	Cash < Price1*Quantity,
	Q1 is Quantity-1,
	find_optimal_Q(Cash, Price1, Q1, Q).


