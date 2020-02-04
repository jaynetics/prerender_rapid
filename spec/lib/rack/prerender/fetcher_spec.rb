
require 'spec_helper'

describe Rack::Prerender::Fetcher do
  describe '#api_url' do
    it 'builds the correct api url with the default url' do
      request = Rack::MockRequest.env_for('https://google.com/search?q=javascript')
      expect(subject.api_url(request)).to eq 'http://service.prerender.io/https://google.com/search?q=javascript'
    end

    it 'builds the correct api url with an environment variable url' do
      ENV['PRERENDER_SERVICE_URL'] = 'http://prerenderurl.com'
      request = Rack::MockRequest.env_for('https://google.com/search?q=javascript')
      expect(subject.api_url(request)).to eq 'http://prerenderurl.com/https://google.com/search?q=javascript'
      ENV['PRERENDER_SERVICE_URL'] = nil
    end

    it 'builds the correct api url with an initialization variable url' do
      fetcher = Rack::Prerender::Fetcher.new(prerender_service_url: 'http://prerenderurl.com')
      request = Rack::MockRequest.env_for('https://google.com/search?q=javascript')
      expect(fetcher.api_url(request)).to eq 'http://prerenderurl.com/https://google.com/search?q=javascript'
    end

    it 'builds the correct https api url with an initialization variable url' do
      fetcher = Rack::Prerender::Fetcher.new(prerender_service_url: 'https://prerenderurl.com')
      request = Rack::MockRequest.env_for('https://google.com/search?q=javascript')
      expect(fetcher.api_url(request)).to eq 'https://prerenderurl.com/https://google.com/search?q=javascript'
    end

    it 'builds the correct api url for the Cloudflare Flexible SSL support' do
      request = Rack::MockRequest.env_for('http://google.com/search?q=javascript', 'CF-VISITOR' => '"scheme":"https"')
      expect(subject.api_url(request)).to eq 'http://service.prerender.io/https://google.com/search?q=javascript'
    end

    it 'builds the correct api url for the Heroku SSL Addon support with single value' do
      request = Rack::MockRequest.env_for('http://google.com/search?q=javascript', 'X-FORWARDED-PROTO' => 'https')
      expect(subject.api_url(request)).to eq 'http://service.prerender.io/https://google.com/search?q=javascript'
    end

    it 'builds the correct api url for the Heroku SSL Addon support with double value' do
      request = Rack::MockRequest.env_for('http://google.com/search?q=javascript', 'X-FORWARDED-PROTO' => 'https,http')
      expect(subject.api_url(request)).to eq 'http://service.prerender.io/https://google.com/search?q=javascript'
    end

    it 'builds the correct api url for the protocol option' do
      fetcher = Rack::Prerender::Fetcher.new(protocol: 'https')
      request = Rack::MockRequest.env_for('http://google.com/search?q=javascript')
      expect(fetcher.api_url(request)).to eq 'http://service.prerender.io/https://google.com/search?q=javascript'
    end
  end
end
