//+------------------------------------------------------------------+
//|                                                Signal Reader.mq4 |
//|                               Copyright © 2012, Marek Mikuliszyn |
//+------------------------------------------------------------------+
#include <sqlite.mqh>
#include <http51.mqh>
#include <helpers.mqh>

#property copyright "Copyright © 2012, Marek Mikuliszyn"
#property link      ""

extern string serverIp = "78.47.43.136";
extern int    serverPort = 9000;

extern double minLot = 0.1;
extern double maxLot = 100.0;
extern double debug = true;
extern int minRequestTime = 5;

string currentSignal[6];
string queryQueue[0];
int tradedSignals[0];
string db, signal, broker, pair;
double pnt, dig, spr, risk;

static int lastTime = 0;

int init()
{   
   db = StringConcatenate(getBroker(), "_", AccountNumber(), ".sqlite");
   
   createTables();
   
   checkForSignals();
   
   return(0);
}

int deinit()
{
   return(0);
}

int start()
{
   everyTick();
   if (Volume[0] > 1) return(0);
   everyBar();
   
   return(0);
}

void everyTick() {
   if (TimeCurrent() - lastTime > minRequestTime) {
      checkForSignals();
      lastTime = TimeCurrent();
   }
   readSignals();
   manageTrades(); 
}

void everyBar() {       
   lastTime = 0;
}

bool checkForSignals() {
   
   string res = serverGet("/signal/reader/", "");
   
   if (res == "NO SIGNALS") return (false);
   
   string rows[];
   string cols[];
   
   SplitString(res, "\n", rows);
   
   for (int i=0; i<ArraySize(rows); i++) {
      ArrayResize(cols, 0);
      SplitString(rows[i], ";", cols);
      
      if (StringLen(cols[1]) == 0) continue;
      
      pair = cols[1];
      risk = StrToDouble(cols[3]);
      pnt = MarketInfo(pair, MODE_POINT);
      dig = MarketInfo(pair, MODE_DIGITS);
      spr = MarketInfo(pair, MODE_SPREAD);
      
      addQueryToQueue("UPDATE signal SET is_deleted = \"true\" WHERE pair = \"" + cols[1] + "\" and direction = \"" + cols[2] + "\" and signal_id != \"" + cols[0] + "\"");
      
      // add signal
      string query = StringConcatenate("",
      "INSERT INTO signal (signal_id, pair, direction, activation_point, entry_point, tp, sl, valid_until, comment, size) VALUES(",
      "\"" + cols[0] + "\",", 
      "\"" + cols[1] + "\", ",
      "\"" + cols[2] + "\", ",
      "\"" + cols[4] + "\", ",
      "\"" + cols[5] + "\", ",
      "\"" + cols[6] + "\", ",
      "\"" + cols[7] + "\", ",
      "\"" + cols[8] + "\", ",
      "\"" + cols[9] + "\", ",
      "\"" + getLot(MathAbs(StrToDouble(cols[4]) - StrToDouble(cols[6])) + spr * pnt) + "\")");
      
      do_exec(db, query);
      
      if (debug == true) {
         //Print(query);
         serverGet("/report/log/", "action=signal_added&signal_id=" + cols[0] + "&pair=" + cols[1] + "&");
      }
   }
   
   executeQueue();
   
   return (true);
}

// Trading

