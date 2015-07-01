//+------------------------------------------------------------------+
//|                                                 ghttpTesting.mq4 |   
//|                           by : Giovanni (giovanni4000@gmail.com) |
//|                                                                  |
//| Thanks to "gunzip" at : http://codebase.mql4.com/7353            |
//|                                                                  |
//| 1) Put this script to ..../experts/scripts/ folder               |
//| 2) Put "ghttp.mqh" to ..../experts/include/ folder               |
//| 3) Create "ghttptesting.php", put to .../apache/htdocs/ folder   |
//| 4) Open MT4 client, activate the "DLL import", open a chart      |
//|    ex: EURUSD M15                                                |
//| 5) Attach this scripts to chart. See result in "experts tab"     |
//|    and on the chart                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| file: "ghttptesting.php" example.                                |
//|                                                                  |
//| <?php                                                            |
//| $openprc = $_GET["open"];                                        |
//| $closeprc = $_GET["close"];                                      |
//| $highprc = $_GET["high"];                                        |
//| $lowprc = $_GET["low"];                                          |
//| if ($openprc < $closeprc) {                                      |
//|     echo ("Prev Candle is: BULLISH.");                           |
//| }                                                                |
//| else {                                                           |
//|     echo ("Prev Candle is: BEARISH.");                           |
//| }                                                                |
//| ?>                                                               |
//+------------------------------------------------------------------+

#include <server.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init(){
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()  {
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   string response;
   bool connection;
   //---
   string url = "http://instadailyapp.com:9000/signal/writer/?csv=pin_divergence,1,EURAUD,M15,BUY,1.52420,1.52450,1.52370,1.52440,2014-02-11%2000:00,FxPro_MT4,6285798,";
   response = serverGet("http://instadailyapp.com:9000", "/signal/writer/?csv=pin_divergence,1,EURAUD,M15,BUY,1.52420,1.52450,1.52370,1.52440,2014-02-11%2000:00,FxPro_MT4,6285798,");

      Comment("The Response => ", response);
      Print("The Response => ", response);
   
   //---
   return(0);
}
//+------------------------------------------------------------------+