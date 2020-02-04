# Rack::Prerender

[![Gem Version](https://badge.fury.io/rb/rack-prerender.svg)](http://badge.fury.io/rb/rack-prerender)
[![Build Status](https://travis-ci.org/jaynetics/rack-prerender.svg?branch=master)](https://travis-ci.org/jaynetics/rack-prerender)

This is a fork and drop-in replacement for [prerender_rails]( https://github.com/prerender/prerender_rails ) with improved performance for non-crawlers.

### Installation

Add it to your gemfile or run

    gem install rack-prerender

### When to use

If you care about ~1ms per request. I plan to maintain this, but `prerender_rails` might receive updates first.

### Usage

The public interface is fully compatible with `prerender_rails`, so see its [readme]( https://github.com/prerender/prerender_rails/blob/68f347b591069ad6369dc58caa8ad6e9e4f6abb8/README.md ).

Only additive changes will be made to the interface, e.g. you can pass a `Regexp` as `whitelist` or `blacklist`, and not just a String with regexp contents.

The middleware class name (`Rack::Prerender`) and options are the same.

If you need to require it manually: `require 'rack/prerender'`
