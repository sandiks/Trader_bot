require 'sequel'

require_relative 'client'

module  Cryptopia
  module Util
    
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'cryptopia', user: 'root')

    def self.save_markets
      data = api_query("GetMarkets" )

      DB.transaction do
        data.each do |dd|

          DB[:markets].insert(dd)
        end
      end
    end
    
    def self.get_market(mid)
      data = api_query("GetMarket", [ mid])

    end    

    def self.save_to_ticks(mid, bid, ask)
      rr = { bid: bid, ask: ask }
      DB[:my_ticks].filter(name: mid).update(rr)
    end

  end
end

#Cryptopia::Util.save_markets

#Cryptopia::Util.get_market(5141) rescue 0