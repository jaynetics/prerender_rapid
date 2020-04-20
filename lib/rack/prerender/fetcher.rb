require 'zlib'

module Rack
  class Prerender
    class Fetcher
      attr_reader :env, :options

      def initialize(options = {})
        @options = options
      end

      # Entry point for automatic fetching via the middleware.
      def call(env)
        cached_response = before_render(env)
        return cached_response.finish if cached_response

        if prerendered_response = fetch_env(env)
          response = build_rack_response_from_prerender(prerendered_response)
          after_render(env, prerendered_response)
          return response.finish
        end

        nil
      end

      # Entry point for manual fetching. Does not run callbacks.
      def fetch(arg)
        case arg
        when String, Symbol, URI then fetch_url(arg.to_s)
        when Hash                then fetch_env(arg)
        when Rack::Request       then fetch_env(arg.env)
        else
          if defined?(ActiveModel::Naming) && ActiveModel::Naming === arg.class
            record_url = Rails.application.routes.url_helpers.url_for(arg)
            fetch_url(record_url)
          else
            raise ArgumentError,
                  "expected URL, Request, env or record, got #{arg.class}"
          end
        end
      end

      def before_render(env)
        return unless callback = options[:before_render]

        cached_render = callback.call(env)

        if cached_render && cached_render.is_a?(String)
          Rack::Response.new(cached_render, 200, { 'Content-Type' => 'text/html; charset=utf-8' })
        elsif cached_render && cached_render.is_a?(Rack::Response)
          cached_render
        else
          nil
        end
      end

      def fetch_env(env)
        fetch_url(request_url(env), as: env['HTTP_USER_AGENT'])
      end

      def fetch_url(url, as: nil)
        uri = try_uri_parse(api_url(url))
        uri && fetch_api_uri(uri, as: as)
      end

      def try_uri_parse(url)
        URI.parse(url)
      rescue URI::InvalidURIError
        nil
      end

      # This is just horrible, but replacing net/http would break compatibility
      # because the response object is leaked to several callbacks :(
      def fetch_api_uri(uri, as: nil)
        req = Net::HTTP::Get.new(uri.request_uri, headers(user_agent: as))
        if options[:basic_auth]
          req.basic_auth(ENV['PRERENDER_USERNAME'], ENV['PRERENDER_PASSWORD'])
        end
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        response = http.request(req)
        decompress(response)
      rescue
        nil
      end

      def api_url(url)
        if service_url.match?(/[=\/]$/)
          "#{service_url}#{url}"
        else
          "#{service_url}/#{url}"
        end
      end

      def service_url
        options[:prerender_service_url] || ENV['PRERENDER_SERVICE_URL'] ||
          'http://service.prerender.io'
      end

      def headers(user_agent: nil)
        {
          'Accept-Encoding'   => 'gzip',
          'User-Agent'        => user_agent,
          'X-Prerender-Token' => token,
        }.compact
      end

      def token
        options[:prerender_token] || ENV['PRERENDER_TOKEN']
      end

      def request_url(env)
        if env['CF-VISITOR'] && protocol = env['CF-VISITOR'][/"scheme":"(http|https)"/, 1]
          configure_protocol(env, protocol)
        end

        if env['X-FORWARDED-PROTO'] && protocol = env["X-FORWARDED-PROTO"].split(',')[0]
          configure_protocol(env, protocol)
        end

        if protocol = options[:protocol]
          configure_protocol(env, protocol)
        end

        Rack::Request.new(env).url
      end

      def configure_protocol(env, protocol)
        return unless protocol == 'http' || protocol == 'https'

        env['rack.url_scheme'] = protocol
        env['HTTPS']           = protocol == 'https'
        env['SERVER_PORT']     = protocol == 'https' ? 443 : 80
      end

      def decompress(response)
        if response['Content-Encoding'] == 'gzip'
          response.body =
            Zlib::GzipReader.wrap(StringIO.new(response.body), &:read)
          response['Content-Length'] = response.body.bytesize
          response.delete('Content-Encoding')
          response.delete('Transfer-Encoding')
        end
        response
      end

      def build_rack_response_from_prerender(prerendered_response)
        response = Rack::Response.new(
          prerendered_response.body,
          prerendered_response.code,
          prerendered_response,
        )
        if callback = options[:build_rack_response_from_prerender]
          callback.call(response, prerendered_response)
        end
        response
      end

      def after_render(env, response)
        (callback = options[:after_render]) && callback.call(env, response)
      end
    end
  end
end
