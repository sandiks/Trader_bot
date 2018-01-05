require "rest-client"
require "json"

module CoinExchange

  class Client

    BASE_URL = "https://www.coinexchange.io/api/v1/"
    API_KEY = "<YOUR_API_KEY>"
    API_SECRET = "<YOUR_API_SECRET>"
    DB = Sequel.connect(adapter: 'mysql2', host: 'localhost', database: 'coinexch', user: 'root')

    def call_api(url)
      response = RestClient.get(url)
      parsed_body = JSON.parse(response.body)
      is_successed = parsed_body["success"]=="1" 
      parsed_body["result"] if is_successed
    end

    def get_markets
      url = "#{BASE_URL}getmarkets"
      data = call_api(url)
      
    end

    def market_summaries
      #https://www.coinexchange.io/api/v1/getorderbook?market_id=1
      url = "#{BASE_URL}getmarketsummaries"
      data = call_api(url)
    end
    
    def get_market_summary(mid)
      #https://www.coinexchange.io/api/v1/getmarketsummary?market_id=
      url = "#{BASE_URL}getmarketsummary?market_id=#{mid}"
      data = call_api(url)
    end

    def get_currencies
      #https://www.coinexchange.io/api/v1/getcurrencies
      url = "#{BASE_URL}getcurrencies"
      data = call_api(url)
    end

    def get_order_book(mid=1)
      #https://www.coinexchange.io/api/v1/getorderbook?market_id=1
      url = "#{BASE_URL}getorderbook?market_id=#{mid}"
      orders = call_api(url)
      
    end

    def parse_orders(crypto_sym="ETH")

      date = DateTime.now.new_offset(3/24.0).strftime("%F %k:%M:%S ")

      p "-------"
      p " PARSE date: #{date}"
      p all_ords = get_order_book(18)["SellOrders"]
      

    end

  end

end
