require 'sequel'
require 'rufus-scheduler'
require 'json'
require_relative 'bittrex/bittrex_api'
require_relative 'bittrex/price_analz'
require_relative 'console_format'
require_relative 'bittrex/db_util'
require_relative 'bittrex/trade_util'
require_relative 'bittrex/order_util'


def run(bot,p1, p2)
  p "---start bot p1:#{p1} p2:#{p2}"
  scheduler = Rufus::Scheduler.new

  TradeUtil.show_tick("BTC-XVC");

  scheduler.every "#{p1}s" do
    p "-----"
    TradeUtil.show_tick("BTC-XVC");

  end
  scheduler.join
end

def help

end

case ARGV[0]
  when 'run'; run(bot,15,60)

  when 'tick';      bid= TradeUtil.show_tick(ARGV[1]);  p '%0.8f' % bid
  when 'buy';       TradeUtil.buy_curr(ARGV[1], ARGV[2].to_f)
  when 'sell';      TradeUtil.sell_curr(ARGV[1], ARGV[2].to_f, ARGV[3])
    
  when 'open';      OrderUtil.show_my_open_orders(ARGV[1])
  when 'ccc';       p TradeUtil.cancel_by_uuid(ARGV[1])
  when 'balance';   p TradeUtil.get_curr_balance(ARGV[1])

  when 'book1';     OrderUtil.order_book('buy',ARGV[1])
  when 'book2';     OrderUtil.order_book('sell',ARGV[1])
  when 'hist';      OrderUtil.my_hist_orders(ARGV[1])

  when "file_low";    PriceAnalz.find_tokens_with_low_price(ARGV[1]||72)  #
  when "file_rising"; PriceAnalz.find_risign_prices(ARGV[1]||10)  #
  when "rising";      PA_show_rising_prices(PriceAnalz.show_falling_and_rising_prices(24))

end

def show_rate4(rr)
  prc = [1,1.02, 1.03, 1.04, 1.05]

  show_prices = prc.map { |pp| " #{'%0.0f' % ((10**8)*pp*rr)}" }.join(' ')
  "rate(0,2,3,4,5)% : #{show_prices}"
end

#p show_rate4(r)

