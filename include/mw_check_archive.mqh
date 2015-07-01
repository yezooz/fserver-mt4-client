// --- KOLEJNA WERSJA

bool isMWExperimental (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int backPeriod = 30;
   int foundWithDir = 0;
   int foundAgainstDir = 0;
   
   double mwLow, mwHigh;
   
   if (dir == OP_BUY && system == "engulfing" && Low[i+1] < Low[i]) mwLow = Low[i+1];
   else mwLow = Low[i];
   if (dir == OP_SELL && system == "engulfing" && High[i+1] > High[i]) mwHigh = High[i+1];
   else mwHigh = High[i];
   
   int j;
   double mwMargin = getMWMargin(i, pair, tf);
   
   for (j=1; j<backPeriod; j++)
   {
      if (dir == OP_BUY)
      {
         if (!isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin)) continue;
         
         if (isPinBar(i+j) ==  1 || isSpinningTB(i+j) ==  1 || isDBHL(i+j) ==  1 || isEngulfing(i+j) ==  1 || isOB(i+j, i+j+1))
         {
            foundWithDir = i+j;
            break;
         }
      }
      else if (dir == OP_SELL)
      {
         if (!isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin)) continue;
                  
         if (isPinBar(i+j) ==  -1 || isSpinningTB(i+j) ==  -1 || isDBHL(i+j) ==  -1 || isEngulfing(i+j) ==  -1 || isOB(i+j, i+j+1))
         {
            foundWithDir = i+j;
            break;
         }
      }
   }
   
   for (j=backPeriod; j>0; j--)
   {
      if (!withCounterFormation) break;
      if (i+j > foundWithDir) continue;
      
      if (dir == OP_BUY)
      {
         if (isPinBar(i+j) == -1 || isSpinningTB(i+j) == -1 || isDBHL(i+j) == -1 || isEngulfing(i+j) == -1)
         {
            int lowest = iLowest(pair, tf, MODE_LOW, (foundWithDir - i) + 10, i);
            if (lowest == i || lowest == i+1 || lowest == i+j) foundAgainstDir = i+j;
         }
      }
      else
      {
         if (isPinBar(i+j) ==  1 || isSpinningTB(i+j) ==  1 || isDBHL(i+j) ==  1 || isEngulfing(i+j) ==  1)
         {
            int highest = iHighest(pair, tf, MODE_HIGH, (foundWithDir - i) + 10, i);
            if (highest == i || highest == i+1 || highest == i+j) foundAgainstDir = i+j;
         }
      }
   }
   
   if (withCounterFormation && foundAgainstDir == 0) return (false);
   
   for (int x=foundWithDir-2; x>i+1; x--) {
      if (dir == OP_BUY  && isBetweenValues(mwLow,  High[x], Low[x])) return (false);
      if (dir == OP_SELL && isBetweenValues(mwHigh, High[x], Low[x])) return (false);
   }
   
   if (foundWithDir - i <= 3) return (false); // za krotkie
   
   if (dir == OP_BUY)
   {
      drawLine(mwLow, Time[i], Time[foundWithDir], "", Green);
   }
   else
   {
      
      drawLine(mwHigh, Time[i], Time[foundWithDir], "", Red);
   }
   
   return (true);
}



// --- POPRZEDNIA WERSJA

double getExtremePoint (int i, int j, int dir)
{
   double line, extreme;
   if (dir == OP_BUY) {
      line = Low[i];
      extreme = High[iHighest(NULL, 0, MODE_HIGH, j-i, i)];
      
   }
   if (dir == OP_SELL) {
      line = High[i];
      extreme = Low[iLowest(NULL, 0, MODE_LOW, j-i, i)];
   }
   
   return (MathAbs(line - extreme));
}

double getAverageDeflection (int i, int j, int dir)
{
   double line;
   if (dir == OP_BUY) {
      line = Low[i];
      
   }
   if (dir == OP_SELL) {
      line = High[i];
   }
   
   double total_def = 0;
   for (int k=i+1; k<j-1; k++) {
      if (dir == OP_BUY) {
         total_def += Low[k] - line;
      }
      else if (dir == OP_SELL) {
         total_def += line - High[k];
      }
   }
   
   return (total_def / (j-i-2));
}

