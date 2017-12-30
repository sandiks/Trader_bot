require 'sequel'

class BitfinexDB

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')
  PID=2

  def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end

  def self.symb_hash
    DB[:symbols].to_hash(:name, :symbol_id)
  end

  def self.base_curr
     "ETH"
  end
  
  def self.get_all_bid_ask
    DB[:my_ticks].to_hash(:symb,[:BID,:ASK])
  end

  def self.save_tick_to_db(symb_id, tt)

    DB[:my_ticks].filter(symb:symb_id).delete

    rr = {symb:symb_id, BID:tt[0],BID_SIZE:tt[1],ASK:tt[2],ASK_SIZE:tt[3],DAILY_CHANGE:tt[4], time:date_now(0)}
    DB[:my_ticks].insert(rr)
  end

  def self.save_to_rates(symb_id, tt)
    rr = {symb:symb_id, bid:tt[0],ask:tt[2], date:date_now(0)}
    DB[:hst_rates].insert(rr)
  end

  def self.save_trades(symb,data) #need show open orders
    
    DB.transaction do

      exist=DB[:trades].filter(symb:1).select_map(:tid)

      data.each do |tr|
        if !exist.include?(tr[0])
          DB[:trades].insert({symb:1, tid:tr[0], time: Time.at(tr[1]/1000), amount:tr[2], ppu:tr[3]})
        end
      end

    end

  end

  def self.save_wallet(wallet) #need show open orders
    DB[:wallets].delete
    wallet.each do |ww|
      DB[:wallets].insert({pid:2, type:ww[0],currency:ww[1], balance:ww[2], available:ww[4] })
    end
  end   



  def self.get_balance

    data = DB[:wallets].filter(pid:2).all   
    
    rates = BitfinexDB.get_all_bid_ask 
    symbols=BitfinexDB.symb_hash
    usd_bid = rates[symbols["#{base_curr}USD"]][0]

    res=[]     
    data.each do |dd|

      curr=dd[:currency].upcase
      
      balance=dd[:balance]
      bid=ask=1
      if curr!=base_curr
        sid = symbols["#{curr}#{base_curr}"]
        bid,ask =rates[sid] 
      end
      usd_bal = balance*bid*usd_bid rescue 0
      #p " curr #{curr} bal #{balance} usd_bid #{usd_bid} bid #{bid}"
      res<<{currency:curr,bid:bid,ask:ask,balance:balance,usd_balance:usd_bal}
    end
    res
  end    
end