require 'faraday'
require 'base64'
require 'json'

module BG
  class Client
    HOST = 'https://bitgrail.com/api/v1/'

    attr_reader :key, :secret

    def initialize(attrs = {})
      @key    = attrs[:key]
      @secret = attrs[:secret]
    end

    def get(path, params = {}, headers = {})
      response = connection.get do |req|
        url = "#{HOST}#{path}"
        req.params.merge!(params)
        req.url(url)
      end

      if response.body!=""
        resp = JSON.parse(response.body)
        resp['response'] if resp['success']==1
      end 
    end

    def post(path, params = {}, headers = {})
      nonce = Time.now.to_i
      response = connection.post do |req|
        url = "#{HOST}#{path}"
        req.url(url)
    
        if key
          #post_data = params.merge({nonce: nonce})
          post_data = params.merge({nonce: nonce})
          encode_data = URI.encode_www_form(post_data)

          req.headers['KEY'] = key
          req.headers['SIGNATURE'] = signature(encode_data)
          
          req.body = post_data
          #params.each { |k,v| req.params[k] = v }

        end
      end
      

      if response.body!=""
        resp = JSON.parse(response.body)
        resp['response'] if resp['success']==1
      end 
    end

    private

    def signature(payload)
      OpenSSL::HMAC.hexdigest('sha512', secret, payload)
    end

    def connection
      @connection ||= Faraday.new(:url => HOST) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
    end
  end
end
