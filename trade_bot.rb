require 'sequel'
require 'rufus-scheduler'

require_relative 'bittrex_bot'
require_relative 'bitfinex/bot_bitfinex'
require_relative 'bitgrail/bot_bitgrail'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

def run(p1)

  bittrex_ticker, bitfinex_ticker, save_market_ticker = 15,20,p1  

  puts "---start trader-bot 
  save_markets_summaries p1:#{p1}  
  update_bittrex_tickers 15s 
  update_simulator_tickers 60s"

  update_bittrex_tickers rescue 0
  update_bitfinex_tickers rescue 0
  update_bitgrail_tickers rescue 0


  counter=0
  scheduler = Rufus::Scheduler.new

  scheduler.every "#{bittrex_ticker}s" do
      
      update_bittrex_tickers
      counter+=1 
     p "---------#{counter}"
  end

  scheduler.every "#{bitfinex_ticker}s" do
      
      update_simulator_tickers rescue 0
      
      ##bitfinex
      update_bitfinex_tickers rescue 0

      ##bitgrail
      update_bitgrail_tickers rescue 0
      #check_and_sell_orders
  end 


  scheduler.every "#{save_market_ticker}m" do
    save_markets_summaries(true)
    p "--save_markets_summaries #{DateTime.now.strftime("%k:%M:%S")}"

    #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))

    #update_min_priced_tokens
  end


  scheduler.join
end

run(6)