double getMWMargin (string pair, int tf)
{
   double mwMargin;
   switch (tf) {
      case PERIOD_M1:
         mwMargin = 5 * pnt;
         break;
      case PERIOD_M5:
         mwMargin = 5 * pnt;
         break;
      case PERIOD_M15:
         mwMargin = 10 * pnt;
         break;
      case PERIOD_H4:
         mwMargin = 50 * pnt;
         break;
      case PERIOD_D1:
         mwMargin = 100 * pnt;
         break;
      default:
         mwMargin = 20 * pnt;
   }
   
   //mwMargin = (High[i] - Low[i]) * 0.2;
   //mwMargin = 5 * pnt;
   
   return (mwMargin);
}

double getAvgDeflectionMargin (string pair, int tf)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   double defMargin;
   switch (tf) {
      case PERIOD_M1:
         defMargin = 40 * pnt;
         break;
      case PERIOD_M5:
      case PERIOD_M15:
         defMargin = 70 * pnt;
         break;
      case PERIOD_M30:
      case PERIOD_H1:
         defMargin = 90 * pnt;
         break;
      case PERIOD_H4:
      case PERIOD_D1:
         defMargin = 400 * pnt;
         break;
      case PERIOD_W1:
      case PERIOD_MN1:
         defMargin = 1000 * pnt;
         break;
   }
   
   return (defMargin);
}

bool isMWExperimentalFilter (int i, int foundAt, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   
   if (filterAvgDeflection && getAverageDeflection(i, foundAt, dir) < getAvgDeflectionMargin(pair, tf)) return (false);
   
   bool notCrossing = false;
   for (int x=foundAt-2; x>i+1; x--) {
      //if (!notCrossing && !isCandleCovered(x, i)) notCrossing = true;
   }
   
   //if (!notCrossing) return (false); // nie mog¹ wszystkie dotykaæ g³ównej œwiecy
   
   int dm;
   if (drawMax <= 0) dm = 0;
   else dm = i;
   
   if (dir == OP_BUY)
   {
      int lowest = iLowest(pair, tf, MODE_CLOSE, (foundAt - i) + 10, i);
      if (lowest == i || lowest == i+1 || lowest == foundAt) {
         if (drawMWLine) drawLine(Low[i], Time[foundAt], Time[dm], "MW_UP", Green);
         if (drawLabels) drawLabel(High[i] + (High[i]-Low[i])*2, Time[i], getLabel(i, foundAt, system, dir));
         return (true);
      }
   }
   if (dir == OP_SELL)
   {
      int highest = iHighest(pair, tf, MODE_CLOSE, (foundAt - i) + 10, i);
      if (highest == i || highest == i+1 || highest == foundAt) {
         if (drawMWLine) drawLine(High[i], Time[foundAt], Time[dm], "MW_DOWN", Red);
         if (drawLabels) drawLabel(High[i] + (High[i]-Low[i])*2, Time[i], getLabel(i, foundAt, system, dir));
         return (true);
      }
   }
   
   return (false);
}

bool isMWExperimental (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int backPeriod = 50;
   
   double mwMargin = getMWMargin(pair, tf);
   
   for (int j=1; j<=backPeriod; j++)
   {
      if (j>3 && (dir == OP_BUY && isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin)) || (dir == OP_SELL && isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin))) {
         if (isMWExperimentalFilter(i, i+j, system, dir, pair, tf)) return (true);
      }
      else if (dir == OP_BUY && Low[i+j] < Low[i] - mwMargin) {
         //return (false);
      }
      else if (dir == OP_SELL && High[i+j] > High[i] + mwMargin) {
         //return (false);
      }
   }
   
   return (false);
}


// --- ARCHIVE

