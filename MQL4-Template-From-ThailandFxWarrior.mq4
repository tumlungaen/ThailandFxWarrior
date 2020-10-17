//+------------------------------------------------------------------+
//|                         MQL4-Template-From-ThailandFxWarrior.mq4 |
//|                              Copyright 2020, Thailand Fx Warrior |
//|                                 http://www.thailandfxwarrior.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Thailand Fx Warrior"
#property link      "http://www.thailandfxwarrior.com"
#property version   "1.00"
#property strict

//--- SYMBOL_TRADE_STOPS_LEVEL and SYMBOL_TRADE_FREEZE_LEVEL levels
int freeze_level ;
int stops_level ;

/**
   //--------
   //--------| FUNCTION FROM MQL5.com
   //--------
   bool CheckOrderForFREEZE_LEVEL(int ticket)
   double GetActivationPrice( int ticket )
   double GetNearestPrice( int type , int distance )
   bool CheckOrderForFREEZE_LEVEL( int ticket )
   int OrdersTotalPending( string sym )
   int OrderPendingSelect( int ind , string sym )
   string GetOrderTypeString( int type )
   bool CheckMoneyForTrade( string symb , double lots , int type )
   bool CheckVolumeValue( double volume , string &description )
   bool IsNewOrderAllowed()
   double PositionVolume( string symbol )
   bool CheckStopLoss_Takeprofit( ENUM_ORDER_TYPE type , double SL , double TP )
*/

int OnInit() {
   //--- distance from the activation price, within which it is not allowed to modify orders and positions
   freeze_level = (int)SymbolInfoInteger( _Symbol , SYMBOL_TRADE_FREEZE_LEVEL ) ;
   if( freeze_level != 0 ) {
      PrintFormat( "SYMBOL_TRADE_FREEZE_LEVEL=%d: order or position modification is not allowed,"  " if there are %d points to the activation price" , freeze_level , freeze_level ) ;
   }//end if
   //---
   
   
   return(INIT_SUCCEEDED);
}//end function

void OnDeinit( const int reason ) {
}//end function

void OnTick() {
   int orders = OrdersTotalPending( _Symbol ) ;
   //--- order ticket and distance to the activation price
   int distance , ticket ;
   
   //--- activation price
   double activation_price ;
   
   //--- only if there is a single pending order
   if( orders == 1 ) {
      //--- select order for working
      if( OrderPendingSelect( 0 , _Symbol ) ) {
         ticket = OrderTicket() ;
         
         //--- activation price
         activation_price = GetActivationPrice( ticket ) ;
         
         //--- output the distance to the order opening price at the current moment
         distance = (int)MathRound( MathAbs( activation_price - OrderOpenPrice() ) / _Point ) ;
         
         //--- get the freeze distance for pending orders and open positions
         freeze_level = (int)SymbolInfoInteger( _Symbol , SYMBOL_TRADE_FREEZE_LEVEL ) ;
         
         //--- get the nearest allowed price for opening this type of orders 
         stops_level = (int)SymbolInfoInteger( _Symbol , SYMBOL_TRADE_STOPS_LEVEL ) ;
         
         //--- allowed distance is the greatest of these two values
         int      min           = MathMax( freeze_level , stops_level ) ;
         double   nearest_price = GetNearestPrice( OrderType() , min + 1 ) ;
         
         //--- the current order activation price
         double openprice = OrderOpenPrice() ;
         
         //--- get the StopLoss and TakeProfit value
         double sl           = OrderStopLoss();
         double tp           = OrderTakeProfit();
         datetime expiration = ( datetime )OrderExpiration() ;

         //--- if the distance is less than the freeze level
         if( distance < freeze_level ) {
            PlaySound( "stops.wav" ) ; // play a sound alert
            Comment( StringFormat( "Distance=%d [SYMBOL_TRADE_FREEZE_LEVEL=%d]  %s  CurrentPrice=%.5f" , distance , freeze_level , GetOrderTypeString( OrderType() ) , activation_price ) ) ;
            
            //--- if the new price if different from the one specified in the order, it can be modified
            if( MathAbs( nearest_price - openprice ) > _Point ) {
               //--- first, write a message to the log
               PrintFormat( "Try to modify %s #%d at %.5f ==> new price=%.5f:  Bid=%.5f  Ask=%.5f" , GetOrderTypeString( OrderType() ) , ticket , openprice , nearest_price , Bid , Ask ) ;

               //--- try to make a forbidden modification
               if( !OrderModify( ticket , nearest_price , sl , tp , expiration ) ) {
                  PrintFormat( "freeze_level=%d" , freeze_level ) ;
                  //--- output the result 
                  PrintFormat("OrderModify for %s #%d failed, Error=%d" , GetOrderTypeString( OrderType() ), ticket , GetLastError() ) ;
               } else
                  PrintFormat( "Modification of order %s #%d done successfully" , GetOrderTypeString( OrderType() ) , ticket ) ;
                  Print( " -------------" ) ;
               } //end if
            //--- worked at the distance less than the freeze level - do nothing else on this tick 
            return ;
         }//end if
         
         if( distance > 2 * min ) {
            //--- now try to move the order as close as possible to the activation price
            nearest_price = GetNearestPrice( OrderType() , stops_level + 1 ) ;
            
            //--- the current distance from the current price to the activation price
            int current_delta = (int)MathAbs( ( openprice - activation_price ) / _Point ) ;
            //--- if the new opening price is different from the previous
            if( MathAbs( nearest_price - openprice ) / _Point >= 1 ) {
               //--- order can be modified
               PrintFormat( "Modify order %s #%d at %.5f => %.5f  OpenPrice-CurrenPrice=%.5f-%.5f=%d points Ask=%.5f Bid=%.5f" , GetOrderTypeString( OrderType() ) , ticket , openprice , nearest_price , openprice , activation_price , current_delta , Ask , Bid ) ;
               //--- modify
               if( OrderModify( ticket , nearest_price , sl , tp , expiration ) ) {
                  PrintFormat("Order %s #%d modified succesfully",GetOrderTypeString(OrderType()),ticket);
               } else { //--- modification failed
                  //--- output the result 
                  PrintFormat( "OrderModify for %s #%d failed, Error=%d" , GetOrderTypeString( OrderType() ) , ticket , GetLastError() ) ;
               }//end if
            }//end if
            //--- worked at a large distance from the freeze level - do nothing else on this tick 
            return ;
         }//end if
         
         //--- worked with the selected pending order
      }//end if order pending select
   
   }//end if orders == 1
   
   //--- OnTick() completed
}//end function