void readSignals()
{
   int handle;
   int cols[1];
   string query;
   
   if (debug == true) {
      query = "SELECT signal_id FROM signal WHERE valid_until < \"" + TimeToStr(Time[0], TIME_DATE) + " " + TimeToStr(Time[0], TIME_MINUTES) + "\" OR is_deleted = \"true\"";
      handle = sqlite_query(db, query, cols);
      while (sqlite_next_row(handle) == 1) {
         serverGet("/report/log/", "action=signal_removed&signal_id=" + sqlite_get_col(handle, 0) + "&");
      }
      
      sqlite_free_query(handle);
   }

   addQueryToQueue("DELETE FROM signal WHERE valid_until < \"" + TimeToStr(Time[0], TIME_DATE) + " " + TimeToStr(Time[0], TIME_MINUTES) + "\" OR is_deleted = \"true\"");
   
   int ticket;
   
   query = "SELECT * FROM signal";
   handle = sqlite_query(db, query, cols);
   
   double aBid, aAsk;
   
   int    row_id;
   int    row_signal_id;
   string row_pair;
   string row_direction;
   double row_size;
   double row_activation_point;
   double row_entry_point;
   double row_tp;
   double row_sl;
   bool   row_is_active;
   string row_time;
   string row_valid_until;
   
   while (sqlite_next_row(handle) == 1) {
      
      row_id               = StrToInteger(sqlite_get_col(handle, 0));
      row_signal_id        = StrToInteger(sqlite_get_col(handle, 1));
      row_pair             = sqlite_get_col(handle, 2);
      row_direction        = sqlite_get_col(handle, 3);
      row_size             = StrToDouble(sqlite_get_col(handle, 4));
      row_activation_point = StrToDouble(sqlite_get_col(handle, 5));
      row_entry_point      = StrToDouble(sqlite_get_col(handle, 6));
      row_tp               = StrToDouble(sqlite_get_col(handle, 7));
      row_sl               = StrToDouble(sqlite_get_col(handle, 8));
      row_time             = sqlite_get_col(handle, 9);
      row_valid_until      = sqlite_get_col(handle, 10);
      
      if (sqlite_get_col(handle, 11) == "true") row_is_active = true;
      else                                      row_is_active = false;
      
      if (hasTradedSignal(row_signal_id)) continue;
      
      aBid  = MarketInfo(row_pair, MODE_BID);
      aAsk  = MarketInfo(row_pair, MODE_ASK);      
      pnt   = MarketInfo(row_pair, MODE_POINT);
      dig   = MarketInfo(row_pair, MODE_DIGITS);
      spr   = MarketInfo(row_pair, MODE_SPREAD);
      
      // jezeli cena jest na odpowiednim poziomie to aktywuj zlecenie i czekaj
      if (!row_is_active && ((row_direction == "BUY" && aBid >= row_activation_point) || (row_direction == "SELL" && aBid <= row_activation_point))) {
         addQueryToQueue("UPDATE signal SET is_activated = \"true\" WHERE id = " + row_id);
         
         if (debug == true) {
            serverGet("/report/log/", "action=signal_activated&signal_id=" + row_signal_id + "&pair=" + row_pair + "&");
         }
         
         Print("Trade activated (" + row_pair + " " + row_direction + ")");
         
      } else if (row_is_active && ((row_direction == "BUY" && aBid <= row_entry_point) || (row_direction == "SELL" && aBid >= row_entry_point))) { // otwieraj zlecenie jezeli cena pasuje
         
         if (row_direction == "BUY")  ticket = openTrade(row_pair, row_direction, row_size, row_sl - 300 * pnt, row_tp + 300 * pnt, "signal=" + row_signal_id);
         if (row_direction == "SELL") ticket = openTrade(row_pair, row_direction, row_size, row_sl + 300 * pnt, row_tp - 300 * pnt, "signal=" + row_signal_id);
         
         addTradedSignal(row_signal_id);
         
         addQueryToQueue("UPDATE signal SET is_deleted = \"true\" WHERE id = " + row_id);
         
         OrderSelect(ticket, SELECT_BY_TICKET);
         
         serverGet("/report/", StringConcatenate("action=open_trade&signal_id=", row_signal_id, "&",
            "ticket=", ticket, "&",
            "size=", DoubleToStr(row_size, 3), "&",
            "projected_tp=", DoubleToStr(row_tp, 5), "&",
            "projected_sl=", DoubleToStr(row_sl, 5), "&",
            "tp=", DoubleToStr(OrderTakeProfit(), 5), "&",
            "sl=", DoubleToStr(OrderStopLoss(), 5), "&",
            "price=", DoubleToStr(OrderOpenPrice(), 5), "&",
            "spread=", spr, "&"));
         
         //Print("Trade opened (" + row_pair + " " + row_direction + ")");
         
         OrderSelect(ticket, SELECT_BY_TICKET);
      }
   }

   sqlite_free_query(handle);
   
   executeQueue();
}

