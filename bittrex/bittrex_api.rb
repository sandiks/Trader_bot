require 'rest-client'

#gem 'json', '=2.1.0'
require 'dotenv'
require_relative '../lib/socksify_mechanize'

Dotenv.load('.env')

class BittrexApi
  BASE_URL = 'https://bittrex.com/api/v1.1/'.freeze
  API_KEY = ENV["Key"]
  API_SECRET = ENV["Secret"]

  URIs = {
    public: {
      markets: 'public/getmarkets',
      currencies: 'public/getcurrencies',
      market_ticker: 'public/getticker?market=%s',
      market_day_summaries: 'public/getmarketsummaries',
      market_day_summary: 'public/getmarketsummary?market=%s',
      order_book: 'public/getorderbook?market=%s&type=%s',
      last_trades: 'public/getmarkethistory?market=%s'
    },
    account: {
      balance: 'account/getbalances',
      currency_balance: 'account/getbalance?currency=%s',
      deposit_address: 'account/getdepositaddress?currency=%s',
      withdraw: 'account/withdraw?currency=%s&quantity=%s&address=%s',
      get_order_by_uuid: 'account/getorder&uuid=%s',
      orders_history: 'account/getorderhistory',
      market_orders_history: 'account/getorderhistory?market=%s',
      withdrawal_history: 'account/getwithdrawalhistory?currency=%s',
      deposit_history: 'account/getwithdrawalhistory?currency=%s'
    },
    market: {
      buy: 'market/buylimit?market=%s&quantity=%s&rate=%s',
      sell: 'market/selllimit?market=%s&quantity=%s&rate=%s',
      cancel_by_uuid: 'market/cancel?uuid=%s',
      open_orders: 'market/getopenorders?market=%s'
    }
  }.freeze

  def get_url(params)
    url = BASE_URL + URIs[params[:api_type].to_sym][params[:action].to_sym]
    case params[:action]
    when 'buy'
      url = sprintf(url, params[:market], params[:quantity], params[:rate])
    when 'sell'
      url = sprintf(url, params[:market], params[:quantity], params[:rate])
    when 'cancel_by_uuid'
      url = sprintf(url, params[:uuid])
    when 'open_orders', 'market_ticker', "market_day_summary", "last_trades", "market_orders_history"
      url = sprintf(url, params[:market])
    when 'currency_balance', 'deposit_address'
      url = sprintf(url, params[:currency])
    when 'order_book'
      url = sprintf(url, params[:market], params[:order_type])
    end
    nonce = Time.now.to_i.to_s
    url += "&apikey=#{API_KEY}&nonce=#{nonce}" if %w(market account).include? params[:api_type]
    url
  end

  def hmac_sha256(msg, key)
    digest = OpenSSL::Digest.new('sha512')
    OpenSSL::HMAC.hexdigest(digest, key, msg)
  end

  def call_api(url)
    response = RestClient.get(url)
    parsed_body = JSON.parse(response.body)
    #puts "Fetching ...#{url}"
    #puts (parsed_body['success'] ? 'Success' : 'Failed')
    parsed_body['result'] if parsed_body['success']
  end

  def call_secret_api(url)
    sign = hmac_sha256(url, API_SECRET)
    response = RestClient.get(url, apisign: sign)
    parsed_body = JSON.parse(response.body)
  
    #puts (parsed_body['success'] ? 'Success' : 'Failed'.red)
    parsed_body['result'] if parsed_body['success']
  end

  def call_tor_api(url)
    headers = { 'User-Agent' => 'Windows / Firefox 32: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:26.0) Gecko/20100101 Firefox/32.0'}
    browser = Mechanize.new
    browser.agent.set_socks('localhost', 9050)

    resp =browser.get(url,headers).body
    puts "Fetching[tor] ...#{url}"
    JSON.parse(resp)['result']
  end

  ##--------------call api
  def get_order_book(market_name, order_type = 'both')
    url = get_url(api_type: 'public', action: 'order_book', market: market_name, order_type: order_type)
    orders = call_api(url)
    # orders.map { |oo| oo["Quantity"]  }
  end

  def get_last_trades(market_name)
    url = get_url(api_type: 'public', action: 'last_trades', market: market_name)
    orders = call_api(url)
  end

  def get_markets_summaries(direct=true)
    url = get_url(api_type: 'public', action: 'market_day_summaries')
    data = direct ? call_api(url) : call_tor_api(url)
  end

  def get_ticker(market_name)
    url = get_url(api_type: 'public', action: 'market_ticker', market: market_name)
    #data = direct ? call_api(url) : call_tor_api(url)
    call_api(url)
  end

  ##--------ACCOUNT

  def get_balances
    url = get_url({api_type: 'account', action: 'balance'})
    data = call_secret_api(url)
  end
  def get_currency_balance(currency)
    url = get_url({api_type: 'account', action: 'currency_balance', currency:currency})
    data = call_secret_api(url)
  end  
  
  def get_order_history
    url = get_url(api_type: 'account', action: 'orders_history')
    data = call_secret_api(url)
  end
  def market_orders_history(market_name)
    url = get_url(api_type: 'account', action: 'market_orders_history', market: market_name)
    data = call_secret_api(url)
  end 
  ##--------MARKET

  def get_open_orders(market_name)
    url = get_url(api_type: 'market', action: 'open_orders', :market => market_name)
    data = call_secret_api(url)
  end

  def buy(market_name,q,r)
    url = get_url(api_type: 'market', action: 'buy', market: market_name, quantity:q, rate:r)
    data = call_secret_api(url)
  end
  def sell(market_name,q,r)
    url = get_url(api_type: 'market', action: 'sell', market: market_name, quantity:q, rate:r)
    data = call_secret_api(url)
  end
  def cancel(uuid)
    url = get_url(api_type: 'market', action: 'cancel_by_uuid', uuid: uuid)
    data = call_secret_api(url)
  end

end
