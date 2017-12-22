require 'sequel'
require 'rufus-scheduler'
require 'json'
require_relative 'bittrex/bittrex_api'
require_relative 'bittrex/trade_util'
require_relative 'bittrex_bot'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end

@played=false

def bittrex_api
  BittrexApi.new
end

def play_sound
  
 `cvlc '../alarm.mp3'`
end

def sell_order(pair,bid,ask)
  return if pair=="BTC-ETH"

  from = date_now(24)

  hist_orders = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and Closed > ? )", get_profile, pair, from) ).reverse_order(:Closed).all
  last_orders = find_last_hist_order_not_sold(hist_orders) 
  ord = last_orders.first

  p "--no order" unless ord
  
  if ord && ord[:PricePerUnit] && ord[:OrderType]=='LIMIT_BUY'
    
    finished = DB[:bot_trading].first(ord_uuid: ord[:OrderUuid],finished:1)
    return if finished
   
    q = ord[:Quantity]
    ppu = ord[:PricePerUnit]
    
    diff = bid/ppu*100
    factor =  DB[:my_trade_pairs].first(pid:get_profile, name:pair)[:sell_factor]

    p "[sell] #{pair.ljust(10,' ')} [factor] #{factor} [diff]#{'%7.1f' % diff} [ord_ppu] #{'%0.8f' % ppu}   [bid,ask] #{'%0.8f' % bid} #{'%0.8f' % ask}"
    
    if !@played && (diff>111 || diff< 95)
      play_sound 
      @played = true
    end
    

    uuid=nil

    if diff>=factor
          
      if !finished
        
        p "SOLD bid #{'%0.8f' % bid} diff #{'%0.8f' % diff} closed #{ord[:Closed].strftime("%F %k:%M ")}"
        #uuid = sell_curr(pair, q, bid)
        #DB[:bot_trading].insert(ord_uuid: ord[:OrderUuid], name:pair, ppu:ppu, quant:q, bought_at: ord[:Closed],  s_ppu:bid, bot_sold_at:date_now, finished:1)
        play_sound

      end

    end
  end

end

def sell_curr(mname, q, bid)
  
    res=  bittrex_api.sell(mname,q,bid)
    sleep 1
    #update_curr_balance(mname.sub('BTC-',''))  
    
    #update_curr_balance('BTC')
end 

def choice_order_and_sell(pair)
     
  bid,ask = TradeUtil.get_bid_ask(pair)
  if bid 
    sell_order(pair,bid,ask)
  end
  sleep 0.2

end

def run(pp)

  p "---start trader-bot #{pp}s "

  pair="BTC-PART"
   choice_order_and_sell(pair)

  scheduler = Rufus::Scheduler.new
 
  scheduler.every "#{pp}s" do
   
   choice_order_and_sell(pair)
  end

  scheduler.join
end

run(20)

