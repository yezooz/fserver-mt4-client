#include <filters.mqh>

#define pinBodyToCandle    0.4
#define pinShortToBody     0.2
#define pinLookBack        3
#define dbhlLookBack       15
#define engulfingLookBack  3

#define useFullEngulfOnly     0
#define engulfMargin          0.9 
#define engulfOpenCloseMargin 0.1
#define engulfCandleToBody    0 //0.6

#include <helpers.mqh>

// --- Settings

bool isBarBigEnough(int i)
{
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   double dig = MarketInfo(Symbol(), MODE_DIGITS);
   
   double H  = NormalizeDouble(High[i], dig);   
   double L  = NormalizeDouble(Low[i], dig);

    return (H - L > getMinBarHeight(Period()) * pnt);
}

double getMinBarHeight(int tf=0) {
   if (tf == 0) tf = Period();
   
   if (Digits == 2 || Digits == 4) return (0);

   switch (tf) {
      case PERIOD_M1:
         return (10);
      case PERIOD_M5:
         return (15);
      case PERIOD_M15:
         return (30);
      case PERIOD_M30:
      case PERIOD_H1:
         return (50);
      case PERIOD_H4:
         return (100);
      case PERIOD_D1:
      default:
         return (200);
   }
}

double getMaxBarHeight(int tf=0) {
   //if (tf == 0) tf = Period();

   return (100000);
}

double getMinBodyHeight(int tf=0) {   
   if (tf == 0) tf = Period();
   
   return (0);
   
   switch (tf) {
      case PERIOD_M1:
      case PERIOD_M5:
         return (4);
      case PERIOD_M15:
         return (5);
      case PERIOD_M30:
      case PERIOD_H1:
         return (7);
      case PERIOD_H4:
         return (14);
      case PERIOD_D1:
      default:
         return (100);
   }
}

double getMaxBodyHeight(int tf=0) {
   //if (tf == 0) tf = Period();

   return (100000);
}

double getDBHLMargin(int tf=0) {
   return (2);   
   
   if (tf == 0) tf = Period();
   
   switch (tf) {
      case PERIOD_M1:
         return (0);
      case PERIOD_M5:
         return (5);
      case PERIOD_M15:
         return (10);
      case PERIOD_M30:
      case PERIOD_H1:
         return (20);
      case PERIOD_H4:
         return (50);
      case PERIOD_D1:
      default:
         return (100);
   }
}

// --- Pin Bar

int isPinBar (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double candleSize = High[i] - Low[i];
   double bodySize = MathAbs(Open[i] - Close[i]);
   
   //if (candleSize > getMaxBarHeight(tf) * pnt || candleSize < getMinBarHeight(tf) * pnt) return (0); // wrong candle size
   
   bool isPin = false;
   int pinDir = 0;
   
   if (bodySize <= candleSize * pinBodyToCandle)
   {
      if (High[i] - Open[i] <= candleSize * pinShortToBody || High[i]  - Close[i] <= candleSize * pinShortToBody) {
          isPin = true;
          pinDir = 1;
      }
      if (Open[i] - Low[i]  <= candleSize * pinShortToBody || Close[i] - Low[i]   <= candleSize * pinShortToBody) {
          isPin = true;
          pinDir = -1;
      }
   }
   
   if (!isPin) return (0);
   
   if (pinDir == 1 && Low[i] < Low[i+1] && Low[i] < Low[i+2])
      return (1);
   else if (pinDir == -1 && High[i] > High[i+1] && High[i] > High[i+2])
      return (-1);
      
   return (0);
}

int isPinBarWithConfirmation (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   if (i <= 2) return (0);
   
   int pin = isPinBar(i, pair, tf);
   
   if (pin == 1  && Open[i+1] > Close[i+1] && Open[i-1] < Close[i-1] && Close[i-1] > High[i]) return (1);
   if (pin == -1 && Open[i+1] < Close[i+1] && Open[i-1] > Close[i-1] && Close[i-1] < Low[i])  return (-1);
   
   return (0);
}

