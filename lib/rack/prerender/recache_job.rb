module Rack
  class Prerender
    RecacheJob =
      if defined?(::ActiveJob::Base)
        Class.new(::ActiveJob::Base)
      elsif defined?(::Sidekiq::Worker)
        Class.new do
          include ::Sidekiq::Worker
          instance_eval { alias perform_later perform_async }
        end
      else
        raise NameError, 'requires ActiveJob or Sidekiq'
      end.class_eval do
        def perform(url, options)
          ::Rack::Prerender::Recacher.new(options).call(url)
        end
      end
  end
end
