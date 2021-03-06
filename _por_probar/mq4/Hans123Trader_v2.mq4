//+------------------------------------------------------------------+
//|                                                Hans123Trader v2  |
//+------------------------------------------------------------------+
#include <stdlib.mqh>

#property copyright   "hans123"
#property link        "http://www.strategybuilderfx.com/forums/showthread.php?t=15439"
// programmed by fukinagashi

extern int BeginSession1=6;
extern int EndSession1=10;
extern int BeginSession2=10;
extern int EndSession2=14;
extern int Spread=4;

extern int ClsOnlUnprTX=1; // 1 = yes / 0 = no
extern int AtMarketIfPendingImpossible=1; // 1= yes / 0 = no

extern double TrailingStop = 0;
extern double TakeProfit = 0;
extern double InitialStopLoss=0;

double Lots = 1;
datetime bartime = 0;
double Slippage=3;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
   {
   int cnt, ticket, err, i, j, cmd;
   int MagicNumber;
   double ts, tp, LowestPrice, HighestPrice, Price;
   bool Order[5];
   string setup;
   datetime Validity=0;

	MagicNumber = 50000 + func_Symbol2Val(Symbol())*100; 

   setup="H123_" + Symbol();

   if (bartime == Time[0]) {
      return(0);
   } else {
      bartime = Time[0]; 
   }



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// MODIFICATIONS ON OPEN ORDERS   ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


   for(cnt=OrdersTotal();cnt>=0;cnt--)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() && (OrderMagicNumber()==MagicNumber+1 || OrderMagicNumber()==MagicNumber+3)) {
      	if(TimeDay(OrderOpenTime())!=TimeDay(Time[0])) {
            if (ClsOnlUnprTX==1) {
               if(Bid-OrderOpenPrice()>0) {
                  OrderClose(OrderTicket(), Lots, Bid, 3, Red);
               }
            } else {
         		 OrderClose(OrderTicket(), Lots, Bid, 3, Red);
         	}
      		if (err>1) { Print("Error closing buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (OrderStopLoss()==0) {
				if (TakeProfit>0) {  tp=OrderOpenPrice()+TakeProfit*Point;
				} else { 				tp=0; }
				if (InitialStopLoss>0) { 	ts=OrderOpenPrice()-InitialStopLoss*Point;
				} else { 						ts=0; }
				OrderModify(OrderTicket(),OrderOpenPrice(),ts,tp,0,White);
				if (err>1) { Print("Error modifying Buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (TrailingStop>0) {	
				ts = Bid-Point*TrailingStop;
				if (OrderStopLoss()<ts && Bid-OrderOpenPrice()>Point*TrailingStop) OrderModify(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
			}
      } else if(OrderType()==OP_SELL && OrderSymbol()==Symbol() && (OrderMagicNumber()==MagicNumber+2 || OrderMagicNumber()==MagicNumber+4)) {
      	if(TimeDay(OrderOpenTime())!=TimeDay(Time[0])) {
            if (ClsOnlUnprTX==1) {
               if(OrderOpenPrice()-Ask>0) {
                  OrderClose(OrderTicket(), Lots, Ask, 3, Red);
               }
            } else {
         		 OrderClose(OrderTicket(), Lots, Ask, 3, Red);
         	}
      		if (err>1) { Print("Error closing Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (OrderStopLoss()==0) {
				if (TakeProfit>0) {  tp=OrderOpenPrice()-TakeProfit*Point;
				} else { 				tp=0; }
				if (InitialStopLoss>0) { 	ts=OrderOpenPrice()+InitialStopLoss*Point;
				} else { 						ts=0; }
				OrderModify(OrderTicket(),OrderOpenPrice(),ts,tp,0,White);
				if (err>1) { Print("Error modifying Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (TrailingStop>0) {	
				ts = Ask+Point*TrailingStop;
				if (OrderStopLoss()>ts && (OrderOpenPrice()-Ask)>(Point*TrailingStop)) OrderModify(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
			}
		}
	}
			

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// SETTING ORDERS                 ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   if(AccountFreeMargin()<(1000*Lots)) return(0);  
   
	Validity=StrToTime(TimeYear(Time[0]) + "." + TimeMonth(Time[0]) + "." + TimeDay(Time[0]) + " 23:59");

	
	for(i=1;i<5;i++) { Order[i]=false; }
	
   for(cnt=OrdersTotal();cnt>=0;cnt--) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber+1) {
      	Order[1]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber+2) {
      	Order[2]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber+3) {
      	Order[3]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber+4) {
      	Order[4]=true;
      }
	}      	
	
	
	if (TimeHour(Time[0])==EndSession1 && TimeMinute(Time[0])==0) {
		
		LowestPrice=Low[Lowest(NULL, 0, MODE_LOW, 240/Period(), 0)];
		HighestPrice=High[Highest(NULL, 0, MODE_HIGH, 240/Period(), 0)];
		
		Print("Determine Low: " + LowestPrice + " and High: " + HighestPrice + " for timephase " + TimeToStr(Time[240/Period()]) + " - " + TimeToStr(Time[0]));
		
		//// the following is necessary, to avoid a BUYSTOP/SELLSTOP Price which is too close to Bid/Ask, 
		//// in which case we get a 130 invalid stops. 
		//// I experimented to change to proper OP_BUY and OP_SELL, but the results where not satisfying
		
		if (AtMarketIfPendingImpossible==1 && HighestPrice+5*Point<Ask+Spread*Point) {
			cmd=OP_BUY;
			Price=Ask;
		} else {
			cmd=OP_BUYSTOP;
			Price=HighestPrice+5*Point;
		}

		if (!Order[1]) ticket=OrderSendExtended(Symbol(),cmd,Lots,Price,Slippage,0,0,setup,MagicNumber+1,Validity,Green);
      	   
		err = GetLastError();
		if (err>1) { Print("Error modifying Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
		
		if (AtMarketIfPendingImpossible==1 && LowestPrice-5*Point>Bid-Spread*Point) {
			cmd=OP_SELL;
			Price=Bid;
		} else {
			cmd=OP_SELLSTOP;
			Price=LowestPrice-5*Point;
		}

		if (!Order[2]) ticket=OrderSendExtended(Symbol(),OP_SELLSTOP,Lots,Price,Slippage,0,0,setup,MagicNumber+2,Validity,Green); 
		err = GetLastError();
		if (err>1) { Print("Error modifying Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
	}
	
	if (TimeHour(Time[0])==EndSession2 && TimeMinute(Time[0])==0) {

		LowestPrice=Low[Lowest(NULL, 0, MODE_LOW, 240/Period(), 0)];
		HighestPrice=High[Highest(NULL, 0, MODE_HIGH, 240/Period(), 0)];
		
		Print("Determine Low: " + LowestPrice + " and High: " + HighestPrice + " for timephase " + TimeToStr(Time[240/Period()]) + " - " + TimeToStr(Time[0]));

		if (AtMarketIfPendingImpossible==1 && HighestPrice+5*Point<Ask+Spread*Point) {
			cmd=OP_BUY;
			Price=Ask;
		} else {
			cmd=OP_BUYSTOP;
			Price=HighestPrice+5*Point;
		}

		if (!Order[3]) ticket=OrderSendExtended(Symbol(),cmd,Lots,Price,Slippage,0,0,setup,MagicNumber+3,Validity,Green); 
		err = GetLastError();
		if (err>1) { Print("Error modifying Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }

		if (AtMarketIfPendingImpossible==1 && LowestPrice-5*Point>Bid-Spread*Point) {
			cmd=OP_SELL;
			Price=Bid;
		} else {
			cmd=OP_SELLSTOP;
			Price=LowestPrice-5*Point;
		}
					
		if (!Order[4]) ticket=OrderSendExtended(Symbol(),cmd,Lots,Price,Slippage,0,0,setup,MagicNumber+4,Validity,Green);
		err = GetLastError();
		if (err>1) { Print("Error modifying Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// DIVERSE SUBROUTINES   /////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int func_Symbol2Val(string symbol) {
	if(symbol=="AUDUSD") {	return(01);

	} else if(symbol=="CHFJPY") {	return(10);

	} else if(symbol=="EURAUD") {	return(10);
	} else if(symbol=="EURCAD") {	return(11);
	} else if(symbol=="EURCHF") {	return(12);
	} else if(symbol=="EURGBP") {	return(13);
	} else if(symbol=="EURJPY") {	return(14);
	} else if(symbol=="EURUSD") {	return(15);

	} else if(symbol=="GBPCHF") {	return(20);
	} else if(symbol=="GBPJPY") {	return(21);
	} else if(symbol=="GBPUSD") { return(22);


	} else if(symbol=="USDCAD") {	return(40);
	} else if(symbol=="USDCHF") {	return(41);
	} else if(symbol=="USDJPY") {	return(42);


	} else if(symbol=="GOLD") {	return(90);
	} else {	Comment("unexpected Symbol"); return(0);
	}
}

int OrderSendExtended(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic, datetime expiration=0, color arrow_color=CLR_NONE) {
   datetime OldCurTime;
   int timeout=30;
   int ticket;

   OldCurTime=CurTime();
   while (GlobalVariableCheck("InTrade") && !IsTradeAllowed()) {
      if(OldCurTime+timeout<=CurTime()) {
         Print("Error in OrderSendExtended(): Timeout encountered");
         return(0); 
      }
      Sleep(1000);
   }
     
   GlobalVariableSet("InTrade", CurTime());  // set lock indicator
   ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
   GlobalVariableDel("InTrade");   // clear lock indicator
   return(ticket);
}

