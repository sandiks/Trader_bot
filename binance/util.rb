require 'sequel'
#require_relative 'client'
require 'binance'


module Binance

  class Util

    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'binance', user: 'root')
    PID=2

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end
    
    def self.get_all_bid_ask
      DB[:my_ticks].where{bid>0}.to_hash(:name,[:bid,:ask])
    end
    
    def self.save_to_ticks(symbol, bid, ask)
      rr = { bid: bid, ask: ask }
      DB[:my_ticks].filter(name: symbol).update(rr)
    end

    def self.save_to_rates(symbol, bid, ask)
      rr = {name:symbol, bid:bid, ask:ask, date:date_now(0)}
      DB[:hst_rates].insert(rr)
    end

    def self.save_markets(data) #need show open orders 
      client = Binance::Client::REST.new
      data = client.exchange_info['symbols']
 
      DB.transaction do
        exist=DB[:markets].select_map(:symbol)
        data.each do |dd|
          if !exist.include?(dd['symbol'])
              rr = { 
                  symbol: dd['symbol'],
                  status: dd['status'],
                  baseAsset: dd['baseAsset'],
                  baseAssetPrecision: dd['baseAssetPrecision'],
                  quoteAsset: dd['quoteAsset'],
                  quotePrecision: dd['quotePrecision'],
                  orderTypes: dd['orderTypes'].join(','),
                  icebergAllowed: dd['icebergAllowed'],
              }
            DB[:markets].insert(rr)
          end
        end
      end

    end

    def self.get_markets #need show open orders  
      DB[:markets].all
    end

    def self.get_mark_prices  
      DB[:wallets].to_hash(:currency,:last_price)
    end
    
    def self.save_all_rates
    
      client = Binance::Client::REST.new

      data = client.all_book_tickers
      DB.transaction do
        data.each do |tt|
          rr = {name:tt['symbol'], bid:tt['bidPrice'], ask:tt['askPrice'], date:date_now(0)}
          DB[:hst_rates].insert(rr)
          
          rr = { bid: rr[:bid], ask: rr[:ask] }
          DB[:my_ticks].filter(name: tt['symbol']).update(rr)
        end
      end
        
    end

    def self.save_wallet(wallet) #need show open orders
      DB[:wallets].delete
      wallet.each do |ww|
        DB[:wallets].insert({pid:2, type:ww[0],currency:ww[1], balance:ww[2], available:ww[4] })
      end
    end   
    def self.get_wallets_curr #need show open orders
      codes = DB[:wallets].filter( Sequel.lit("balance>0") ).select_map(:currency)
      codes=codes-['BTC']
      codes.map { |curr| "#{curr}BTC"  }
    end  
 
  end
end
