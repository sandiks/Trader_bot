require 'sequel'

#PID=2
#DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'trading', user: 'root')

class PriceAnalz

  def self.date_now(hours_back=0); DateTime.now.new_offset(0/24.0)- hours_back/(24.0) ; end


  def self.show_ticks
    tracked_pairs = DB[:tprofiles].filter(pid:PID, enabled:1, check:1,group:1).select_map(:name)
    tracked=[]
    tracked<<"updated #{DateTime.now.strftime('%k:%M:%S')} "
    
    from = date_now(0.5)
    all_data = DB[:hst_btc_rates].filter(Sequel.lit("(date > ? and name in ?)", from, tracked_pairs))
    .reverse_order(:date).select(:name,:date,:bid,:ask).all

    tracked_pairs.each do |m_name|
      data = all_data.select{|dd|dd[:name] == m_name }

      next if data.size<1
      last_bid=data.first[:bid]
      last_ask=data.first[:ask]
  
      hist_prixes =data.take(10).map { |dd| "#{'%0.0f' % (dd[:bid]/last_bid*1000)}" }.join(' ') 
      tracked<< "<b>#{m_name} </b>#{'%0.8f' % last_bid} #{'%0.8f' % last_ask} || #{hist_prixes} " 
      #{name:m_name, last_bid:last_bid, hist_bids:last3 } 
    end
    tracked.join("<br />")
  end

  def self.get_balance(usdt_rate)

    balances = DB[:my_balances].to_hash(:currency,:Balance)
    curr_ = balances.keys.map { |rr| "BTC-#{rr}" }
    bids = DB[:markets].filter(Sequel.lit(" name in ? ", curr_)).to_hash(:name,:Bid) 

    res={}

    balances.each do |k,v|
      next if k=='BTC'
       bid=bids["BTC-#{k}"] 
       btc_bal = v*bid rescue 0
       usdt_bal = btc_bal*usdt_rate
       res[k]={ btc:btc_bal, usdt:usdt_bal}
  end
    res
  end  

##########--------------------
 
  @@last_rised=[]

  def self.show_falling_and_rising_prices(hours_back=12,group=1)
    p "show_rising_prices hours_back:#{hours_back}"

    markets = DB[:tprofiles].filter(pid:PID, group: group, enabled:1).select_map(:name)
    #tracked_pairs = DB[:tprofiles].filter(pid:PID, group: group, enabled:1, check:[1,2]).select_map(:name)
    tracked_pairs = DB[:my_balances].filter(pid:2).all.map { |dd| "BTC-#{dd[:currency]}"  }

    usd_btc_bid = DB[:hst_usdt_rates].filter(name:'USDT-BTC').reverse_order(:date).limit(1).select_map(:bid)[0]
    balances = get_balance(usd_btc_bid)

    now = date_now(0)
    ress={}
    ind=0
    tracked=[]
    
    curr_rising =[]

    from = date_now(hours_back)    

    mins = 8.times.map {|i| i<4 ? (now.min+i)%60 : (30+now.min+i)%60 }
    hours = 6.times.map {|hh| (now.hour+ hh*4) % 24} 

    all_data = DB[:hst_btc_rates]
    .filter(Sequel.lit(" (date > ? and name in ? and MINUTE(date) in ?)", from, markets, mins))
    .reverse_order(:date).select(:name,:date,:bid,:ask).all


    markets.each do |mname|

      
      data = all_data.select{|dd|dd[:name] == mname }

      ind+=1
      next if data.size<3
    
      last_bid=data.first[:bid]
      last_ask=data.first[:ask]

      bid_prices = data.map { |dd| dd[:bid]/last_bid}
      ask_prices = data.map { |dd| dd[:ask]/last_ask}
      #minp = bid_prices.min 
      #maxp = bid_prices.max

      rise_ff=nil
      fall_ff=nil

      1.times do |i|
        rr = bid_prices[i,i+3]
        ff = bid_prices[i,i+3]

        if rr[0]>rr[1]
         rise_ff=(rr[0]-rr[2])/rr[0]
        end
        
        if (ff[0]<ff[1])
         fall_ff=(ff[2]-ff[0])/ff[2]
        end

      end

      if fall_ff || rise_ff 
        is_tracked = tracked_pairs.include?(mname) ? "**" : ""
        title ="(#{ind.to_s.ljust(3)})--#{mname} #{is_tracked} ".ljust(25)
        
          
        data2=data.select.with_index { |x, i| i<3 || (i % 5 == 0) }.group_by{|dd| dd[:date].day}       
        ## when falling  divide by --last_bid
        base= fall_ff ? last_bid : last_ask
        hist = data2.map { |d, d_rates| "day(#{d}) "+d_rates.map { |dd| "#{'%4d' % (dd[:bid]/last_bid*1000)} " }.join(' ') }
        res="#{title} bid: #{'%0.8f' % last_bid} #{hist.join("  **")}"
          
        ress[mname] = {line: res}
        ress[mname][:rising_factor] = rise_ff||0 
        ress[mname][:falling_factor] = fall_ff||100 
      end

      if tracked_pairs.include?(mname)
        currency = mname.sub('BTC-','')

        bal = balances[currency]
        bal_usdt = bal ? bal[:usdt] : 0
      
        last3=[]
        if  last_bid!=0
          last3=data.select.with_index { |x, i| (i<2)|| (i % 10 == 0) }.map{ |dd| "#{'%4d' % (dd[:bid]/last_bid*1000)}" }.join(' ') 
        end
        tracked<<{mname: mname, usdt: bal_usdt, last_bid: last_bid, last_ask:last_ask, history_prices: last3 } 
      end  
    end

    rising_markets = []
    ress.sort_by{|k,v| -v[:rising_factor]}.take(10).each {|k,vv| curr_rising<<k; rising_markets<<vv[:line]  }

    rising_prev_now= (curr_rising & @@last_rised)
    .map { |dd| "https://bittrex.com/Market/Index?MarketName=#{dd}   #{dd}"  }
    @@last_rised = curr_rising

    falling_markets =ress.sort_by{|k,v| v[:falling_factor]}.take(12).map {|k,vv| vv[:line]  }
    
    usd_rate = "USDT-BTC bid #{'%0.0f' % usd_btc_bid} "
 
    {falling: falling_markets, rising: rising_markets, tracked:tracked, usd:usd_rate }
  end


