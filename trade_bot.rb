require 'sequel'
require 'rufus-scheduler'

require_relative 'bot_bittrex'
require_relative 'bot_bitfinex'
require_relative 'bot_bitgrail'
require_relative 'bot_cryptopia'
require_relative 'bot_coinexch'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end


def run(p1)

  fast, middle, slow = 90,120,6  

  puts "---start trader-bot fast [#{fast}s] middle [#{middle}s] slow [#{slow}m]"

  #update_bittrex_tickers rescue 0
  #update_bitfinex_tickers rescue 0
  #update_bitgrail_tickers rescue 0
  #save_markets_summaries(true)
  #check_and_sell_orders
  #CRPBot.update_cryptopia_tickers([5141]) ##CTF/BTC

  counter=0
  scheduler = Rufus::Scheduler.new
  bot = BGBot.new      
  #bot.update_bitgrail_tickers 
  
  scheduler.every "#{fast}s" do
      
      #update_bittrex_tickers
      period = 120/fast
      p need_save = (counter % period ==0)
      begin 
        bot.update_bitgrail_tickers(need_save) 

      
      rescue => ex
        p ex.class
      end

      counter+=1 
     p "---------#{counter}"
  end 

  scheduler.every "#{middle}s" do
      
      CoinExchBot.update_coinexchange_tickers
      CRPBot.update_cryptopia_tickers([5141]) ##CTF/BTC
      
      update_bitfinex_tickers
      
      #update_simulator_tickers rescue 0
      #check_and_sell_orders
  end 


  scheduler.every "#{slow}m" do
    
    save_markets_summaries(true)
    CoinExchBot.save_coinexchange_rates
    
    #update_bitfinex_tickers
    
    #update_bitgrail_tickers rescue 0

    p "--finish slow updater #{DateTime.now.strftime("%k:%M:%S")}"

    #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))

    #update_min_priced_tokens
  end


  scheduler.join
end

run(6)