//--------------------------------------------------
//--------------------| Function From MQL4
//--------------------------------------------------

bool CheckStopLoss_Takeprofit( ENUM_ORDER_TYPE type , double SL , double TP ) {
   //--- get the SYMBOL_TRADE_STOPS_LEVEL level
   stops_level = (int)SymbolInfoInteger( _Symbol , SYMBOL_TRADE_STOPS_LEVEL ) ;
   if( stops_level != 0 ) {
      PrintFormat( "SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must" + " not be nearer than %d points from the closing price" , stops_level , stops_level ) ;
   }//end if
   //---
   bool SL_check = false , TP_check = false ;
   //--- check only two order types
   switch( type ) {
      //--- Buy operation
      case  ORDER_TYPE_BUY : {
         //--- check the StopLoss
         SL_check = ( Bid - SL > stops_level * _Point ) ;
         if( !SL_check ) PrintFormat( "For order %s StopLoss=%.5f must be less than %.5f" + " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)", EnumToString( type ) , SL , Bid - stops_level * _Point,Bid , stops_level ) ;
         //--- check the TakeProfit
         TP_check = ( TP - Bid > stops_level * _Point ) ;
         if( !TP_check ) PrintFormat( "For order %s TakeProfit=%.5f must be greater than %.5f" + " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)" , EnumToString( type ) , TP , Bid + stops_level * _Point , Bid , stops_level ) ;
         //--- return the result of checking
         return( SL_check && TP_check ) ;
      }//end case
      //--- Sell operation
      case  ORDER_TYPE_SELL : {
         //--- check the StopLoss
         SL_check = ( SL - Ask > stops_level * _Point ) ;
         if( !SL_check ) PrintFormat( "For order %s StopLoss=%.5f must be greater than %.5f " + " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)", EnumToString( type ) , SL , Ask + stops_level * _Point , Ask , stops_level ) ;
         //--- check the TakeProfit
         TP_check = ( Ask - TP > stops_level * _Point ) ;
         if( !TP_check ) PrintFormat( "For order %s TakeProfit=%.5f must be less than %.5f " + " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)", EnumToString( type ) , TP , Ask - stops_level * _Point , Ask , stops_level ) ;
         //--- return the result of checking
         return( TP_check&&SL_check ) ;
      }//end case
      break ;
   }//end switch
   //--- a slightly different function is required for pending orders
   return false ;
}//end function

