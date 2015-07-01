#property copyright "Copyright � 2012-2014, Marek Mikuliszyn"

#include <http51.mqh>
#include <helpers.mqh>

#define version   1
#define serverIp  ""
#define serverPort 9000

string serverGet(string url, string params) {
   string broker = getBroker();
   
   string xUrl = StringConcatenate("http://", serverIp, ":", serverPort, url);
   string xParams = StringConcatenate(params, "broker=", broker, "&account=", AccountNumber(), "&nocache=", TimeCurrent());
   
   //if (url == "/report/log/" || url == "/report/") Print(xUrl + "?" + xParams);
   
   Print(xUrl + "?" + xParams);
   
   string res = httpGET(xUrl + "?" + xParams);
   Print("HTTP:", res);
   
   return (res);
}

string sendToServer(int i, string dir, string system, double h=0, double l=0)
{
   if (h == 0) h = High[i];
   if (l == 0) l = Low[i];
   
   string url = StringConcatenate("http://", serverIp, ":", serverPort, "/signal/writer/");
   string param = StringConcatenate("csv=", system, ",", version, ",", Symbol(), ",", getPeriodName(Period()), ",", dir, ",", 
   DoubleToStr(Open[i], 5), ",", DoubleToStr(h, 5), ",", DoubleToStr(l, 5), ",", DoubleToStr(Close[i], 5), ",",
   Replace(TimeToStr(Time[i], TIME_DATE), ".", "-"), " ", TimeToStr(Time[i], TIME_MINUTES), ",", getBroker(), ",", AccountNumber(), ",");
   
   //Print(param);
   
   string res = httpGET(url + "?" + param);
   Print("HTTP:", res);
   
   return (res);
}

string sendCSVToServer(string system, string pair, int period, string csv)
{
   string url = StringConcatenate("http://", serverIp, ":", serverPort, "/signal/writer/");
   string param = StringConcatenate("csv=", system, ",", version, ",", pair, ",", getPeriodName(period), ",", csv, ",", getBroker(), ",", AccountNumber(), ",");
   
   Print(url + "?" + param);
   
   string res = httpGET(url + "?" + param);
   Print("HTTP:", res);
   
   return (res);
}