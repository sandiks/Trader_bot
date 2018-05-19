require 'dotenv'
require_relative 'coinexchange/util'

Dotenv.load('.env')

class CoinExchBot


  def self.update_tickers

    #data = CoinExchange::Client.new.market_summaries

    tracked = CoinExchange::Util.get_wallets_curr('BTC')
    active_simul_pairs = CoinExchange::Util.get_simul_pairs

    #data.each do |tt|
    out = []

    markets_names = CoinExchange::Util.marketID_code
    mark_prices = CoinExchange::Util.get_mark_prices

    (tracked+active_simul_pairs).each do |market_id|
      sleep 0.5

      ticker = CoinExchange::Client.new.get_market_summary(market_id)
      mid =ticker['MarketID'].to_i

      asset,base= markets_names[mid]
     
      #bid,ask = ticker['BidPrice'],ticker['AskPrice']
      bid=BigDecimal.new(ticker['BidPrice'])
      ask=BigDecimal.new(ticker['AskPrice'])

      mark_price = mark_prices["#{asset}/#{base}"]
      mark_price = mark_prices[asset] unless mark_price

      #p "#{'%0.8f' % mark_price}"

      diff_bid=100
      diff_ask=100
      if mark_price && mark_price!=0
       diff_bid=bid/mark_price*100
       diff_ask=ask/mark_price*100
      end

      CoinExchange::Util.save_to_ticks(mid,bid,ask)
      mname = "#{asset}-#{base}".ljust(15,' ') 

        
      mark = ""  
      if diff_bid>120    
        play_sound
        mark = "!!! RISE "  

      elsif diff_ask<85
        play_sound
        mark = "!!! FALL "  
      end  
 
      out<< "---(#{mid}) #{mname} ask: %0.8f  bid: %0.8f  diff ask_bid [%0.1f %0.1f] #{mark}" % [ ask, bid, diff_ask, diff_bid]
    end
    p "*******CoinExchange*********"
    puts out


  end

  def self.update_simul_pairs
    simul = CoinExchange::Util.get_simul_pairs

    simul.each do |market_id|
      begin
        tt = CoinExchange::Client.new.get_market_summary(market_id)  
        next unless tt

        bid,ask=tt['BidPrice'],tt['AskPrice'] #BigDecimal.new(tt['BidPrice'])

        CoinExchange::Util.save_to_ticks(market_id,bid,ask)
      rescue =>ex
        p "#{ex.message}" 
      end
      sleep 0.5
    end
  end
  
  def self.save_all_rates
   
    ## 21-DOGE 473-XCS 574-QTUM 581-POS 138-CUBE
    data = CoinExchange::Client.new.market_summaries
    CoinExchange::Util.save_all_rates(data)

  end  

  def self.play_sound(r=1)
    if r==1
      `sudo beep -f 600 -l 600 -r 1`
    elsif r==2
      `sudo beep -f 600 -l 1000 -r 2`
    end
  end

end

#CoinExchBot.update_tickers
