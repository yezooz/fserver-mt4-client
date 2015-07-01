//+------------------------------------------------------------------+
//|                                                          Pin.mq4 |
//|                                     Copyright © 2012-2014, w3net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2014, w3net"
#property link      "http://www.w3net.pl"

#property indicator_chart_window
#property indicator_buffers 0

#include <helpers.mqh>

extern string drawTF = "H4";
extern int barLimit = 10000;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{   
   if (barLimit >= 1000)
      drawRectangle(5000, 0, Time[barLimit], Time[barLimit+1], "_candle", Red);
   
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   for(int x = ObjectsTotal()-1; x >= 0; x--) {
		if (StringFind(ObjectName(x), "_pin") == -1 && StringFind(ObjectName(x), "_candle") == -1) continue;
		ObjectDelete(ObjectName(x));
	}
	
   return(0);
}

int getTF(string tf) {
   if (tf == "W1")
      return PERIOD_W1;
   if (tf == "D1")
      return PERIOD_D1;
   if (tf == "H4")
      return PERIOD_H4;
   if (tf == "H1")
      return PERIOD_H1;
   if (tf == "M30")
      return PERIOD_M30;
   if (tf == "M15")
      return PERIOD_M15;
   if (tf == "M5")
      return PERIOD_M5;
   return PERIOD_H1;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   
   if (counted_bars < 0) return(-1);
   if (counted_bars > 0) counted_bars--;
   
   int limit = barLimit;
   if (limit == 0) {
      limit = Bars - counted_bars;
   }
   
   int tf = getTF(drawTF);
   
   for(int i=1; i<limit; i++)
   {
      double up   = iCustom(NULL, tf, "Pin", 0, i);
      double down = iCustom(NULL, tf, "Pin", 1, i);
      
      if (up == 0 && down == 0) {
         continue;
      }
      
      drawRectangle(iHigh(NULL, tf, i), iLow(NULL, tf, i), iTime(NULL, tf, i-1), iTime(NULL, tf, (i>50 ? i-50 : 0)), "_pin", (up > 0 ? Lime : Salmon));
      //drawRectangle(5000, 0, iTime(NULL, tf, i), iTime(NULL, tf, i-1), "_candle", (up > 0 ? Lime : Salmon));
   }
   
   return(0);
}