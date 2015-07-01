//+------------------------------------------------------------------+
//|                                                  helpers_new.mqh |
//|                      Copyright © 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property strict

string getPeriodName(int period=0)
{
   if (period == 0) period = Period();
   
   switch (period) {
      case PERIOD_M1:
      case PERIOD_M5:
      case PERIOD_M15:
      case PERIOD_M30:
         return ("M" + period);
      case PERIOD_H1:
      case PERIOD_H4:
         return ("H" + (period / 60));
      case PERIOD_D1:
         return ("D1");
      case PERIOD_W1:
         return ("W1");
      default:
         return (period);
   }
}