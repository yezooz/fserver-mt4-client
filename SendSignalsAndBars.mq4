//+------------------------------------------------------------------+
//|                                           SendSignalsAndBars.mq4 |
//|                               Copyright Â© 2013, Marek Mikuliszyn |
//+------------------------------------------------------------------+
#include <server.mqh>
#include <helpers.mqh>

#property copyright "Copyright © 2014, Marek Mikuliszyn"
#property link      ""

extern bool debug = false;
extern bool doSendBars = true;
extern bool doSendSignals = true;
extern bool doSendPing = true;
extern bool doSendTradeUpdates = true;
extern bool doSendPairUpdates = false;

extern bool perTF = false;
extern bool perPair = false;

string signal, pair;
double pnt, dig, spr, risk;

double up      = 0.0;
double down    = 0.0;
double size    = 0.0;
string csv     = "";

datetime lastTick;

string pairs[] = {
	"EURUSD",
	"GBPUSD",
	"USDCHF",
	"USDJPY",
	"USDCAD",
	"AUDUSD",
	"EURGBP",
	"NZDUSD",
	"EURJPY",
	"GBPCHF",
	"GBPJPY",
	"AUDCAD",
	"EURCAD",
	"EURAUD",
	"CHFJPY",
	"GBPAUD",
	"GBPCAD",
	"CADJPY",
	"AUDJPY",
	"EURNZD",
	"GBPNZD",
	"NZDCAD",
	"NZDCHF",
	"NZDJPY",
	"AUDNZD",
	"AUDCHF",
	"CADCHF"
};

int tfs[] = {
   PERIOD_M5,
   PERIOD_M15,
   PERIOD_M30,
   PERIOD_H1,
   PERIOD_H4,
   PERIOD_D1,
   //PERIOD_W1
};

datetime lastSignalM5[100];
datetime lastSignalM15[100];
datetime lastSignalM30[100];
datetime lastSignalH1[100];
datetime lastSignalH4[100];
datetime lastSignalD1[100];
//datetime lastSignalW1[100];

int init()
{
   lastTick = TimeCurrent();

   for (int i=0; i<ArraySize(pairs); i++) {
      lastSignalM5[i]   = iTime(pairs[i], PERIOD_M5,  1);
      lastSignalM15[i]  = iTime(pairs[i], PERIOD_M15, 1);
      lastSignalM30[i]  = iTime(pairs[i], PERIOD_M30, 1);
      lastSignalH1[i]   = iTime(pairs[i], PERIOD_H1,  1);
      lastSignalH4[i]   = iTime(pairs[i], PERIOD_H4,  1);
      lastSignalD1[i]   = iTime(pairs[i], PERIOD_D1,  1);
      //lastSignalW1[i]   = iTime(pairs[i], PERIOD_W1,  1);
   }

   return(0);
}

int deinit()
{
   return(0);
}

int start()
{
   everyTick();
   if (Volume[0] > 1) return(0);
   everyBar();
   
   return(0);
}

void everyTick() {
   if (TimeCurrent() - lastTick < 10) {
      return (0);
   }
   
   sendTradeUpdates();

   lastTick = TimeCurrent();
}

void everyBar() {
   
   for (int i=0; i<ArraySize(pairs); i++) {
      if (iTime(pairs[i], PERIOD_M5, 1) != lastSignalM5[i]) {
         sendStuff(pairs[i], PERIOD_M5);
         lastSignalM5[i] = iTime(pairs[i], PERIOD_M5, 1);
      }
      if (iTime(pairs[i], PERIOD_M15, 1) != lastSignalM15[i]) {
         sendStuff(pairs[i], PERIOD_M15);
         lastSignalM15[i] = iTime(pairs[i], PERIOD_M15, 1);
      }
      if (iTime(pairs[i], PERIOD_M30, 1) != lastSignalM30[i]) {
         sendStuff(pairs[i], PERIOD_M30);
         lastSignalM30[i] = iTime(pairs[i], PERIOD_M30, 1);
      }
      if (iTime(pairs[i], PERIOD_H1, 1) != lastSignalH1[i]) {
         sendStuff(pairs[i], PERIOD_H1);
         lastSignalH1[i] = iTime(pairs[i], PERIOD_H1, 1);
      }
      if (iTime(pairs[i], PERIOD_H4, 1) != lastSignalH4[i]) {
         sendStuff(pairs[i], PERIOD_H4);
         lastSignalH4[i] = iTime(pairs[i], PERIOD_H4, 1);
      }
      if (iTime(pairs[i], PERIOD_D1, 1) != lastSignalD1[i]) {
         sendStuff(pairs[i], PERIOD_D1);
         sendPairUpdates(pairs[i]);
         lastSignalD1[i] = iTime(pairs[i], PERIOD_D1, 1);
      }
      //if (iTime(pairs[i], PERIOD_W1, 1) != lastSignalW1[i]) {
      //   sendStuff(pairs[i], PERIOD_W1);
      //   lastSignalW1[i] = iTime(pairs[i], PERIOD_W1, 1);
      //}
   }

   sendPing();

   iCustom("EURUSD", PERIOD_M1, "Pin", 0, 1);
}

