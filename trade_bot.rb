require 'sequel'
require 'rufus-scheduler'

require_relative 'bot_bittrex'
require_relative 'bot_bitfinex'
require_relative 'bot_bitgrail'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

def run(p1)

  fast, middle, slow = 5,120,6  

  puts "---start trader-bot 
  save_markets_summaries [#{slow}m]  
  update_bittrex_tickers [#{fast}s] 
  update_simulator_tickers [#{middle}s]"

  #update_bittrex_tickers rescue 0
  #update_bitfinex_tickers rescue 0
  #update_bitgrail_tickers rescue 0
  #save_markets_summaries(true)
  #check_and_sell_orders

  counter=0
  scheduler = Rufus::Scheduler.new
  bot = BGBot.new      
  bot.update_bitgrail_tickers 
  
  scheduler.every "#{fast}s" do
      
      #update_bittrex_tickers
      bot.update_bitgrail_tickers 
      
      counter+=1 
     p "---------#{counter}"
  end 

  scheduler.every "#{middle}s" do
      
      update_bitfinex_tickers
      
      #update_simulator_tickers rescue 0
      #check_and_sell_orders
  end 


  scheduler.every "#{slow}m" do
    
    save_markets_summaries(true)
    
    #update_bitfinex_tickers
    
    #update_bitgrail_tickers rescue 0

    p "--finish slow updater #{DateTime.now.strftime("%k:%M:%S")}"

    #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))

    #update_min_priced_tokens
  end


  scheduler.join
end

run(6)