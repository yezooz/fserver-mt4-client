#property copyright "Copyright © 2012, Marek Mikuliszyn"

#include <stderror.mqh>
#include <stdlib.mqh>

#define momentumATR          1.5
#define momentumBodyToCandle 0.5

#import "kernel32.dll"
   void OutputDebugStringA(string msg);
#import

double lines[];

bool isBetweenValues (double testValue, double high, double low) {
   if (low > high) {
      double temp = low;
      low = high;
      high = temp;
   }
   
   return (testValue <= high && testValue >= low);
}

// --- General candle functions

int getCandleDirection (int i, int tf=0)
{
   if (tf == 0) tf = Period();
   
   if (iOpen(NULL, tf, i) == iClose(NULL, tf, i)) return (0);
   if (iOpen(NULL, tf, i) < iClose(NULL, tf, i))  return (1);
   return (-1);
}

double getCandleShadowSize (int i, bool top_part) {
   double shadow;
   double candle = High[i] - Low[i];
   int dir = getCandleDirection(i);
   
   
   if (dir == 1 && top_part)       shadow = High[i] - Close[i];
   else if (dir <= 0 &&  top_part) shadow = High[i] - Open[i];
   else if (dir == 1 && !top_part) shadow = Close[i] - Low[i];
   else if (dir <= 0 && !top_part) shadow = Open[i] - Low[i];
   
   return (shadow / candle);
}

bool isCandleCovered (int A, int B)
{
   if (isBetweenValues(High[A],  High[B], Low[B])) return (true);
   if (isBetweenValues(Low[A],   High[B], Low[B])) return (true);
   if (isBetweenValues(Open[A],  High[B], Low[B])) return (true);
   if (isBetweenValues(Close[A], High[B], Low[B])) return (true);
   
   if (isBetweenValues(High[B],  High[A], Low[A])) return (true);
   if (isBetweenValues(Low[B],   High[A], Low[A])) return (true);
   if (isBetweenValues(Open[B],  High[A], Low[A])) return (true);
   if (isBetweenValues(Close[B], High[A], Low[A])) return (true);
   
   return (false);
}

void upperShadow(int i, double &arr[]) {
   arr[0] = High[i];
   if (getCandleDirection(i) == 1) {
      arr[1] = Close[i];
   }
   else {
      arr[1] = Open[i];
   }
}

void lowerShadow(int i, double &arr[]) {
   arr[1] = Low[i];
   if (getCandleDirection(i) == 1) {
      arr[0] = Open[i];
   }
   else {
      arr[0] = Close[i];
   }
}

double candleCovered(int A, int B) 
{   
   if (Open[B] == Close[B]) return (0.0);
   if (Open[B]  < Open[A]  && Close[B] > Close[A]) return (1.0);
   if (Close[B] < Close[A] && Open[B]  > Open[A])  return (1.0);
   
   if (Close[A] > Open[A] && Close[B] > Open[B] && (Open[B] < Close[A] || Close[B] > Open[A]))  return (0.0); // both up,  wrong place
   if (Close[A] < Open[A] && Close[B] < Open[B] && (Open[B] > Close[A] || Close[B] < Open[A]))  return (0.0); // both down, wrong place
   if (Close[A] > Open[A] && Close[B] < Open[B] && (Open[B] < Open[A]  || Close[B] > Close[A])) return (0.0); // up, down, wrong place
   if (Close[A] < Open[A] && Close[B] > Open[B] && (Open[B] > Close[A] || Close[B] < Open[A]))  return (0.0); // down, up, wrong place
   
   if (Close[A] > Open[A] && Close[B] > Open[B]) return ((Close[A] - Open[B])  / MathAbs(Open[B] - Close[B]));
   if (Close[A] < Open[A] && Close[B] < Open[B]) return ((Open[A]  - Close[B]) / MathAbs(Open[B] - Close[B]));
   if (Close[A] > Open[A] && Close[B] < Open[B]) return ((Close[A] - Open[B])  / MathAbs(Open[B] - Close[B]));
   if (Close[A] < Open[A] && Close[B] > Open[B]) return ((Open[A]  - Close[B]) / MathAbs(Open[B] - Close[B]));
   
   return (0.0);
}

