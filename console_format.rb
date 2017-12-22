
@out=[]
def PA_show_rising_prices(data)


  #puts ""
  #puts "---falling price"
  #puts data[:falling]

  puts ""
  puts "---rise price"
  puts data[:rising]

  # puts ""
  # puts "--TRACKED"
  # puts data[:tracked].sort_by{|dd| dd[:usdt]}
  # .map{|dd| "#{dd[:mname].ljust(10)} usdt:#{('%04.2f' % dd[:usdt]).ljust(7)} bid:#{'%0.8f' % dd[:last_bid]} ask:#{'%0.8f' % dd[:last_ask]}   #{ dd[:history_prices]} "  }

  puts "--USD"
  puts data[:usd]

  puts @out
end

def clean_log
  @out=[]
end

def log(data)
  return unless data
  if data.is_a?(Array)
    @out+=data
  else
    @out<<data
  end
  #puts data
end
