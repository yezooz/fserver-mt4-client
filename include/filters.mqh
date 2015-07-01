#property copyright "Copyright © 2012, Marek Mikuliszyn"

#define SRCandles             150

#define candlesBeforePin      1
#define pinMaxCoveredPercent  0.75
#define barsBeforeSwing       5

#define DBHLMargin   5
#define PivotMargin  0

#define roundLevel            100
#define roundLevelMargin      0

#define useFullEngulfOnly     0
#define engulfMargin          0.9 
#define engulfOpenCloseMargin 0.1
#define engulfCandleToBody    0 //0.6
#define maxCounterShadow      0.2

#define pinNeedsSpace      1
#define pinUsesTrend       0
#define allowFlatTrend     0
#define useTrendingCandles 0
#define trendPeriod        25

#define RSILevelUp         25
#define RSILevelDown       75
#define divergenceBarBack  25
#define useDivergence      1
#define useDivergenceOnly  0

// --- RSI Settings
#define RSIPeriod 6

// --- MA Settings
#define MA1Value 55
#define MA2Value 150
#define MA3Value 200
#define MA4Value 365

#include <helpers.mqh>
#include <patterns.mqh>

double getMinATR(string pair="", int tf=0)
{
   if (tf == 0) tf = Period();
   
   switch (tf) {
      case PERIOD_M5:
         return (30);
      default:
         return (2 * tf);
   }
}