void manageTrades() {
   
   bool   result;
   double aBid, aAsk, point, profit;
   int    cmd, total, error;
   
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         cmd = OrderType();
         if(cmd != OP_BUY && cmd != OP_SELL) continue;
         if (OrderTakeProfit() == 0.0 || OrderStopLoss() == 0.0) continue;
         
         aBid  = MarketInfo(OrderSymbol(), MODE_BID);
         aAsk  = MarketInfo(OrderSymbol(), MODE_ASK);
         point = MarketInfo(OrderSymbol(), MODE_POINT);
         
         // zamykaj zlecenie ktory dotarly do poziomu SOFT TP/SL
         if ((cmd == OP_BUY  && (aBid >= OrderTakeProfit() - 300 * point || aBid < OrderStopLoss() + 300 * point)) || 
             (cmd == OP_SELL && (aBid <= OrderTakeProfit() + 300 * point || aBid > OrderStopLoss() - 300 * point))) {
            
            if (cmd == OP_BUY)  profit = closeTrade(OrderTicket(), aBid);
            if (cmd == OP_SELL) profit = closeTrade(OrderTicket(), aAsk);
            
            // update
            if (profit >= 0.0) {
               Print("Soft TP. +$" + DoubleToStr(profit, 2));
               //SendMail("TP (" + broker + ")", "+$" + DoubleToStr(profit, 2));
               serverGet("/report/", StringConcatenate("action=close_trade&ticket=", OrderTicket(), "&",
                  "price=", DoubleToStr(OrderClosePrice(), 5), "&",
                  "spread=", MarketInfo(OrderSymbol(), MODE_SPREAD), "&",
                  "profit=", DoubleToStr(profit, 2), "&"));
            }
            else {
               Print("Soft SL. -$" + DoubleToStr(MathAbs(profit), 2));
               //SendMail("SL (" + broker + ")", "-$" + DoubleToStr(MathAbs(profit), 2));
               serverGet("/report/", StringConcatenate("action=close_trade&ticket=", OrderTicket(), "&",
                  "price=", DoubleToStr(OrderClosePrice(), 5), "&",
                  "spread=", MarketInfo(OrderSymbol(), MODE_SPREAD), "&",
                  "profit=", DoubleToStr(profit, 2), "&"));
            }
         }
      }
      else { Print( "Error when order select ", GetLastError()); break; }
   }
}

int openTrade (string pair, string direction, double lots, double sl, double tp, string comment="") {
   int ticket, dir, error;
   double price;
   
   if      (direction == "BUY")  {
      dir = OP_BUY;
      price = MarketInfo(pair, MODE_ASK);
   }
   else if (direction == "SELL") {
      dir = OP_SELL;
      price = MarketInfo(pair, MODE_BID);
   }
   
   while(true) {
      ticket = OrderSend(pair, dir, lots, price, 3, 0.0, 0.0, comment, 0, 0, CLR_NONE);
      
      if (ticket < 0) { error = GetLastError(); Print("LastError = ", error); }
      else {
         OrderSelect(ticket, SELECT_BY_TICKET);
         
         double actualPrice = OrderOpenPrice();
         
         if (direction == "BUY") {
            tp += MathAbs(price - actualPrice) * pnt;
            sl -= MathAbs(price - actualPrice) * pnt;
         }
         else {
            tp -= MathAbs(price - actualPrice) * pnt;
            sl += MathAbs(price - actualPrice) * pnt;
         }
      
         OrderModify(ticket, price, sl, tp, 0, CLR_NONE);
         return (ticket);
      }
      
      if (error == 130) { 
         Print("WRONG STOPS! price=" + DoubleToStr(price, 5) + ";sl=" + DoubleToStr(sl, 5) + ";tp=" + DoubleToStr(tp, 5));
         //SendMail("Wrong Stops", "price=" + DoubleToStr(price, 5) + ";sl=" + DoubleToStr(sl, 5) + ";tp=" + DoubleToStr(tp, 5) + ". " + broker);
         serverGet("/report/log/", "action=open_error&signal_id=" + stringReplace(comment, "signal=") + "&comment=wrong stops&");
         return (0);
      }
      if (error == 138) RefreshRates();
      if (error == 132 || error == 133) return (0);
      if (error == 134) {
         //SendMail("No money to open trade", pair + ", " + lots + " lot. " + broker);
         Print("No money to open trade ", pair + ", " + DoubleToStr(lots, 2) + " lot. ");
         serverGet("/report/log/", "action=open_error&signal_id=" + stringReplace(comment, "signal=") + "&comment=no money&");
         return (0);
      }
      if (error == 148) {
         // trade number limit
         return (0);
      }
      if (error == 131) {
         serverGet("/report/log/", "action=open_error&signal_id=" + stringReplace(comment, "signal=") + "&comment=" + lots + " is invalid number of lots&");
         return (0);
      }
   }
}