bool isMWExperimental_CLOSE_FIVE (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int backPeriod = 50;
   int foundAt = 0;
   
   double mwMargin;
   
   switch (tf) {
      case PERIOD_M1:
         mwMargin = 0 * pnt;
         break;
      case PERIOD_M5:
         mwMargin = 10 * pnt;
         break;
      default:
         mwMargin = 20 * pnt;
   }
   
   //double mwMargin = (High[i] - Low[i]) * 0.25;
   //mwMargin = 20 * pnt;
   
   for (int j=1; j<=backPeriod; j++)
   {
      if (j>3 && isBetweenValues(Close[i], Close[i+j] + mwMargin, Close[i+j] - mwMargin))
      {
         foundAt = i+j;
         
         break;
      }
      else if (dir == OP_BUY && Close[i+j] < Close[i] - mwMargin) {
         return (false);
      }
      else if (dir == OP_SELL && Close[i+j] > Close[i] + mwMargin) {
         return (false);
      }
   }
   
   if (foundAt > 0)
   {
      bool notCrossing = false;
      for (int x=foundAt-2; x>i+1; x--) {
         if (isBetweenValues(Close[i], High[x], Low[x])) return (false);
         if (!notCrossing && candleCovered(x, i) == 0) notCrossing = true;
      }
      
      if (!notCrossing) return (false); // nie mog¹ wszystkie dotykaæ g³ównej œwiecy
      
      if (dir == OP_BUY)
      {
         int lowest = iLowest(pair, tf, MODE_CLOSE, (foundAt - i) + 10, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) {
            drawLine(Close[i], Time[foundAt], Time[i]);
            return (true);
         }
      }
      if (dir == OP_SELL)
      {
         int highest = iHighest(pair, tf, MODE_CLOSE, (foundAt - i) + 10, i);
         if (highest == i || highest == i+1 || highest == foundAt) {
            drawLine(Close[i], Time[foundAt], Time[i]);
            return (true);
         }
      }
   }
   
   return (false);
}

