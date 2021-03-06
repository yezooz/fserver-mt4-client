//+------------------------------------------------------------------+
//|                                                          Pin.mq4 |
//|                                     Copyright � 2012-2014, w3net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2012-2014, w3net"
#property link      "http://www.w3net.pl"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Green
#property indicator_color2 Red

#include <helpers.mqh>

double BufferUp[];
double BufferDown[];
double spr, pnt, dig;

extern int barLimit = 1000;

bool V2 = false;
extern bool pinDiv1 = false;
extern bool pinDiv2 = false;
extern bool pinInPin = true;
extern bool checkDirection = true;

extern double pinBodyToCandle = 0.33;
extern double pinShortToBody = 0.15;

bool perfectPin = false;
int TF = 0;
extern int lookBack = 15;
int lineMargin = 2;
int minTouches = 3;
double margin = 10;
double RR = 1.0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_ARROW); 
   SetIndexArrow(0, 233); 
   SetIndexBuffer(0, BufferUp); 
   SetIndexEmptyValue(0, 0.0);
   SetIndexStyle(1, DRAW_ARROW); 
   SetIndexArrow(1, 234); 
   SetIndexBuffer(1, BufferDown); 
   SetIndexEmptyValue(1, 0.0);
   
   pnt = MarketInfo(Symbol(), MODE_POINT);
   dig = MarketInfo(Symbol(), MODE_DIGITS);
   spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   if (barLimit > 1000)
      drawRectangle(5000, 0, Time[barLimit], Time[barLimit+1], "_candle", Red);
   
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   for(int x = ObjectsTotal()-1; x >= 0; x--) {
		if (StringFind(ObjectName(x), "_div_line") == -1 && StringFind(ObjectName(x), "_candle") == -1) continue;
		ObjectDelete(ObjectName(x));
	}
	
	Comment("");
	
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   pnt = MarketInfo(Symbol(), MODE_POINT);
   dig = MarketInfo(Symbol(), MODE_DIGITS);
   spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   // Symbol() + " " + getPeriodName(Period())
   Comment("Spread: ", spr, ". ", "DblPin", (pinDiv1 ? "+Div1" : ""), (pinDiv2 ? "+Div2" : ""), (pinInPin ? " pin-in-pin" : ""), (checkDirection ? " in right direction" : " in any direction"), " (", barLimit, ")");
   
   int counted_bars = IndicatorCounted();
   
   if (counted_bars < 0) return(-1);
   if (counted_bars > 0) counted_bars--;
   
   int limit = barLimit;
   if (limit == 0) {
      limit = Bars - counted_bars;
   }
   
   //if (Volume[0] > 1) return (0);
   
   for(int i=1; i<limit; i++)
   {
      int dir = getSignal(i, pinDiv1);
      
      for (int j=2; j<lookBack; j++)
      {
         int dir2 = getSignal(i+j, pinDiv2);
         
         if (dir != 0 && dir2 != 0 && dir == dir2)
         {
            if (pinInPin && dir == 1 && (isBetweenValues(High[i], High[i+j], Low[i+j]) || isBetweenValues(High[i+j], High[i], Low[i])))
            {
               if (checkDirection && Low[i] > Low[i+j]) return;
               UP(i);
               drawLine(Low[i], iTime(NULL, TF, i), Low[i+j], iTime(NULL, TF, i+j), "_div_line", LimeGreen, 2);
            }
            else if (pinInPin && dir == -1 && (isBetweenValues(Low[i], High[i+j], Low[i+j]) || isBetweenValues(Low[i+j], High[i], Low[i])))
            {
               if (checkDirection && High[i] < High[i+j]) return;
               DOWN(i);
               drawLine(High[i], iTime(NULL, TF, i), High[i+j], iTime(NULL, TF, i+j), "_div_line", Crimson, 2);
            }
            else if (!pinInPin && dir == 1)
            {
               if (checkDirection && Low[i] > Low[i+j]) return;
               UP(i);
               drawLine(Low[i], iTime(NULL, TF, i), Low[i+j], iTime(NULL, TF, i+j), "_div_line", LimeGreen, 2);
            }
            else if (!pinInPin && dir == -1)
            {
               if (checkDirection && High[i] < High[i+j]) return;
               DOWN(i);
               drawLine(High[i], iTime(NULL, TF, i), High[i+j], iTime(NULL, TF, i+j), "_div_line", Crimson, 2);
            }
         }
      }
   }
   
   return(0);
}

