require 'sequel'
require 'rufus-scheduler'

#require_relative 'bot_bitfinex'
require_relative 'bot_bittrex'
#require_relative 'bot_bitgrail'
require_relative 'bot_cryptopia'
require_relative 'bot_coinexch'
require_relative 'bot_binance'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end


def run(p1)

  fast, middle, slow = 30,1,5 

  puts "---start trader-bot fast [#{fast}s] middle [#{middle}m] slow [#{slow}m]"

  counter=0
  need_simul = true

  scheduler = Rufus::Scheduler.new
 # bot = BGBot.new      

  #Cryptopia::Util.save_markets #alarm_market

  #BinanceBot.update_tickers
      CryptopiaBot.alarm_market

#  CoinExchBot.update_tickers
  #begin; CryptopiaBot.update_tickers; rescue =>ex; p ex.class; end  
  #begin bot.update_bitgrail_tickers; rescue =>ex; p ex.message; end

  scheduler.every "#{fast}s" do
      
      #update_bittrex_tickers
      period = 120/fast
      need_save = (counter % period ==0)

      #CoinExchBot.update_tickers
      #CryptopiaBot.update_tickers
      #BinanceBot.update_tickers

      CryptopiaBot.alarm_market

      counter+=1 
      #p "---------#{counter}"
  end 

  scheduler.every "#{middle}m" do

      
      #bot.update_bitgrail_tickers rescue 0
      #update_bitfinex_tickers
      #BinanceBot.save_all_rates rescue 0
      
      CoinExchBot.update_tickers

      if need_simul
        
        #CoinExchBot.update_simul_pairs
        #CryptopiaBot.update_simul_pairs
        
        #BittrexBot.new.update_simulator_tickers rescue 0
      end
  end 

  scheduler.every "#{slow}m" do
    
    #save_markets_summaries(true) rescue 0

    #update_bitfinex_tickers

    #CoinExchBot.save_all_rates rescue 0

    #CryptopiaBot.save_all_rates rescue 0
    
    #BinanceBot.save_all_rates rescue 0

    
    p "--finish slow updater #{DateTime.now.strftime("%k:%M:%S")}"

    #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))
  end


  scheduler.join
end

run(6)