#property copyright "Copyright © 2012, Marek Mikuliszyn"

#define minLot 0.1
#define maxLot 5.0

#define debug 0
#define notifyServer 0

#include <server.mqh>
#include <settings.mqh>

int openTrade (string pair, int op, double lots, double sl, double tp, string comment="") {
   int ticket, dir, error;
   double price;
   
   double pnt = MarketInfo(pair, MODE_POINT);
   
   if      (op == OP_BUY)  {
      price = Ask;
   }
   else if (op == OP_SELL) {
      price = Bid;
   }
   
   while(true) {
      ticket = OrderSend(pair, op, lots, price, getSlippage(), 0.0, 0.0, comment, 0, 0, CLR_NONE);
      
      if (ticket < 0) {
         error = GetLastError();
         if (debug == 1) Print("LastError = ", error);
      }
      else {
         OrderSelect(ticket, SELECT_BY_TICKET);
         
         double actualPrice = OrderOpenPrice();
         
         if (op == OP_BUY) {
            tp += MathAbs(price - actualPrice) * pnt;
            sl -= MathAbs(price - actualPrice) * pnt;
         }
         else {
            tp -= MathAbs(price - actualPrice) * pnt;
            sl += MathAbs(price - actualPrice) * pnt;
         }
      
         OrderModify(ticket, price, sl, tp, 0, CLR_NONE);
         
         if (notifyServer == 1) {
            serverGet("/report/", StringConcatenate("action=open_trade&",
               "ticket=", ticket, "&",
               "size=", DoubleToStr(OrderLots(), 3), "&",
               "projected_tp=", DoubleToStr(tp, 5), "&",
               "projected_sl=", DoubleToStr(sl, 5), "&",
               "tp=", DoubleToStr(OrderTakeProfit(), 5), "&",
               "sl=", DoubleToStr(OrderStopLoss(), 5), "&",
               "price=", DoubleToStr(OrderOpenPrice(), 5), "&",
               "spread=", MarketInfo(pair, MODE_SPREAD), "&"));
         }
         
         return (ticket);
      }
      
      if (error == 130) { 
         if (debug == 1) {
            Print("WRONG STOPS! price=" + DoubleToStr(price, 5) + ";sl=" + DoubleToStr(sl, 5) + ";tp=" + DoubleToStr(tp, 5));
            //SendMail("Wrong Stops", "price=" + DoubleToStr(price, 5) + ";sl=" + DoubleToStr(sl, 5) + ";tp=" + DoubleToStr(tp, 5) + ". " + getBroker());
         }
         if (notifyServer == 1) {
            serverGet("/report/log/", "action=open_error&signal_id=" + Replace(comment, "signal=") + "&comment=wrong stops&");
         }
         return (0);
      }
      if (error == 138) RefreshRates();
      if (error == 132 || error == 133) return (0);
      if (error == 134) {
         if (debug == 1) {
            //SendMail("No money to open trade", pair + ", " + lots + " lot. " + getBroker());
            Print("No money to open trade", pair + ", " + lots + " lot. ");
         }
         if (notifyServer == 1) {
            serverGet("/report/log/", "action=open_error&signal_id=" + Replace(comment, "signal=") + "&comment=no money&");
         }
         return (0);
      }
      if (error == 131) {
         if (notifyServer == 1) {
            serverGet("/report/log/", "action=open_error&signal_id=" + Replace(comment, "signal=") + "&comment=" + lots + " is invalid number of lots&");
         }
         return (0);
      }
   }
}

double closeTrade (int ticket, double price) {
   bool result, error;
   OrderSelect(ticket, SELECT_BY_TICKET);
   
   while(true) {
      result = OrderClose(OrderTicket(), OrderLots(), price, getSlippage(), CLR_NONE);
      
      if (result != TRUE) {
         error = GetLastError();
         
         if (debug == 1) {
            Print("LastError = ", error);
         }
         if (notifyServer == 1) {
            serverGet("/report/log/", "action=close_error&signal_id=" + Replace(OrderComment(), "signal=") + "&comment=" + error + "&");
         }
      }
      else {
         error = 0;
         
         if (notifyServer == 1) {
            serverGet("/report/", StringConcatenate("action=close_trade&ticket=", OrderTicket(), "&",
               "price=", DoubleToStr(OrderClosePrice(), 5), "&",
               "spread=", MarketInfo(OrderSymbol(), MODE_SPREAD), "&",
               "profit=", DoubleToStr(OrderProfit(), 2), "&"));
         }
      }
      
      if (error == 135) RefreshRates();
      else return (OrderProfit());
   }
}

bool canTrade()
{
   if (!IsTradeAllowed()) return (false);
   
   return (isRightTimeToTrade());
}

bool isRightTimeToTrade()
{
   // TOOD: implement
   return (true);
}

// --- MW Breakout

