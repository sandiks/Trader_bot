require 'sequel'
require 'rufus-scheduler'

PID=2
DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading_hitbtc', user: 'root')

def date_now(min_back=0); DateTime.now.new_offset(0/24.0)- min_back/(24.0*60) ; end

def save_log(type, text)
  DB[:bot_logs].insert({type:type, info:text, date: date_now})
end


def find_vibrate_prices(min_back=30)

  markets = DB[:tprofiles].filter(uid:PID).select_map([:name])
  from = date_now(min_back.to_i)
  ind = 0

  ress={}

  markets.each do |mm,vol|

    data = DB[:hst_rates].filter(Sequel.lit("date > ? and name=?",from, mm)).reverse_order(:date).select(:date,:last).all
    last_price=data.first[:last]
    ind+=1
    res=[]
    
    prices = data.map { |dd| (dd[:last]/last_price*1000).to_f}
    minp = prices.min
    maxp = prices.max
    prices.size
    
    rise_pos=nil
    ff=nil
    
    for i in 0..prices.size-3 do
      pp = prices[i,i+3]
      if pp[2] && pp[0]<pp[1] && pp[1]<pp[2]
        rise_pos =i
        ff1=(pp[0]-minp)/(maxp-minp)*10
        ff=ff1.round(1)+i
        break 
      end
    end
    
    res<<"(#{ind})-------#{mm} ff:#{ff}  last: #{'%0.8f' % last_price}"
    
    data.select.with_index { |x, i| x if (i<2) || (i<50 &&  (i % 10 == 0)) || (i>=50 &&  (i % 30 == 0)) }.each do |dd| 
      curr=dd[:last]/last_price*1000
      s1="#{[dd[:date].hour, dd[:date].min]}"
      res<<"#{s1.ljust(10)}  #{'|'.rjust((curr-970)/2,' ')} #{'%0.0f' % curr}" 
    end if true
    ress[mm] = {lines: res, price_factor: ff||100}
  end

  lines = []
  ress.sort_by{|k,v| v[:price_factor]}.each {|k,vv|  lines+=vv[:lines]  }

  File.write('hitbtc_vibrate.txt', lines.join("\n"))
end

def show_last_3_falling_prices(min_back=20)
  p "show_last_3_falling_prices min_back:#{min_back}"
  markets = DB[:tprofiles].filter(uid:PID).select_map([:name])

  from = date_now(min_back)
  ress={}
  ind=0

  markets.each do |mm|

    data = DB[:hst_rates].filter(Sequel.lit("date > ? and name=?",from, mm)).reverse_order(:date).select(:date,:last).all
    ind+=1

  
    next unless data
    last_price=data.first[:last]
    p data.size

    prices = data.map { |dd| (dd[:last]/last_price*1000).to_f}
  
    falling=false
    ff=nil
    1.times do |i|
      pp = prices[i,i+3]
      if (  pp[0]<pp[1] && pp[1]<=pp[2] )
        falling=true  
        ff=(pp[2]-pp[0])/pp[2]*10
        break 
      end
    end
    
    if falling
      res=[]
      res<<"(#{ind})-------#{mm} ff:#{ff} "
    
      data.take(6).each do |dd| 
       curr=dd[:last]/last_price*1000

        time="#{[dd[:date].hour, dd[:date].min]}"
        res<<"#{time}  last:#{'%0.8f' % dd[:last]} #{'%0.0f' % curr} " 
      end
      ress[mm] = {lines: res, price_factor: ff||0}
    end

  end

  lines = []
  ress.sort_by{|k,v| -v[:price_factor]}.take(5).each {|k,vv| lines<<""; lines+=vv[:lines]  }
  puts lines 
end


case ARGV[0].to_i
when 2; show_tracked_tokens_price
when 3; show_last_3_falling_prices
when 444; find_vibrate_prices(ARGV[1]||600)  #
end
