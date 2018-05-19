require 'binance'
require_relative 'binance/util'



class BinanceBot

  
  def self.update_tickers

    client = Binance::Client::REST.new
    out = []
    
    tracked = Binance::Util.get_wallets_curr
    p "*******Binance*********"
    
    mark_prices = Binance::Util.get_mark_prices
    
    tracked.each do |symbol|

      tt = client.book_ticker(symbol:symbol)
      bid=BigDecimal.new(tt['bidPrice'])
      ask=BigDecimal.new(tt['askPrice'])

      Binance::Util.save_to_ticks(symbol, bid, ask)

      diff_ask, diff_bid = 100,100

      mark=''
      curr = symbol.sub('BTC','').strip
      mark_price = mark_prices[curr]||0

      if mark_price && mark_price!=0
       diff_bid=bid/mark_price*100
       diff_ask=ask/mark_price*100
      end

      if diff_bid>106  
        play_sound
        mark = "!!! RISE "  

      elsif diff_ask<97
        play_sound(2)
        mark = "!!! FALL "  
      end  

      p "--- #{symbol} ask: %0.8f  bid: %0.8f  diff ask_bid [%0.1f %0.1f] #{mark}" % [ ask, bid, diff_ask, diff_bid]
    end

  end

  def self.save_all_rates
     Binance::Util.save_all_rates
  end  
 
   def self.play_sound(r=1)
     if r==1
       `sudo beep -f 600 -l 600 -r 1`
     elsif r==2
       `sudo beep -f 600 -l 1000 -r 2`
     end
   end

end

#BinanceBot.update_tickers
