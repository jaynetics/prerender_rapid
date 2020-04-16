# Rack::Prerender

[![Gem Version](https://badge.fury.io/rb/rack-prerender.svg)](http://badge.fury.io/rb/rack-prerender)
[![Build Status](https://travis-ci.org/jaynetics/rack-prerender.svg?branch=master)](https://travis-ci.org/jaynetics/rack-prerender)

This is a fork and drop-in replacement for [prerender_rails]( https://github.com/prerender/prerender_rails ) with some improvements, most notably improved performance for non-crawlers.

### Installation

Add it to your gemfile or run

    gem install rack-prerender

### Usage

The public interface is fully compatible with `prerender_rails`, so see its [readme]( https://github.com/prerender/prerender_rails/blob/68f347b591069ad6369dc58caa8ad6e9e4f6abb8/README.md ).

The middleware class name (`Rack::Prerender`) and options are the same.

Only additive changes will be made to the interface, see `Improvements` below.

If you need to require the gem manually: `require 'rack/prerender'`

### Improvements

#### Better performance for regular users (non-bots)

About 0.07ms instead of 0.5ms lost per request in my case. See `benchmark.rb`.

#### Modular structure

You can call the service manually:
- `Rack::Prerender.fetch(my_url)` (uses token etc. from middleware setup or ENV)
- or `Rack::Prerender.fetch(my_url, prerender_token: token, ...)`
- you can pass a request or env to `#fetch` as well

You can use your own constraint or fetcher:
- `Rack::Prerender.constraint = MyBotConstraint.new`

Recaching / cache-busting functionality:
- `Rack::Prerender.recache_later(my_url)` (async, requires ActiveJob or Sidekiq)
- `Rack::Prerender.recache_now(my_url)` (sync)
- both use token from middleware setup or ENV and default API URL, to override:
- `Rack::Prerender.recache_now(my_url, prerender_recache_url: my_api_url, ...)`

More options for constraints:
- you can pass a single `Regexp` as `whitelist` or `blacklist`
- (`prerender_rails` supports only a String, or an Array of Strings or Regexps)
- you can pass Regexp(s) for `crawler_user_agents` and `extensions_to_ignore`

Directly works with the param-based URL of the prerender node app:
- e.g. `PRERENDER_SERVICE_URL=https://my-service.com/render?url=`

#### Bugfixes

- correct Content-Length for compressed pages with multibyte chars
- removes Transfer-Encoding header after result decompression
- supports recent (non-vulnerable) versions of Rack
- works without undeclared dependency `activesupport`

### Contribute

Pull requests and suggestions are welcome.
