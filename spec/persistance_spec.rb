require "spec_helper"

describe "Qmore::Persistence::Monitor" do
  before(:each) do
    Qmore.client.redis.flushall
  end

  it "updates periodically based on the interval" do
    persistence = Qmore::Persistence::Reqless.new(Qmore.client)
    persistence.should_receive(:load).at_least(3)
    monitor = Qmore::Persistence::Monitor.new(persistence, 1)
    monitor.start
    sleep 4
    monitor.stop
  end
end

describe "Qmore::Persistence::Reqless" do
  before(:each) do
    Qmore.client.redis.flushall
  end


  context "dynamic queues" do
    it "can read/write dynamic queues to redis" do
      queues = {
        "key_a" => ["foo"],
        "key_b" => ["bar"],
        "key_c" => ["foo", "bar"]
      }

      configuration = Qmore::Configuration.new
      configuration.dynamic_queues = queues
      persistence = Qmore::Persistence::Reqless.new(Qmore.client)
      persistence.write(configuration)

      actual_configuration = persistence.load

      configuration.dynamic_queues.should == actual_configuration.dynamic_queues
    end
  end

  context "priorities" do
    it "can read/write priorities to redis" do
      priorities = [
        Reqless::QueuePriorityPattern.new(%w[foo*], false),
        Reqless::QueuePriorityPattern.new(%w[default], false),
      ]
      configuration = Qmore::Configuration.new
      configuration.priority_buckets = priorities

      persistence = Qmore::Persistence::Reqless.new(Qmore.client)
      persistence.write(configuration)

      actual_configuration = persistence.load
      configuration.priority_buckets.should == actual_configuration.priority_buckets
    end
  end
end

