require 'sequel'
require_relative 'lib/arr_helper'


#PID=2
class OrderAnalz

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')
  def date_now(hours=0); DateTime.now.new_offset(0/24.0)- hours/(24.0) ; end

  def self.show_sell_buy_orders
    mname = 'BTC-DNT'
    data = DB[:my_hst_orders].filter(Exchange:mname).all
    
    sell_ord =[]
    buy_ord =[]

    data.each do |dd|
      if dd[:OrderType] == "LIMIT_SELL"
        sell_ord<<dd
      end
      
      if dd[:OrderType] == "LIMIT_BUY"
        buy_ord<<dd
      end
    
    end

    buy_min = buy_ord.min_by{|ee| ee[:Limit]}[:Limit]
    sell_max = sell_ord.max_by{|ee| ee[:Limit]}[:Limit]

    p "------BUY"
    buy_ord.each do |dd|
        puts "date:#{dd[:TimeStamp].strftime("%F %k:%M ")} rate:#{'%0.8f' % dd[:Limit]} q: #{'%0.3f' % dd[:Quantity]} btc: #{'%0.8f' % dd[:Price]}"
    end
    p "------SELL"
    sell_ord.each do |dd|
        puts "date:#{dd[:TimeStamp].strftime("%F %k:%M ")} rate:#{'%0.8f' % dd[:Limit]} q: #{'%0.3f' % dd[:Quantity]} btc: #{'%0.8f' % dd[:Price]}"
    end

  end

  def self.range_price
    mname = 'BTC-DNT'
    data = DB[:my_hst_orders].filter(Exchange:mname).all

    sell_ord =[]
    buy_ord =[]

    data.each do |dd|
      if dd[:OrderType] == "LIMIT_SELL"
        sell_ord<<dd
      end

      if dd[:OrderType] == "LIMIT_BUY"
        #puts "buy date:#{dd[:date]} rate:#{'%0.8f' % dd[:rate].to_f} total: #{'%0.3f' % dd[:total]} btc: #{'%0.8f' % dd[:btc]}"
        buy_ord<<dd
      end

    end

    p buy_min = buy_ord.min_by{|ee| ee[:Limit]}[:Limit]
    p sell_max = sell_ord.max_by{|ee| ee[:Limit]}[:Limit]

    bsum=0
    ssum=0
    step = 0.00000030  #(sell_max-buy_min)/10
    i =buy_min

    while i<sell_max
      i+=step
      p "----#{'%0.8f' % (i-step)} - #{'%0.8f' % i}" 

      #sell_ord.select{|x| x[:rate]<i}.each{|x| p "sell #{'%0.8f' % x[:Limit]}" }
      
      ss= sell_ord.select{|x| x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Price] }
      sellq= sell_ord.select{|x| x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Quantity] }
      
      bb= buy_ord.select{|x|  x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Price] }
      buyq= buy_ord.select{|x|  x[:Limit]>=i-step && x[:Limit]<i}.map{|x| x[:Quantity] }
      
      
      bsum+=bb.sum
      ssum+=ss.sum  # inject(0){|sum,x| sum + x[0] }
      
      #p "buy total:#{'%0.8f' %  bbamount.sum}" 
      p "   buy:#{'%0.8f' %  bb.sum} q:#{'%0.1f' % buyq.sum}" 
      p "   sell:#{'%0.8f' % ss.sum} q:#{'%0.1f' % sellq.sum}"
      
      #p "diff  sell - buy:  #{'%0.8f' % (ssum-bsum)}"
      
    end

  #puts "sell_sum #{sell_sum}  buy_sum #{buy_sum}"
  end

end