void sendStuff(string pair, int tf) {
   if (perTF && tf != Period()) return;

   sendBar(pair, tf);
   sendSignals(pair, tf);
}

void sendSignals(string pair, int tf) {
   if (!doSendSignals) return;

   if (tf >= PERIOD_D1) {
      findSignals(pair, tf, "Pin", "pin");
      findSignals(pair, tf, "Pin", "pin_v2");
   }
   findSignals(pair, tf, "Pin", "pin_divergence");
   //findSignals(pair, tf, "DblPin", "double_pin");
   //findSignals(pair, tf, "DblPin", "double_pin_div");
}

void sendBar(string pair, int tf) {
   if (!doSendBars) return;

   serverGet("/signal/writer/bar", StringConcatenate("pair=", pair, "&tf=", getPeriodName(tf), "&time=", iTime(pair, tf, 1), "&open=", DoubleToStr(iOpen(pair, tf, 1), 5), "&high=", DoubleToStr(iHigh(pair, tf, 1), 5), "&low=", DoubleToStr(iLow(pair, tf, 1), 5), "&close=", DoubleToStr(iClose(pair, tf, 1), 5), "&"));
}

void sendPing() {
   if (doSendTradeUpdates && OrdersTotal() > 0) return;
   if (!doSendPing) return;

   serverGet("/signal/writer/ping", "");
}

void sendTradeUpdates() {
   if (!doSendTradeUpdates) return;

   for (int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         string trade_id = OrderComment();
         double profit = OrderProfit();
         
         // poki co nie ma trade_id
         
         serverGet("/signal/writer/update", StringConcatenate("trade_id=", trade_id, "&profit=", profit));
      }
      else {
         Print("Error when order select ", GetLastError());
         break;
      }
   }
}

void sendPairUpdates(string pair) {
   if (!doSendPairUpdates) return;
   
   serverGet("/pair/", StringConcatenate("pair=", pair, "&pip_value=", DoubleToStr(MarketInfo(pair, MODE_TICKVALUE), 5), "&digits=", MarketInfo(pair, MODE_DIGITS)));
}

void findSignals(string pair, int period, string indicatorName, string systemName) {
   if (systemName == "pin") {
      up = iCustom(pair, period, indicatorName, 10, 0, 1);
      down = iCustom(pair, period, indicatorName, 10, 1, 1);
   }
   else if (systemName == "pin_v2") {
      up = iCustom(pair, period, indicatorName, 50, true, false, 0, 1);
      down = iCustom(pair, period, indicatorName, 50, true, false, 1, 1);
   }
   else if (systemName == "pin_divergence") {
      up = iCustom(pair, period, indicatorName, 10, false, true, 0, 1);
      down = iCustom(pair, period, indicatorName, 10, false, true, 1, 1);
   }
   else if (systemName == "double_pin") {
      up = iCustom(pair, period, indicatorName, 10, false, false, true, true, 0, 1);
      down = iCustom(pair, period, indicatorName, 10, false, false, true, true, 1, 1);
   }
   else if (systemName == "double_pin_div") {
      up = iCustom(pair, period, indicatorName, 10, true, false, true, true, 0, 1);
      down = iCustom(pair, period, indicatorName, 10, true, false, true, true, 1, 1);
   }

   if (up > 0 && up < 10000) {
      csv = StringConcatenate(
         "BUY,",
         DoubleToStr(iOpen(pair, period, 1), 5), ",",
         DoubleToStr(iHigh(pair, period, 1), 5), ",",
         DoubleToStr(iLow(pair, period, 1), 5), ",",
         DoubleToStr(iClose(pair, period, 1), 5), ",",
         Replace(TimeToStr(iTime(pair, period, 0), TIME_DATE), ".", "-"), " ", TimeToStr(iTime(pair, period, 0), TIME_MINUTES)
      );
   }
   else if (down > 0 && down < 10000) {
      csv = StringConcatenate(
         "SELL,",
         DoubleToStr(iOpen(pair, period, 1), 5), ",",
         DoubleToStr(iHigh(pair, period, 1), 5), ",",
         DoubleToStr(iLow(pair, period, 1), 5), ",",
         DoubleToStr(iClose(pair, period, 1), 5), ",",
         Replace(TimeToStr(iTime(pair, period, 0), TIME_DATE), ".", "-"), " ", TimeToStr(iTime(pair, period, 0), TIME_MINUTES)
      );
   }
   else {
      return;
   }

   sendCSVToServer(systemName, pair, period, csv);
}