//+------------------------------------------------------------------+
//|                                                   Screenshot.mq4 |
//|                      Copyright © 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#include <helpers_new.mqh>

extern string systemName = "";

int init()
{
   makeScreenshot();
   return(0);
}

int deinit()
{
   return(0);
}

int start()
{   
   everyTick();
   if (Volume[0] == 1) everyBar();
   
   return(0);
}

void everyTick()
{
   
}

void everyBar()
{       
	makeScreenshot();
}

void makeScreenshot()
{
   WindowScreenShot(getPath(systemName), 800, 600);
}

string getPath(string tail)
{
   datetime t = iTime("EURUSD", Period(), 0);
   
   string path = StringConcatenate("screen", "\\", normalizeInt(TimeYear(t)), "\\", normalizeInt(TimeMonth(t)), "\\", normalizeInt(TimeDay(t)), "\\", Symbol(), "\\", getPeriodName(Period()), "\\");
   //string path = StringConcatenate("screen", "\\", Symbol(), "_", getPeriodName(Period()), "_");
   return (path + normalizeInt(TimeHour(t)) + "_" + normalizeInt(TimeMinute(t)) + (StringLen(tail) > 0 ? "_" + tail : "") + ".gif");
}

string normalizeInt(int i)
{
   string str = (string) i;
   if (StringLen(str) == 1) {
      str = "0" + str;
   }
   return (str);
}

//+------------------------------------------------------------------+