string makeSignalStringForMWB (int i, double high, double low, int direction, double tp, double sl)
{
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   string csv, dir;
   double activation, entry, size;
   
   if (direction == OP_BUY)       dir = "BUY";
   else if (direction == OP_SELL) dir = "SELL";
   
   if (direction == OP_BUY)
   {
      activation = high + getActivationDistanceForMWB() * pnt;
      entry = activation;
   }
   else
   {
      activation = low - getActivationDistanceForMWB() * pnt;
      entry = activation;
   }
   
   size = (high - low) + spr * pnt + getActivationDistanceForMWB() * pnt;
   
   csv = StringConcatenate(
      dir, ",",
      DoubleToStr(size, 5), ",",
      DoubleToStr(activation, 5), ",",
      DoubleToStr(entry, 5), ",",
      DoubleToStr(tp, 5), ",",
      DoubleToStr(sl, 5), ",",
      Time[i], ",",
      Time[i] + (getSignalCancelPeriodForMWB() * Period() * 60)
   );
   
   //Print(csv);
   
   return (csv);
}

string makeSignalWithPriceTPAndSL (int i, int direction, double tp, double sl)
{
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   string csv, dir;
   double entry, size, high, low;
   
   high = High[i];
   low = Low[i];
   
   if (direction == OP_BUY) {
      dir = "BUY";
      entry = high + ((high - low) * 0.1);
   }
   else if (direction == OP_SELL) {
      dir = "SELL";
      entry = low - ((high - low) * 0.1);
   }
   
   size = (high - low) + spr * pnt;
   
   csv = StringConcatenate(
      dir, ",",
      DoubleToStr(size, 5), ",",
      DoubleToStr(entry, 5), ",",
      DoubleToStr(tp, 5), ",",
      DoubleToStr(sl, 5), ",",
      Time[i], ",",
      Time[i] + (getSignalCancelPeriod() * Period() * 60)
   );
   
   //Print(csv);
   
   return (csv);
}

string makeSignalStringWithTPAndSL (int i, int direction, double tp, double sl)
{
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   string csv, dir;
   double activation, entry, size, high, low;
   
   high = High[i];
   low = Low[i];
   
   if (direction == OP_BUY)       dir = "BUY";
   else if (direction == OP_SELL) dir = "SELL";
   
   if (direction == OP_BUY)
   {
      activation = high + getActivationDistance() * pnt;
      entry = high + getEntryDistance() * pnt;
   }
   else
   {
      activation = low - getActivationDistance() * pnt;
      entry = low - getEntryDistance() * pnt;
   }
   
   size = (high - low) + spr * pnt + getActivationDistance() * pnt;
   
   csv = StringConcatenate(
      dir, ",",
      DoubleToStr(size, 5), ",",
      DoubleToStr(activation, 5), ",",
      DoubleToStr(entry, 5), ",",
      DoubleToStr(tp, 5), ",",
      DoubleToStr(sl, 5), ",",
      Time[i], ",",
      Time[i] + (getSignalCancelPeriod() * Period() * 60)
   );
   
   //Print(csv);
   
   return (csv);
}

string makeSignalString (int i, int direction, string system)
{
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   string csv, dir;
   double activation, entry, tp, sl, size, high, low;
   
   if (system == "1_bar")
   {
      high = High[i];
      low = Low[i];
   }
   else if (system == "2_bar")
   {
      if (direction == OP_BUY) {
         high = High[i];
         low = Low[iLowest(NULL, 0, MODE_LOW, 2, i)];
      }
      else {
         high = High[iHighest(NULL, 0, MODE_HIGH, 2, i)];
         low = Low[i];
      }
   }
   else if (system == "3_bar" || system == "momentum")
   {
      if (direction == OP_BUY) {
         high = High[i];
         low = Low[iLowest(NULL, 0, MODE_LOW, 3, i)];
      }
      else {
         high = High[iHighest(NULL, 0, MODE_HIGH, 3, i)];
         low = Low[i];
      }
   }
   
   if (direction == OP_BUY)       dir = "BUY";
   else if (direction == OP_SELL) dir = "SELL";
   
   if (direction == OP_BUY)
   {
      activation = high + getActivationDistance(system) * pnt;
      entry = high + getEntryDistance(system) * pnt;
      tp = high + ((high - low) + spr * pnt + spr * pnt + getSlippage() * pnt + getEntryDistance(system) * pnt + getExitDistance(system) * pnt) * getRR(system);
      sl = low - getExitDistance(system) * pnt;
      //tp = high + getATRTP(i);
      //sl = high - getATRSL(i);
   }
   else
   {
      activation = low - getActivationDistance(system) * pnt;
      entry = low - getEntryDistance(system) * pnt;
      tp = low - ((high - low) + spr * pnt + spr * pnt + getSlippage() * pnt + getEntryDistance(system) * pnt + getExitDistance(system) * pnt) * getRR(system);
      sl = high + getExitDistance(system) * pnt;
      //tp = low - getATRTP(i);
      //sl = low + getATRSL(i);
   }
   
   size = high - low;
   
   csv = StringConcatenate(
      dir, ",",
      DoubleToStr(size, 5), ",",
      DoubleToStr(activation, 5), ",",
      DoubleToStr(entry, 5), ",",
      DoubleToStr(tp, 5), ",",
      DoubleToStr(sl, 5), ",",
      Time[i], ",",
      Time[i] + (getSignalCancelPeriod(system) * Period() * 60)
   );
   
   //Print(csv);
   
   return (csv);
}

double getATRTP(int i) {
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   return (((iATR(NULL, 0, 14, i) * 1.5) * getRR()) + spr * pnt);
}

double getATRSL(int i) {
   return (iATR(NULL, 0, 14, i) * 1.5);
}