//+------------------------------------------------------------------+
//|                                                          Pin.mq4 |
//|                                     Copyright © 2012-2014, w3net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012-2014, w3net"
#property link      "http://www.w3net.pl"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Green
#property indicator_color2 Red

#include <helpers.mqh>

double BufferUp[];
double BufferDown[];
double spr, pnt, dig;

extern int barLimit = 10000;

extern bool V2 = false;
extern bool withDivergence = true;
extern bool onlySD = false;
extern bool onMW = false;

extern double pinBodyToCandle = 0.33;
extern double pinShortToBody = 0.15;

extern bool perfectPin = false;
int TF = 0;
extern int lookBack = 16;
int lineMargin = 2;
extern int minTouches = 3;
extern double minATR = 0;
extern bool drawSD = false;
extern bool noBodyInSd = false;
extern int minSDTouched = 0;
double margin = 10;
double RR = 0;

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

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   pnt = MarketInfo(Symbol(), MODE_POINT);
   dig = MarketInfo(Symbol(), MODE_DIGITS);
   spr = MarketInfo(Symbol(), MODE_SPREAD);
   
   // Symbol() + " " + getPeriodName(Period())
   Comment("Spread: ", spr, ". ", (perfectPin ? "Perfect " : ""), "Pin", (withDivergence ? "+Div" : ""), (V2 ? " V2 (" + lookBack + "," + minTouches + ")" : ""), (minATR > 0 ? " ATR x" + minATR + " " : ""), "(", barLimit, ")");
   
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
      int pin = isPinBar(i);
      
      if (pin == 0) {
         continue;
      }
      
      if (perfectPin) {
         if      (pin ==  1 && iOpen(NULL, TF, i+1) > iClose(NULL, TF, i+1) && iOpen(NULL, TF, i) < iClose(NULL, TF, i) && iOpen(NULL, TF, i) >= iClose(NULL, TF, i+1) && iHigh(NULL, TF, i) < iOpen(NULL, TF, i+1)) {}
         else if (pin == -1 && iOpen(NULL, TF, i+1) < iClose(NULL, TF, i+1) && iOpen(NULL, TF, i) > iClose(NULL, TF, i) && iOpen(NULL, TF, i) <= iClose(NULL, TF, i+1) && iLow(NULL, TF, i)  > iOpen(NULL, TF, i+1)) {}
         else { continue; }
      }
      
      if (onMW) {
         datetime zz_1_time = 0;
         datetime zz_2_time = 0;
         datetime zz_3_time = 0;
         
         double zz_1 = 0;
         double zz_2 = 0;
         double zz_3 = 0;
         for (int j = i; j < i+300; j++) {
            double zz = iCustom(NULL, 0, "ZigZag", 0, j);
               
            if (zz > 0 && zz_1 == 0) {
               zz_1 = zz;
               zz_1_time = Time[j];
            }
            else if (zz > 0 && zz_1 > 0 && zz_2 == 0) {
               zz_2 = zz;
               zz_2_time = Time[j];
            }
            else if (zz > 0 && zz_1 > 0 && zz_2 > 0 && zz_3 == 0) {
               zz_3 = zz;
               zz_3_time = Time[j];
            }
            else if (zz_1 > 0 && zz_2 > 0 && zz_3 > 0) {
               break;
            }
         }
         
         /*
         if (pin == 1 && zz_1 == Low[i] && isBetweenValues(zz_3, High[i], Low[i])) {
            
         }
         else if (pin == -1 && zz_1 == High[i] && isBetweenValues(zz_3, High[i], Low[i])) {
            
         }
         */
         
         if (pin == 1 && Low[i] <= zz_3 && isBetweenValues(zz_3, High[i], Low[i])) {
            bool foundLower = false;
            for (int k=j; k>i; k--) {
               if (Low[k] < Low[i]) {
                  foundLower = true;
                  break;
               }
            }
            if (foundLower) {
               continue;
            }
         }
         else if (pin == -1 && High[i] >= zz_3 && isBetweenValues(zz_3, High[i], Low[i])) {
            bool foundHigher = false;
            for (k=j; k>i; k--) {
               if (High[k] > High[i]) {
                  foundHigher = true;
                  break;
               }
            }
            if (foundHigher) {
               continue;
            }
         }
         else {
            continue;
         }
      }
      
      if (minATR > 0) {
         if (High[i] - Low[i] < iATR(NULL, 0, 14, i) * minATR) {
            continue;
         }
      }
      
      double divUp;
      double divDown;
      
      if (withDivergence) {
         divUp   = iCustom(NULL, 0, "FX5_MACD_Divergence_V1.1_Custom", 0, i);
         divDown = iCustom(NULL, 0, "FX5_MACD_Divergence_V1.1_Custom", 1, i);

         if (pin == 1 && divUp < 10000) {
            UP(i);
         }
         else if (pin == -1 && divDown < 10000) {
            DOWN(i);
         }
         else {
            continue;
         }
      }
      else
      {
         if (pin == 1) {
            UP(i);
         }
         else if (pin == -1) {
            DOWN(i);
         }
         else {
            continue;
         }
      }
      
      if (onMW) {
         drawRectangle(High[i], Low[i], Time[i], zz_3_time, "_pin");
      }
      if (drawSD) {
         double shadow[2];
         if (pin == 1) {
            lowerShadow(i, shadow);
         }
         else {
            upperShadow(i, shadow);
         }
         
         int SDTouched = 0;
         for (k=i; k<i+150; k++) {
            if (noBodyInSd) {
               if (pin == 1 && Close[k] < shadow[0]) {
                  break;
               }
               if (pin == -1 && Close[k] > shadow[1]) {
                  break;
               }
            }
            else {
               if (pin == 1 && Close[k] < Low[i]) {
                  break;
               }
               if (pin == -1 && Close[k] > High[i]) {
                  break;
               }
            }
            
            if (pin == 1 && isBetweenValues(Low[k], shadow[0], shadow[1])) {
               SDTouched++;
            }
            else if (pin == -1 && isBetweenValues(High[k], shadow[0], shadow[1])) {
               SDTouched++;
            }
         }
         
         if (minSDTouched > 0 && minSDTouched > SDTouched) {
            continue;
         }
         
         if (k < i+10) {
            continue;
         }
         
         color sdc = Yellow;
         if (k == i+150) {
            sdc = Gold;
         }
         
         drawRectangle(shadow[0], shadow[1], Time[i], Time[k], "_pin", sdc);
      }
   }
   
   return(0);
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
   
   if (onlySD) {
      bool foundSD = false;
      for(int x = ObjectsTotal()-1; x >= 0; x--) {
		   if (StringFind(ObjectName(x), "aII_SupDem") == -1) continue;
		   
		   string name = ObjectName(x);
		   
		   color c = ObjectGet(name, OBJPROP_COLOR);
      	if (c != Green && c != DarkGreen) {
      	   continue;
      	}
      	
      	datetime d = ObjectGet(name, OBJPROP_TIME1);
      	if (d > Time[i]) {
      	   continue;
      	}
      	
      	double h = ObjectGet(name, OBJPROP_PRICE1);
      	double l = ObjectGet(name, OBJPROP_PRICE2);
      	
      	if (isBetweenValues(h, High[i], Low[i]) || isBetweenValues(l, High[i], Low[i])) {
      	   foundSD = true;
      	   break;
      	}
   	}
   	
   	if (!foundSD) {
   	   return;
   	}
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
   
   if (onlySD) {
      bool foundSD = false;
      for(int x = ObjectsTotal()-1; x >= 0; x--) {
		   if (StringFind(ObjectName(x), "aII_SupDem") == -1) continue;
		   
		   string name = ObjectName(x);
   	
      	color c = ObjectGet(name, OBJPROP_COLOR);
      	if (c != Green && c != DarkGreen) {
      	   continue;
      	}
      	
      	datetime d = ObjectGet(name, OBJPROP_TIME1);
      	if (d > Time[i]) {
      	   continue;
      	}
      	
      	double h = ObjectGet(name, OBJPROP_PRICE1);
      	double l = ObjectGet(name, OBJPROP_PRICE2);
      	
      	if (isBetweenValues(h, High[i], Low[i]) || isBetweenValues(l, High[i], Low[i])) {
      	   foundSD = true;
      	   break;
      	}
   	}
   	
   	if (!foundSD) {
   	   return;
   	}
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