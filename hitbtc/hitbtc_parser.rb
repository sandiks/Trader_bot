require 'parallel'
require 'sequel'
require_relative 'arr_helper'
require_relative 'hitbtc_api'


Sequel.datetime_class = DateTime

class HitBtcParser

  attr_accessor :config

  def initialize
    #@config = DB[:config].select_hash(:name, :value)
  end

  DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading_hitbtc', user: 'root')

  def print_float(dd); sprintf('%02.4f', dd); end

  def save_public_symbol
    data = HitbtcApi.new.get_public_symbol

    DB.transaction do
      exist = DB[:symbol].select_map(:id)

      data.each do |dd|        
        DB[:symbol].insert(dd) if !exist.include?(dd["id"])
      end

    end
  end
  def save_public_currency
    data = HitbtcApi.new.get_public_currency

    DB.transaction do
      exist = DB[:currency].select_map(:id)

      data.each do |dd|        
        DB[:currency].insert(dd)  if !exist.include?(dd["id"])
      end

    end
  end  
  
  def copy_symbol_to_profile(pid=2)
    all = DB[:symbol].filter(Sequel.like(:id, '%BTC')).select_map(:id)
    all<<"BTCUSD"
    DB.transaction do
      exist = DB[:tprofiles].filter(uid:pid).select_map(:name)
      all.each do |mm|
        DB[:tprofiles].insert({uid:pid, name:mm}) if !exist.include?(mm)
      end
    end
  end  

  ### tickers
  def save_tickers(tor=false)

    data = HitbtcApi.new.get_public_ticker
    DB.transaction do
      ##save to rates
      data.each{ |dd|
        rr = {name:dd["symbol"],last:dd["last"], bid:dd["bid"], date:date_now(0)}
        DB[:hst_rates].insert(rr) if dd["symbol"].end_with?("BTC") 
      }
    end

  end  
  

  def log(txt)
    #p txt
  end

  ##--------------------
  def date_now(min_back=10); DateTime.now.new_offset(0/24.0)- min_back/(24.0*60) ; end

  def process_orders_and_save(_ords, token, type)
    data = _ords.reverse.group_by { |pp| dd = pp[:Date]; DateTime.new(dd.year, dd.month, dd.day, dd.hour, dd.minute) }
    .map { |k, vv| { sym: token, date: k, count: vv.size, vol: vv.reduce(0) { |sum, x| sum + x[:Total] }, type: type } }

    log "***process_orders_and_save #{data.size}"
    save_ords(token, data, type)
    save_token_volume_hours(token,data) if type=="BUY"

    data
  end

  def load_completed_orders_from_bittrix(token)

    ords = BittrexApi.new.get_last_trades("BTC-#{token}")

    save_token_checked_time(token)

    if  ords

      buy_ords = ords.select { |ord| ord['OrderType'] == 'BUY' }
      .map { |ord| { sym:token, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

      sell_ords = ords.select { |ord| ord['OrderType'] == 'SELL' }
      .map { |ord| { sym:token, Date: DateTime.parse(ord['TimeStamp']).new_offset(0 / 24.0), Total: ord['Total'], Type: 'BUY' } }

      log "--load_completed_orders_from_bittrix SELL #{sell_ords.size} BUY #{buy_ords.size}"

      sell_data =[] # process_orders_and_save(sell_ords, token, 'SELL')
      buy_data = process_orders_and_save(buy_ords, token, 'BUY')
    end
    {sell:sell_data , buy:buy_data||[]}

  end

  def format_vol(dd, avg, type)
    # "#{dd[:sym]} #{type} [#{dd[:date].strftime("%k:%M")}]  "+"vol: #{ print_float(dd[:vol])} ".ljust(17) +" AVG: #{print_float(avg)}".ljust(17)+" count:#{dd[:count]}"
    "#{dd[:sym]} [#{dd[:date].strftime("%k:%M")}] (#{dd[:count]}) #{ print_float(dd[:vol])}"
  end




  def get_orders_from_database(token, min_back=20)
    ##from table
    #p "token: #{token} min_back #{min_back} date_now #{date_now(0)}"
    #p DB[:orders].filter(Sequel.lit('sym=? and date > ?', token, date_now(min_back))).order(:date).sql

    ords = DB[:orders].filter(Sequel.lit("sym=? and date > ? and type='BUY' ", token, date_now(min_back))).order(:date).all
    log "---get_orders_from_api_or_database token:#{token} ---DB size:#{ords.size} minutes_back:#{min_back}"

    buy_data = ords.select { |ord| ord[:type] == 'BUY' }
    sell_data = [] #ords.select { |ord| ord[:type] == 'SELL' }

    {sell:sell_data,buy:buy_data}
  end



end