bool filterByDailyPivots(int i, string pair = "", int tf = 0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   int i_to_daily = (i / (PERIOD_D1 / tf)) + 1;
   
   double d_h = iHigh(NULL, PERIOD_D1, i_to_daily);
   double d_l = iLow(NULL, PERIOD_D1, i_to_daily);
   double d_c = iClose(NULL, PERIOD_D1, i_to_daily);
   
   double P  = (d_h + d_l + d_c)/3;
   double R  = d_h - d_l;
   double R1 = P + (R * 0.382);
   double S1 = P - (R * 0.382);
   double R2 = P + (R * 0.618);
   double S2 = P - (R * 0.618);
   double R3 = P + (R * 0.99);
   double S3 = P - (R * 0.99);
   
   double h = iHigh(pair, tf, i);
   double l = iLow(pair, tf, i);
   
   if (isBetweenValues(P,  h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(R,  h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(R1, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(S1, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(R2, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(S2, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(R3, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   if (isBetweenValues(S3, h + PivotMargin * pnt, l - PivotMargin * pnt)) return (true);
   
   return (false);
}

bool filterByMA(int i, int ma, int ma_type)
{
   if (ma <= 0) return (false);
   return (isBetweenValues(iMA(NULL, 0, ma, 0, ma_type, MODE_CLOSE, i), High[i], Low[i]));
}

bool filterByRSI(int i, string system, int rsi)
{
   if (system == "pin" && useDivergenceOnly == 0) {
      if ((iRSI(NULL, 0, rsi, PRICE_CLOSE, i) <= RSILevelUp || iRSI(NULL, 0, rsi, PRICE_CLOSE, i+1) <= RSILevelUp)) return (true);
      return (false);
   }
   if (system == "pin" && useDivergenceOnly == 1) {
      for (int j=1; j<divergenceBarBack; j++) {
        if (iRSI(NULL, 0, rsi, PRICE_CLOSE, i+j) <= RSILevelUp && iRSI(NULL, 0, rsi, PRICE_CLOSE, i+j) < iRSI(NULL, 0, rsi, PRICE_CLOSE, i) && Close[i] < Close[i+j]) {
            return (true);
        }
      }
   }
   if (system == "engulfing_down") {
      return ((iRSI(NULL, 0, rsi, PRICE_CLOSE, i+1) > 50 && iRSI(NULL, 0, rsi, PRICE_CLOSE, i) < 50) || (iRSI(NULL, 0, rsi, PRICE_CLOSE, i+1) >= 80 && iRSI(NULL, 0, rsi, PRICE_CLOSE, i) < 80));
   }
   if (system == "engulfing_up") {
      return ((iRSI(NULL, 0, rsi, PRICE_CLOSE, i+1) < 50 && iRSI(NULL, 0, rsi, PRICE_CLOSE, i) > 50) || (iRSI(NULL, 0, rsi, PRICE_CLOSE, i+1) <= 20 && iRSI(NULL, 0, rsi, PRICE_CLOSE, i) > 20));
   }
   
   return (false);
}

bool filterBySwing(int i, string system)
{
   int s=0;
   if (system == "1_bar") {
      //if (candleCovered(i, i+1) > 0.6) return(false);
      
      for (s=1; s<barsBeforeSwing; s++) {
         if (candleCovered(i, i+s+1) > 0) return(false);
      }
   }
   if (system == "2_bars") {
      if (candleCovered(i+1, i+2) > 0.2) return(false);
      
      for (s=1; s<barsBeforeSwing; s++) {
         if (candleCovered(i+1, i+s+2) > 0) return(false);
      }
   }
   
   return (true);
}

bool filterByCountingBars(int i, int dir, string system)
{
   int inDir = 0;
   int j = 1;
   int bars = barsBeforeSwing;
   
   if (system == "engulfing") {
      j = 2;
      bars++;
   }
   
   for (j=1; j<bars; j++) {
      if (dir ==  1 && Open[i+j] > Close[i+j]) inDir++;
      if (dir == -1 && Open[i+j] < Close[i+j]) inDir++;
   }
   
   return (inDir >= 3);
}

bool filterByRoundLevel(int i, string pair="")
{
   if (pair == "") pair = Symbol();
   double pnt = MarketInfo(pair, MODE_POINT);
   double dig = MarketInfo(pair, MODE_DIGITS);
   
   bool r = false;
   int h_r = (High[i] + roundLevelMargin * pnt) * MathPow(10, dig - 1);
   int l_r = (Low[i]  - roundLevelMargin * pnt) * MathPow(10, dig - 1);
   
   while (h_r > l_r) {
      if (h_r % roundLevel == 0) {
         r = true;
         break;
      }
      h_r -= 1;
   }
   return (r);
}

bool filterByBox(int i, string pair="", int tf=0)
{
   // TODO: improve!

   int inBox = 0;
   for (int k=1; k<5; k++) {
      if (isBetweenValues(Close[i], Open[i+k], Close[i+k]) || isBetweenValues(Open[i], Open[i+k], Close[i+k])) inBox++;
   }
   if (inBox >= 3) return(false);
   
   return (true);
}

int candleDirection(int i)
{
   if (Open[i] < Close[i]) return (1);
   if (Open[i] > Close[i]) return (-1);
   return (0);
}

int candleGotSpace(int i)
{
   int result=0;
   
   for (int j=1; j<=candlesBeforePin; j++)
   {
      if (High[i+j] >= High[i] && Low[i+j] <= Low[i]) return (0); // outside bar
      if (High[i] >= High[i+j] && Low[i] <= Low[i+j]) return (0); // inside bar
      
      if (j == 1)
      {
         if (High[i+j] > High[i] && Low[i+j] > Low[i] && Low[i+j] < High[i] && High[i] - Low[i+j] < MathAbs(Low[i] - High[i]) * pinMaxCoveredPercent)
         {
            result = 1;
         }
         else if (High[i+j] < High[i] && Low[i+j] < Low[i] && High[i+j] > Low[i] && High[i+j] - Low[i] < MathAbs(Low[i] - High[i]) * pinMaxCoveredPercent)
         {
            result = -1;
         }
         else if (High[i+j] > High[i] && Low[i+j] >= High[i]) // gap
         {
            result = 1;
         }
         else if (High[i+j] < High[i] && Low[i+j] < Low[i] && High[i+j] <= Low[i]) // gap
         {
            result = -1;
         }
         else
         {
            return (0);
         }
      }
   }
   
   return (result);
}

bool gotTrendingCandles(int i, int trend)
{
   if (candleDirection(i+1) == trend && candleDirection(i+2) == trend) return (true);
   if (candleDirection(i+2) == trend && candleDirection(i+3) == trend) return (true);
   return (false);
}

int getPinBarTrend(int i)
{
   double MAs[2];
   
   MAs[0] = iMA(NULL, 0, trendPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
   MAs[1] = iMA(NULL, 0, trendPeriod, 0, MODE_EMA, PRICE_CLOSE, i+1);
   MAs[2] = iMA(NULL, 0, trendPeriod, 0, MODE_EMA, PRICE_CLOSE, i+2);
   
   if (allowFlatTrend) {}
   
   if (MAs[0] > MAs[1] && MAs[1] > MAs[2])
   {
      return (-1);
   }
   if (MAs[0] < MAs[1] && MAs[1] < MAs[2])
   {
      return (1);
   }
   
   return (0);
}

bool cleanLevel (int i, int dir, double level)
{
   int goBack = 5;
   int j;
   
   if (dir == OP_BUY)
   {
      for (j=2; j<=goBack+2; j++)
      {
         if (Low[i+j] < level) return (false);
      }
   }
   if (dir == OP_SELL)
   {
      for (j=2; j<=goBack+2; j++)
      {
         if (High[i+j] > level) return (false);
      }
   }
   
   return (true);
}