double getCandleSizeToATR(int i, int atr_period=6)
{
   double atr = iATR(NULL, 0, atr_period, i+1);
   if (High[i] - Low[i] == 0 || atr == 0) return (0.0);
   
   return ((High[i] - Low[i]) / atr);
}

bool isMomentumBar(int i, double customMomentumATR=0)
{
   if (Open[i] - Close[i] == 0 || High[i] - Low[i] == 0) return (false);
   if (customMomentumATR == 0) customMomentumATR = momentumATR;
   
   int direction = getCandleDirection(i);
   
   if (getCandleSizeToATR(i) > customMomentumATR && (MathAbs(Open[i] - Close[i]) / (High[i] - Low[i])) >= momentumBodyToCandle) {}
   else return (false);
   
   // check left side
   for (int j=1; j<=10; j++)
   {
      //if ((direction == -1 && Low[i] >= Low[i+j]) || (direction == 1 && High[i] <= High[i+j])) return (false);
   }
   
   return (true);
}

double getSessionOpen(int i)
{
   double dayOpen = 0;
   
   int j=0;
   while (j<1000)
   {
      if (TimeHour(iTime(NULL, 0, i+j)) == 7 && TimeMinute(iTime(NULL, 0, i+j)) == 0)
      {
         return (iOpen(NULL, 0, i+j));
      }
      j++;
   }
   
   return (dayOpen);
}

//
// Strings
//

string Join(string separator, string values[])
{
   string result;
   int size = ArraySize(values);
   
   for(int i = 0; i < size; i++)
   {
      result = StringConcatenate(result, values[i]);
      
      if(i < size - 1)
      {
         result = StringConcatenate(result, separator);
      }
   }

   return(result);
}

bool Split(string stringValue, string separatorSymbol, string& results[], int expectedResultCount = 0)
{

   if (StringFind(stringValue, separatorSymbol) < 0)
   {// No separators found, the entire string is the result.
      ArrayResize(results, 1);
      results[0] = stringValue;
   }
   else
   {   
      int separatorPos = 0;
      int newSeparatorPos = 0;
      int size = 0;

      while(newSeparatorPos > -1)
      {
         size = size + 1;
         newSeparatorPos = StringFind(stringValue, separatorSymbol, separatorPos);
         
         ArrayResize(results, size);
         if (newSeparatorPos > -1)
         {
            if (newSeparatorPos - separatorPos > 0)
            {  // Evade filling empty positions, since 0 size is considered by the StringSubstr as entire string to the end.
               results[size-1] = StringSubstr(stringValue, separatorPos, newSeparatorPos - separatorPos);
            }
         }
         else
         {  // Reached final element.
            results[size-1] = StringSubstr(stringValue, separatorPos, 0);
         }
         
         
         //Alert(results[size-1]);
         separatorPos = newSeparatorPos + 1;
      }
   }   
   
   if (expectedResultCount == 0 || expectedResultCount == ArraySize(results))
   {  // Results OK.
      return (true);
   }
   else
   {  // Results are WRONG.
      Print("ERROR - size of parsed string not expected.", true);
      return (false);
   }
}

string Replace(string haystack, string needle, string replace=""){
   string left, right;
   int start=0;
   int rlen = StringLen(replace);
   int nlen = StringLen(needle);
   while (start > -1){
      start = StringFind(haystack, needle, start);
      if (start > -1){
         if(start > 0){
            left = StringSubstr(haystack, 0, start);
         }else{
            left="";
         }
         right = StringSubstr(haystack, start + nlen);
         haystack = left + replace + right;
         start = start + rlen;
      }
   }
   return (haystack);  
}

// Converts string to upper case (for english text only).
string Upper(string str)
{
   string s = str;
   int lenght = StringLen(str) - 1;
   int symbol;
   
   while(lenght >= 0)
   {
      symbol = StringGetChar(s, lenght);
      
      if((symbol > 96 && symbol < 123) || (symbol > 223 && symbol < 256))
      {
         s = StringSetChar(s, lenght, symbol - 32);
      }
      else if(symbol > -33 && symbol < 0)
      {
         s = StringSetChar(s, lenght, symbol + 224);
      }
      
      lenght--;
   }

   return(s);
}

