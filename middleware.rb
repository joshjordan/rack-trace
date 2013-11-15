require File.expand_path('../collector', __FILE__)

module Rack
  module Trace
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        collector = Collector.new
        @app.call(env).tap do
          collector.stop
          write(collector.counts)
        end
      end

      def write(data)
        filename = "request_trace_#{Process.pid}_#{Time.now.to_formatted_s :number}.json"
        ::File.open(Rails.root.join('tmp', filename), 'w') do |f|
          f.puts data.to_json
        end
      end
    end
  end
end