module Rack
  class Prerender
    class Recacher
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def call(cached_url)
        uri = URI(api_url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
          request.body = %({"prerenderToken":"#{token}","url":"#{cached_url}"})
          http.request(request) # => Net::HTTPResponse object
        end
      end

      def api_url
        options[:prerender_recache_url] || ENV['PRERENDER_RECACHE_URL'] ||
          'http://api.prerender.io/recache'
      end

      def token
        options[:prerender_token] || ENV['PRERENDER_TOKEN']
      end
    end
  end
end