// Converts string to lower case (for english text only).
string Lower(string str)
{
   string s = str;
   int lenght = StringLen(str) - 1;
   int symbol;
   
   while(lenght >= 0)
   {
      symbol = StringGetChar(s, lenght);
      
      if((symbol > 64 && symbol < 91) || (symbol > 191 && symbol < 224))
      {
         s = StringSetChar(s, lenght, symbol + 32);
      }
      else if(symbol > -65 && symbol < -32)
      {
         s = StringSetChar(s, lenght, symbol + 288);
      }
      
      lenght--;
   }
   
   return(s);
}

//
// Date and Time
//

// Converts HH:MM or HH:MM:SS string to datetime value.
// Returns true when convertion is succeeded.
bool StringToTime(string value, datetime& result)
{
   result = StrToTime(value);
   return((TimeToStr(result, TIME_MINUTES) == value) || 
          (TimeToStr(result, TIME_SECONDS) == value));
}

// Compares two datetimes ignoring the date part
bool TimeEquals(datetime a, datetime b)
{
   return(TimeHour(a) == TimeHour(b) &&
          TimeMinute(a) == TimeMinute(b) &&
          TimeSeconds(a) == TimeSeconds(b));
}

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

//
// Logging
//

bool _DebugViewEnabled = false;

void EnableDebugView()
{
   _DebugViewEnabled = true;
}

void DisableDebugView()
{
   _DebugViewEnabled = false;
}

void SetDebugView(bool enabled)
{
   _DebugViewEnabled = enabled;
}

bool GetDebugView()
{
   return(_DebugViewEnabled);
}

void Log(string message, string symbol = "")
{
   _Log("", symbol, message);
}

void LogFatal(string message, string symbol = "")
{
   _Log("Fatal", symbol, message);
}

void LogError(string message, string symbol = "")
{
   _Log("Error", symbol, message);
}

void LogWarn(string message, string symbol = "")
{
   _Log("Warn", symbol, message);
}

void LogDebug(string message, string symbol = "")
{
   _Log("Debug", symbol, message);
}

void LogInfo(string message, string symbol = "")
{
   _Log("Info", symbol, message);
}

void LogLastError(string symbol = "")
{
   int error = GetLastError();
   LogError(ErrorDescription(error) + "(code " + error + ")");
}

void _Log(string status, string symbol, string message)
{
   string msg = message;
   if(status == "") msg = message; else msg = status + ": " + message; 
   Print(msg);
   
   if(_DebugViewEnabled)
   {
      string prefix = "";
      if(symbol != "") prefix = GetExpertName(symbol) + " ";
      OutputDebugStringA(prefix + msg);
   }
}

//
// Misc
//

double getLineMargin ()
{
   double margin;
   double pnt = MarketInfo(Symbol(), MODE_POINT);
   
   switch (Period()) {
      case PERIOD_M1:
         return (5 * pnt);
      case PERIOD_M5:
         return (40 * pnt);
      case PERIOD_M15:
         return (70 * pnt);
      case PERIOD_M30:
         return (100 * pnt);
      case PERIOD_H1:
         return (150 * pnt);
      case PERIOD_H4:
         return (300 * pnt);
      case PERIOD_D1:
      case PERIOD_W1:
      case PERIOD_MN1:
         return (1000 * pnt);
   }
}

bool hasLineAround (double value)
{
   double margin = getLineMargin();
   
   double v;
   for (int i=ArraySize(lines)-1; i>=0; i--)
   {
      if (isBetweenValues(lines[i], value + margin, value - margin)) return (true);
   }
   
   return (false);
}

void getLinesWithSuffix (string suffix, double &arr[])
{
   string name;
   for(int x = ObjectsTotal()-1; x >= 0; x--) {
      name = ObjectName(x);
      if (StringFind(name, suffix, 0) == -1) continue;
      arrayPushDouble(ObjectGet(name, OBJPROP_PRICE1), arr);
   }
   
   //printDoubleArray(arr);
}

