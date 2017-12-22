require "rest-client"
require "json"
require 'dotenv'
#require_relative 'db_util'


Dotenv.load('.env')

BASE_URL = "https://bitgrail.com/api/v1"
API_KEY = ENV["Key"]
API_SECRET = ENV["Secret"]

def call_api(url)
  response = RestClient.get(url)
  parsed_body = JSON.parse(response.body)
  #puts "Fetching ..."
  parsed_body
end
#tETHUSD tBTCUSD tEOSETH

def ticker(symb)
  url = "#{BASE_URL}/#{symb}/ticker"
  parsed_body = call_api(url)
  parsed_body['response'] if parsed_body['success']
end

def get_order_book(symb)
  url = "#{BASE_URL}/#{symb}/orderbook"
  parsed_body = call_api(url)
  parsed_body['response'] if parsed_body['success']
  
end


def trades(symb)
  url = "#{BASE_URL}/trades/#{symb}/hist"
  trades = call_api(url)
end