//+------------------------------------------------------------------+
//| Check Money
//+------------------------------------------------------------------+
bool CheckMoneyForTrade( string symb , double lots , int type ) {
   double free_margin = AccountFreeMarginCheck( symb , type , lots ) ;
   
   //-- if there is not enough money
   if( free_margin < 0 ) {
      string oper = ( type == OP_BUY ) ? "Buy" : "Sell" ;
      Print( "Not enough money for " , oper , " " , lots , " " , symb , " Error code=" , GetLastError() ) ;
      return( false ) ;
   }//end if
   
   //--- checking successful
   return( true ) ;
}//end function

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue( double volume , string &description ) {
   //--- minimal allowed volume for trade operations
   double min_volume = SymbolInfoDouble( Symbol() , SYMBOL_VOLUME_MIN ) ;
   if( volume < min_volume ) {
      description = StringFormat( "Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f" , min_volume ) ;
      return( false ) ;
   }//end if

   //--- maximal allowed volume of trade operations
   double max_volume = SymbolInfoDouble( Symbol() , SYMBOL_VOLUME_MAX ) ;
   if( volume > max_volume ) {
      description = StringFormat( "Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f" , max_volume ) ;
      return( false ) ;
   }//end if

   //--- get minimal step of volume changing
   double volume_step = SymbolInfoDouble( Symbol() , SYMBOL_VOLUME_STEP ) ;

   int ratio = (int)MathRound( volume / volume_step ) ;
   if( MathAbs( ratio * volume_step - volume ) > 0.0000001 ) {
      description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f" , volume_step , ratio * volume_step ) ;
      return( false ) ;
   }//end if
   description = "Correct volume value" ;
   return( true ) ;
}//end function

//+------------------------------------------------------------------+
//| Check if another order can be placed                             |
//+------------------------------------------------------------------+
bool IsNewOrderAllowed() {
   //--- get the number of pending orders allowed on the account
   int max_allowed_orders = (int)AccountInfoInteger( ACCOUNT_LIMIT_ORDERS ) ;

   //--- if there is no limitation, return true; you can send an order
   if( max_allowed_orders == 0 ) return( true ) ;

   //--- if we passed to this line, then there is a limitation; find out how many orders are already placed
   int orders = OrdersTotal() ;

   //--- return the result of comparing
   return ( orders < max_allowed_orders ) ;
}//end function

//+------------------------------------------------------------------+
//| Return the current order activation price                        |
//+------------------------------------------------------------------+
double GetActivationPrice( int ticket ) {
   //---
   double activation_price = 0 ;
   //---
   if( OrderSelect( ticket , SELECT_BY_TICKET , MODE_TRADES ) ) {
      int type = OrderType() ;
      if( type == OP_BUYLIMIT || type == OP_BUYSTOP ) {           //--- orders are activated by the Ask price
         activation_price = Ask ;
      } else if( type == OP_SELLLIMIT || type == OP_SELLSTOP ) {  //--- orders are activated by the Bid price
         activation_price = Bid ;
      }//end if
   }//end if
   
   //--- price is not determined for the other orders
   return activation_price ;
}//end function

//+------------------------------------------------------------------+
//| Calculate the nearest opening price for the current moment       |
//+------------------------------------------------------------------+
double GetNearestPrice( int type , int distance ) {
   double price = 0 ;
   //--- iterate over the order types
   switch( type ) {
      case  OP_SELLSTOP  :   price = Bid - distance * _Point ;    break ;
      case  OP_BUYLIMIT  :   price = Ask - distance * _Point ;    break ;
      case  OP_SELLLIMIT :   price = Bid + distance * _Point ;    break ;
      case  OP_BUYSTOP :     price = Ask + distance * _Point ;    break ;
      default : break;
   }//end switch
   
   //--- return the received result
   return( NormalizeDouble( price , _Digits ) ) ;
}//end function

