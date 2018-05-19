require_relative 'client'
require_relative 'db'

def update_balance
  
  p Bitfinex::BFClient.load_wallet
  
  curr_ = BitfinexDB.get_wallet_curr 
  curr_.each do |curr|
    p pair =curr.sub('t','')
    Bitfinex::BFClient.history_trades(pair) if pair!="ETHETH"
    
  end

end
update_balance