// z wykrywaniem konsoli, etc
bool isMWExperimental_FOUR (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int backPeriod = 50;
   int foundAt = 0;
   
   double mwMargin;
   
   switch (tf) {
      case PERIOD_M1:
         mwMargin = 5 * pnt;
         break;
      case PERIOD_M15:
         mwMargin = 30 * pnt;
         break;
      case PERIOD_M30:
      case PERIOD_H1:
         mwMargin = 50 * pnt;
         break;
      case PERIOD_H4:
         mwMargin = 150 * pnt;
         break;
      case PERIOD_D1:
         mwMargin = 500 * pnt;
         break;
      default:
         mwMargin = 10 * pnt;
   }
   
   if (mwMargin < (High[i] - Low[i]) * 0.25) mwMargin = (High[i] - Low[i]) * 0.25;
   //mwMargin = (High[i] - Low[i]) * 0.25;
   
   bool checkForConsole = true;
   int levelDiff = 2;
   double cancelIfSmallerRatio = 3.0;
   double cancelIfSmallerRatioBetween = 1.0;
   
   if (checkForConsole && isConsole(i)) return (false);
   
   for (int j=3; j<=backPeriod+3; j++)
   {
      if (dir == OP_SELL && (isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin) || isBetweenValues(High[i+j], High[i] + mwMargin, High[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != -1 && isSpinningTB(i+j) != -1 && isDBHL(i+j) != -1 && isEngulfing(i+j) != -1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, j, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, backPeriod, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
      if (dir == OP_BUY  && (isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin) || isBetweenValues(Low[i+j], Low[i] + mwMargin, Low[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != 1 && isSpinningTB(i+j) != 1 && isDBHL(i+j) != 1 && isEngulfing(i+j) != 1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, j, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, backPeriod, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
   }
   
   if (foundAt > 0)
   {
      int x,y,outside=0;
      
      if (checkForConsole && isConsole(foundAt)) return (false);
      
      if (dir == OP_BUY)
      {
         int lowest = iLowest(pair, tf, MODE_LOW, (foundAt - i) + 10, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) {
            
            if (High[iHighest(pair, tf, MODE_HIGH, 10, foundAt)] - Low[foundAt] > (High[foundAt] - Low[foundAt]) * levelDiff) {
               for (x=foundAt; x>i; x--) {
                  //BufferDownTP[x] = Low[foundAt];
                  
                  if (High[x] > High[foundAt]) outside++;
               }
               
               if (outside < 2) return (false);
               
               return (true);
            }
            
            //return (true);
         }
         //else { BufferDownTP[foundAt] = Low[foundAt]; }
      }
      if (dir == OP_SELL)
      {
         int highest = iHighest(pair, tf, MODE_HIGH, (foundAt - i) + 10, i);
         if (highest == i || highest == i+1 || highest == foundAt) {
            
            if (High[foundAt] - Low[iLowest(pair, tf, MODE_LOW, 10, foundAt)] > (High[foundAt] - Low[foundAt]) * levelDiff) {
               for (x=foundAt; x>i; x--) {
                  //BufferUpTP[x] = High[foundAt];
                  
                  if (Low[x] < Low[foundAt]) outside++;
               }
               
               if (outside < 2) return (false);
               
               return (true);
            }
            
            //return (true);
         }
         //else { BufferUpTP[foundAt] = High[foundAt]; }
      }
   }
   
   return (false);
}

// musi byæ silny ruch przed pierwszym odbiciem (wielokrotnoœæ œwiecy z odbicia), a pomiêdzy 
bool isMWExperimental_THREE (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int levelDiff = 2;
   int backPeriod = 50;
   int foundAt = 0;
   
   double mwMargin;
   
   switch (tf) {
      case PERIOD_M1:
         mwMargin = 5 * pnt;
         break;
      case PERIOD_M15:
         mwMargin = 30 * pnt;
         break;
      case PERIOD_M30:
      case PERIOD_H1:
         mwMargin = 50 * pnt;
         break;
      case PERIOD_H4:
         mwMargin = 150 * pnt;
         break;
      case PERIOD_D1:
         mwMargin = 500 * pnt;
         break;
      default:
         mwMargin = 10 * pnt;
   }
   
   //if (mwMargin < (High[i] - Low[i]) * 0.25) mwMargin = (High[i] - Low[i]) * 0.25;
   mwMargin = (High[i] - Low[i]) * 0.25;
   
   double cancelIfSmallerRatio = 3.0;
   double cancelIfSmallerRatioBetween = 2.0;
   double cancelIfSmallerTrend = 3.0;
   
   for (int j=3; j<=backPeriod+3; j++)
   {
      if (dir == OP_SELL && (isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin) || isBetweenValues(High[i+j], High[i] + mwMargin, High[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != -1 && isSpinningTB(i+j) != -1 && isDBHL(i+j) != -1 && isEngulfing(i+j) != -1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, j, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, backPeriod, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
      if (dir == OP_BUY  && (isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin) || isBetweenValues(Low[i+j], Low[i] + mwMargin, Low[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != 1 && isSpinningTB(i+j) != 1 && isDBHL(i+j) != 1 && isEngulfing(i+j) != 1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, j, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, backPeriod, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
   }
   
   if (foundAt > 0)
   {
      int x,y,outside=0;
      
      if (dir == OP_BUY)
      {
         int lowest = iLowest(pair, tf, MODE_LOW, (foundAt - i) + 10, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) {
            
            if (High[iHighest(pair, tf, MODE_HIGH, 10, foundAt)] - Low[foundAt] > (High[foundAt] - Low[foundAt]) * levelDiff) {
               for (x=foundAt; x>i; x--) {
                  //BufferDownTP[x] = Low[foundAt];
                  
                  if (High[x] > High[foundAt]) outside++;
               }
               
               if (outside < 2) return (false);
               
               return (true);
            }
            
            //return (true);
         }
         //else { BufferDownTP[foundAt] = Low[foundAt]; }
      }
      if (dir == OP_SELL)
      {
         int highest = iHighest(pair, tf, MODE_HIGH, (foundAt - i) + 10, i);
         if (highest == i || highest == i+1 || highest == foundAt) {
            
            if (High[foundAt] - Low[iLowest(pair, tf, MODE_LOW, 10, foundAt)] > (High[foundAt] - Low[foundAt]) * levelDiff) {
               for (x=foundAt; x>i; x--) {
                  //BufferUpTP[x] = High[foundAt];
                  
                  if (Low[x] < Low[foundAt]) outside++;
               }
               
               if (outside < 2) return (false);
               
               return (true);
            }
            
            //return (true);
         }
         //else { BufferUpTP[foundAt] = High[foundAt]; }
      }
   }
   
   return (false);
}

// tutaj patrzymy na ATR, na œwieczkach dochodz¹cych musi byæ wiêkszy, ni¿ X
bool isMWExperimental_TWO (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   double momentumToATR = 1.5;
   int backPeriod = 50;
   int foundAt = 0;
   
   double mwMargin = (High[i] - Low[i]) * 0.25;
   
   double cancelIfSmallerRatio = 3.0;
   double cancelIfSmallerRatioBetween = 1.0;
   double cancelIfSmallerTrend = 3.0;
   
   for (int j=3; j<=backPeriod+3; j++)
   {
      if (dir == OP_SELL && (isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin) || isBetweenValues(High[i+j], High[i] + mwMargin, High[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != -1 && isSpinningTB(i+j) != -1 && isDBHL(i+j) != -1 && isEngulfing(i+j) != -1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, j, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, backPeriod, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
      if (dir == OP_BUY  && (isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin) || isBetweenValues(Low[i+j], Low[i] + mwMargin, Low[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != 1 && isSpinningTB(i+j) != 1 && isDBHL(i+j) != 1 && isEngulfing(i+j) != 1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, j, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, backPeriod, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
   }
   
   if (foundAt > 0)
   {
      int x,y,yi,niceMoveA,niceMoveB;
      
      if (dir == OP_BUY)
      {
         int lowest = iLowest(pair, tf, MODE_LOW, (foundAt - i) + 10, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) {
            
            for (y=1; y<=5; y++) {
               if (isMomentumBar(foundAt+y, momentumToATR)) niceMoveA++;
            }
            
            for (y=1; y<=5; y++) {
               if (isMomentumBar(i+y, momentumToATR)) niceMoveB++;
            }
            
            if (niceMoveA > 0 && niceMoveB > 0)
            {
               for (x=foundAt; x>i; x--) {
                  BufferDownTP[x] = Low[foundAt];
               }
            }
            
            return (true);
         }
      }
      if (dir == OP_SELL)
      {
         int highest = iHighest(pair, tf, MODE_HIGH, (foundAt - i) + 10, i);
         if (highest == i || highest == i+1 || highest == foundAt) {
         
            for (y=1; y<=5; y++) {
               if (isMomentumBar(foundAt+y, momentumToATR)) niceMoveA++;
            }
            
            for (y=1; y<=5; y++) {
               if (isMomentumBar(i+y, momentumToATR)) niceMoveB++;
            }
            
            if (niceMoveA > 0 && niceMoveB > 0)
            {
               for (x=foundAt; x>i; x--) {
                  BufferUpTP[x] = High[foundAt];
               }
            }
            
            return (true);
         }
      }
   }
   
   return (false);
}

// Sprawdza czy jest ostry ruch przed pierwszym szczytem, ma byæ 8 z 10 œwiec w danym kierunku
bool isMWExperimental_ONE (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int countCandle = 7;
   int countCandleOf = 10;
   int backPeriod = 50;
   int foundAt = 0;
   
   double mwMargin = (High[i] - Low[i]) * 0.25;
   
   double cancelIfSmallerRatio = 3.0;
   double cancelIfSmallerRatioBetween = 1.0;
   double cancelIfSmallerTrend = 3.0;
   
   for (int j=3; j<=backPeriod+3; j++)
   {
      if (dir == OP_SELL && (isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin) || isBetweenValues(High[i+j], High[i] + mwMargin, High[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != -1 && isSpinningTB(i+j) != -1 && isDBHL(i+j) != -1 && isEngulfing(i+j) != -1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, j, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, backPeriod, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
      if (dir == OP_BUY  && (isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin) || isBetweenValues(Low[i+j], Low[i] + mwMargin, Low[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != 1 && isSpinningTB(i+j) != 1 && isDBHL(i+j) != 1 && isEngulfing(i+j) != 1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, j, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, backPeriod, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
   }
   
   if (foundAt > 0)
   {
      int x,y,yi;
      int niceMove=0;
      
      if (dir == OP_BUY)
      {
         // czy mamy trend, sprawdzamy 10 ostatnich swieczek czy zrobily jakies momentum
         //highest = iHighest(pair, tf, MODE_HIGH, 10, foundAt);
         //if (iHigh(pair, tf, highest) - iLow(pair, tf, foundAt) < iATR(pair, tf, 5, foundAt) * cancelIfSmallerTrend) return (false);

         int lowest = iLowest(pair, tf, MODE_LOW, (foundAt - i) + countCandleOf, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) {
            
            for (y=1; y<=countCandleOf; y++) {
               if (getCandleDirection(foundAt+y) == -1) niceMove++;
            }
            
            if (niceMove >= countCandle)
            {
               return (true);
            }
         }
      }
      if (dir == OP_SELL)
      {
         // czy mamy trend, sprawdzamy 10 ostatnich swieczek czy zrobily jakies momentum
         //lowest = iLowest(pair, tf, MODE_LOW, 10, foundAt);
         //if (iHigh(pair, tf, foundAt) - iLow(pair, tf, lowest) < iATR(pair, tf, 5, foundAt) * cancelIfSmallerTrend) return (false);
         
         int highest = iHighest(pair, tf, MODE_HIGH, (foundAt - i) + countCandleOf, i);
         if (highest == i || highest == i+1 || highest == foundAt) {
         
            for (y=1; y<=countCandleOf; y++) {
               if (getCandleDirection(foundAt+y) == 1) niceMove++;
            }
            
            if (niceMove >= countCandle)
            {
               return (true);
            }
         }
      }
   }
   
   return (false);
}

bool isMWExperimental_ZERO (int i, string system, int dir, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   int backPeriod = 50;
   int foundAt = 0;
   
   /*
   double mwMargin;
   
   switch (tf) {
      case PERIOD_M1:
         mwMargin = 5 * pnt;
         break;
      case PERIOD_M15:
         mwMargin = 30 * pnt;
         break;
      case PERIOD_M30:
      case PERIOD_H1:
         mwMargin = 50 * pnt;
         break;
      case PERIOD_H4:
         mwMargin = 150 * pnt;
         break;
      case PERIOD_D1:
         mwMargin = 500 * pnt;
         break;
      default:
         mwMargin = 10 * pnt;
   }
   */
   
   double mwMargin = (High[i] - Low[i]) * 0.25;
   
   double cancelIfSmallerRatio = 3.0;
   double cancelIfSmallerRatioBetween = 1.0;
   double cancelIfSmallerTrend = 3.0;
   
   for (int j=3; j<=backPeriod+3; j++)
   {
      if (dir == OP_SELL && (isBetweenValues(High[i], High[i+j] + mwMargin, High[i+j] - mwMargin) || isBetweenValues(High[i+j], High[i] + mwMargin, High[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != -1 && isSpinningTB(i+j) != -1 && isDBHL(i+j) != -1 && isEngulfing(i+j) != -1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, j, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iLow(pair, tf, iLowest(pair, tf, MODE_LOW, backPeriod, i)) > iLow(pair, tf, i) - (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
      if (dir == OP_BUY  && (isBetweenValues(Low[i], Low[i+j] + mwMargin, Low[i+j] - mwMargin) || isBetweenValues(Low[i+j], Low[i] + mwMargin, Low[i] - mwMargin)))
      {
         //if (isPinBar(i+j) != 1 && isSpinningTB(i+j) != 1 && isDBHL(i+j) != 1 && isEngulfing(i+j) != 1 && !isOB(i, i+1) && !isOB(i+1, i)) continue;
         foundAt = i+j;
         
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, j, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatioBetween) return (false);
         //if (iHigh(pair, tf, iHighest(pair, tf, MODE_HIGH, backPeriod, i)) < iHigh(pair, tf, i) + (iHigh(pair, tf, i) - iLow(pair, tf, i)) * cancelIfSmallerRatio) return (false);
         
         break;
      }
   }
   
   if (foundAt > 0)
   {
      if (dir == OP_BUY)
      {
         // czy mamy trend, sprawdzamy 10 ostatnich swieczek czy zrobily jakies momentum
         //highest = iHighest(pair, tf, MODE_HIGH, 10, foundAt);
         //if (iHigh(pair, tf, highest) - iLow(pair, tf, foundAt) < iATR(pair, tf, 5, foundAt) * cancelIfSmallerTrend) return (false);

         int lowest = iLowest(pair, tf, MODE_LOW, (foundAt - i) + 5, i);
         if (lowest == i || lowest == i+1 || lowest == foundAt) return (true);
      }
      if (dir == OP_SELL)
      {
         // czy mamy trend, sprawdzamy 10 ostatnich swieczek czy zrobily jakies momentum
         //lowest = iLowest(pair, tf, MODE_LOW, 10, foundAt);
         //if (iHigh(pair, tf, foundAt) - iLow(pair, tf, lowest) < iATR(pair, tf, 5, foundAt) * cancelIfSmallerTrend) return (false);
         
         int highest = iHighest(pair, tf, MODE_HIGH, (foundAt - i) + 5, i);
         if (highest == i || highest == i+1 || highest == foundAt) return (true);
      }
   }
   
   return (false);
}