bool checkPinConditions(int dir, int i, string pair="")
{
   if (pair == "") pair = Symbol();
   
   if (getCandleDirection(i+1) == dir) return (false);
   if (High[i+1] - Low[i+1] > High[i] - Low[i]) return (false);
   if (pinNeedsSpace == 1 && candleGotSpace(i) != dir) return (false);
   if (pinUsesTrend == 1 && getPinBarTrend(i) != -dir) return (false);
   if (useTrendingCandles == 1 && !gotTrendingCandles(i, -dir)) return (false); 
   
   return (true);
}

// --- Spinning Top / Bottom

int isSpinningTB (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double candleLength = High[i] - Low[i];
   double bodyLength = MathAbs(Open[i] - Close[i]);
   double shadowLength = candleLength - bodyLength;
   
   if (candleLength == 0 || shadowLength == 0) return (0);
   
   int pin = isPinBar(i);
   if (pin != 0) return (pin);
   
   if (shadowLength / candleLength < 0.7) return (false);
   if (candleLength > getMaxBarHeight(tf) * pnt || candleLength < getMinBarHeight(tf) * pnt) return (0); // wrong candle size
   
   if (iHighest(pair, NULL, MODE_HIGH, pinLookBack, i) == i && getCandleDirection(i+1) == 1)
   {
      if (isPinBar(i) == -1) return (false);
      //if (Low[iLowest(pair, NULL, MODE_LOW, checkLast, i)] > (Low[i] - ((High[i] - Low[i]) * checkRR))) return (false);
      return (-1);
   }
   
   if (iLowest(pair, NULL, MODE_LOW, pinLookBack, i) == i && getCandleDirection(i+1) == -1)
   {
      if (isPinBar(i) == 1) return (false);
      //if (High[iHighest(pair, NULL, MODE_HIGH, checkLast, i)] > (High[i] + ((High[i] - Low[i]) * checkRR))) return (false);
      return (1);
   }
   
   return (0);
}

// --- Double Bar High Lower Close / Double Bar Low Higher Close

int isDBHL (int i, string pair="", int tf=0) 
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   if (MathAbs(High[i] - High[i+1]) <= 2 * pnt && iHighest(pair, tf, MODE_HIGH, dbhlLookBack, i+1) == i+1 && Low[i] < Low[i+1]) {
      return (-1);
   }
   if (MathAbs(Low[i] - Low[i+1]) <= 2 * pnt && iLowest(pair, tf, MODE_LOW, dbhlLookBack, i+1) == i+1 && High[i] > High[i+1]) {
      return (1);
   }
   
   return (0);
}

// --- Engulfing

int isEngulfing (int i, string pair="", int tf=0) 
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double barSizeA =  MathAbs(Open[i] - Close[i]);
   double barSizeB =  MathAbs(Open[i+1] - Close[i+1]) * engulfMargin;
   
   double candleSizeA = High[i] - Low[i];
   double candleSizeB = High[i+1] - Low[i+1];
   
   double minBarHeight = getMinBarHeight();
   double maxBarHeight = getMaxBarHeight();
   double minBodyHeight = getMinBodyHeight();
   double maxBodyHeight = getMaxBodyHeight();
   
   if (candleSizeA > maxBarHeight * pnt || candleSizeA < minBarHeight * pnt || candleSizeB > maxBarHeight * pnt || candleSizeB < minBarHeight * pnt) return (0); // wrong candle size
   if (barSizeA > maxBodyHeight * pnt || barSizeA < minBodyHeight * pnt || barSizeB > maxBodyHeight * pnt || barSizeB < minBodyHeight * pnt)         return (0); // wrong candle size
   //if (barSizeA / candleSizeA < 0.6) return (0);
   
   if ( iLowest(pair, tf, MODE_LOW,  engulfingLookBack, i+1) == i+1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) ==  1 && Close[i] >= Open[i+1] && Low[i] <= Close[i+1])  return (1);
   if (iHighest(pair, tf, MODE_HIGH, engulfingLookBack, i+1) == i+1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) == -1 && Close[i] <= Open[i+1] && High[i] >= Close[i]) return (-1);
   
   //if (  && Open[i+1] > Close[i+1] && Open[i] < Close[i] && (Open[i]  <= Open[i+1]  || isBetweenValues(Open[i+1],  Open[i]  + (High[i]-Low[i]) * engulfOpenCloseMargin, Open[i]  - (High[i]-Low[i]) * engulfOpenCloseMargin))) return (1);
   //if ( && Open[i+1] < Close[i+1] && Open[i] > Close[i] && (Close[i] <= Close[i+1] || isBetweenValues(Close[i+1], Close[i] + (High[i]-Low[i]) * engulfOpenCloseMargin, Close[i] - (High[i]-Low[i]) * engulfOpenCloseMargin))) return (-1);
   
   return (0);
}

