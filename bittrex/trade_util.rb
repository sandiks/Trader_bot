require 'sequel'
#require 'dotenv'
require_relative 'bittrex_api'
require_relative 'db_util'

class TradeUtil
  API_KEY = ENV["Key"]
  API_SECRET = ENV["Secret"]

  PID=2
  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')


  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end
 
  def self.show_tick(ticks)

    ticks.each do |mname|

      dd= bittrex_api.get_ticker(mname)
      save_tick_to_db(mname,dd) rescue p("#{mname}")
      sleep 0.5
      
      if dd && dd['Bid'] && dd['Ask'] && dd['Last']
        frm = mname=="USDT-BTC" ? '%0.0f' : '%0.8f'
        p "---#{mname.ljust(10)}| bid: #{frm % dd['Bid']} ask: #{frm % dd['Ask'] }"
      else
        p dd
      end
    end
  end

  def self.get_bid_ask(mname) 

    dd= bittrex_api.get_ticker(mname)

    if dd
      save_tick_to_db(mname,dd) if dd['Bid']!=0
      [dd['Bid'],dd['Ask']]
    else
      [1,1]
    end
  end

  def self.get_bid_ask_from_tick(curr) 
    mname = curr
    mname = "BTC-#{curr}" if !curr.start_with?("BTC-")
    
    dd = DB[:my_ticks].first(name:mname)
    [dd[:bid],dd[:ask]]
  end    

  def self.get_curr_balance(sym)

    dd = bittrex_api.get_currency_balance(sym)
    DB[:my_balances].where(currency:sym).delete
    DB[:my_balances].insert(dd)
    dd
  end 
  
  def self.usdt_btc ##used in ---controllers/trade.rb
    bct_rate = DB[:hst_usdt_rates].filter(name:'USDT-BTC').reverse_order(:date).limit(1).select_map(:bid)[0]
  end
  
  def self.update_curr_balance(sym)
    dd= bittrex_api.get_currency_balance(sym)
    DB[:my_balances].where(currency:sym).delete
    DB[:my_balances].insert(dd)
    dd
  end

  def self.get_last_order(mname) 
     last = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and OrderType='LIMIT_BUY')", get_profile, mname) )
     .reverse_order(:Closed).limit(1).first
  end

  def self.buy_curr(mname, q, r)
    res=  bittrex_api.buy(mname,q,r)
    update_curr_balance(mname.sub('BTC-',''))   
    #update_curr_balance('BTC')  

    res
  end 

  def self.sell_curr(mname, q, cmd)
    
    factor = DB[:my_trade_pairs].first(pid:get_profile, name:mname)[:sell_factor]
    bid,ask = TradeUtil.get_bid_ask(mname)
    
    ppu = TradeUtil.get_last_order(mname)[:PricePerUnit]
    diff = (bid/ppu*100)
    p "bid #{'%0.8f' % bid} diff #{'%0.1f' % diff }"

    if diff>= factor || cmd=="must"
      p "[SOLD] #{mname} q_#{'%0.0f' % q}"
      #res=  bittrex_api.sell(mname,q,r)
      
      #update_curr_balance(mname.sub('BTC-',''))  
      #update_curr_balance('BTC')
    else
      p "LOW_BID #{mname} q_#{'%0.0f' % q}"

    end
  end 

  def self.cancel_by_uuid(uuid)
    p res =bittrex_api.cancel(uuid)
    DB[:my_open_orders].filter(OrderUuid:uuid).delete
    res
  end

##################

  
  def self.save_market
    p "--- save_markets_summaries #{date_now(0).strftime("%F %k:%M ") }"

    save_markets_summaries(true,true)
  end

  def self.balance_table
    DB[:my_balances].filter(pid:get_profile).to_hash(:currency,:Balance)
  end  
  
  def self.usdt_btc ##used in ---controllers/trade.rb
    bct_rate = DB[:hst_usdt_rates].filter(name:'USDT-BTC').reverse_order(:date).limit(1).select_map(:bid)[0]
  end
  
  def self.pair(curr)
    config(:group)==1 ? "BTC-#{curr}" : "ETH-#{curr}"
  end

  def self.get_balance(usdt_base=0)
    usdt_base = TradeUtil.usdt_base if usdt_base==0

    balances = balance_table
    ticks = DB[:my_ticks].to_hash(:name,[:bid,:ask])

    res={}

    balances.each do |k,bal_avail|
      balance, available = bal_avail

       if k==base_crypto
        res[k]={ btc:balance, usdt:balance*usdt_base}
        next
       end
       pair = pair(k)

       bid,ask=ticks[pair]

       btc_bal = balance * bid rescue 0
       usdt_bal = btc_bal*usdt_base
       next if usdt_bal<2
       res[k]={ btc:btc_bal, usdt:usdt_bal, bid:bid, ask:ask}
    end
    res
  end  


  def self.usdt_base ##used in ---controllers/trade.rb
    mname =  config(:group) ==1 ? 'USDT-BTC' : 'USDT-ETH'
    base_rate = DB[:hst_usdt_rates].filter(name: mname).reverse_order(:date).limit(1).select_map(:bid)[0]

  end
  
  def self.find_last_hist_order_not_sold(hist_orders)
      last_indx=0
      ##find last not solded
      hist_orders.each do|ord|
        last_indx +=1 if ord[:OrderType]=='LIMIT_SELL'
        last_indx -=1 if ord[:OrderType]=='LIMIT_BUY'
        if last_indx<0
          return ord 
        end
      end  
      return nil
  end
  
end

#TradeUtil.get_balance.sort_by{|k,v| v[:usdt]}.each{ |k,v| p v}