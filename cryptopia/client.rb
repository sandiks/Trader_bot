require "uri"
require "set"
require "cgi"
require "json"
require "base64"
require "net/http"
require "net/https"

def api_query( method, req = {} )
  _API_KEY = "YOUR_API_KEY"
  _API_SECRET = "YOUR_API_SECRET"

  public_set = Set[ "GetCurrencies", "GetTradePairs", "GetMarkets", "GetMarket", "GetMarketHistory", "GetMarketOrders", "GetMarketOrderGroups" ]
  private_set = Set[ "GetBalance", "GetDepositAddress", "GetOpenOrders", "GetTradeHistory", "GetTransactions", "SubmitTrade", "CancelTrade", "SubmitTip" ]
  
  if public_set.include?( method )
    url = 'https://www.cryptopia.co.nz/api/' + method
    if req
      for param in req
        url += '/' + param.to_s
      end
    end
    uri = URI( url )

    r = Net::HTTP::Get.new( uri.path, initheader = {'Content-Type' =>'application/json'})
  
  elsif private_set.include?( method )
    url = "https://www.cryptopia.co.nz/Api/" + method
    uri = URI( url )
    nonce = Time.now.to_i.to_s
    post_data = req.to_json.to_s
    
    md5 = Digest::MD5.new.digest( post_data )
    requestContentBase64String = Base64.encode64( md5 )
    signature = ( _API_KEY + "POST" + CGI::escape( url ).downcase + nonce + requestContentBase64String ).strip
    hmac_raw = OpenSSL::HMAC.digest('sha256', Base64.decode64( _API_SECRET ), signature )
    hmacsignature = Base64.encode64( OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), Base64.decode64( _API_SECRET ), signature) ).strip
    header_value = "amx " + _API_KEY + ":" + hmacsignature + ":" + nonce
    
    r = Net::HTTP::Post.new(uri.path)
    r.body = req.to_json
    r["Authorization"] = header_value
    r["Content-Type"] = "application/json; charset=utf-8"
  end

  sleep(1)
  https = Net::HTTP.new( uri.host, uri.port )
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  r["User-Agent"] = "Mozilla/4.0 (compatible; Cryptopia.co.nz API Ruby client)"
  res = https.request( r )

  parsed_body = JSON.parse(res.body)
  parsed_body['Data'] if parsed_body['Success']
end


# Public
# print api_query('GetCurrencies')
# +
# print api_query( "GetTradePairs" );
# +
# print api_query( "GetMarkets" );
# +
# print api_query( "GetMarkets", [ 6 ] );
# +
# print api_query("GetMarket", [ 100, 6 ] );
# +
# print api_query("GetMarketHistory", [ 100 ] );
# +
# print api_query("GetMarketOrders", [ 100 ] );

# Private
 #print api_query("GetBalance")

#print api_query("GetBalance", {'CurrencyId' => 2} )

