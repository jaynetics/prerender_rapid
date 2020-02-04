module Rack
  class Prerender
    require 'net/http'
    require_relative 'prerender/constraint'
    require_relative 'prerender/fetcher'
    require_relative 'prerender/version'

    attr_reader :app, :constraint, :fetcher

    def initialize(app, options = {})
      @app        = app
      @constraint = Constraint.new(options)
      @fetcher    = Fetcher.new(options)
    end

    def call(env)
      constraint.matches?(env) && fetcher.call(env) || app.call(env)
    end
  end
end
