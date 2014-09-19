module Rack
  module Trace
    class Collector
      def initialize
        begin_trace
      end

      def stop
        trace_point.disable
        allocation_stats.stop
      end

      def statistics
        @statistics ||= call_counts.dup.tap do |statistics|
          statistics[:allocations] = allocation_stats.allocations.count
          statistics[:allocated_memory] = allocation_stats.allocations.sum(&:memsize)
          allocation_stats.allocations.group_by(:class).each do |klass, allocations|
            statistics[klass] = {} if !statistics.has_key? klass
            statistics[klass][:allocations] = allocations.count
            statistics[klass][:allocated_memory] = allocations.sum(&:memsize)
          end
        end
      end

      private

      attr_reader :trace_point, :allocation_stats

      def call_counts
        @call_counts ||= Hash.new(0)
      end

      def begin_trace
        begin_call_trace
        begin_allocation_trace
      end

      CALL_EVENTS = [:call, :c_call]

      def begin_call_trace
        @trace_point = TracePoint.trace(:call, :c_call, :raise) do |t|
          if CALL_EVENTS.include? t.event
            call_counts[:total_calls] += 1
            call_counts[t.defined_class] = Hash.new(0) if !call_counts.has_key? t.defined_class
            call_counts[t.defined_class][:total_calls] += 1
            call_counts[t.defined_class][t.method_id] += 1
          elsif t.event == :raise
            call_counts[:exceptions] += 1
          end
        end
      end

      def begin_allocation_trace
        @allocation_stats = AllocationStats.trace
        puts "beginning trace"
      end
    end
  end
end