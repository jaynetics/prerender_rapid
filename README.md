# Rack::Prerender

[![Gem Version](https://badge.fury.io/rb/rack-prerender.svg)](http://badge.fury.io/rb/rack-prerender)
[![Build Status](https://travis-ci.org/jaynetics/rack-prerender.svg?branch=master)](https://travis-ci.org/jaynetics/rack-prerender)

This is a fork of and drop-in replacement for [prerender_rails]( https://github.com/prerender/prerender_rails ) with the same public interface but significantly improved performance.

### Installation

Add it to your gemfile or run

    gem install rack-prerender
    
### Usage

See the [readme of prerender_rails]( https://github.com/prerender/prerender_rails/blob/68f347b591069ad6369dc58caa8ad6e9e4f6abb8/README.md ).

The class name (`Rack::Prerender`) and options are the same.

The only changes in the public interface are expansive ones, e.g. you can pass a `Regexp` as `whitelist` or `blacklist`, and not just a String with regexp contents.
