require 'sequel'

require_relative 'client'

module  Cryptopia
  module Util
    
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'cryptopia', user: 'root')

    def self.date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end

    def self.save_markets
      data = api_query("GetMarkets" )

      DB.transaction do
        data.each do |dd|

          DB[:markets].insert(dd)
        end
      end
    end

    def self.fetch_markets_and_save_to_rates
      #data = api_query("GetMarkets", market_list)
      data = api_query("GetMarkets")
      DB.transaction do
        data.each do |dd|
          
          trade_pair_id = dd['TradePairId']
          label = dd['Label']
          bid,ask = dd['BidPrice'],dd['AskPrice']
          
          if label.end_with?('/BTC')
           rr={mid: trade_pair_id, bid:bid,ask:ask, date:date_now(0) }
           DB[:hst_rates].insert(rr)
          end

        end
      end
    end 

    @@market_store= Hash.new([])

    def self.market_store
      @@market_store
    end    

    def self.fetch_markets_and_alarm_20_PERCENT(wallet_pairs)

      data = api_query("GetMarkets")

      data.each do |dd|
        
        trade_pair_id = dd['TradePairId']
        label = dd['Label']
        bid,ask = dd['BidPrice'],dd['AskPrice']
        
        if label.end_with?('/BTC') #&& wallet_pairs.include?(trade_pair_id)

          rr={mid: trade_pair_id, bid:bid,ask:ask, date:date_now(0) }
          
          if  wallet_pairs.include?(trade_pair_id)
            save_to_ticks(trade_pair_id, bid,ask)
          end

          pair_data = @@market_store[trade_pair_id]
          #p label
          #p pair_data
          @@market_store[trade_pair_id] = [ pair_data[1], [bid,ask] ]

        end

      end
      @@market_store

    end     
    
    def self.save_rising_pair(mid, bid, ask, diff_bid, diff_ask)
      return if bid.nil? || ask.nil? || diff_bid.nil? || diff_ask.nil?

      rr = {mid:mid, bid: bid, ask: ask, diff_bid:diff_bid, diff_ask:diff_ask, date:date_now(0) }
      DB[:rising_pairs].insert(rr)
    end


    def self.get_market(mid)
      data = api_query("GetMarket", [ mid])

    end    

    def self.get_mark_prices  
      DB[:wallets].to_hash(:currency,:last_price)
    end
        
    def self.get_markets_from_db
      DB[:markets].to_hash(:TradePairId, :Label)
    end

    def self.save_to_ticks(mid, bid, ask)
      rr = { bid: bid, ask: ask }
      DB[:my_ticks].filter(name: mid).update(rr)
    end

    def self.get_wallets_curr

      curr_names = DB[:wallets].filter(active:1).select_map(:currency)
      pairs = curr_names.map { |dd| "#{dd}/BTC" }
      #pairs<<"DOGE/BTC"
      DB[:markets].filter(Label: pairs).select_map(:TradePairId)  #to_hash(:MarketAssetCode,:MarketID)
    end   
    def self.get_simul_pairs

      pairs = DB[:simul_markets].select_map(:mid)
    end   

  end
end

#Cryptopia::Util.save_markets
#p Cryptopia::Util.get_wallets_curr

#Cryptopia::Util.get_market(5141) rescue 0