module Rack
  module Trace
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        counter = Counter.new
        @app.call(env).tap do
          counter.stop
          write(counter.counts)
        end
      end

      def write(data)
        filename = "request_trace_#{Process.pid}_#{Time.now.to_formatted_s :number}.json"
        ::File.open(Rails.root.join('tmp', filename), 'w') do |f|
          f.puts data.to_json
        end
      end
    end

    class Counter
      def initialize
        begin_trace
      end

      def stop
        trace_point.disable
      end

      def counts
        @counts ||= Hash.new(0)
      end

      private

      CALL_EVENTS = [:call, :c_call]
      attr_reader :trace_point

      def begin_trace
        @trace_point = TracePoint.trace(:call, :c_call, :raise) do |t|
          if CALL_EVENTS.include? t.event
            counts[:total_calls] += 1
            counts[t.defined_class] = Hash.new(0) if counts[t.defined_class] == 0
            counts[t.defined_class][:total_calls] += 1
            counts[t.defined_class][t.method_id] += 1
          elsif t.event == :raise
            counts[:exceptions] += 1
          end
        end
      end
    end
  end
end