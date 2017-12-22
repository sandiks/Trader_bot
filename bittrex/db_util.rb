require 'sequel'
require_relative 'bittrex_api'

DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')
PID=2

def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end


def save_tick_to_db(mname,dd)
  #return if mname.start_with?("USDT-")
  #DB[:my_ticks].filter(name:mname).delete
  rr = {last:dd['Last'], bid:dd['Bid'], ask:dd["Ask"] }
  DB[:my_ticks].filter(name:mname).update(rr)
end

def config(key)
  case key
    when :simulate; DB[:config].first(name:'trade_type')[:value]=='simulate'
    when :real; DB[:config].first(name:'trade_type')[:value]=='real'
    when :group; DB[:config].first(name:'group')[:value].to_i
  end
end

def get_trading_mode
  type = DB[:config].first(name:'trade_type')[:value]
end 

def get_profile
  type = DB[:config].first(name:'trade_type')[:value]
  type=='simulate' ? 1 : 2
end 

def base_crypto
  config(:group) ==1 ? "BTC" : "ETH"
end

def base_pair(curr='')
  config(:group) ==1 ? "BTC-#{curr}" : "ETH-#{curr}"
end


def save_markets_summaries(reload_market=true)
  
  data = BittrexApi.new.get_markets_summaries(true) ## is direct?

  DB.run("truncate table markets") if reload_market

  DB.transaction do

    data.each do |dd|
      # "#{dd["MarketName"]} vol: #{dd["BaseVolume"]} time_stamp: #{dd["TimeStamp"]}" }
      item = {
        name: dd["MarketName"],
        High: dd["High"],
        Low: dd["Low"],
        Volume: dd["Volume"],
        Last: dd["Last"],
        BaseVolume: dd["BaseVolume"],
        TimeStamp: dd["TimeStamp"],
        Bid: dd["Bid"],
        Ask: dd["Ask"],
        OpenBuyOrders: dd["OpenBuyOrders"],
        OpenSellOrders: dd["OpenSellOrders"],
        PrevDay: dd["PrevDay"],
        Created: dd["Created"]
      }
      DB[:markets].insert(item) if reload_market
    end
    ##save to rates
    data.each{ |dd|
      mname = dd["MarketName"]

      rr = {name:mname, bid:dd["Bid"], ask:dd["Ask"], date:date_now(0) }
      save_tick_to_db(mname, dd)
      DB[:hst_btc_rates].insert(rr) if mname.start_with?("BTC-")
      DB[:hst_eth_rates].insert(rr) if mname.start_with?("ETH-")
      DB[:hst_usdt_rates].insert(rr) if mname.start_with?("USDT-")
    }

  end
end

def save_log(type, text)
  DB[:bot_logs].insert({type:type, info:text, date: now})
end

def copy_market_to_profile
  all = DB[:markets].filter(Sequel.like(:name, 'BTC-%')).select_map(:name)
  all<<"USDT-BTC"
  DB.transaction do
    exist = DB[:tprofiles].filter(uid:PID).select_map(:name)
    
    all.each do |mm|
      
      if !exist.include?(mm)
       DB[:tprofiles].insert({uid:PID, name:mm, group:1, enabled:1}) 
       p "--insert #{mm}"
      end
    end
  end
end

def copy_market_to_market_ids
  market_names = DB[:markets].filter(Sequel.like(:name, 'BTC-%')).order(:Created).select_map([:name, :Created])

  DB.transaction do
    exist = DB[:market_ids].select_map(:name)
    indx=0
    market_names.each do |mname,created|

      if !exist.include?(mname)
       indx+=1
       DB[:market_ids].insert({id: indx, name:mname, created: created}) 
       p "--insert #{mname}"
      end

    end
  end
end


def fill_tick_table_by_markets_tokens
  p "---fill_tick_table_by_markets_tokens"
  market_names = DB[:markets].filter(Sequel.like(:name, 'BTC-%')).select_map(:name)
  market_names<<"USDT-BTC"
  
  DB.transaction do

    exist = DB[:my_ticks].select_map(:name)
    
    market_names.each do |mname|
      
      if !exist.include?(mname)
       DB[:my_ticks].insert({name:mname}) 
      end
    end
  end
end

#fill_tick_table_by_markets_tokens

def track_market(sym,enb="+")
  enb_= enb=="+" ? 1:0
  DB[:tprofiles].filter(pid:PID, name:"BTC-#{sym}").update(check:enb_)
end

def del_rates
  from = date_now(7*24)
  p DB[:hst_btc_rates].filter(Sequel.lit("date < ?", from)).delete
end

def config(key)
  case key
    when :simulate; DB[:config].first(name:'trade_type')[:value]=='simulate'
    when :real; DB[:config].first(name:'trade_type')[:value]=='real'
    when :group; DB[:config].first(name:'group')[:value].to_i
  end
end

def base_crypto
  config(:group) ==1 ? "BTC" : "ETH"
end

def copy_to_bot_trading
  pairs = TradeUtil.get_balance.select{|k,v| v[:usdt]>5 }.map { |k,v| "BTC-#{k}"  }
  
  
  DB.transaction do
   
    pairs.each do |mname|
      p "--- PROCESS #{mname} profile #{get_profile}"

      ord = DB[:my_hst_orders].filter(pid:get_profile, Exchange:mname).reverse_order(:Closed).first
  
      if ord && ord[:OrderType]=='LIMIT_BUY'
  
        uuid=ord[:OrderUuid]

        unless DB[:bot_trading].first(ord_uuid:uuid)
          p "--- INSERT #{uuid} q: #{ord[:Quantity]}"
          
          rr = {ord_uuid:ord[:OrderUuid], name:mname, quant: ord[:Quantity],ppu:ord[:Limit], bought_at:ord[:Closed]}
          DB[:bot_trading].insert(rr)

        end
      end
  
    end
  
  end
end
