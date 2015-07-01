//+------------------------------------------------------------------+
//|                                                       Bridge.mq4 |
//|                                          Copyright © 2012, w3net |
//|                                              http://www.w3net.pl |
//+------------------------------------------------------------------+
#include <helpers.mqh>
#include <server.mqh>
#include <trade.mqh>

#property copyright "Copyright © 2012, Marek Mikuliszyn"

extern double risk = 0.01;
extern int tp_sl_margin = 500;

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
   int handle = FileOpen(Symbol() + ".csv", FILE_CSV|FILE_READ, ';');
   if (handle > -1)
   {
      while (FileIsEnding(handle) == false)
      {   
         signal = FileReadString(handle);
         processSignal();
         
         if (FileIsEnding(handle) == true)
            break;
      }

      FileClose(handle);
   
      FileDelete(Symbol() + ".csv");
   }
   
   manageTrades();
}

void everyBar()
{       
   signal = "";
      
   // refresh cash
   if (Hour() == 0 && Minute() == 0 && AccountBalance() > cash) cash = AccountBalance();
}

// --- Trading

void processSignal()
{
   string csv[], comment;
   int dir, ticket;
   double entry, tp, sl, size;
   
   if (signal != "") Split(signal, ",", csv);
   
   if (csv[0] == "BUY") dir = OP_BUY;
   else                 dir = OP_SELL;
   
   size = StrToDouble(csv[1]);
   entry = StrToDouble(csv[2]);
   tp = StrToDouble(csv[3]);
   sl = StrToDouble(csv[4]);
   comment = csv[5];
   
   if (csv[0] == "CLOSE") {
      
   
      signal = "";
      return;
   }
   
   // tylko raz jeden sygnal
   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderComment() == comment)
         {
            Print("Cancelled signal");
            signal = "";
            return;
         }
      }
   }
   
   if (dir == OP_BUY)  ticket = openTrade(Symbol(), dir, getLot(Symbol(), risk, size), sl - tp_sl_margin * pnt, tp + tp_sl_margin * pnt, comment);
   if (dir == OP_SELL) ticket = openTrade(Symbol(), dir, getLot(Symbol(), risk, size), sl + tp_sl_margin * pnt, tp - tp_sl_margin * pnt, comment);
      
   Print("Trade opened");
      
   signal = "";
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
             (cmd == OP_SELL && (Ask <= OrderTakeProfit() + tp_sl_margin * pnt || Bid > OrderStopLoss() - tp_sl_margin * pnt)) ||
             (Time[0] > OrderOpenTime() + (50 * Period() * 60) && OrderProfit() > 0)) {
            
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