require 'dotenv'
require 'sequel'
require 'rest-client'

require_relative 'bitgrail/client'
require_relative 'bitgrail/bg_util'

Dotenv.load('.env')


class BGBot

  BTG_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

  attr_accessor :client

  def initialize
    auth = {key:ENV["BG_KEY"], secret:ENV["BG_SECRET"] }
    @client = BG::Client.new(auth) 
  end

  def date_now(hours=0)
     DateTime.now.new_offset(0/24.0)- hours/(24.0)
  end
  

  def show_order_book(symb="")
      symb="BTC-CFT"
      orders = get_order_book(symb)

      orders['asks'].take(10).each do |ord| 
          p "price: %0.8f  amount: %0.8f" % [ ord['price'], ord['amount'] ]
      end

  end

  def play_sound(r=1)
  # `cvlc '../alarm.mp3'`
    if r==1
      `sudo beep -f 600 -l 1000 -r 1`
    elsif r==2
      `sudo beep -f 600 -l 1000 -r 2`
    end
  end

  def find_last_hist_order_not_sold(hist_orders)
    
    amount=0
    orders=[]

    hist_orders.each do|ord|
    
      amount -=ord[:amount] if ord[:type]=='sell'
      if amount>0
        orders<<ord 
      end
      amount += ord[:amount] if ord[:type]=='buy' 
    end  
    
    if orders.size==0
      hist_orders.first
    else
      orders.first
    end
  end

  def update_bitgrail_tickers(need_save=false)
      
      symbols = ["BTC-CFT", "BTC-XRB", "BTC-DOGE"]
      #symbols = ["BTC-CFT"]
      #symbols = ["BTC-XRB"]
      
      #p "---bitgrail tickers #{symbols}"
      out = []

      symbols.each do |symb|

          tt = ticker(symb)
          bid,ask = tt["bid"], tt["ask"]
          bid=BigDecimal.new(bid)
          ask=BigDecimal.new(ask)

          last_trades=BTG_DB[:hst_trades].filter(market:symb).reverse_order(:date).limit(4).all
          last_trade = find_last_hist_order_not_sold(last_trades)
          

          BG::Util.save_to_ticks(symb, bid, ask)
          BG::Util.save_to_rates(symb, bid, ask) if need_save
          #next unless last_trade

          diff_bid=100
          diff_ask=100
          tid=0

          if last_trade
            diff_bid = bid/last_trade[:price]*100 
            diff_ask = ask/last_trade[:price]*100 
            tid=last_trade[:tid]
          end

          out<< "--- #{symb.ljust(10,' ')} ASK %0.8f  BID %0.8f diff [%0.1f %0.1f] trade:#{tid}" % [ ask, bid, diff_bid, diff_ask]
          

          need_sound =  false#( symb=="BTC-DOGE" && (ask<0.00000062 || bid>=0.00000090) )  
          
          if  need_sound
            play_sound 
            #p "--sell order #{symb}"
            #sell_order(symb,last_trade[:amount],bid)
            #sleep 1
            #last_trades
          end

          sleep(1)
      end
      p "**********BitGrail*************"
      puts out

  end

  #p form_data = URI.encode_www_form({KEY: auth[:key], nonce: Time.now.to_i * 1000 })
  def ticker(symb)
    @client.get("#{symb}/ticker")
  end
  
  def buy_order(mname, amount, price)
    data = {market:mname, amount: amount, price: price}
    @client.post('buyorder',data)
  end    

  def sell_order(mname,amount,price)
    data = {market:mname, amount: amount, price: price}
    @client.post('sellorder',data)
  end    
 

  def balance
    balance = @client.post('balances')
    BTG_DB.run("truncate table balances")  
    balance.each do |bb|
      BTG_DB[:balances].insert( bb[1].merge({curr: bb[0]}) )      
    end
  end

  def last_trades
    BTG_DB.transaction do
      
      #BTG_DB.run("truncate table hst_trades") 
      exist=BTG_DB[:hst_trades].select_map(:tid)
      
      trades =  @client.post('lasttrades') 
      trades.each do |tr|
        
        if !exist.include?(tr[0].to_i)
          tr[1]['date'] = Time.at(tr[1]['date'].to_i)  
          BTG_DB[:hst_trades].insert( tr[1].merge({tid: tr[0]}) )
        end        
      end

    end
  end

end

def test
  bot = BGBot.new
  bot.update_bitgrail_tickers
  curr="BTC-XRB"
  quant=2

  ask= BG::Util.get_all_bid_ask[curr][1]
  ask = 0.00115995
  
  p '%0.8f' % ask
  
  #p bot.buy_order(curr, '%0.8f' % quant, '%0.8f' % ask)
  #p bot.sell_order(curr, '%0.8f' % quant, '%0.8f' % ask)
  
  # bot.last_trades
  # sleep 1;  p bot.balance
  #p bot.ticker("BTC-XRB")
  #p bot.client.post('depositshistory',{coin:'ETH'})

end
