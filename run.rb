require 'rufus-scheduler'
require 'sequel'
require_relative 'bittrex/price_analz'
require_relative 'console_format'
require_relative 'bittrex/db_util'
require_relative 'bittrex/trade_util'



def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
###########

@min_prices=nil
@last_update=nil

def update_min_priced_tokens
  
  if @last_update.nil? || @last_update<date_now(0.1)
   
   @min_priced = PriceAnalz.find_tokens_min_priced_but_rising.take(8)
   
   str = @min_priced.map { |dd| dd[:name]  }
   p "priced min = #{str.join(' ')}"

   @last_update = date_now
  end
end

#update_min_priced_tokens


def run_and_trade(p1, p2)
  p "---start scheduler period: #{p1} min"
  #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))

  scheduler = Rufus::Scheduler.new

  scheduler.every "#{p1}m" do

    begin
      
      save_markets_summaries(true)
      #PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))

      p "finished #{DateTime.now.strftime("%k:%M:%S")}"

    rescue => ex
      p ex.class
    end

    #update_min_priced_tokens
  end


  scheduler.join
end


case ARGV[0]

  when "run_and_trade"; run_and_trade(ARGV[1]||5,ARGV[2]||2)
  when "rising"; PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))
  when "save"; save_markets_summaries(true) 
  when "pump"; analz_pump(180)
  when "pb"; BittrexParser.new.check_pump_from_bittrex
end

#save_markets_summaries(true)
#PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(3))
