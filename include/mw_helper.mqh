double getMWMargin (int i=1, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   
   if (tf == PERIOD_M1)
      return (0);
   else if (tf == PERIOD_M5)
      return (5 * pnt);
   return (10 * pnt);
   
   double m;
   switch (tf) {
      case PERIOD_M1:
         m = 5 * pnt;
         break;
      case PERIOD_M5:
         m = 5 * pnt;
         break;
      case PERIOD_M15:
         m = 10 * pnt;
         break;
      case PERIOD_M30:
         m = 40 * pnt;
         break;
      case PERIOD_H1:
         m = 50 * pnt;
      case PERIOD_H4:
         m = 100 * pnt;
         break;
      case PERIOD_D1:
         m = 200 * pnt;
         break;
      default:
         m = 40 * pnt;
   }
   
   //return (5 * pnt);
   
   //if (pair == "EURGBP" || StringFind(pair, "JPY", 0) > -1) return (m/2);
   if (pnt == 1 || pnt == 0.01 || pnt == 0.0001) return (m/10);
   
   //m = (High[i] - Low[i]) * 0.25;
   //m = 5 * pnt;
   
   return (m);
}

double getHSMargin (int i=1, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   
   if (tf == PERIOD_M1)
      return (0);
   else if (tf == PERIOD_M5)
      return (5 * pnt);
   return (10 * pnt);
   
   double m;
   switch (tf) {
      case PERIOD_M1:
         m = 5 * pnt;
         break;
      case PERIOD_M5:
         m = 5 * pnt;
         break;
      case PERIOD_M15:
         m = 10 * pnt;
         break;
      case PERIOD_M30:
         m = 40 * pnt;
         break;
      case PERIOD_H1:
         m = 50 * pnt;
      case PERIOD_H4:
         m = 100 * pnt;
         break;
      case PERIOD_D1:
         m = 200 * pnt;
         break;
      default:
         m = 40 * pnt;
   }
   
   //return (5 * pnt);
   
   //if (pair == "EURGBP" || StringFind(pair, "JPY", 0) > -1) return (m/2);
   if (pnt == 1 || pnt == 0.01 || pnt == 0.0001) return (m/10);
   
   //m = (High[i] - Low[i]) * 0.25;
   //m = 5 * pnt;
   
   return (m);
}

double getSRMargin (int i=1, string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0) tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   double m;
   switch (tf) {
      case PERIOD_M1:
         m = 5 * pnt;
         break;
      case PERIOD_M5:
         m = 5 * pnt;
         break;
      case PERIOD_M15:
         m = 10 * pnt;
         break;
      case PERIOD_M30:
         m = 40 * pnt;
         break;
      case PERIOD_H1:
         m = 50 * pnt;
      case PERIOD_H4:
         m = 100 * pnt;
         break;
      case PERIOD_D1:
         m = 200 * pnt;
         break;
      default:
         m = 40 * pnt;
   }
   
   if (pair == "EURGBP" || StringFind(pair, "JPY", 0) > -1) return (m/2);
   if (pnt == 1 || pnt == 0.01 || pnt == 0.0001) return (m/10);
   
   return (m);
}

// ---

double maxBreakoutBox(string pair="", int tf=0)
{
   if (pair == "") pair = Symbol();
   if (tf == 0)    tf = Period();
   double pnt = MarketInfo(pair, MODE_POINT);
   
   switch (tf)
   {
      case PERIOD_M5:
         return (120 * pnt);
      case PERIOD_M15:
         return (200 * pnt);
      case PERIOD_M30:
         return (300 * pnt);
      case PERIOD_H1:
         return (400 * pnt);
      case PERIOD_H4:
         return (1200 * pnt);
      case PERIOD_D1:
         return (2500 * pnt);
      default:
         return (10000 * pnt);
   }
}