void drawLine (double value, int from, int to, string suffix="", color c=Yellow, int width=1)
{
   //if (hasLineAround (value)) return (false);
   
   string id = "line_" + from + "_" + to;
   if (suffix != "") id = StringConcatenate(id, suffix);
   else id = StringConcatenate(id, "_", DoubleToStr(value, 5));
   
   ObjectCreate(id, OBJ_TREND, 0, from, value, to, value);
   ObjectSet(id, OBJPROP_RAY, false);
   ObjectSet(id, OBJPROP_COLOR, c);
   ObjectSet(id, OBJPROP_WIDTH, width);
   //arrayDoublePush(value, lines);
}

void drawLine (double value1, int from, double value2, int to, string suffix="", color c=Yellow, int width=1)
{
   //if (hasLineAround (value)) return (false);
   
   string id = "line_" + from + "_" + to;
   if (suffix != "") id = StringConcatenate(id, suffix);
   else id = StringConcatenate(id, "_", DoubleToStr(value1, 5));
   
   ObjectCreate(id, OBJ_TREND, 0, from, value1, to, value2);
   ObjectSet(id, OBJPROP_RAY, false);
   ObjectSet(id, OBJPROP_COLOR, c);
   ObjectSet(id, OBJPROP_WIDTH, width);
   //arrayDoublePush(value, lines);
}

void drawRectangle (double value1, double value2, int from, int to, string suffix="", color c=Yellow)
{
   string id = "rectangle_" + from + "_" + to + suffix;
   id = StringConcatenate(id, "_", DoubleToStr(value1, 5), "_", DoubleToStr(value2, 5));
   
   ObjectCreate(id, OBJ_RECTANGLE, 0, from, value1, to, value2);
   ObjectSet(id, OBJPROP_COLOR, c);
   ObjectSet(id, OBJPROP_BACK, true);
}

void drawLabel (double value, int time, string text, string suffix="", color c=Black)
{
   string id = "label_" + time;
   if (suffix != "") id = StringConcatenate(id, suffix);
   else id = StringConcatenate(id, "_", DoubleToStr(value, 5));
   
   ObjectCreate (id, OBJ_TEXT, 0, time, value);
   ObjectSetText (id, text, 8, "Arial", c);
}

color _Colors[] = { Maroon, Indigo, MidnightBlue, DarkBlue, DarkOliveGreen, SaddleBrown, ForestGreen, OliveDrab,
                   SeaGreen, DarkGoldenrod, DarkSlateBlue, Sienna, MediumBlue, Brown, DarkTurquoise, DimGray,
                   LightSeaGreen, DarkViolet, FireBrick, MediumVioletRed, MediumSeaGreen, Chocolate, Crimson, SteelBlue,
                   Goldenrod, MediumSpringGreen, LawnGreen, CadetBlue, DarkOrchid, YellowGreen, LimeGreen, OrangeRed,
                   DarkOrange, Orange, Gold, Yellow, Chartreuse, Lime, SpringGreen, Aqua };

int _LastColor = 0;

color GetNextColor()
{
   color result = _Colors[_LastColor];
   _LastColor = (_LastColor + 1) % ArraySize(_Colors);
   return(result);
}

string GetExpertName(string symbol = "")
{
   string result = WindowExpertName();
   
   if(StringLen(symbol) > 0)
   {
      result = result + " [" + symbol + "]";
   }
   
   return(result);
}

string GetOperationName(int operation)
{
   switch(operation)
   {
      case OP_BUY:
         return("Buy");

      case OP_SELL:
         return("Sell");

      case OP_BUYLIMIT:
         return("Buy limit pending");

      case OP_SELLLIMIT:
         return("Sell limit pending");

      case OP_BUYSTOP:
         return("Buy stop pending");

      case OP_SELLSTOP:
         return("Sell stop pending");

      default:
         return("Operation #" + operation);
   }
}

string getBroker() {
   string broker = AccountCompany();
   if      (broker == "Triple A Investment Services S.A.") broker = "AAAFx";
   else if (broker == "FxPro Financial Services Ltd")      broker = "FxPro_MT4";
   else if (broker == "Alpari (US), LCC.")                 broker = "Alpari US";
   
   return (broker);
}