#####################
  def self.find_tokens_min_priced_but_rising(hours_back=48)

    markets = DB[:tprofiles].filter(pid:PID, group: 1, enabled:1).select_map(:name)
    
    now = date_now(0)
    from = date_now(hours_back.to_i)

    ress=[]
    mins = 8.times.map {|i| i<4 ? (now.min+i)%60 : (30+now.min+i)%60 }
    hours = 6.times.map {|hh| (now.hour+ hh*4) % 24} 

    all_data = DB[:hst_btc_rates]
    .filter(Sequel.lit(" (date > ? and name in ? and MINUTE(date) in ? and HOUR(date) in ?)", from, markets, mins, hours))
    .reverse_order(:date).select(:name,:date,:bid,:ask).all

    markets.each do |mname|
      #next if mname!='BTC-DNT'

      data = all_data.select{|dd|dd[:name] == mname }
      next if data.size<3

      last_bid=data[0][:bid]
      last_ask=data[0][:ask] 

      begin
      
        prices = data.map { |dd| (dd[:bid]/last_bid*1000) }
        minp = prices.min
        maxp = prices.max
      
      
        if prices[0]>prices[1]
          first = prices[0]
          ff=(first-minp)/(maxp-minp)
        else
          ff=1
        end

        ress<< { name: mname, price_factor: ff, bid: last_bid, ask:last_ask,
          min:minp, max:maxp, last_prices:prices.take(2)}    

      rescue => ex
        #p "#{mname} #{ex}"
      end  
    end

    ress.sort_by{|tt| tt[:price_factor]} 
  end

  def self.find_tokens_with_low_price(hours_back=48)

    p "find_tokens_with_low_price -- hours_back:#{hours_back}"

    markets = DB[:tprofiles].filter(enabled:1).select_map([:name])    
    now = date_now(0)
    from = date_now(hours_back)
    ind = 0

    ress={}
    mins = 3.times.flat_map {|i|  [(now.min+i*20)%60,(now.min+1+i*20)%60] }
    #mins = 6.times.map {|i| i<3 ? (now.min+i)%60 : (now.min+30+i)%60 }

    markets.each do |m_name|
      data = DB[:hst_btc_rates].filter(Sequel.lit(" (date > ? and name=? and MINUTE(date) in ?)", from, m_name, mins)).reverse_order(:date).select(:date,:bid).all    
      #data = DB[:hst_btc_rates].filter(Sequel.lit("date > ? and name=? ",from, m_name)).reverse_order(:date).select(:date,:bid).all
      next if data.size==0 

      ind+=1
      res=[]

      last_price=data.first[:bid]
      next if last_price.zero? 
      #p "data: #{data.map{|dd| dd[:bid].to_s}}" if last_price.zero?

      prices = data.map { |dd| (dd[:bid]/last_price*1000).to_f }
      minp = prices.min #rescue p("name:#{m_name} #{last_price}")
      maxp = prices.max
      next if maxp-minp ==0 

      ### calculate factor
      ff=nil
      
      4.times do|i|
        pp = prices[i,i+3]

        if pp[2] #&& pp[0]<pp[1] && pp[1]<pp[2]
          ff1=(pp[0]-minp)/(maxp-minp)*10
          ff=ff1.round(1)+i
          break 
        end
      end

      res<<"(#{ind})-------#{m_name} ff:#{'%0.1f' % ff} bid=#{'%0.8f' % last_price}"
      
      data.select.with_index { |x, i| (i<4)|| (i % 10 == 0) }.each do |dd|
        curr=dd[:bid]/last_price*1000
        s1="#{[dd[:date].hour, dd[:date].min]}"
        res<<"#{s1.ljust(10)}  #{'|'.rjust((curr-950)/3,' ')} #{'%0.0f' % curr}" 
      end if true

      ress[m_name] = {lines: res, price_factor: ff||100}
    end

    lines = []
    lines<<"generated #{DateTime.now.strftime('%k:%M:%S')} from: #{hours_back} hours back"
    ress.sort_by{|k,v| v[:price_factor]}.each {|k,vv|  lines+=vv[:lines]} 

    File.write('reports/low_prices.txt', lines.join("\n"))
  end

  ####################################  

  def self.find_risign_prices(hours_back=4)

    markets = DB[:tprofiles].filter(enabled:1).select_map([:name])    
    now = date_now(0)
    from = date_now(hours_back)
    ind = 0

    ress={}
    mins = 3.times.flat_map {|i|  [(now.min+i*20)%60,(now.min+1+i*20)%60] }
    #mins = 6.times.map {|i| i<3 ? (now.min+i)%60 : (now.min+30+i)%60 }

    markets.each do |m_name|
      #data = DB[:hst_btc_rates].filter(Sequel.lit(" (date > ? and name=? and MINUTE(date) in ?)", from, m_name, mins)).reverse_order(:date).select(:date,:ask).all    
      
      data = DB[:hst_btc_rates].filter(Sequel.lit("date > ? and name=? ",from, m_name)).reverse_order(:date).select(:date,:ask).all
      next if data.size==0 

      ind+=1
      res=[]

      last_price=data.first[:ask]
      #p "last ask #{last_price}"
      next if last_price==0

      prices = data.map { |dd| (dd[:ask]/last_price*1000) }
      minp = prices.min 
      maxp = prices.max
      next if maxp-minp ==0 

      ### calculate factor
      ff=nil
      
      pp = prices[0,3]

      if  pp[0]>pp[1] && pp[1]>pp[2]
        ff=(pp[0]-minp)/(maxp-minp)*10
      end
      ff=100 unless ff

      res<<"(#{ind})-------#{m_name} ff:#{'%0.1f' % ff} bid=#{'%0.8f' % last_price}"
      
      #data.each do |dd|
      data.select.with_index { |x, i| (i<3) || (i % 10 == 0) }.each do |dd|
        curr=dd[:ask]/last_price*1000
        s1="#{[dd[:date].hour, dd[:date].min]}"
        res<<"#{s1.ljust(10)}  #{'|'.rjust((curr-950)/3,' ')} #{'%0.0f' % curr}" 
      end 
  
      ress[m_name] = {lines: res, price_factor: ff}
  end  

    lines = []
    lines<<"generated #{DateTime.now.strftime('%k:%M:%S')} from: #{hours_back} hours back"
    ress.sort_by{|k,v| -v[:price_factor]}.each {|k,vv|  lines+=vv[:lines]} 

    File.write('reports/rising_prices.txt', lines.join("\n"))
  end
end
