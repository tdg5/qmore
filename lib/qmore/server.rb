require 'qmore'
require 'reqless'

module Qmore
  module Server

    Attr = Qmore::Attributes

    def self.registered(app)

      app.helpers do

        def qmore_view(filename, options = {}, locals = {})
          options = {:layout => true, :locals => { :title => filename.to_s.capitalize }}.merge(options)
          dir = File.expand_path("../server/views/", __FILE__)
          erb(File.read(File.join(dir, "#{filename}.erb")), options, locals)
        end

        alias :original_tabs :tabs
        def tabs
          qmore_tabs = [
              {:name => 'DynamicQueues', :path => '/dynamicqueues'},
              {:name => 'QueuePriority', :path => '/queuepriority'}
          ]
          queue_tab_index = original_tabs.index {|t| t[:name] == 'Queues' }
          original_tabs.insert(queue_tab_index + 1, *qmore_tabs)
        end

      end

      #
      # Dynamic queues
      #

      app.get "/dynamicqueues" do
        @queues = []
        real_queues = Qmore.client.queues.counts.collect {|q| q['name'] }

        dqueues = Qmore.persistence.get_queue_identifier_patterns
        dqueues.each do |k, v|
          expanded = Attr.expand_queues(["@#{k}"], real_queues)
          expanded = expanded.collect { |q| q.split(":").last }
          view_data = {
              'name' => k,
              'value' => Array(v).join(", "),
              'expanded' => expanded.join(", ")
          }
          @queues << view_data
        end

        @queues.sort! do |a, b|
          an = a['name']
          bn = b['name']
          if an == 'default'
            1
          elsif bn == 'default'
            -1
          else
            an <=> bn
          end
        end

        qmore_view :dynamicqueues
      end

      app.post "/dynamicqueues" do
        queues = params['queues']
        dynamic_queues = {}
        queues.each do |queue|
          values = queue['value'].to_s.split(',').collect { |q| q.gsub(/\s/, '') }
          dynamic_queues[queue['name']] = values
        end

        Qmore.configuration.dynamic_queues = dynamic_queues
        Qmore.persistence.set_queue_identifier_patterns(dynamic_queues)
        redirect to("/dynamicqueues")
      end

      #
      # Queue priorities
      #

      app.get "/queuepriority" do
        # For the UI we always want the latest persisted data
        @priorities = Qmore.persistence.get_queue_priority_patterns.map do |priority_pattern|
          {
            'fairly' => priority_pattern.should_distribute_fairly,
            'pattern' => priority_pattern.pattern.join(', '),
          }
        end
        qmore_view :priorities
      end

      app.post "/queuepriority" do
        priorities = params['priorities']
        priority_patterns = priorities.map do |priority_pattern|
          fairly = priority_pattern.fetch('fairly', 'false')
          should_distribute_fairly = fairly == true || fairly == 'true'
          Reqless::QueuePriorityPattern.new(
            priority_pattern['pattern'].to_s.split(',').collect { |q| q.gsub(/\s/, '') },
            should_distribute_fairly,
          )
        end
        Qmore.configuration.priority_buckets = priority_patterns
        Qmore.persistence.set_queue_priority_patterns(priority_patterns)

        redirect to("/queuepriority")
      end
    end
  end
end
