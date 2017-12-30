require 'sequel'
require_relative 'bittrex/db_util'
require_relative 'bittrex/trade_util'

def date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end


def buy(mname,ppu,q,ask) 
    if q>0 && ppu>=ask 
      TradeUtil.buy_curr(mname, q, ask) 
      p "---!!! buy q: #{q} ppu: #{'%0.8f' % ask} price: #{'%0.8f' % q*ask}"
      return true
    end
    false
end


def find_last_hist_order_not_sold(hist_orders)
    
    last_indx=0
    orders=[]
    ##find last not solded
    hist_orders.each do|ord|
      
      last_indx +=1 if ord[:OrderType]=='LIMIT_SELL'
      if last_indx==0
        orders<<ord 
      end
      last_indx -=1 if ord[:OrderType]=='LIMIT_BUY' && last_indx>0 
      
      #p "order #{ord[:OrderType]} last_indx #{last_indx}"
    end  
    
    orders
end

@played=false

def play_sound
 # `cvlc '../alarm.mp3'`
 `sudo beep -f 600 -l 1000 -r 2`
end

def find_last_order(pair)
  from = date_now(72)

  hist_orders = DB[:my_hst_orders].filter( Sequel.lit("(pid=? and Exchange=? and Closed > ? )", get_profile, pair, from) ).reverse_order(:Closed).all
  last_orders = find_last_hist_order_not_sold(hist_orders) 
  ord = last_orders.first
  unless ord
    ord = hist_orders.select{|ord| ord[:OrderType]=='LIMIT_BUY'}.first
  end
  ord  
end

def sell_order(pair,bid,ask)
  return if pair=="BTC-ETH"
  
  ord = find_last_order(pair)
  p "no order #{pair}" unless ord

  if ord && ord[:PricePerUnit] && ord[:OrderType]=='LIMIT_BUY'
    
    finished = DB[:bot_trading].first(ord_uuid: ord[:OrderUuid],finished:1)
    #return if finished
   
    q = ord[:Quantity]
    ppu = ord[:PricePerUnit]
    
    factor =  DB[:my_trade_pairs].first(pid:get_profile, name:pair)[:sell_factor] 
    #center_price =  DB[:my_trade_pairs].first(pid:get_profile, name:pair)[:center_price]||0
    #diff = bid/center_price*100
    
    diff = bid/ppu*100
    ask_bid_diff = ask/bid*100

    p "[sell] #{pair.ljust(10,' ')} [factor,diff] #{factor} #{'%7.1f' % diff}  [bid, ask, diff] #{'%0.8f' % bid} #{'%0.8f' % ask} #{'%7.1f' % ask_bid_diff}"
    
    if (diff< 98 && ask_bid_diff<100.5) || diff>factor 
      play_sound 
    end
    
    uuid=nil
    if false && diff>factor

      #play_sound unless @played
      #@played = true
      
      #uuid=TradeUtil.sell_curr(pair, q, bid)
      if !finished
        p "SOLD bid #{'%0.8f' % bid} diff #{'%0.8f' % diff} closed #{ord[:Closed].strftime("%F %k:%M ")}"
        DB[:bot_trading].insert(ord_uuid: ord[:OrderUuid], name:pair, ppu:ppu, quant:q, bought_at: ord[:Closed],  s_ppu:bid, bot_sold_at:date_now, finished:1)
      end
    end

  end

end

def choice_order_and_sell(pairs)
    pairs.each do |pair|
      #next if pair!='DNT'
     
        if pair!="BTC"

          pair="BTC-#{pair}" if !pair.start_with?("BTC-") 
          bid,ask = TradeUtil.get_bid_ask_from_tick(pair)
          if bid 
            sell_order(pair,bid,ask)
          end
          sleep 0.3
        end
    end
end

def check_and_sell_orders
      balance_pairs = TradeUtil.get_balance.sort_by{|k,v| v[:usdt]}.map { |k,v| k   }
      choice_order_and_sell(balance_pairs)  
end

def update_bittrex_tickers
      balance_currs = TradeUtil.get_balance.keys
      balance_currs.each do |curr|
        #next if curr!='DNT'
          if curr==base_crypto
            TradeUtil.get_bid_ask(base_pair('USDT'))
          else
            curr=base_pair(curr) if !curr.start_with?(base_crypto) 
            bid,ask = TradeUtil.get_bid_ask(curr)            
            p "(tick) #{curr.ljust(14,' ')} #{'%0.8f ' % bid} #{'%0.8f ' % ask}"
            sleep 0.05
          end
      end      
      #choice_order_and_sell(balance_pairs)  
end

def update_simulator_tickers_without_balance(exclude_pairs)

    simul_curr =  DB[:simul_trades].filter(pid:get_profile).all
    simul_curr.each do |curr|
      pair = curr[:pair]
      next if exclude_pairs.include?(pair.sub('BTC-',''))

      bid,ask = TradeUtil.get_bid_ask(pair) 
      p "[simulator tick] #{pair.ljust(12,' ')} bid #{'%0.8f' % (bid||0)} ask #{'%0.8f' % (ask||0)}"
      sleep 0.2
    end

end

def update_simulator_tickers
      balance_pairs = TradeUtil.get_balance.sort_by{|k,v| v[:usdt]}.map { |k,v| k   }
      update_simulator_tickers_without_balance(balance_pairs)
end