int isStrictEngulfing (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double barSizeA =  MathAbs(Open[i] - Close[i]);
   double barSizeB =  MathAbs(Open[i+1] - Close[i+1]) * engulfMargin;
   
   double candleSizeA = High[i] - Low[i];
   double candleSizeB = High[i+1] - Low[i+1];
   
   double minBarHeight = getMinBarHeight();
   double maxBarHeight = getMaxBarHeight();
   double minBodyHeight = getMinBodyHeight();
   double maxBodyHeight = getMaxBodyHeight();
   
   if (candleSizeA > maxBarHeight * pnt || candleSizeA < minBarHeight * pnt || candleSizeB > maxBarHeight * pnt || candleSizeB < minBarHeight * pnt) return (0); // wrong candle size
   if (barSizeA > maxBodyHeight * pnt || barSizeA < minBodyHeight * pnt || barSizeB > maxBodyHeight * pnt || barSizeB < minBodyHeight * pnt)         return (0); // wrong candle size
   //if (barSizeA < barSizeB) return (0);
   if (barSizeA > barSizeB * 3) return (0); // can't too big
   if (barSizeA * 4 < candleSizeA || barSizeB * 4 < candleSizeB) return (0);
   //if ((barSizeA / candleSizeA) < engulfCandleToBody || (barSizeB / candleSizeB) < engulfCandleToBody) return (0); // only small shadows
   
   // TODO: minimalna wielosc body ponizej ktorego olewamy kolor swiecy
   
   if (useFullEngulfOnly == 1) {
      if (candleSizeA < candleSizeB) return (0);
      if (Open[i] < Close[i] && High[i] >= High[i+1] && Low[i] <= Low[i+1]) return (1);
      if (Open[i] > Close[i] && High[i] >= High[i+1] && Low[i] <= Low[i+1]) return (-1);
      return (0);
   }
   
   //if (Open[i+1] > Close[i+1] && Open[i] < Close[i] && Open[i]  <= Open[i+1])  return (1);
   //if (Open[i+1] < Close[i+1] && Open[i] > Close[i] && Close[i] <= Close[i+1]) return (-1);
   
   if ( iLowest(pair, tf, MODE_LOW,  engulfingLookBack, i+1) == i+1 && Open[i+1] > Close[i+1] && Open[i] < Close[i] && (Open[i]  <= Open[i+1]  || isBetweenValues(Open[i+1],  Open[i]  + (High[i]-Low[i]) * engulfOpenCloseMargin, Open[i]  - (High[i]-Low[i]) * engulfOpenCloseMargin))) return (1);
   if (iHighest(pair, tf, MODE_HIGH, engulfingLookBack, i+1) == i+1 && Open[i+1] < Close[i+1] && Open[i] > Close[i] && (Close[i] <= Close[i+1] || isBetweenValues(Close[i+1], Close[i] + (High[i]-Low[i]) * engulfOpenCloseMargin, Close[i] - (High[i]-Low[i]) * engulfOpenCloseMargin))) return (-1);
   
   return (0);
}

// --- Moribou

int isMarubozu (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double barSize =  MathAbs(Open[i] - Close[i]);
   double candleSize = High[i] - Low[i];
   
   double minBarHeight = getMinBarHeight();
   double maxBarHeight = getMaxBarHeight();
   double minBodyHeight = getMinBodyHeight();
   double maxBodyHeight = getMaxBodyHeight();
   
   if (candleSize > maxBarHeight * pnt || candleSize < minBarHeight * pnt) return (0); // wrong candle size
   if (barSize > maxBodyHeight * pnt || barSize < minBodyHeight * pnt)     return (0); // wrong candle size
   if (barSize / candleSize < 0.9) return (0);
   
   return (getCandleDirection(i));
}

