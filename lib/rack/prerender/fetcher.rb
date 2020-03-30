module Rack
  class Prerender
    class Fetcher
      attr_reader :env, :options

      def initialize(options = {})
        @options = options
      end

      def call(env)
        cached_response = before_render(env)
        return cached_response.finish if cached_response

        if prerendered_response = fetch(env)
          response = build_rack_response_from_prerender(prerendered_response)
          after_render(env, prerendered_response)
          return response.finish
        end
        nil
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

      def fetch(env)
        url = URI.parse(api_url(env))
        headers = {
          'User-Agent'      => env['HTTP_USER_AGENT'],
          'Accept-Encoding' => 'gzip'
        }
        headers['X-Prerender-Token'] = ENV['PRERENDER_TOKEN'] if ENV['PRERENDER_TOKEN']
        headers['X-Prerender-Token'] = options[:prerender_token] if options[:prerender_token]
        req = Net::HTTP::Get.new(url.request_uri, headers)
        req.basic_auth(ENV['PRERENDER_USERNAME'], ENV['PRERENDER_PASSWORD']) if options[:basic_auth]
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.scheme == 'https'
        response = http.request(req)
        if response['Content-Encoding'] == 'gzip'
          response.body = ActiveSupport::Gzip.decompress(response.body)
          response['Content-Length'] = response.body.bytesize
          response.delete('Content-Encoding')
        end
        response
      rescue
        nil
      end

      def api_url(env)
        new_env = env
        if env['CF-VISITOR']
          match = /"scheme":"(http|https)"/.match(env['CF-VISITOR'])
          new_env['HTTPS'] = true and new_env['rack.url_scheme'] = "https" and new_env['SERVER_PORT'] = 443 if (match && match[1] == 'https')
          new_env['HTTPS'] = false and new_env['rack.url_scheme'] = "http" and new_env['SERVER_PORT'] = 80 if (match && match[1] == 'http')
        end

        if env['X-FORWARDED-PROTO']
          new_env['HTTPS'] = true and new_env['rack.url_scheme'] = "https" and new_env['SERVER_PORT'] = 443 if env["X-FORWARDED-PROTO"].split(',')[0] == 'https'
          new_env['HTTPS'] = false and new_env['rack.url_scheme'] = "http" and new_env['SERVER_PORT'] = 80 if env["X-FORWARDED-PROTO"].split(',')[0] == 'http'
        end

        if options[:protocol]
          new_env['HTTPS'] = true and new_env['rack.url_scheme'] = "https" and new_env['SERVER_PORT'] = 443 if options[:protocol] == 'https'
          new_env['HTTPS'] = false and new_env['rack.url_scheme'] = "http" and new_env['SERVER_PORT'] = 80 if options[:protocol] == 'http'
        end

        url = Rack::Request.new(new_env).url
        prerender_url = prerender_service_url()
        forward_slash = prerender_url[-1, 1] == '/' ? '' : '/'
        "#{prerender_url}#{forward_slash}#{url}"
      end

      def prerender_service_url
        options[:prerender_service_url] || ENV['PRERENDER_SERVICE_URL'] || 'http://service.prerender.io/'
      end

      def build_rack_response_from_prerender(prerendered_response)
        response = Rack::Response.new(prerendered_response.body, prerendered_response.code, prerendered_response)
        options[:build_rack_response_from_prerender].call(response, prerendered_response) if options[:build_rack_response_from_prerender]
        response
      end

      def after_render(env, response)
        (callback = options[:after_render]) && callback.call(env, response)
      end
    end
  end
end
