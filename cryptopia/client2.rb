require 'rest-client'
require 'json'
require 'mechanize'
require_relative '../lib/socksify_mechanize'

class CtopiaApi

  BASE_URL = 'https://www.cryptopia.co.nz/api/'.freeze
  API_KEY = ''.freeze
  API_SECRET = ''.freeze

  def hmac_sha256(msg, key)
    digest = OpenSSL::Digest.new('sha512')
    OpenSSL::HMAC.hexdigest(digest, key, msg)
  end

  def get_url(part, is_account=false)
    url = "#{BASE_URL}#{part}"
   
    nonce = Time.now.to_i.to_s
    url += "&apikey=#{API_KEY}&nonce=#{nonce}" if is_account
    url
  end

  def call_api(url)
    response = RestClient.get(url)
    parsed_body = JSON.parse(response.body)
    puts "Fetching ...#{url}"
    parsed_body
    #parsed_body['result'] if parsed_body['success']
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
  def get_public_symbol; call_api(get_url("/public/symbol")); end
  
  def trade_pairs; call_api( get_url("GetTradePairs") ); end
  
  def get_public_ticker; call_api(get_url("/public/ticker")); end
  
  def get_public_ticker_sym(sym); call_api(get_url("/public/ticker/#{sym}")); end

  ##-----------------------

  def get_balances
    url = get_url(api_type: 'account', action: 'balance')
    data = call_secret_api(url)
  end

end

p CtopiaApi.new.trade_pairs