int isClosingMarubozu (int i, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();

   double pnt = MarketInfo(pair, MODE_POINT);
   
   double barSize =  MathAbs(Open[i] - Close[i]);
   double candleSize = High[i] - Low[i];
   
   double minBarHeight = getMinBarHeight();
   double maxBarHeight = getMaxBarHeight();
   double minBodyHeight = getMinBodyHeight();
   double maxBodyHeight = getMaxBodyHeight();
   
   if (candleSize > maxBarHeight * pnt || candleSize < minBarHeight * pnt) return (0); // wrong candle size
   if (barSize > maxBodyHeight * pnt || barSize < minBodyHeight * pnt)     return (0); // wrong candle size
   
   if (getCandleDirection(i) ==  1 && (High[i] - Close[i]) / candleSize > 0.05) return (0);
   if (getCandleDirection(i) == -1 && (Close[i] - Low[i]) / candleSize > 0.05) return (0);
   
   return (getCandleDirection(i));
}

// --- Inside & Outside Bar

bool isOB (int out, int in, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();
   if (in == 0)    in = out + 1;

   double pnt = MarketInfo(pair, MODE_POINT);
   double dig = MarketInfo(pair, MODE_DIGITS);
   
   double H  = NormalizeDouble(High[out], dig);
   double H1 = NormalizeDouble(High[in], dig);
   
   double L  = NormalizeDouble(Low[out], dig);
   double L1 = NormalizeDouble(Low[in], dig);
   
   if (H-L > getMaxBarHeight(tf) * pnt && H1-L1 > getMaxBarHeight(tf) * pnt) return (false); // candle too large
   if (H-L < getMinBarHeight(tf) * pnt && H1-L1 < getMinBarHeight(tf) * pnt) return (false); // candle too small
   
   if ((H >= H1) && (L <= L1)) {      
      return (true);
   }
   
   return (false);
}

bool isIB (int out, int in, string pair="", int tf=0, double IBMargin=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();
   
   double pnt = MarketInfo(pair, MODE_POINT);
   double dig = MarketInfo(pair, MODE_DIGITS);
   
   double H  = NormalizeDouble(High[in], dig);
   double H1 = NormalizeDouble(High[out], dig) + (IBMargin * pnt);
   
   double L  = NormalizeDouble(Low[in], dig);
   double L1 = NormalizeDouble(Low[out], dig) - (IBMargin * pnt);
   
   if (H-L > getMaxBarHeight(tf) * pnt || H1-L1 > getMaxBarHeight(tf) * pnt) return (false); // candle too large
   if (H-L < getMinBarHeight(tf) * pnt || H1-L1 < getMinBarHeight(tf) * pnt) return (false); // candle too small
   
   if ((H >= H1) && (L<= L1)) {
      return (true);
   }
   
   return (false);
}

bool isTripleIB(int i, string pair="", int tf=0)
{
   if (isIB(i, i+3) && isIB(i+1, i+3) && isIB(i+2, i+3)) return (true);
   return (false);
}

int isMomentumThree (int i, string pair="", int tf=0)
{
   if (getCandleDirection(i+2) ==  1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) == -1 && isIB(i, i+2, pair, tf) && isIB(i+1, i+2, pair, tf) && isMomentumBar(i+2)) {
      //Print(TimeToString(Time[i+2]) + ": ATR=" + DoubleToStr(getCandleSizeToATR(i+2), 1) + "; Body/Candle=" + DoubleToStr((MathAbs(Open[i+2] - Close[i+2]) / (High[i+2] - Low[i+2])), 2));
      return (-1);
   }
   if (getCandleDirection(i+2) == -1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) ==  1 && isIB(i, i+2, pair, tf) && isIB(i+1, i+2, pair, tf) && isMomentumBar(i+2)) {
      //Print(TimeToString(Time[i+2]) + ": ATR=" + DoubleToStr(getCandleSizeToATR(i+2), 1) + "; Body/Candle=" + DoubleToStr((MathAbs(Open[i+2] - Close[i+2]) / (High[i+2] - Low[i+2])), 2));
      return (1);
   }   
   return (0);
}

