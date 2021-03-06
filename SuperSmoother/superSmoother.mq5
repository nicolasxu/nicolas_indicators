//+------------------------------------------------------------------+
//|                                                superSmoother.mq5 |
//|                                                        NicolasXu |
//|                                       https://www.noWebsite5.com |
//+------------------------------------------------------------------+
#property copyright "NicolasXu"
#property link      "https://www.noWebsite5.com"
#property version   "1.00"


#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1 DRAW_COLOR_LINE

#property indicator_color1  clrYellow,clrLime,clrRed,C'0,0,0',C'0,0,0',C'0,0,0',C'0,0,0',C'0,0,0'
#property indicator_width1 2

// Super Smoother introduced by John F.

// M_E: e
// cosin: MathCos



int minBarNumber = 2; // calculation starts at 3rd

// buffer
double dataBuffer[];
double colorBuffer[];
double smoothed[];


int OnInit() {
   MqlDateTime dt;
   TimeCurrent(dt);
   printf("Super Smoother initializing... %d", dt.sec  );
   SetIndexBuffer(0,dataBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 



   
//---
   return(INIT_SUCCEEDED);
}

/*
EasyLanguage:

a1 = expvalue(-1.414*3.14159 / 10);
b1 = 2*a1*Cosine(1.414*180 / 10);
c2 = b1;
c3 = -a1*a1;
c1 = 1 - c2 - c3;
Filt = c1*(Close + Close[1]) / 2 + c2*Filt[1] + c3*Filt[2]; 


*/



void superSmoother(const double &inputData[], double &outputData[], int prev_calculated, int rates_total ) {
   //printf("count is: %d", count);
   int    ssPeriod = 8; // calculation period, 3 is 3 bars.
   double coeA = MathPow(M_E,-1.414*3.14159/ssPeriod);
   double coeB = 2*coeA*MathCos(1.414*180/ssPeriod);
   double coeC2 = coeB;
   double coeC3 = -coeA*coeA;
   double coeC1 = 1 - coeC2 - coeC3;
   
   ArrayResize(outputData, rates_total);
  

   for(int i=prev_calculated; i<rates_total; i++){
      
      if(i < minBarNumber) {
         outputData[i] = inputData[i];
      }
      if(i >= minBarNumber){
         outputData[i] = coeC1 * (inputData[i] + inputData[i-1]) / 2 + coeC2 * outputData[i-1] + coeC3 * outputData[i-2];         
      }
   }
}


void addColor(const double &inputData[], double &outputData[], int prev_calculated, int rates_total) {

   for(int i=prev_calculated;i<rates_total; i++) {
      
      outputData[i] = 0;
      if(i >= minBarNumber) {

         if(inputData[i]< inputData[i-1]) {
            outputData[i] = 1;
         }
         
         if(inputData[i]> inputData[i-1]) {
            outputData[i] = 2;
         }
      }
   }
}

/*

//Highpass filter cyclic components whose periods are shorter than 48 bars
// in EasyLanguage Cosine taks degree, 0 to 360,  not radians

radian = degree * 3.14 / 180 
alpha1 = (Cosine(.707*360 / 48) + Sine (.707*360 / 48) - 1) / Cosine(.707*360 / 48);
HP = (1 - alpha1 / 2)*(1 - alpha1 / 2)*(Close - 2*Close[1] + Close[2]) + 2*(1 - alpha1)*HP[1] - (1 - alpha1)*(1 - alpha1)*HP[2];


*/


void decycle(const double &inputData[], double &outputData[], int prev_calculated, int rates_total) {
   int cutOff = 8;
   int delay = 2; // counts, start at 1
   double alpha = (MathCos((360/cutOff) * (M_PI/180) ) + MathSin((360/cutOff)  * (M_PI/180) ) - 1) / MathCos((360/cutOff) * (M_PI/180));
   ArrayResize(outputData, rates_total);
   for(int i=prev_calculated; i<rates_total; i++) {
      if(i <= 1) {
         outputData[i] = inputData[i];
      }
      if(i > 1) {
     
         outputData[i] = (alpha / 2)*(inputData[i] + inputData[i-1]) + (1- alpha)*outputData[i-1]; 
         //outputData[i] = (1 - alpha/2)* (1 - alpha/2)* (inputData[i] - 2*inputData[i-1] + inputData[i-2]) + 2*(1-alpha)*outputData[i-1] - (1-alpha)*(1-alpha)*outputData[i -2];
         
      }
   }
   
   for(int i=prev_calculated; i<rates_total; i++){
      if(i < 5){
         printf("outputData[%d]: %G", i, outputData[i]); 
      }
        
   }
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   // 1st, 2nd value is just the input price
   
   if(rates_total < minBarNumber) {
      return (0);
   }
  
   // 1. smooth it
  
   // 2. decycle it
   //decycle(close, smoothed, prev_calculated, rates_total);
   
   superSmoother(close, dataBuffer, prev_calculated, rates_total);   
   
   // 3. color it
   addColor(dataBuffer, colorBuffer, prev_calculated, rates_total);
   
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {


   
}

