require 'dotenv'
require 'sequel'
require 'rest-client'

require_relative 'cryptopia/client'
require_relative 'cryptopia/util'

Dotenv.load('.env')


class CRPBot

  BTG_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

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


  def self.update_cryptopia_tickers(markets,need_save=false)
      
      #"CFT/BTC" 5141
      
      #p "---bitgrail tickers #{symbols}"
      
      out=[]
      mnames= [[5141,"CFT/BTC"]].to_h

      markets.each do |symb|
          data = Cryptopia::Util.get_market(symb)
          bid,ask = [data['BidPrice'],data['AskPrice']]

          Cryptopia::Util.save_to_ticks(symb, bid, ask)
          #next unless last_trade

          out<< "-- #{mnames[symb]}  BID: %0.8f  ASK: %0.8f" % [bid,ask]
          diff = bid/0.00000700*100

          if diff<85
            #play_sound(1)
          end

          if  diff>120
            play_sound(1) 
            p "--sell order #{symb}"
            #sell_order(symb,last_trade[:amount],bid)
            #sleep 1
            #last_trades
          end

          sleep(1)
      end
      p "**********Cryptopia*************"
      puts out      
  end

end

#CRPBot.update_cryptopia_tickers([5141])