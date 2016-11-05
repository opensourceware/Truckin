
:- dynamic
	masm_choice/3,
	agent_state/1,
	moves_remaining/1,
	place/6,
	player/6,
	holding/3.

agent_name(masm_agent).

%:- [masm_agent_kb].

:- [masm_agent_helpers].
init_agent:-
	%reset_KB,
	asserta(agent_state(init)).

move(masm_agent,_,_):-
	not(agent_state(_)),
	agent_state(init).

move(masm_agent,_,_):-
	agent_state(init),
	set_agent_state(decide_masm),
	fail.		% Here, Fail is used to make prolog try the next move/3


move(masm_agent, MoveType, MoveQuantity):-
	not(agent_state(do_masm_sell)), not( agent_state(decide_masm)),
	%not(agent_state(decide_masm)),
	needs_to_fill_fuel(FuelStation),
	set_agent_state(do_fuel_buy),
	format('WARNING: NEEDS TO FUEL'),
	step_to_go_to(FuelStation, Steps),
	not(Steps == 0),
	MoveType = m,
	MoveQuantity is Steps.

move(masm_agent, MoveType, MoveQuantity):-
	agent_state(do_fuel_buy),
	%player(_,_,_,_,Fuel,_),
	MoveType = t,
	moves_remaining(MRemaining),
	place(F_loc,_,_,_,_,finish),
	player(masm_agent,_,_,_,Fuel,Where ),
	masm_choice( BestSeller, BestBuyer, _),
	step_between(Where, BestSeller, StepS),
	absol(StepS, Ss),
	step_between(BestSeller, BestBuyer, StepB),
	absol(StepB, Sb),
	closest_station(BestBuyer, FS),
	step_between(BestBuyer, FS, Step1),
	absol(Step1, S1),
	MoveQuantity is S1+Ss+Sb + 33 - Fuel,
	%Mtravel is MRemaining-2,

	%MRemaining-2 because I want atleast one transaction (buy and sell) now that I am refueling; And you don't need fuel for one buy and sell; Basically, we won't need to refuel again since we won't have any moves to; We might be refueling more than required;

	%MoveQuantity is Mtravel*8,
	%NewFuel is MoveQuantity+Fuel,
	set_agent_state(decide_masm).

move(masm_agent, MoveType, MoveQuantity):-
	% Irrespective of the state, If you have to go home, You have to go home;
	% If you have to fill fuel, you have to fill fuel.
	%needs_to_fill_fuel(FuelStation),
	%step_to_go_to( FuelStation, MoveQuantity),
	needs_to_go_home,
	MoveType = m,
	place(F_loc,_,_,_,_,finish),
	step_to_go_to( F_loc, MoveQuantity).

move(masm_agent,_,_):-
	% Greedily pick the Item with lowest seller and highest buyer
	agent_state(decide_masm),
	retractall( masm_choice(_,_,_) ),
	find_best_item( BestSeller, BestBuyer, Q ),
	format('BestSeller: ~d BestBuyer: ~d Quantity: ~d\n', [BestSeller, BestBuyer, Q]),
	asserta( masm_choice(BestSeller, BestBuyer, Q) ),
	set_agent_state(do_masm_buy),
	fail.

% do_masm_buy
move( masm_agent, MoveType, MoveQuantity ):-
	agent_state( do_masm_buy ),
	player( masm_agent, _,_,_,_, Where ),
	masm_choice( BestSeller, _, Q),
	Where = BestSeller,
	MoveType = t,
	%max_buy( BestSeller, MoveQuantity ),
	MoveQuantity is Q,
	set_agent_state(do_masm_sell).

move( masm_agent, MoveType, MoveQuantity ):-
	agent_state( do_masm_buy ),
	%player( masm_agent, _,_,_,_, Where),
	MoveType = m,
	format('MoveType: ~s \n', [MoveType]),
	masm_choice( BestSeller, _, _),
	step_to_go_to(BestSeller, MoveQuantity).

% do_masm_sell
move( masm_agent, MoveType, MoveQuantity ):-
	agent_state( do_masm_sell ),
	player( masm_agent, _,_,_,_, Where ),
	masm_choice( _, BestBuyer, Q),
	Where = BestBuyer,
	MoveType = t,
	%max_sell( BestBuyer, MoveQuantity ),
	MoveQuantity is Q,
	%set_agent_state(do_masm_buy),
	set_agent_state(decide_masm).


move( masm_agent, MoveType, MoveQuantity ):-
	agent_state( do_masm_sell ),
%	player( masm_agent, _,_,_,_, Where ),
	masm_choice( _, BestBuyer, _),
	MoveType = m,
	step_to_go_to(BestBuyer, MoveQuantity).


find_best_item(BestSeller, BestBuyer, Quant):-
% Finds the dealers of the item with max price diff
	findall(
	    %Added 4th element Q to pppdiff structure
		pppdiff(Place1,Place2,PriceDiff, Q), % Just a name for the structure
		(
				place(Place1,_,Item,Quantity1,Price1,seller),
				player(_,_,Cash,_,Fuel,_),
				place(Place2,_,Item,Quantity2,Price2,buyer),
				place(F_loc,_,_,_,_,finish),
				Quantity is min(Quantity1, Quantity2),
				%Price1 is (Price1/100),
				%Price2 is (Price2/100),
				find_optimal_Q(Cash, Price1, Quantity, Q),
				step_to_go_to(Place1, Steps1),
				step_between(Place1, Place2, Steps2),
				step_between(Place2, F_loc, StepsF),
				absol(Steps1, S1),
				absol(Steps2, S2),
				absol(StepsF, SF),
				moves_remaining(MRemaining),
				MReqd is ((S1+8)/8)+((S2+8)/8)+((SF+8)/8)+2,
				MRemaining >= MReqd,
				Fuel >= S1+S2+SF,
				PriceDiff is (Price2 - Price1)*Q
		),
		PPList
	),
	find_max_pricediff( PPList, MaxPriceDiff),
	%Added 4th element Q to pppdiff structure
	MaxPriceDiff = pppdiff(BestSeller, BestBuyer, _, Quant).

find_optimal_Q(Cash, Price1, Quantity, Quantity):-
	Cash>=Price1*Quantity.

find_optimal_Q(Cash, Price1, Quantity, Q):-
	Cash < Price1*Quantity,
	Q1 is Quantity-1,
	find_optimal_Q(Cash, Price1, Q1, Q).

absol(A, B):-
	A < 0,
	B is -1*A.

absol(A, B):-
	A >= 0,
	B is A.