double closeTrade (int ticket, double price) {
   bool result, error;
   OrderSelect(ticket, SELECT_BY_TICKET);
   
   while(true) {
      result = OrderClose(OrderTicket(), OrderLots(), price, 3, CLR_NONE);
      
      if (result != TRUE) { error = GetLastError(); Print("LastError = ", error); serverGet("/report/log/", "action=close_error&signal_id=" + stringReplace(OrderComment(), "signal=") + "&comment=" + error + "&"); }
      else error = 0;
      
      if (error == 135) RefreshRates();
      else return (OrderProfit());
   }
}

// Trading environment

bool canTrade()
{
   return (isRightTimeToTrade());
}

bool isRightTimeToTrade()
{
   return (true);
}

// Extras

string getPeriod(int period)
{
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

double getLot(double size) 
{
   double amnt = AccountBalance() * risk;
   
   if      (dig >= 4) size *= 100000;
   else if (dig >= 2) size *= 1000;
   
   double lot = amnt / size;
   
   //Print("Lot = " + lot + "; risk = " + risk + "; size = " + size);
   
   if (lot > maxLot) return (maxLot);
   if (lot < minLot) return (minLot);
   
   if (MarketInfo("EURUSD", MODE_LOTSTEP) == 0.01)
      return (StrToDouble(DoubleToStr(lot, 2)));
   if (MarketInfo("EURUSD", MODE_LOTSTEP) == 0.1)
      return (StrToDouble(DoubleToStr(lot, 1)));
   if (MarketInfo("EURUSD", MODE_LOTSTEP) == 1)
      return (StrToDouble(DoubleToStr(lot, 0)));
}

bool SplitString(string stringValue, string separatorSymbol, string& results[], int expectedResultCount = 0)
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

string stringReplace(string haystack, string needle, string replace=""){
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

// DB

void do_exec (string db, string exp)
{
   int i = 10;
   while (true) {
      int res = sqlite_exec (db, exp);
      
      if (res == 19) return;
      if (res != 0) Print ("Retrying Query (Error: " + res + "). Expression '" + exp + "' failed");
      else return;
      
      i--;
      if (i == 0) {
         Print("Query failed");
         //SendMail("Query failed (" + res + ")", exp + ". " + broker + " / " + system);
         return;
      }
   }
}

bool do_check_table_exists (string db, string table)
{
    int res = sqlite_table_exists (db, table);

    if (res < 0) {
        Print ("Check for table existence failed with code " + res);
        return (false);
    }

    return (res > 0);
}

void addQueryToQueue(string query) {
   queryQueue[ArraySize(queryQueue) - 1] = query;
   ArrayResize(queryQueue, ArraySize(queryQueue) + 1);
}

void executeQueue() {
   for (int i=0; i<ArraySize(queryQueue)-1; i++) {
      do_exec(db, queryQueue[i]);
   }
   ArrayResize(queryQueue, 1);
   queryQueue[0] = "";
}

void addTradedSignal(int signal_id) {
   tradedSignals[ArraySize(tradedSignals) - 1] = signal_id;
   ArrayResize(tradedSignals, ArraySize(tradedSignals) + 1);
}

bool hasTradedSignal(int signal_id) {
  int c;
  bool r;
  
  r = false;
  for(c = 0; c < ArraySize(tradedSignals); c++) {
    if (signal_id == tradedSignals[c]) {
      //r = true;
       return (true);
    }
  }  
  
  return(false);
}

string serverGet(string url, string params) {
   int status[1];
   string xUrl = StringConcatenate("http://", serverIp, ":", serverPort, url);
   string xParams = StringConcatenate(params, "broker=", broker, "&account=", AccountNumber());
   
   if (url == "/report/log/" || url == "/report/") Print(xUrl + "?" + xParams);
   
   return (httpGET(xUrl + "?" + xParams, status));
}

void createTables()
{
   string query;
   if (!do_check_table_exists (db, "signal")) {
      Print ("Signal table does not exist, create schema");
      query = StringConcatenate("",
      "CREATE TABLE signal (id INTEGER PRIMARY KEY  AUTOINCREMENT NULL ,",
      "signal_id INTEGER NOT NULL, pair VARCHAR NOT NULL , direction VARCHAR NOT NULL, size DOUBLE NOT NULL, activation_point DOUBLE NOT NULL , entry_point DOUBLE NOT NULL ,",
      "tp DOUBLE NOT NULL , sl DOUBLE NOT NULL ,",
      "client_time DATETIME NULL, valid_until DATETIME NOT NULL , is_activated BOOL DEFAULT false, is_deleted BOOL DEFAULT false, comment VARCHAR NULL, ",
      "CONSTRAINT unq UNIQUE (signal_id))");
      do_exec (db, query);
   }
}