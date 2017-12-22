#require 'parallel'
require 'sequel'
require_relative 'arr_helper'
require_relative 'bittrex_api'


Sequel.datetime_class = DateTime

class VolumeAnalz

  attr_accessor :config

  def initialize
    @config = DB[:config].select_hash(:name, :value)
  end

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')

  def print_float(dd); sprintf('%02.4f', dd); end

  def save_ords(mname, data, type)
    min_d = date_now(30) #data.min { |oo| oo[:date] }
    exist = DB[:order_volumes].filter(Sequel.lit('name=? and date > ? and type=?', mname, min_d, type)).map(:date)
    exist = exist.map { |dd| [dd.hour, dd.min] }

    data.each do |ord|
      dd = ord[:date]
      if !exist.include?([dd.hour, dd.minute]) && dd>min_d
        #p "******new: #{type} hh_mm:#{[dd.hour, dd.minute]} count:#{ord[:count]} vol:#{ord[:vol]}"
        DB[:order_volumes].insert(ord)
      end
    end


  end

  def save_token_volume_hours(name,data)
    back10 =date_now(10)
    back20 =date_now(20)
    back30 =date_now(30)
    back60 =date_now(60)

    vol10 = data.select{ |dd|  dd[:date]>back10 }.reduce(0) { |sum, x| sum + x[:vol] }
    vol20 = data.select{ |dd|  dd[:date]>back20 }.reduce(0) { |sum, x| sum + x[:vol] }
    vol30 = data.select{ |dd|  dd[:date]>back30 }.reduce(0) { |sum, x| sum + x[:vol] }
    log "---save_token_volume_hours  vol:#{[vol10,vol20,vol30]}"
    DB[:stat_market_volumes].filter(name:name).update(vol10:vol10, vol20:vol20, vol30:vol30);

  end

  def save_token_checked_time(mname)
    DB[:stat_market_volumes].filter(name:mname).update(last_checked_at: date_now(0));
  end


  def log(txt)
    #p txt
  end

  ##--------------------
  def date_now(min_back=10); DateTime.now.new_offset(0/24.0)- min_back/(24.0*60) ; end

  def process_orders_and_save(_ords, mname, type)
    data = _ords.reverse.group_by { |pp| dd = pp[:Date]; DateTime.new(dd.year, dd.month, dd.day, dd.hour, dd.minute) }
    .map { |k, vv| { name: mname, date: k, count: vv.size, vol: vv.reduce(0) { |sum, x| sum + x[:Total] }, type: type } }

    log "***process_orders_and_save #{data.size}"
    save_ords(mname, data, type)
    save_token_volume_hours(mname,data) if type=="BUY"

    data
  end

  def load_completed_orders_from_bittrix(mname)
    p "--load orders #{mname}"

    ords = BittrexApi.new.get_last_trades(mname)

    save_token_checked_time(mname)

    if  ords

      buy_ords = ords.select { |ord| ord['OrderType'] == 'BUY' }
      .map { |ord| { name:mname, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

      sell_ords = ords.select { |ord| ord['OrderType'] == 'SELL' }
      .map { |ord| { name:mname, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

      log "-- SELL #{sell_ords.size} BUY #{buy_ords.size}"

      sell_data =[] # process_orders_and_save(sell_ords, token, 'SELL')
      buy_data = process_orders_and_save(buy_ords, mname, 'BUY')
    end
    {sell:sell_data , buy:buy_data||[]}

  end

  def format_vol(dd, avg, type)
    "#{dd[:name]} [#{dd[:date].strftime("%k:%M")}] (#{dd[:count]}) #{ print_float(dd[:vol])}"
  end


  def calc_rise_fall_avg(data, type, need_show_all=false)
    res=[]

    vols= data.map{|el| el[:vol]}
    avgs = []
    rise={}
    fall={}

    for i in 0..data.size-1
      avgs<<  (i==0 ? vols[i..i+1].mean :  vols[i-1..i+1].mean)
    end
    #p "vol_size:#{vols.size} avg_size:#{avgs.size}"

    for i in 1..data.size-1
      ff= vols[i]/vols[i-1]
      #ff= avgs[i]/avgs[i-1]

      rise[i]=ff if ff>2 && vols[i]>0.5
      #fall[i]=ff if ff<0.5
    end

    min_vol=@config["show_orders_with_min_volume"].to_f


    is_rised=1
    prev=""
    ldate=nil
    for i in 0..data.size-1
      dd = data[i]
      ss =format_vol(dd, avgs[i], "BUY")

      if rise[i]
        res<<"<b>#{ss}</b> ***RISE #{print_float(rise[i])}"
        is_rised=0
        ldate=dd[:date]
      else
        res<<"#{ss}" if need_show_all || is_rised==0 #||data[i][:vol]>= min_vol
        is_rised+=1
      end

    end

    {text:res.reverse,last_date:ldate}
  end

  def get_order_volumes_from_database(mname, min_back=20)
    ##from table

    ords = DB[:order_volumes].filter(Sequel.lit("sym=? and date > ? and type='BUY' ", mname, date_now(min_back))).order(:date).all
    log "---get_orders_from_api_or_database market:#{mname} ---DB size:#{ords.size} minutes_back:#{min_back}"

    buy_data = ords.select { |ord| ord[:type] == 'BUY' }
    sell_data = [] #ords.select { |ord| ord[:type] == 'SELL' }

    {sell:sell_data,buy:buy_data}
  end

  def show_order_volumes(mname, need_show_all=false)

    data = get_orders_from_database(mname,@config["history_orders_min_back"].to_i)[:buy]
    return [] unless data

    dd = calc_rise_fall_avg(data,"BUY", need_show_all)
    find_and_save_LAST_RISE(mname, dd, "check_token")
    dd[:text]
  end

  def find_and_save_LAST_RISE(mname, data, label)

    text= data[:text]
    ldate= data[:last_date].to_datetime if data[:last_date]

    last_rise = text.find{|ss| ss.include?("***RISE")}
    #p "-------now:#{now} rise_date:#{ldate}---------last_rise:#{last_rise}"
    now = date_now(0)

    if last_rise && !last_rise.empty?
      last_rise="#{last_rise} "
      if ldate && ldate+1/24.0 <now
        last_rise=""
      end
    else
      last_rise=""
    end
    prr = DB[:markets].filter( name: mname ).select_map(:Last).first
    last_rise="#{'%0.8f'% (prr||0)} #{last_rise} "

    DB[:stat_market_volumes].filter(name:mname).update(last_rise:last_rise,last_rised_at:ldate)

  end

  def self.select_last_rised
    DB[:stat_market_volumes].reverse_order(:last_rised_at).limit(20).select_map(:name)
  end

  def show_pump(mname)

    res=[]
      
    orders = load_completed_orders_from_bittrix(mname)[:buy]
    log "---show_pump_report_for_group  SIZE:#{orders.size}"

    dd= calc_rise_fall_avg(orders,"BUY")
    find_and_save_LAST_RISE(mname, dd, "pump_report")
    res+=dd[:text]
    res
  end

  def show_pump_report_for_group(mname_array, page_size=20)

    res=[]
    last_checked = DB[:stat_market_volumes].to_hash(:name,:last_checked_at)
    
    Parallel.map_with_index(mname_array,:in_threads=>3)  do |mname,indx|
     
      if last_checked[mname] && last_checked[mname].to_datetime>date_now(15)
        p "--pump_group #{mname} already checked #{last_checked[mname].strftime("%k:%M")}"
        next
      end

      orders = load_completed_orders_from_bittrix(mname)[:buy]
      log "---show_pump_report_for_group  SIZE:#{orders.size}"

      dd= calc_rise_fall_avg(orders,"BUY")
      find_and_save_LAST_RISE(mname, dd, "pump_report")
      res+=dd[:text]
    end

    res
  end

end
