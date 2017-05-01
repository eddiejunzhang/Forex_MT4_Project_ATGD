//+------------------------------------------------------------------+
//|                                           ATGD_MT4_Alpha 0.2.mq4 |
//|             Copyright 2016, Eddie Zhang, eddie.j.zhang@gmail.com |
//|                            http://blog.sina.com.cn/eddiejunzhang |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, eddie.j.zhang@gmail.com"
#property link      "http://blog.sina.com.cn/eddiejunzhang"
#property version   "Alpha 0.2"
#property strict
//+------------------------------------------------------------------+
//|交易策略说明                                                      |
//|2016年我在浏览京东网页时发现了一本书，机械交易系统，我买来读了以后|
//|觉得作者的见解正好刺痛我的弱点。此前，我一直想做一个在外部交易建议|
//|指导下，基于海豚战法等交易策略的半自动交易程序，把自己从DailyFX网 |
//|站上得到的交易指导写入一个文件本文件，由程序读取这些信息，然后进行|
//|交易。在读了机械交易系统之后，我又从群晖DSM的下载应用中下载了     |
//|Andrew R. Young写的EA Programming - Creating Automated Trading    |
//|Ssytems in MQL for MetaTrader4. 此书系统地讲了MT4的编程方法以及一 |
//|一些标准代码。于是动手做此程序。                                  |
//|本程序取自书中172-175页，另有一个程序Experts Advisor with Function|
//|Pending Orders 在175-178页。                                      |
//|本程序关联的include程序在180-197页。                              |
//|ATGD=Auto Trade Guided by DailyFX                                 |
//|0.1版是原程序，0.2版开始增加读取文件的代码。2016-7-22             |
//+------------------------------------------------------------------+

#include <IncludeExample.mqh>

// External variables
extern bool DynamicLotSize=true;
extern double EquityPercent= 2;
extern double FixedLotSize = 0.1;

extern double StopLoss=50;
extern double TakeProfit=100;

extern int TrailingStop = 50;
extern int MinimumProfit= 50;

extern int Slippage=5;
extern int MagicNumber=123;

extern int FastMAPeriod = 10;
extern int SlowMAPeriod = 20;

extern bool CheckOncePerBar=true;

// Global variables
int BuyTicket;
int SellTicket;

double UsePoint;
int UseSlippage;

datetime CurrentTimeStamp;
// Init function
int init()
  {
   UsePoint=PipPoint(Symbol());
   UseSlippage=GetSlippage(Symbol(),Slippage);
   return(INIT_SUCCEEDED);
  }
// Start function
int start()
  {
   bool NewBar;
   int BarShift;
// Execute on bar open
   if(CheckOncePerBar==true)
     {
      BarShift=1;
      if(CurrentTimeStamp!=Time[0])
        {
         CurrentTimeStamp=Time[0];
         NewBar=true;
        }
      else NewBar=false;
     }
   else
     {
      NewBar=true;
      BarShift=0;
     }

//Obtain guide infomation from text file
   string subfolder="ATGD\\";
   string filename="ATGD.txt";
   int file_handle;

   file_handle=FileOpen(subfolder+filename,FILE_READ|FILE_TXT); //Error responses.
   if(file_handle!=INVALID_HANDLE)
     {
      int    str_size;
      string str;
      //--- read data from the file 
      while(!FileIsEnding(file_handle))
        {
         str_size=FileReadInteger(file_handle,INT_VALUE);
         str=FileReadString(file_handle,str_size);

         PrintFormat(str);
        }

      FileClose(file_handle);
     }
   else
      PrintFormat("Failed to open %s file, Error code = %d",filename,GetLastError());

// Moving averages
   double FastMA = iMA(NULL,0,FastMAPeriod,0,0,0,BarShift);
   double SlowMA = iMA(NULL,0,SlowMAPeriod,0,0,0,BarShift);

   double LastFastMA = iMA(NULL,0,FastMAPeriod,0,0,0,BarShift+1);
   double LastSlowMA = iMA(NULL,0,SlowMAPeriod,0,0,0,BarShift+1);

// Calculate lot size
   double LotSize=CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);
   LotSize=VerifyLotSize(LotSize);

// Begin trade block
   double OpenPrice;
   if(NewBar==true)
     {
      // Buy order
      if(FastMA>SlowMA && LastFastMA<=LastSlowMA && 
         BuyMarketCount(Symbol(),MagicNumber)==0)
        {

         // Close sell orders
         if(SellMarketCount(Symbol(),MagicNumber)>0)
           {
            CloseAllSellOrders(Symbol(),MagicNumber,Slippage);
           }

         // Open buy order
         BuyTicket=OpenBuyOrder(Symbol(),LotSize,UseSlippage,MagicNumber);

         // Order modification
         if(BuyTicket>0 && (StopLoss>0 || TakeProfit>0))
           {
            OrderSelect(BuyTicket,SELECT_BY_TICKET);
            OpenPrice=OrderOpenPrice();

            // Calculate and verify stop loss and take profit
            double BuyStopLoss=CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
            if(BuyStopLoss>0) BuyStopLoss=AdjustBelowStopLevel(Symbol(),
               BuyStopLoss,5);

            double BuyTakeProfit=CalcBuyTakeProfit(Symbol(),TakeProfit,
                                                   OpenPrice);
            if(BuyTakeProfit>0) BuyTakeProfit=AdjustAboveStopLevel(Symbol(),
               BuyTakeProfit,5);

            // Add stop loss and take profit
            AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit);
           }
        }

      // Sell Order
      if(FastMA<SlowMA && LastFastMA>=LastSlowMA
         && SellMarketCount(Symbol(),MagicNumber)==0)
        {
         if(BuyMarketCount(Symbol(),MagicNumber)>0)
           {
            CloseAllBuyOrders(Symbol(),MagicNumber,Slippage);
           }

         SellTicket=OpenSellOrder(Symbol(),LotSize,UseSlippage,MagicNumber);

         if(SellTicket>0 && (StopLoss>0 || TakeProfit>0))
           {
            OrderSelect(SellTicket,SELECT_BY_TICKET);
            OpenPrice=OrderOpenPrice();

            double SellStopLoss=CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
            if(SellStopLoss>0) SellStopLoss=AdjustAboveStopLevel(Symbol(),
               SellStopLoss,5);

            double SellTakeProfit=CalcSellTakeProfit(Symbol(),TakeProfit,
                                                     OpenPrice);

            if(SellTakeProfit>0) SellTakeProfit=AdjustBelowStopLevel(Symbol(),
               SellTakeProfit,5);
            AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
           }
        }
     }  // End trade block

// Adjust trailing stops
   if(BuyMarketCount(Symbol(),MagicNumber)>0 && TrailingStop>0)
     {
      BuyTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber);
     }

   if(SellMarketCount(Symbol(),MagicNumber)>0 && TrailingStop>0)
     {
      SellTrailingStop(Symbol(),TrailingStop,MinimumProfit,MagicNumber);
     }

   return(0);
  }
//+------------------------------------------------------------------+
