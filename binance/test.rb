require 'binance'

client = Binance::Client::REST.new

p client.klines symbol: 'EOSETH', interval: '1m', limit: 1