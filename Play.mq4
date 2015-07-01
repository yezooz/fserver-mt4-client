//+------------------------------------------------------------------+
//|                                                         Play.mq4 |
//|                                          Copyright © 2012, w3net |
//|                                              http://www.w3net.pl |
//+------------------------------------------------------------------+

// graj zgodnie z wybranym indykatorem

#include <helpers.mqh>
#include <server.mqh>
#include <trade.mqh>

#property copyright "Copyright © 2012, Marek Mikuliszyn"

extern string indicator = "DblPin";

extern int minHour = 8;
extern int maxHour = 20;
extern double risk = 0.05;
extern int tp_sl_margin = 50;
extern double exit_percent = 0.2;
double RR = 1.0;

string signal = "";

double pnt, dig, spr, cash;

int init()
{
   pnt = MarketInfo(Symbol(), MODE_POINT);
   dig = MarketInfo(Symbol(), MODE_DIGITS);
   spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   if (cash == 0) cash = AccountBalance();
   
   return(0);
}

int deinit()
{
   return(0);
}

int start()
{   
   spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   everyTick();
   if (Volume[0] == 1) everyBar();
   
   return(0);
}

void everyTick()
{
   manageSignal();
   manageTrades();
}

void everyBar()
{
   double size = High[1] - Low[1];
   
   //if (TimeHour(Time[1]) < minHour || TimeHour(Time[1]) > maxHour) return (0);
   if (size < 50 * pnt) return (0);

   //double up      = iCustom(NULL, 0, indicator, 10, false, true, 0, 1);
   //double down    = iCustom(NULL, 0, indicator, 10, false, true,1, 1);

   double up      = iCustom(NULL, 0, indicator, 10, true, false, true, true, 0, 1);
   double down    = iCustom(NULL, 0, indicator, 10, true, false, true, true, 1, 1);
   double up_tp   = High[1] + (size * RR); //iCustom(NULL, 0, indicator, 2, 1);
   double up_sl   = Low[1] - (size * exit_percent); //iCustom(NULL, 0, indicator, 3, 1);
   double down_tp = Low[1] - (size * RR); //iCustom(NULL, 0, indicator, 4, 1);
   double down_sl = High[1] + (size * exit_percent); //iCustom(NULL, 0, indicator, 5, 1);
   
   if (up > 0)
      signal = makeSignalWithPriceTPAndSL (1, OP_BUY, up_tp, up_sl);
   else if (down > 0)
      signal = makeSignalWithPriceTPAndSL (1, OP_SELL, down_tp, down_sl);
   else
      return;
      
   // refresh cash
   if (Hour() == 0 && Minute() == 0 && AccountBalance() > cash) cash = AccountBalance();
}

// --- Trading

void manageSignal()
{
   if (signal == "") return;
   
   // tylko jeden trade na raz
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol())
         {
            Print("Cancelled signal");
            signal = "";
            return;
         }
      }
   }
   
   processSignal(); // process main signal
}

void processSignal()
{
   string csv[];
   int dir, ticket;
   double entry, tp, sl, size;
   int valid_until;
   
   if (signal != "") Split(signal, ",", csv);
   
   if (csv[0] == "BUY")  dir = OP_BUY;
   else                  dir = OP_SELL;
   
   size = StrToDouble(csv[1]);
   entry = StrToDouble(csv[2]);
   tp = StrToDouble(csv[3]);
   sl = StrToDouble(csv[4]);
   valid_until = StrToInteger(csv[6]);
   
   if (valid_until <= Time[1]) {
      Print("Signal removed");
      
      signal = "";
      return;
   }
   
   if ((dir == OP_BUY && Bid >= entry) || (dir == OP_SELL && Bid <= entry))
   {
      if (dir == OP_BUY)  ticket = openTrade(Symbol(), dir, getLot(Symbol(), risk, size), sl - tp_sl_margin * pnt, tp + tp_sl_margin * pnt, Symbol() + "_" + getPeriodName(Period()));
      if (dir == OP_SELL) ticket = openTrade(Symbol(), dir, getLot(Symbol(), risk, size), sl + tp_sl_margin * pnt, tp - tp_sl_margin * pnt, Symbol() + "_" + getPeriodName(Period()));
      
      //OrderSelect(ticket, SELECT_BY_TICKET);
      
      //Print("TP = " + DoubleToStr((MathAbs(Bid - OrderTakeProfit()) - tp_sl_margin * pnt), 5) + "; SL = " + DoubleToStr((MathAbs(Bid - OrderStopLoss()) - tp_sl_margin * pnt), 5));
      
      Print("Trade opened");
      
      signal = "";
   }
}

void manageTrades()
{
   bool result;
   int cmd, total, error;
   double profit;
   
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         cmd = OrderType();
         if (cmd != OP_BUY && cmd != OP_SELL) continue;
         //if (OrderTakeProfit() == 0.0 || OrderStopLoss() == 0.0) continue;
         if (OrderComment() != Symbol() + "_" + getPeriodName(Period())) continue;
         
         // zamykaj zlecenie ktory dotarly do poziomu SOFT TP/SL
         if ((cmd == OP_BUY  && (Bid >= OrderTakeProfit() - tp_sl_margin * pnt || Bid < OrderStopLoss() + tp_sl_margin * pnt)) || 
             (cmd == OP_SELL && (Ask <= OrderTakeProfit() + tp_sl_margin * pnt || Bid > OrderStopLoss() - tp_sl_margin * pnt))) {
            
            if (cmd == OP_BUY)  profit = closeTrade(OrderTicket(), Bid);
            if (cmd == OP_SELL) profit = closeTrade(OrderTicket(), Ask);
            
            // update
            if (profit >= 0.0) {
               Print("Soft TP. +$" + DoubleToStr(profit, 2));
               //SendMail("TP (" + getBroker() + ")", "+$" + DoubleToStr(profit, 2));
            }
            else {
               Print("Soft SL. -$" + DoubleToStr(MathAbs(profit), 2));
               //SendMail("SL (" + getBroker() + ")", "-$" + DoubleToStr(MathAbs(profit), 2));
            }
         }
      }
      else {
         Print("Error when order select ", GetLastError());
         break;
      }
   }
}

double getLot(string pair, double risk, double size) 
{
   double amnt = cash * risk;
   double dig = MarketInfo(pair, MODE_DIGITS);
   
   if      (dig >= 4) size *= 100000;
   else if (dig >= 2) size *= 1000;
   
   double lot = amnt / (size * MarketInfo(pair, MODE_TICKVALUE));
   
   if (lot > maxLot) return (maxLot);
   if (lot < minLot) return (minLot);
   
   if (MarketInfo(Symbol(), MODE_LOTSTEP) == 0.01)
      return (StrToDouble(DoubleToStr(lot, 2)));
   if (MarketInfo(Symbol(), MODE_LOTSTEP) == 0.1)
      return (StrToDouble(DoubleToStr(lot, 1)));
   if (MarketInfo(Symbol(), MODE_LOTSTEP) == 1)
      return (StrToDouble(DoubleToStr(lot, 0)));
}