int isMomentumIB (int i, string pair="", int tf=0)
{
   if (isMomentumBar(i+1, 2.0) && isIB(i, i+1))
   {
      if (getCandleDirection(i) ==  1) return (1);
      if (getCandleDirection(i) == -1) return (-1);
   }
   return (0);
}

int isMomentumIBV2 (int i, string pair="", int tf=0)
{
   if (getCandleDirection(i+2) ==  1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) == -1 && isIB(i+1, i+2, pair, tf) && isMomentumBar(i+2)) {
      return (-1);
   }
   if (getCandleDirection(i+2) == -1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) ==  1 && isIB(i+1, i+2, pair, tf) && isMomentumBar(i+2)) {
      return (1);
   }   
   return (0);
}

int isMomentumPin (int i, string pair="", int tf=0)
{
   if (getCandleDirection(i+1) ==  1 && isMomentumBar(i+1) && isPinBar(i) == -1) return (-1);
   if (getCandleDirection(i+1) == -1 && isMomentumBar(i+1) && isPinBar(i) ==  1) return (1);
}

int isThreeInside (int i, string pair="", int tf=0)
{
   if (getCandleDirection(i+2) ==  1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) == -1 && isIB(i+1, i, pair, tf) && Close[i] <= Low[i+2])  return (-1);
   if (getCandleDirection(i+2) == -1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) ==  1 && isIB(i+1, i, pair, tf) && Close[i] >= High[i+2]) return (1);
   
   
   // With Pin
   /*
   if (Close[i+2] > Open[i+2] && Close[i+1] <= Open[i+1] && isIB(i+1, pair, tf) && Close[i] <= Close[i+2] && Low[i] < Low[i+2]) {
      if (isPinBar(i, pair, tf) == 1) return (1);
      return (-1);
   }
   if (Close[i+2] < Open[i+2] && Close[i+1] >= Open[i+1] && isIB(i+1, pair, tf) && Close[i] >= Close[i+2] && High[i] > High[i+2]) {
      if (isPinBar(i, pair, tf) == -1) return (-1);
      return (1);
   }
   */
   
   return (0);
}

int isThreeOutside (int i, string pair="", int tf=0)
{
   if (getCandleDirection(i+2) ==  1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) == -1 && isOB(i+1, pair, tf)) return (-1);
   if (getCandleDirection(i+2) == -1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) ==  1 && isOB(i+1, pair, tf)) return (1);
}

int isThreeInOut (int i, string pair="", int tf=0)
{
   if (isMomentumBar(i+2) && getCandleDirection(i+2) ==  1 && getCandleDirection(i+1) == -1 && getCandleDirection(i) == -1 && isIB(i, i+1)) return (-1);
   if (isMomentumBar(i+2) && getCandleDirection(i+2) == -1 && getCandleDirection(i+1) ==  1 && getCandleDirection(i) ==  1 && isIB(i, i+1)) return (1);
}

bool isMorningStar (int i, string pair="", int tf=0)
{
   // TODO: also check candle positions
   if (getCandleDirection(i+2) == -1 && isPinBar(i+1) != 0 && getCandleDirection(i) == 1 && Close[i+2] > Open[i+1] && Close[i] > Open[i+1] && Close[i] > Close[i+1] && isPinBar(i+2) >= 0 && isPinBar(i) >= 0) return (true);
   return (false);
}

bool isEveningStar (int i, string pair="", int tf=0)
{
   // TODO: also check candle positions
   //if (getCandleDirection(i+2) == 1 && isPinBar(i+1) != 0 && getCandleDirection(i) == -1) return (true);
   
   if (getCandleDirection(i+2) == 1 && isPinBar(i+1) != 0 && getCandleDirection(i) == -1 && Open[i+2] < Open[i+1] && Open[i] < Open[i+1] && Open[i] < Close[i+1] && isPinBar(i+2) <= 0 && isPinBar(i) <= 0) return (true);
   return (false);
}