//+------------------------------------------------------------------+
//| Check the distance from opening price to activation price        |
//+------------------------------------------------------------------+
bool CheckOrderForFREEZE_LEVEL( int ticket ) {
   //--- get the SYMBOL_TRADE_FREEZE_LEVEL level
   freeze_level = (int)SymbolInfoInteger( _Symbol , SYMBOL_TRADE_FREEZE_LEVEL ) ;
   if( freeze_level != 0 ) PrintFormat( "SYMBOL_TRADE_FREEZE_LEVEL=%d: Cannot modify order" + "  nearer than %d points from the activation price",freeze_level,freeze_level ) ;
   
   //--- select order for working
   if( !OrderSelect( ticket , SELECT_BY_TICKET,MODE_TRADES ) ) {
      //--- failed to select order
      return ( false ) ;
   }//end if

   //--- get the order data
   double price   = OrderOpenPrice() ;
   double sl      = OrderStopLoss() ;
   double tp      = OrderTakeProfit() ;
   int    type    = OrderType() ;

   //--- result of checking 
   bool check = false ;

   //--- check the order type
   switch( type ) {
      //--- BuyLimit pending order
      case  OP_BUYLIMIT :  {
         //--- check the distance from the opening price to the activation price
         check = ( ( Ask - price ) > freeze_level * _Point ) ;
         if( !check ) PrintFormat( "Order OP_BUYLIMIT #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket , (int)( ( Ask - price ) /_Point ) , freeze_level ) ;
         return( check ) ;
      }//end case
      //--- BuyLimit pending order
      case  OP_SELLLIMIT : {
         //--- check the distance from the opening price to the activation price
         check = ( ( price - Bid ) > freeze_level * _Point ) ;
         if( !check ) PrintFormat( "Order OP_SELLLIMIT #%d cannot be modified: Open-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points" , ticket , (int)( ( price - Bid ) / _Point ) , freeze_level ) ;
         return( check ) ;
      }//end case
      break ;
      //--- BuyStop pending order
      case  OP_BUYSTOP : {
         //--- check the distance from the opening price to the activation price
         check = ( ( price - Ask ) > freeze_level * _Point ) ;
         if( !check ) PrintFormat( "Order OP_BUYSTOP #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points" , ticket , (int)( ( price - Ask ) / _Point ) , freeze_level ) ;
         return( check ) ;
      }//end case
      //--- SellStop pending order
      case  OP_SELLSTOP : {
         //--- check the distance from the opening price to the activation price
         check = ( ( Bid - price ) > freeze_level * _Point ) ;
         if( !check ) PrintFormat( "Order OP_SELLSTOP #%d cannot be modified: Bid-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket , (int)( ( Bid - price ) / _Point ) , freeze_level ) ;
         return( check ) ;
      }//end case
      break ;
      //--- checking opened Buy order
      case  OP_BUY : {
         //--- check TakeProfit distance to the activation price
         bool TP_check = ( tp - Bid > freeze_level * _Point ) ;
         if( !TP_check ) PrintFormat( "Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket , (int)( ( tp - Bid ) / _Point ) , freeze_level ) ;
         //--- check TakeProfit distance to the activation price
         bool SL_check = ( Bid - sl > freeze_level * _Point ) ;
         if( !SL_check ) PrintFormat( "Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket , (int)( ( Bid - sl ) / _Point ) , freeze_level ) ;
         return( SL_check && TP_check ) ;
      }//end case
      break ;
      //--- checking opened Sell order
      case  OP_SELL : {
         //--- check TakeProfit distance to the activation price
         bool TP_check = ( Ask - tp > freeze_level * _Point ) ;
         if( !TP_check ) PrintFormat( "Order OP_SELL %d cannot be modified: Ask-TakeProfit=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket , (int)( ( Ask - tp ) / _Point ) , freeze_level ) ;
         //--- check TakeProfit distance to the activation price
         bool SL_check = ( sl - Ask > freeze_level * _Point ) ;
         if( !SL_check ) PrintFormat("Order OP_BUY %d cannot be modified: TakeProfit-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points", ticket ,(int)( ( sl - Ask ) /_Point ) , freeze_level ) ;
         return ( SL_check&&TP_check ) ;
      } //end case
      break ;
   }//end switch

   //--- order did not pass the check
   return ( false ) ;
}//end function
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Return the total number of pending orders on the symbol          |
//+------------------------------------------------------------------+
int OrdersTotalPending( string sym ) {
   int orders = 0 ;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i , SELECT_BY_POS ,MODE_TRADES ) ) {
         if( OrderSymbol() == sym ) {
            if( ( OrderType() != OP_BUY ) && ( OrderType() != OP_SELL ) ) {
               orders++;
            }//end if
         }//end if
      }//end if
   }//end for
   return( orders ) ;
}//end function

//+------------------------------------------------------------------+
//| Return the ticket of a pending order by number                   |
//+------------------------------------------------------------------+
int OrderPendingSelect( int ind , string sym ) {
   int ticket = 0 , counter = 0 ;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i , SELECT_BY_POS , MODE_TRADES ) ) {
         if( OrderSymbol() == sym ) {
            if( ( OrderType() != OP_BUY ) && ( OrderType() != OP_SELL ) ) {
               if( counter == ind ) {
                  ticket = OrderTicket() ;
                  break ;
               }//end if
               counter++ ;
            }//end if
         }//end if
      }//end if
   }//end for

   return( ticket ) ;
}//end function

//+------------------------------------------------------------------+
//| Return the order type as a string                                |
//+------------------------------------------------------------------+
string GetOrderTypeString( int type ) {
   switch( type ) {
      case  OP_BUY  :      return( "OP_BUY" ) ;       break ;
      case  OP_SELL :      return( "OP_SELL" ) ;      break ;
      case  OP_BUYLIMIT :  return( "OP_BUYLIMIT" ) ;  break ;
      case  OP_SELLLIMIT : return( "OP_SELLLIMIT" ) ; break ;
      case  OP_BUYSTOP :   return( "OP_BUYSTOP" ) ;   break ;
      case  OP_SELLSTOP :  return( "OP_SELLSTOP" ) ;  break ;
   }//end switch
   //--- unknown order type
   return( "Unknown order type" ) ;
}//end function
//+------------------------------------------------------------------+
