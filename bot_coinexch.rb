require 'dotenv'
require 'bitfinex-rb'
require_relative 'coinexchange/util'

Dotenv.load('.env')


class CoinExchBot


  def self.update_coinexchange_tickers

    #data = CoinExchange::Client.new.market_summaries
   
    ## 21-DOGE 473-XCS 574-QTUM 581-POS 138-CUBE

    tracked = [473,138]
   
    #data.each do |tt|
    out = []
    markets_names = CoinExchange::Util.get_markets

    tracked.each do |market_id|

      tt = CoinExchange::Client.new.get_market_summary(market_id)

      mid =tt['MarketID'].to_i
      mname= markets_names[mid]
     
      #bid,ask = tt['BidPrice'],tt['AskPrice']
      bid=BigDecimal.new(tt['BidPrice'])
      ask=BigDecimal.new(tt['AskPrice'])

      CoinExchange::Util.save_to_rates(mid,bid,ask) 

      out<< "[coinexchange] #{mname}-BTC  ask: %0.8f  bid: %0.8f  diff %0.1f" % [ ask, bid, 0]

      need_sound = ( ask<0.00000200 || bid>0.00000330) 
        
      if  need_sound
        play_sound 
      end

    end
    p "*******CoinExchange*********"
    puts out


  end

  def self.save_coinexchange_rates
   
    ## 21-DOGE 473-XCS 574-QTUM 581-POS 138-CUBE
    data = CoinExchange::Client.new.market_summaries
    CoinExchange::Util.save_all_rates(data)

  end  

  def self.play_sound(r=1)
    if r==1
      `sudo beep -f 600 -l 1000 -r 1`
    elsif r==2
      `sudo beep -f 600 -l 1000 -r 2`
    end
  end

end

