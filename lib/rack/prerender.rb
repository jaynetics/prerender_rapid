module Rack
  class Prerender
    require 'net/http'
    require_relative 'prerender/constraint'
    require_relative 'prerender/fetcher'
    require_relative 'prerender/recacher'
    require_relative 'prerender/version'

    attr_accessor :app, :constraint, :fetcher

    def initialize(app, options = {})
      @app        = app
      @constraint = Constraint.new(options)
      @fetcher    = Fetcher.new(options)
      @@options   = options
    end

    def call(env)
      constraint.matches?(env) && fetcher.call(env) || app.call(env)
    end

    # utility methods

    def self.fetch(arg, **options)
      Fetcher.new(@@options.to_h.merge(options)).fetch(arg)
    end

    def self.recache_now(url, **options)
      Recacher.new(@@options.to_h.merge(options)).call(url)
    end

    def self.recache_later(url, **options)
      # require on demand, so ActiveJob/Sidekiq can come later in load order
      require_relative 'prerender/recache_job'
      RecacheJob.perform_later(url, @@options.to_h.merge(options))
    end
  end
end