int getSignal(int i, bool withDivergence) {
   int pin = isPinBar(i);
      
   if (perfectPin) {
      if      (pin ==  1 && iOpen(NULL, TF, i+1) > iClose(NULL, TF, i+1) && iOpen(NULL, TF, i) < iClose(NULL, TF, i) && iOpen(NULL, TF, i) >= iClose(NULL, TF, i+1) && iHigh(NULL, TF, i) < iOpen(NULL, TF, i+1)) {}
      else if (pin == -1 && iOpen(NULL, TF, i+1) < iClose(NULL, TF, i+1) && iOpen(NULL, TF, i) > iClose(NULL, TF, i) && iOpen(NULL, TF, i) <= iClose(NULL, TF, i+1) && iLow(NULL, TF, i)  > iOpen(NULL, TF, i+1)) {}
      else { return (0); }
   }
   
   double divUp;
   double divDown;
   
   if (withDivergence) {
      divUp   = iCustom(NULL, 0, "FX5_MACD_Divergence_V1.1_Custom", 0, i);
      divDown = iCustom(NULL, 0, "FX5_MACD_Divergence_V1.1_Custom", 1, i);

      if (pin == 1 && divUp < 10000) {
         return (1);
      }
      else if (pin == -1 && divDown < 10000) {
         return (-1);
      }
   }
   else
   {
      if (pin == 1)
         return (1);
      else if (pin == -1)
         return (-1);
   }
   
   return (0);
}
  
  
void UP(int i, double price=0) {
   if (price == 0) price = iLow(NULL, TF, i);
   
   if (V2) {
      double line = lineMargin * pnt;
      int isBetween = 0;
      int touches = 0;
      for (int j=1; j<=lookBack; j++) {
         if (iClose(NULL, TF, i+j) + line < price)
            return;
         if (isBetweenValues(iHigh(NULL, TF, i+j), iHigh(NULL, TF, i), iLow(NULL, TF, i)) && isBetweenValues(iLow(NULL, TF, i+j), iHigh(NULL, TF, i), iLow(NULL, TF, i)))
            isBetween++;
         if (iLow(NULL, TF, i+j) - line <= iLow(NULL, TF, i))
            touches++;
      }
      if (touches < minTouches) return;
      
      drawLine(price, iTime(NULL, TF, i+lookBack), iTime(NULL, TF, i-1), "_div_line", LimeGreen, 3);
   }
   
   BufferUp[i] = iLow(NULL, TF, i);
}

void DOWN(int i, double price=0) {
   if (price == 0) price = iHigh(NULL, TF, i);
   
   if (V2) {
      double line = lineMargin * pnt;
      int isBetween = 0;
      int touches = 0;
      for (int j=1; j<=lookBack; j++) {
         if (iClose(NULL, TF, i+j) - line > price)
            return;
         if (isBetweenValues(iHigh(NULL, TF, i+j), iHigh(NULL, TF, i), iLow(NULL, TF, i)) && isBetweenValues(iLow(NULL, TF, i+j), iHigh(NULL, TF, i), iLow(NULL, TF, i)))
            isBetween++;
         if (iHigh(NULL, TF, i+j) + line >= iHigh(NULL, TF, i))
            touches++;
      }
      if (touches < minTouches) return;
      
      drawLine(price, iTime(NULL, TF, i+lookBack), iTime(NULL, TF, i-1), "_div_line", Crimson, 3);
      
   }
   
   BufferDown[i] = iHigh(NULL, TF, i);
}
//+------------------------------------------------------------------+

int isPinBar (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double candleSize = iHigh(NULL, TF, i) - iLow(NULL, TF, i);
   double bodySize = MathAbs(iOpen(NULL, TF, i) - iClose(NULL, TF, i));
   
   //if (candleSize > getMaxBarHeight(tf) * pnt || candleSize < getMinBarHeight(tf) * pnt) return (0); // wrong candle size
   
   bool isPin = false;
   int pinDir = 0;
   
   if (bodySize <= candleSize * pinBodyToCandle)
   {
      if (iHigh(NULL, TF, i) - iOpen(NULL, TF, i) <= candleSize * pinShortToBody || iHigh(NULL, TF, i)  - iClose(NULL, TF, i) <= candleSize * pinShortToBody) {
          isPin = true;
          pinDir = 1;
      }
      if (iOpen(NULL, TF, i) - iLow(NULL, TF, i)  <= candleSize * pinShortToBody || iClose(NULL, TF, i) - iLow(NULL, TF, i)   <= candleSize * pinShortToBody) {
          isPin = true;
          pinDir = -1;
      }
   }
   
   if (!isPin) return (0);
   
   if (pinDir == 1 && iLow(NULL, TF, i) < iLow(NULL, TF, i+1) && iLow(NULL, TF, i) < iLow(NULL, TF, i+2))
      return (1);
   else if (pinDir == -1 && iHigh(NULL, TF, i) > iHigh(NULL, TF, i+1) && iHigh(NULL, TF, i) > iHigh(NULL, TF, i+2))
      return (-1);
      
   return (0);
}

double getTP (double high, double low, int dir) {
   return ((high - low) * RR + spr * pnt);
}

double getSL (double high, double low, int dir) {
   return ((high - low) + (10 * pnt));
}