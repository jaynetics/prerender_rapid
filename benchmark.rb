require 'benchmark/ips'
require 'prerender_rails'
require 'rack' # comes last because prerender_rails needs an old version

PrerenderRails = Rack::Prerender.dup

Rack.send(:remove_const, :Prerender)

require_relative 'lib/rack/prerender'

OLD = PrerenderRails.new(nil, whitelist: ['/search', '/users/.*/profile'], blacklist: ['/badguy'])
NEW = Rack::Prerender.new(nil, whitelist: ['/search', '/users/.*/profile'], blacklist: ['/badguy'])

REQUEST_ENV = {
  'HTTP_REFERER'    => 'https://www.disney.com',
  'HTTP_USER_AGENT' => 'Mozilla/5.0 (Linux; Android 8.0.0; SAMSUNG SM-N9500 Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/7.4 Chrome/59.0.3071.125 Mobile Safari/537.36',
  'REQUEST_METHOD'  => 'GET',
}

Benchmark.ips do |x|
  x.report('prerender_rails', 'OLD.should_show_prerendered_page(REQUEST_ENV)')
  x.report('rack-prerender',  'NEW.constraint.matches?(REQUEST_ENV)')
  x.compare!
end
