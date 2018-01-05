require 'dotenv'
require 'bitfinex-rb'
require 'rufus-scheduler'

require_relative 'db'
Dotenv.load('../.env')

module Bitfinex
  
  class BFClient

      API_KEY = ENV["BF_API_KEY"]
      API_SECRET = ENV["BF_SECRET"]


    Bitfinex::Client.configure do |conf|
        conf.secret = API_SECRET
        conf.api_key = API_KEY
        #conf.use_api_v2
    end

    def self.load_wallet
      client = Bitfinex::Client.new
      ww=client.balances
      BitfinexDB.save_wallet(ww)
    end

    def self.buy_pair(pair,q,r)
      client = Bitfinex::Client.new
      pp =pair.sub('t','')
      client.new_order(pair, q, "market", "buy", r)
    end

    def self.sell_pair(pair,q,r)
      client = Bitfinex::Client.new
      pp =pair.sub('t','')
      client.new_order(pair, q, "market", "sell", r)
    end

    def self.history_trades(pair)

      client = Bitfinex::Client.new
      pp =pair.sub('t','')
      trades = client.mytrades(pair)
      BitfinexDB.save_mytrades(trades)
    end

  end

end
