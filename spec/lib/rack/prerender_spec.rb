require 'spec_helper'

describe Rack::Prerender do
  let(:prerender) { Rack::Prerender.new(app) }
  let(:app)       { ->*{ [200, {}, 'live_body'] } }
  let(:bot)       { 'Baiduspider+(+http://www.baidu.com/search/spider.htm)' }
  let(:user)      { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36' }

  it 'has a VERSION number' do
    expect(Rack::Prerender::VERSION).to match(/\A\d+\.\d+\.\d+(\.\d+)?\z/)
  end

  it 'returns a prerendered response for a crawler with the returned status code and headers' do
    request = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => bot)
    stub_request(:get, prerender.fetcher.api_url(request)).with(headers: ({ 'User-Agent' => bot }))
      .to_return(body: 'prerender_body', status: 301, headers: ({ 'Location' => 'http://google.com' }))
    response = Rack::Prerender.new(app).call(request)
    expect(response[0]).to eq 301
    expect(response[1]).to eq('location' => 'http://google.com')
    expect(response[2]).to eq ['prerender_body']
  end

  it 'returns a prerendered reponse if user is a bot by checking for _escaped_fragment_' do
    request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user)
    stub_request(:get, prerender.fetcher.api_url(request)).with(headers: ({ 'User-Agent' => user }))
      .to_return(body: 'prerender_body')
    response = Rack::Prerender.new(app).call(request)
    expect(response[2]).to eq ['prerender_body']
  end

  it 'continues to app routes if the request is not a GET' do
    request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user, 'REQUEST_METHOD' => 'POST')
    response = Rack::Prerender.new(app).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'continues to app routes if user is not a bot by checking agent string' do
    request = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => user)
    response = Rack::Prerender.new(app).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'continues to app routes if contains X-Prerender header' do
    request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user, 'HTTP_X_PRERENDER' => '1')
    response = Rack::Prerender.new(app).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'continues to app routes if user is a bot, but the bot is requesting a resource file' do
    request = Rack::MockRequest.env_for('/main.js?anyQueryParam=true', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'continues to app routes if the url is not part of the regex specific whitelist' do
    request = Rack::MockRequest.env_for('/saved/search/blah?_escaped_fragment_=', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app, whitelist: ['^/search', '/help']).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'sets use_ssl to true for https prerender_service_url' do
    prerender = Rack::Prerender.new(app, prerender_service_url: 'https://service.prerender.io/')
    request = Rack::MockRequest.env_for('/search/things/123/page?_escaped_fragment_=', 'HTTP_USER_AGENT' => bot)
    stub_request(:get, prerender.fetcher.api_url(request)).to_return(body: 'prerender_body')
    response = prerender.call(request)
    expect(response[2]).to eq ['prerender_body']
  end

  it 'returns a prerendered response if the url is part of the regex specific whitelist' do
    request = Rack::MockRequest.env_for('/search/things/123/page?_escaped_fragment_=', 'HTTP_USER_AGENT' => bot)
    stub_request(:get, prerender.fetcher.api_url(request)).to_return(body: 'prerender_body')
    response = Rack::Prerender.new(app, whitelist: ['^/search.*page', '/help']).call(request)
    expect(response[2]).to eq ['prerender_body']
  end

  it 'continues to app routes if the url is part of the regex specific blacklist' do
    request = Rack::MockRequest.env_for('/search/things/123/page', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app, blacklist: ['^/search', '/help']).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'continues to app routes if the hashbang url is part of the regex specific blacklist' do
    request = Rack::MockRequest.env_for('?_escaped_fragment_=/search/things/123/page', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app, blacklist: ['/search', '/help']).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'returns a prerendered response if the url is not part of the regex specific blacklist' do
    request = Rack::MockRequest.env_for('/profile/search/blah', 'HTTP_USER_AGENT' => bot)
    stub_request(:get, prerender.fetcher.api_url(request)).to_return(body: 'prerender_body')
    response = Rack::Prerender.new(app, blacklist: ['^/search', '/help']).call(request)
    expect(response[2]).to eq ['prerender_body']
  end

  it 'continues to app routes if the referer is part of the regex specific blacklist' do
    request = Rack::MockRequest.env_for('/api/results', 'HTTP_USER_AGENT' => bot, 'HTTP_REFERER' => '/search')
    response = Rack::Prerender.new(app, blacklist: ['^/search', '/help']).call(request)
    expect(response[2]).to eq 'live_body'
  end

  it 'returns a prerendered response if the referer is not part of the regex specific blacklist' do
    request = Rack::MockRequest.env_for('/api/results', 'HTTP_USER_AGENT' => bot, 'HTTP_REFERER' => '/profile/search')
    stub_request(:get, prerender.fetcher.api_url(request)).to_return(body: 'prerender_body')
    response = Rack::Prerender.new(app, blacklist: ['^/search', '/help']).call(request)
    expect(response[2]).to eq ['prerender_body']
  end

  it 'returns a prerendered response if a string is returned from before_render' do
    request = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app, before_render: ->*{ '<html>cached</html>' }).call(request)
    expect(response[2]).to eq ['<html>cached</html>']
  end

  it 'returns a prerendered response if a response is returned from before_render' do
    request = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => bot)
    response = Rack::Prerender.new(app, before_render: ->*do
      Rack::Response.new('<html>cached2</html>', 200, 'test' => 'test2Header')
    end).call(request)
    expect(response[0]).to eq 200
    expect(response[1]).to eq('test' => 'test2Header')
    expect(response[2]).to eq ['<html>cached2</html>']
  end
end
