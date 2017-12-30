require 'sequel'
require_relative 'client'

module BG
  class Util
    def self.date_now(hours = 0)
      DateTime.now.new_offset(0 / 24.0) - hours / 24.0
    end

    BGDB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitgrail', user: 'root')
    BF_DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'bitfinex', user: 'root')

    def init_my_ticks
      BTG_DB.run('truncate table my_ticks')

      symbols = ['BTC-XRB']

      symbols.each do |symb|
        BTG_DB[:my_ticks].insert(name: symb)
      end
    end

    def self.save_to_ticks(symb, bid, ask)
      rr = { bid: bid, ask: ask }
      BGDB[:my_ticks].filter(name: symb).update(rr)
    end

    def self.save_to_rates(symb, bid, ask)
      rr = { name: symb, bid: bid, ask: ask, date: date_now(0) }
      BGDB[:hst_rates].insert(rr)
    end

    def self.base_curr
      'ETH'
    end

    def self.btc_usd
      usd_bid = BF_DB[:my_ticks].filter(symb: 3).select(:bid, :ask).first
    end

    def self.my_btc
      BGDB[:balances].filter(curr: 'BTC').first[:balance]
    end

    def self.get_all_bid_ask
      BGDB[:my_ticks].to_hash(:name, [:bid, :ask])
    end

    def self.show_order_book(symb = '')
      symb = 'BTC-XRB'
      orders = get_order_book(symb)

      orders['asks'].take(10).each do |ord|
        p 'price: %0.8f  amount: %0.8f' % [ord['price'], ord['amount']]
      end
    end

    def self.get_hist_trades(symb)
      last_trades = BGDB[:hst_trades].filter(market: symb).reverse_order(:date).limit(10).all
    end

    def self.last_buy_trade(symb)
      BGDB[:hst_trades].filter(market: symb, type: 'buy').reverse_order(:date).first
    end

    def self.fast_buy_curr(curr, quant)
      ask = BG::Util.get_all_bid_ask[curr][1]
      BG::BGBot.new.buy_order(curr, quant, ask)
    end

    def self.fast_sell_curr(curr, quant)
      bid = BG::Util.get_all_bid_ask[curr][0]
      BG::BGBot.new.sell_order(curr, quant, bid)
    end
  end
end
