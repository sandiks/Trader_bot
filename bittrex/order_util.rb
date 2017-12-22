require 'sequel'
require 'rufus-scheduler'
require_relative 'bittrex_api'
require_relative 'db_util'

class OrderUtil


  PID=2
  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')


  def self.bittrex_api
    BittrexApi.new
  end

  def self.date_now(min_back=0); DateTime.now.new_offset(0/24.0)- min_back/(24.0*60) ; end 


  def self.order_book(tt="buy",mname)
    
    p "#{mname}"
    p "----------ORDER BOOK    BUY    |    SELL"
    sum=0
    #p "----#{tt}"
    bittrex_api.get_order_book(mname, tt).take(15).each do |rr|
      q = rr["Quantity"]
      r = rr["Rate"]
      sum+=r*q
      s1="q: #{'%0.1f' % q}".ljust(10)
      s2= "r: #{'%0.8f' % r}"
      if tt=='buy'
        p " SUM:#{'%0.4f' % sum}   total: #{'%0.4f' % (r*q)}         #{s1} #{s2} "
      else
        p " #{s1} #{s2}       total: #{'%0.4f' % (r*q)} SUM:#{'%0.4f' % sum}"
      end
    end
  end

  def self.show_my_open_orders(mname) #need show open orders
    
    p "--------OPEN ODRERS  #{mname}"
    DB.transaction do
      DB[:my_open_orders].filter(Exchange:mname).delete
      exist = DB[:my_open_orders].filter(Exchange:mname).select_map(:OrderUuid)

      bittrex_api.get_open_orders(mname).each do |ord|
        if !exist.include?(ord['OrderUuid'])
          p "insert"
          DB[:my_open_orders].insert(ord)
        end
        r = ord['Limit']
        p "#{ord['OrderUuid']} type:#{ord['OrderType']} q:#{'%0.1f' % ord['Quantity']} limit:#{'%0.8f' % r}"
      end
    end
  end


  def self.my_hist_orders(mname) #need show open orders
    
    p "--------HISTORY ODRERS  #{mname}"
    DB.transaction do
      exist = DB[:my_hst_orders].filter(Exchange:mname).select_map(:OrderUuid)
      p exist.size

      bittrex_api.market_orders_history(mname).each do |ord|

        if !exist.include?(ord['OrderUuid'])
          p "insert #{ord[:OrderUuid]}"
          DB[:my_hst_orders].insert(ord)
        end

        tm = DateTime.parse(ord['TimeStamp'])
        r = ord['Limit']
        p "time: #{tm.strftime('%F  %k:%M')} type:#{ord['OrderType']} q:#{'%0.1f' % ord['Quantity']} price:#{'%0.8f' % r}"
      end

    end

  end

end