void arrayPush (string item, string &arr[], bool unique=false)
{
   ArrayResize(arr, ArraySize(arr)+1);
   arr[ArraySize(arr)-1] = item;
}

void arrayPushDouble (double item, double &arr[], bool unique=false)
{
   if (unique)
   {
      for (int i=ArraySize(arr)-1; i>=0; i--)
      {
         if (arr[i] == item) return;
      }
   }
   
   ArrayResize(arr, ArraySize(arr)+1);
   arr[ArraySize(arr)-1] = item;
}

void arrayPushInt (int item, int &arr[], bool unique=false)
{
   if (unique)
   {
      for (int i=ArraySize(arr)-1; i>=0; i--)
      {
         if (arr[i] == item) return;
      }
   }
   
   ArrayResize(arr, ArraySize(arr)+1);
   arr[ArraySize(arr)-1] = item;
}

void arrayPushTime (datetime item, datetime &arr[], bool unique=false)
{
   if (unique)
   {
      for (int i=ArraySize(arr)-1; i>=0; i--)
      {
         if (arr[i] == item) return;
      }
   }
   
   ArrayResize(arr, ArraySize(arr)+1);
   arr[ArraySize(arr)-1] = item;
}

void arrayRemove(string item, string &arr[], string &newArr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) continue;
      arrayPush(arr[i], newArr);
   }
}

void arrayDoubleRemove(double item, double &arr[], double &newArr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) continue;
      arrayPushDouble(arr[i], newArr);
   }
}

void arrayIntRemove(int item, int &arr[], int &newArr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) continue;
      arrayPushInt(arr[i], newArr);
   }
}

void arrayTimeRemove(datetime item, datetime &arr[], datetime &newArr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) continue;
      arrayPushTime(arr[i], newArr);
   }
}

bool inArray(string item, string arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (true);
   }
   
   return (false);
}

bool inDoubleArray(double item, double arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (true);
   }
   
   return (false);
}

bool inIntArray(int item, int arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (true);
   }
   
   return (false);
}

bool inTimeArray(datetime item, datetime arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (true);
   }
   
   return (false);
}

int findInArray(string item, string arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (i);
   }
   
   return (-1);
}

int findInDoubleArray(double item, double arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (i);
   }
   
   return (-1);
}

int findInIntArray(int item, int arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (i);
   }
   
   return (-1);
}

bool findInTimeArray(datetime item, datetime arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (i);
   }
   
   return (-1);
}

bool doubleInArray(double item, double arr[])
{
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      if (arr[i] == item) return (true);
   }
   
   return (false);
}

void printArray(string arr[])
{
   Print("{ " + Join(", ", arr) + " }");
}

void printDoubleArray(double arr[])
{
   string sArr[];
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      arrayPush(DoubleToStr(arr[i], 5), sArr);
   }
   
   printArray(sArr);
}

void printIntArray(int arr[])
{
   string sArr[];
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      arrayPush(DoubleToStr(arr[i], 0), sArr);
   }
   
   printArray(sArr);
}

void printTimeArray(datetime arr[])
{
   string sArr[];
   for (int i=ArraySize(arr)-1; i>=0; i--)
   {
      arrayPush(TimeToString(arr[i]), sArr);
   }
   
   printArray(sArr);
}

/*
void addQueryToQueue(string query) {
   queryQueue[ArraySize(queryQueue) - 1] = query;
   ArrayResize(queryQueue, ArraySize(queryQueue) + 1);
}

void executeQueue() {
   for (int i=0; i<ArraySize(queryQueue)-1; i++) {
      //do_exec(db, queryQueue[i]);
   }
   ArrayResize(queryQueue, 1);
   queryQueue[0] = "";
}

void pushToArray(string item, &string arr) {
   arr[ArraySize(arr) - 1] = item;
   ArrayResize(arr, ArraySize(arr) + 1);
}

bool hasSignal(int signal_id) {
  int c;
  bool r;
  
  r = false;
  for(c = 0; c < ArraySize(tradedSignals); c++) {
    if (signal_id == tradedSignals[c]) {
      return (true);
    }
  }  
  
  return(false);
}
*/