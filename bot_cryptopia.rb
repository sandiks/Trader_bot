require 'dotenv'
require 'sequel'
require 'rest-client'

require_relative 'cryptopia/client'
require_relative 'cryptopia/util'

Dotenv.load('.env')


class CryptopiaBot

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

  attr_accessor :client

  def initialize
  end

  def date_now(hours=0)
     DateTime.now.new_offset(0/24.0)- hours/(24.0)
  end


  def self.play_sound(r=1)
  # `cvlc '../alarm.mp3'`
    if r==1
      `sudo beep -f 600 -l 400 -r 1`
    elsif r==2
      `sudo beep -f 600 -l 400 -r 2`
    end
  end


  def self.alarm_market
      
      wallet_pairs = Cryptopia::Util.get_wallets_curr

      pairs = Cryptopia::Util.fetch_markets_and_alarm_20_PERCENT(wallet_pairs)

      out=[]
      mnames= Cryptopia::Util.get_markets_from_db
      mark_prices = Cryptopia::Util.get_mark_prices

      pairs.each do |mid , data|

          bid,ask = data[1]
          bid1,ask1 = data[0]

          mname = mnames[mid.to_i]
          mname = mname.ljust(15,' ') if mname
          diff_bid,diff_ask = 100,100
          

          ## wallet alarm
          if wallet_pairs.include?(mid)
            curr = mname.sub('/BTC','').strip
            mark_price = mark_prices[curr]||0

            diff_bid=100
            if mark_price && mark_price!=0
             diff_bid=bid/mark_price*100
            end

            mark = ""  
            if diff_bid>110    
              play_sound
              mark = "!!! RISE BID WALLET"  
            end  
            
            if mark!=""
              out<< "-- #{mname} ASK: %0.8f BID: %0.8f diff ask_bid [%0.1f %0.1f]  #{mark}" % [ ask, bid, diff_ask, diff_bid ]
            end
          end

          if data[0]
            diff_bid=bid/bid1*100
            diff_ask=ask/ask1*100

            mark = ""  
            if diff_ask>110     
              mark = "!!! RISE ASK 110"  
              Cryptopia::Util.save_rising_pair(mid, bid, ask, diff_bid, diff_ask)

            elsif diff_bid>105    
              mark = "!!! RISE BID 105"  
              Cryptopia::Util.save_rising_pair(mid, bid, ask, diff_bid, diff_ask)

            elsif diff_ask<95
              mark = "!!! FALL ASK 95"  
              Cryptopia::Util.save_rising_pair(mid, bid, ask, diff_bid, diff_ask)

            end  
            
            if mark!=""
              out<< "-- #{mname} ASK: %0.8f BID: %0.8f diff ask_bid [%0.1f %0.1f]  #{mark}" % [ ask, bid, diff_ask, diff_bid ]
            end
          end
      end
      p "**********Cryptopia*************"
      puts out      
  end

  def self.update_tickers(need_save=false)
      
      #p Cryptopia::Util.get_markets(markets_list)

      markets_list = Cryptopia::Util.get_wallets_curr

      out=[]

      mnames= Cryptopia::Util.get_markets_from_db
      mark_prices = Cryptopia::Util.get_mark_prices
      #p mark_prices.keys.map

      markets_list.each do |market_id|

          data = Cryptopia::Util.get_market(market_id)
          bid,ask = [data['BidPrice'],data['AskPrice']]

          Cryptopia::Util.save_to_ticks(market_id, bid, ask)
          #next unless last_trade
          mname = mnames[market_id].ljust(15,' ')
          curr = mname.sub('/BTC','').strip

 
          mark_price = mark_prices[curr]||0

          #p "#{curr} last: #{'%0.8f' % mark_price}"
          diff_bid=100
          diff_ask=100
          if mark_price && mark_price!=0
           diff_bid=bid/mark_price*100
           diff_ask=ask/mark_price*100
          end

          mark = ""  
          if diff_bid>110    
            play_sound
            mark = "!!! RISE "  

          elsif diff_ask<90
            play_sound(2)
            mark = "!!! FALL "  
          end  

          out<< "-- #{mname} ASK: %0.8f BID: %0.8f diff ask_bid [%0.1f %0.1f]  #{mark}" % [ ask, bid, diff_ask, diff_bid ]
        
          sleep 0.5
      end
      p "**********Cryptopia*************"
      puts out      
  end

  def self.update_simul_pairs
    simul = Cryptopia::Util.get_simul_pairs

    simul.each do |market_id|
      begin
        tt = Cryptopia::Util.get_market(market_id)  
        next unless tt

        bid,ask=tt['BidPrice'],tt['AskPrice'] #BigDecimal.new(tt['BidPrice'])

        Cryptopia::Util.save_to_ticks(market_id,bid,ask)
      rescue =>ex
        p "#{ex.message}" 
      end
      sleep 0.5
    end
  end

  def self.alarm_all_rates
    
    Cryptopia::Util.fetch_markets_and_save_to_rates
  end  
  
  def self.save_all_rates
    
    Cryptopia::Util.fetch_markets_and_save_to_rates
  end  

end

