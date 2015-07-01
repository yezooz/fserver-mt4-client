#include <helpers.mqh>

#define filterMA          0
#define filterRSI         0
#define filterRoundLevels 0
#define filterSwing       0
#define filterBox         0
#define filterSR          0
#define filterBarCounting 0

double getRR (string pair="", int tf=0)
{
   return (2.0);
   //return (1.0);
}

int getSignalCancelPeriod (string system="", string pair="", int tf=0)
{
   return (3);
}

int getSignalCancelPeriodForMWB (string system="", string pair="", int tf=0)
{
   return (100);
}

string getFilters (string system="", string pair="", int tf=0)
{
   return ("");
}

double getEntryDistance (string system="", string pair="", int tf=0)
{
   return (11.0);
}

double getActivationDistance (string system="", string pair="", int tf=0)
{
   return (11.0);
}

double getActivationDistanceForMWB (string system="", string pair="", int tf=0)
{
   if (tf == 0) tf = Period();
   
   switch (tf) {
      case PERIOD_M5:
         return (20);
      case PERIOD_M15:
      case PERIOD_M30:
      case PERIOD_H1:
      case PERIOD_H4:
      case PERIOD_D1:
      default:
         return (20);
   }
}

double getExitDistance (string system="", string pair="", int tf=0)
{
   if (tf == 0) tf = Period();

   switch (tf) {
      case PERIOD_M1:
         return (10);
      case PERIOD_M5:
         return (20);
      case PERIOD_M15:
         return (30);
      case PERIOD_M30:
      case PERIOD_H1:
         return (50);
      case PERIOD_H4:
         return (50);
      case PERIOD_D1:
      default:
         return (100);
   }
}

double getExitDistanceForMWB (string system="", string pair="", int tf=0)
{
   if (tf == 0) tf = Period();
   
   switch (tf) {
      case PERIOD_M5:
         return (20);
      case PERIOD_M15:
      case PERIOD_M30:
      case PERIOD_H1:
      case PERIOD_H4:
      case PERIOD_D1:
      default:
         return (20);
   }
}

int getSlippage (string pair="", int tf=0)
{
   return (1);
}