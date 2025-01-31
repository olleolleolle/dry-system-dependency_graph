require_relative './graph_builder'

module Dry
  module System
    module DependencyGraph
      class Base
        attr_reader :graph_builder, :dependencies_calls

        def initialize(container, graph_builder: Dry::System::DependencyGraph::GraphBuilder.new)
          @events = {}
          @container = container
          @notifications = container[:notifications]
          @graph_builder = graph_builder
          @dependencies_calls = {}

          register_subscribers
        end

        def graph
          @dependency_graph ||= graph_builder.call(@events)

          @dependency_graph.each_graph do |scope_name, g|
            g.each_node do |name, node|
              label = node[:label].to_s.gsub( "\"", "" )
              node[:tooltip] = "Calls count: #{dependencies_calls[label]}"
            end
          end

          @dependency_graph
        end

        def enable_realtime_calls!
          keys_for_monitoring.each do |key|
            dependencies_calls[key] = 0 
            @container.monitor(key) { |_event| dependencies_calls[key] += 1  }
          end
        end

      private

        def register_subscribers
          @events[:resolved_dependency] ||= []
          @events[:registered_dependency] ||= []

          @notifications.subscribe(:resolved_dependency) do |event|
            @events[:resolved_dependency] << event.to_h
          end

          @notifications.subscribe(:registered_dependency) do |event|
            @events[:registered_dependency] << event.to_h
          end
        end

        def keys_for_monitoring
          @container.keys - [:dependency_graph, 'dependency_graph', :notifications, 'notifications']
        end
      end
    end
  end
end
