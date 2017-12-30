require 'dotenv'
require 'bitfinex-rb'
require_relative 'bitfinex/db_util'

Dotenv.load('.env')

BASE_URL = "https://api.bitfinex.com/v2/"
API_KEY = ENV["BF_API_KEY"]
API_SECRET = ENV["BF_SECRET"]


Bitfinex::Client.configure do |conf|
  conf.secret = API_SECRET
  conf.api_key = API_KEY
  conf.use_api_v2
end

def base_curr
 "ETH"
end

def get_pairs
    #["tEOSETH","tBTCUSD","tETHUSD","tNEOETH","tOMGETH"]

    curr=BitfinexDB.get_balance.map do |dd| 
      curr=dd[:currency]
      if curr==base_curr
        "t#{base_curr}USD"
      else
        "t#{curr}#{base_curr}"
      end
    end
    curr<<"tBTCUSD"
    curr
end


def update_bitfinex_tickers

    client = Bitfinex::Client.new

    symbols_id=BitfinexDB.symb_hash
    
    #symbols = ["tEOSETH","tBTCUSD","tETHUSD","tNEOBTC","tLTCBTC"]
    symbols = get_pairs
    
    #p "---bitfinex tickers #{symbols}"
    dd = client.ticker(*symbols)

    dd.each do |tt|

        symb=tt.shift
        sid = symbols_id[symb.sub('t','')]
        BitfinexDB.save_tick_to_db(sid,tt)
        BitfinexDB.save_to_rates(sid,tt)

        p "[bitfinex] #{symb}(#{sid}) bid %0.8f  ask %0.8f" % [tt[0], tt[2]]
    end
end

def get_wallet

client = Bitfinex::Client.new
p ww = client.wallets
BitfinexDB.save_wallet(ww)

end
