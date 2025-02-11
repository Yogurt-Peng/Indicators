//+------------------------------------------------------------------+
//|                                                         ALMA.mq5 |
//|                                        Copyright © 2022, Centaur |
//|                            https://www.mql5.com/en/users/centaur |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2022, Centaur"
#property link "https://www.mql5.com/en/users/centaur"
#property version "1.00"
//--- indicator description
#property description "Arnaud Legoux Moving Average (ALMA)"
#property description " "
//--- general indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots 1
//--- plot ALMA
#property indicator_label1 "ALMA"
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_color1 clrDeepSkyBlue, clrSandyBrown
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
//--- enumerations
enum ENUM_PRICE_DERIVATIVE
{
   Open,     // Open
   High,     // High
   Low,      // Low
   Close,    // Close
   Median,   // Median, (h+l)/2
   Mid,      // Mid, (o+c)/2
   Typical,  // Typical, (h+l+c)/3
   Weighted, // Weighted, (h+l+c+c)/4
   Average   // Average, (o+h+l+c)/4
};
//--- input parameters
input group "ALMA Settings:";
input int inp_length = 9;                  // Length
input int inp_sigma = 6;                       // Sigma
input double inp_offset = 0.85;                // Offset
input ENUM_PRICE_DERIVATIVE inp_price = Close; // Derivative
//--- indicator plot buffers
double ALMA[];
double ALMA_Color[];
double prices[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- verify input parameters
   int length = inp_length < 1 ? 1 : inp_length;
   int sigma = inp_sigma < 1 ? 1 : inp_sigma;
   double offset = inp_offset < 0.01 ? 0.01 : inp_offset;
   //--- indicator buffers mapping
   SetIndexBuffer(0, ALMA, INDICATOR_DATA);
   SetIndexBuffer(1, ALMA_Color, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, prices, INDICATOR_CALCULATIONS);
   //--- set indicator accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   //--- set indicator name display
   string short_name = "ALMA (" + IntegerToString(length) + ", " + IntegerToString(sigma) + ", " + DoubleToString(offset, 2) + ", " + EnumToString(inp_price) + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   //--- sets drawing lines to empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   //--- initialization succeeded
   return (INIT_SUCCEEDED);
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
   //--- check period
   if (rates_total < inp_length - 1)
      return (0);
   //--- calculate start position
   int bar;
   if (prev_calculated == 0)
      bar = 0;
   else
      bar = prev_calculated - 1;
   //--- main loop
   for (int i = bar; i < rates_total && !_StopFlag; i++)
   {
      //--- populate price array
      if (inp_price == Open)
         prices[i] = open[i];
      if (inp_price == High)
         prices[i] = high[i];
      if (inp_price == Low)
         prices[i] = low[i];
      if (inp_price == Close)
         prices[i] = close[i];
      if (inp_price == Median)
         prices[i] = (high[i] + low[i]) / 2;
      if (inp_price == Mid)
         prices[i] = (open[i] + close[i]) / 2;
      if (inp_price == Typical)
         prices[i] = (high[i] + low[i] + close[i]) / 3;
      if (inp_price == Weighted)
         prices[i] = (high[i] + low[i] + close[i] + close[i]) / 4;
      if (inp_price == Average)
         prices[i] = (open[i] + high[i] + low[i] + close[i]) / 4;
      //--- calculate arnaud legoux moving average
      ALMA[i] = i < inp_length - 1 ? EMPTY_VALUE : ALMA(i, inp_length, inp_sigma, inp_offset, prices);
      ALMA_Color[i] = i < inp_length - 1 ? EMPTY_VALUE : ALMA[i] - ALMA[i - 1] > 0.0 ? 0.0
                                                                                     : 1.0;
   }
   //--- return value of prev_calculated for next call
   return (rates_total);
}
//+------------------------------------------------------------------+
//| Function: Arnaud Legoux Moving Average (ALMA)                    |
//+------------------------------------------------------------------+
double ALMA(const int _position, const int _period, const int _sigma, const double _offset, const double &price[])
{
   double result = 0.0, m = (_offset * (_period - 1)), s = _period / _sigma;
   double WtdSum = 0.0, CumWt = 0.0, Wtd;
   for (int j = 0; j < _period - 1; j++)
   {
      Wtd = exp(-((j - m) * (j - m)) / (2 * s * s));
      WtdSum = WtdSum + Wtd * price[_position - (_period - 1 - j)];
      CumWt = CumWt + Wtd;
   }
   result = WtdSum / CumWt;
   return (result);
}
//+------------------------------------------------------------------+
