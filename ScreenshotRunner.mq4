//+------------------------------------------------------------------+
//|                                             ScreenshotRunner.mq4 |
//|                      Copyright © 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

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


int init()
{
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
	for (int i=0; i<ArraySize(pairs); i++) {
      ChartSetSymbolPeriod(0, pairs[i], Period());
   }
   
   ChartSetSymbolPeriod(0, "EURUSD", Period());
}