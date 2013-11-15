module Rack
  module Trace
    class Collector
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