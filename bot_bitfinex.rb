require 'dotenv'
require 'bitfinex-rb'
require_relative 'bitfinex/db'

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

def use_v2

  Bitfinex::Client.configure do |conf|
    conf.use_api_v2
  end  
end

def get_pairs
    #["tEOSETH","tBTCUSD","tETHUSD","tNEOETH","tOMGETH"]

    curr = BitfinexDB.get_wallet_curr 
    curr.delete("tETHETH")
    curr+=["tETHUSD","tBTCUSD"]
    curr
end


def update_bitfinex_tickers

    client = Bitfinex::Client.new
    #use_v2
    
    symbols_id=BitfinexDB.symb_hash
    
    symbols = get_pairs
    
    tickers = client.ticker(*symbols)
    
    out=[]
    tickers.each do |tt|

        symb=tt.shift
        v1name = symb.sub('t','')
        sid = symbols_id[v1name]

        BitfinexDB.save_tick_to_db(sid,tt)
        BitfinexDB.save_to_rates(sid,tt)

        bid=tt[0]
        last = BitfinexDB.get_last_order(v1name).first

        diff=100
        if last
          diff = bid/last[:price]*100
        end
        mname = "#{symb}(#{sid})".ljust(13,' ')

        out<< "[bitfinex] #{mname} ask %0.8f bid %0.8f    diff %0.1f" % [ tt[2], tt[0], diff ]
    end

    p "**********Bitfinex*************"
    puts out    
    p "******************************"

end

