
require 'spec_helper'

describe Rack::Prerender::Constraint do
  let(:user) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36' }
  let(:bot)  { 'Baiduspider+(+http://www.baidu.com/search/spider.htm)' }

  describe '#matches?' do
    it 'is false if the request is not a GET' do
      request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user, 'REQUEST_METHOD' => 'POST')
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if user is not a bot by checking agent string' do
      request = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => user)
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if contains X-Prerender header' do
      request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user, 'HTTP_X_PRERENDER' => '1')
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if user is a bot, but the bot is requesting a resource file' do
      request = Rack::MockRequest.env_for('/main.js?anyQueryParam=true', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if the url is not part of the whitelist' do
      subject = Rack::Prerender::Constraint.new(whitelist: ['^/search', '/help'])
      request = Rack::MockRequest.env_for('/saved/search/blah?_escaped_fragment_=', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if the url is part of the blacklist' do
      subject = Rack::Prerender::Constraint.new(blacklist: ['^/search', '/help'])
      request = Rack::MockRequest.env_for('/search/things/123/page', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if the hashbang url is part of the blacklist' do
      subject = Rack::Prerender::Constraint.new(blacklist: ['/search', '/help'])
      request = Rack::MockRequest.env_for('?_escaped_fragment_=/search/things/123/page', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq false
    end

    it 'is false if the referer is part of the blacklist' do
      subject = Rack::Prerender::Constraint.new(blacklist: ['^/search', '/help'])
      request = Rack::MockRequest.env_for('/api/results', 'HTTP_USER_AGENT' => bot, 'HTTP_REFERER' => '/search')
      expect(subject.matches?(request)).to eq false
    end

    it 'is true if the user agent is a bot' do
      request = Rack::MockRequest.env_for('/profile/blah', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq true
    end

    it 'is true if user is a bot by checking for _escaped_fragment_' do
      request = Rack::MockRequest.env_for('/path?_escaped_fragment_=', 'HTTP_USER_AGENT' => user)
      expect(subject.matches?(request)).to eq true
    end

    it 'is true if the url is part of the regex specific whitelist' do
      subject = Rack::Prerender::Constraint.new(whitelist: ['^/search.*page', '/help'])
      request = Rack::MockRequest.env_for('/search/things/123/page?_escaped_fragment_=', 'HTTP_USER_AGENT' => bot)
      expect(subject.matches?(request)).to eq true
    end

    it 'is true if the referer is not part of the regex specific blacklist' do
      subject = Rack::Prerender::Constraint.new(blacklist: ['^/search', '/help'])
      request = Rack::MockRequest.env_for('/api/results', 'HTTP_USER_AGENT' => bot, 'HTTP_REFERER' => '/profile/search')
      expect(subject.matches?(request)).to eq true
    end
  end
end
