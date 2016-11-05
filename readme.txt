This is a single-player prolog agent that plays a monopoly game of Truckin and maximizes its profit.

Game strategy:
1. Our agent runs looks for the Best Buyer and Best Seller using the find_best_item predicate in masm_agent.prolog. This predicate looks for the item that returns highest profit i.e. the item which gives maximum price difference between the product of price and quantity. We first find the quantity (Optimal_Q) of the item that can be bought, given limited amount of cash available to the agent, and choose the item which has maximum value of:

			PriceDiff = (Cost Price - Selling Price)*Optimal_Q

This predicate also gives the corresponding BestBuyer and BestSeller of the most profitable commodity.

2. Once we find the most profitable item, we proceed to buy and sell the item using move predicates.

3. After each transaction (i.e. buying and selling the best item according to find_best_item), we update the BestBuyer and BestSeller using find_best_item to find the best item given new constraints of increased cash amount. Since we expect to have a higher value of cash in hand after making a profit, we can buy a commodity of higher value. This potentially changes the best item.

4. The conditions of refilling the fuel or returning to the finish position (27 - Alice) if number of moves remaining are over, have also been implemented.

With the given code, we are getting the following results:
		No. of moves			      Money earnt
			30				$11490.18
			100				$181642.88
			200				$967889.96
