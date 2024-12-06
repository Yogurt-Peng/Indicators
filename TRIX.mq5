
#property description "Trix oscillator"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   3
//--- plot Trix
#property indicator_label1  "Trix"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Hist
#property indicator_label3  "Histogram"
#property indicator_type3   DRAW_COLOR_HISTOGRAM
#property indicator_color3  clrGreen,clrRed,clrDarkGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- input parameters
input uint                 InpPeriod         =  14;            // Period
input ENUM_MA_METHOD       InpMethod1        =  MODE_SMA;      // First MA method
input ENUM_MA_METHOD       InpMethod2        =  MODE_SMA;      // Second MA method
input ENUM_MA_METHOD       InpMethod3        =  MODE_SMA;      // Third MA method
input uint                 InpPeriodSig      =  9;             // Signal period
input ENUM_MA_METHOD       InpMethodSig      =  MODE_SMA;      // Signal method
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
//--- indicator buffers
double         BufferTrix[];
double         BufferSignal[];
double         BufferHist[];
double         BufferColors[];
double         BufferMA1[];
double         BufferMA2[];
double         BufferMA3[];
//--- global variables
int            period_ma;
int            period_sig;
int            handle_ma;
int            weight_sum2;
int            weight_sum3;
int            weight_sumS;
//--- includes
#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period_ma=int(InpPeriod<2 ? 2 : InpPeriod);
   period_sig=int(InpPeriodSig<2 ? 2 : InpPeriodSig);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferTrix,INDICATOR_DATA);
   SetIndexBuffer(1,BufferSignal,INDICATOR_DATA);
   SetIndexBuffer(2,BufferHist,INDICATOR_DATA);
   SetIndexBuffer(3,BufferColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,BufferMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,BufferMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BufferMA3,INDICATOR_CALCULATIONS);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Trix ("+MethodToString(InpMethod1)+"("+(string)period_ma+"),"+MethodToString(InpMethod2)+"("+(string)period_ma+"),"+MethodToString(InpMethod3)+"("+(string)period_ma+"))");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferTrix,true);
   ArraySetAsSeries(BufferSignal,true);
   ArraySetAsSeries(BufferHist,true);
   ArraySetAsSeries(BufferColors,true);
   ArraySetAsSeries(BufferMA1,true);
   ArraySetAsSeries(BufferMA2,true);
   ArraySetAsSeries(BufferMA3,true);
//--- create MA's handles
   ResetLastError();
   handle_ma=iMA(NULL,PERIOD_CURRENT,period_ma,0,InpMethod1,InpAppliedPrice);
   if(handle_ma==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period_ma,") by ",EnumToString(InpAppliedPrice)," object was not created: Error ",GetLastError());
      return INIT_FAILED;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- Проверка и расчёт количества просчитываемых баров
   if(rates_total<fmax(period_ma,4) || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-2;
      ArrayInitialize(BufferTrix,0);
      ArrayInitialize(BufferSignal,0);
      ArrayInitialize(BufferHist,EMPTY_VALUE);
      ArrayInitialize(BufferMA1,0);
      ArrayInitialize(BufferMA2,0);
      ArrayInitialize(BufferMA3,0);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1),copied=0;
   copied=CopyBuffer(handle_ma,0,0,count,BufferMA1);
   if(copied!=count) return 0;

   switch(InpMethod2)
     {
      case MODE_EMA  :  if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA1,BufferMA2)==0) return 0;                break;
      case MODE_SMMA :  if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA1,BufferMA2)==0) return 0;                   break;
      case MODE_LWMA :  if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA1,BufferMA2,weight_sum2)==0) return 0; break;
      //---MODE_SMA
      default        :  if(SimpleMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA1,BufferMA2)==0) return 0;                     break;
     }
   switch(InpMethod3)
     {
      case MODE_EMA  :  if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA2,BufferMA3)==0) return 0;                break;
      case MODE_SMMA :  if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA2,BufferMA3)==0) return 0;                   break;
      case MODE_LWMA :  if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA2,BufferMA3,weight_sum3)==0) return 0; break;
      //---MODE_SMA
      default        :  if(SimpleMAOnBuffer(rates_total,prev_calculated,period_ma,period_ma,BufferMA2,BufferMA3)==0) return 0;                     break;
     }

//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      double MA3_0=BufferMA3[i];
      double MA3_1=BufferMA3[i+1];
      BufferTrix[i]=(MA3_1!=0 ? (MA3_0-MA3_1)/MA3_1/Point() : 0);
     }

   switch(InpMethodSig)
     {
      case MODE_EMA  :  if(ExponentialMAOnBuffer(rates_total,prev_calculated,period_ma,period_sig,BufferTrix,BufferSignal)==0) return 0;                break;
      case MODE_SMMA :  if(SmoothedMAOnBuffer(rates_total,prev_calculated,period_ma,period_sig,BufferTrix,BufferSignal)==0) return 0;                   break;
      case MODE_LWMA :  if(LinearWeightedMAOnBuffer(rates_total,prev_calculated,period_ma,period_sig,BufferTrix,BufferSignal,weight_sumS)==0) return 0; break;
      //---MODE_SMA
      default        :  if(SimpleMAOnBuffer(rates_total,prev_calculated,period_ma,period_sig,BufferTrix,BufferSignal)==0) return 0;                     break;
     }
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      BufferHist[i]=BufferTrix[i]-BufferSignal[i];
      BufferColors[i]=(BufferHist[i]>BufferHist[i+1] ? 0 : BufferHist[i]<BufferHist[i+1] ? 1 : 2);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Возвращает метод расчёта как текст                               |
//+------------------------------------------------------------------+
string MethodToString(const ENUM_MA_METHOD method)
  {
   return StringSubstr(EnumToString(method),5);
  }
//+------------------------------------------------------------------+
