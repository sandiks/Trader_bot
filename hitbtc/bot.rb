require 'sequel'
require 'rufus-scheduler'
require_relative 'hitbtc_parser'

DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading_hitbtc', user: 'root')
PID=2
#HitBtcParser.new.save_public_symbol
#HitBtcParser.new.save_public_currency
#HitBtcParser.new.copy_symbol_to_profile
def set_track_market(sym,enb="+")
  enb_= enb=="+" ? 1:0
  DB[:tprofiles].filter(uid:PID, name:"#{sym}BTC").update(check:enb_)
end

def show_tracked_tokens_price

  profiles=DB[:tprofiles].filter(uid:PID,check:1).select_map(:name)

  res =[]
  profiles.each do |symb|
    if symb.end_with?("BTC")
      data = DB[:hst_rates].filter( name: symb ).reverse_order(:date).limit(20).select_map([:date,:last, :bid])
    end
    res<<"---------#{symb}"
    res<< data.select.with_index { |x, i| x if i<2 || (i>2 &&  (i % 4 == 0))}
    .map { |dd| "#{symb}>>  #{dd[0].strftime("%F  %k:%M ")}  last: #{'%0.8f' % dd[1]} bid: #{'%0.8f' % (dd[2]||0)}"  }.join("\n") if data
  end
  puts res
end

def scheduler( period = 180)
  p "---start scheduler period:#{period}"
  #save_log("start-price-analz-scheduler s#{period}", "")

  scheduler = Rufus::Scheduler.new
  
  scheduler.every "#{period}s" do
    HitBtcParser.new.save_tickers(true)
    show_tracked_tokens_price
    #show_last_3_falling_prices

    p "finished #{DateTime.now.strftime("%k:%M:%S")}"
  end

  scheduler.join
end

case ARGV[0].to_i
when 1; scheduler(ARGV[1]||120)
when 2; show_tracked_tokens_price
when 444; find_vibrate_prices(ARGV[1].to_i)  #
when 11; set_track_market(ARGV[1],ARGV[2])
end