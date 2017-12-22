require 'dotenv'
require 'sequel'

require_relative 'bitgrail_api'

Dotenv.load('.env')

def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
BTG_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')

def set_db
  BTG_DB.run("truncate table my_ticks")
  
  symbols = ["BTC-XRB"]
  
  symbols.each do |symb|
    BTG_DB[:my_ticks].insert({symb:symb})
  end
end

def save_to_ticks(symb,bid,ask)

  rr = {bid:bid, ask:ask }
  BTG_DB[:my_ticks].filter(symb:symb).update(rr)
end

def save_to_rates(symb, bid,ask)

    rr = {symb:symb, bid:bid, ask:ask, date:date_now(0)}
    BTG_DB[:hst_rates].insert(rr)
end

def show_order_book(symb="")
    symb="BTC-XRB"
    orders = get_order_book(symb)

    orders['asks'].take(10).each do |ord| 
        p "price: %0.8f  amount: %0.8f" % [ ord['price'], ord['amount'] ]
    end

end

def update_bitgrail_tickers
    
    symbols = ["BTC-XRB"]
    
    #p "---bitgrail tickers #{symbols}"
    

    symbols.each do |symb|
        tt = ticker(symb)
        bid,ask = tt["bid"], tt["ask"]

        save_to_ticks(symb, bid, ask)
        save_to_rates(symb, bid, ask)

        p "[bitgrail] #{symb} BID %0.8f  ASK %0.8f" % [bid,ask]
    end
end

#set_db
#update_bitgrail_tickers
#show_order_book