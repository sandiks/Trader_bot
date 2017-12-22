require "rest-client"
require "json"
require 'dotenv'
require_relative 'db_util'


Dotenv.load('.env')

BASE_URL = "https://api.bitfinex.com/v2"
API_KEY = ENV["Key"]
API_SECRET = ENV["Secret"]

def call_api(url)
  response = RestClient.get(url)
  parsed_body = JSON.parse(response.body)
  puts "Fetching ..."
  parsed_body
end
#tETHUSD tBTCUSD tEOSETH

def get_order_book
  url = "#{BASE_URL}/trades/tETHUSD/hist"
  orders = call_api(url)
  orders.map { |rr| p rr   }
end

SYMB={'tEOSETH':1}

def ticker(symb)
  url = "#{BASE_URL}/ticker/#{symb}"
  p tt = call_api(url)
end

def trades(symb)
  url = "#{BASE_URL}/trades/#{symb}/hist"
  trades = call_api(url)
end

def candles(sym)
  url = "#{BASE_URL}/candles/trade:1m:#{sym}/hist"
  data = call_api(url)
  p data.map{|d| Time.at(d[0]/1000).strftime("%F %k:%M")}

end

#save_trades('tEOSETH', trades('tEOSETH') )

ticker('tEOSETH')
