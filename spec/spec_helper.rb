require 'rspec'
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

require 'qmore'

def dump_redis
  result = {}
  redis = Qmore.client.redis
  redis.keys("*").each do |key|
    type = redis.type(key)
    result["#{key} (#{type})"] = case type
      when 'string' then redis.get(key)
      when 'list' then redis.lrange(key, 0, -1)
      when 'zset' then redis.zrange(key, 0, -1, :with_scores => true)
      when 'set' then redis.smembers(key)
      when 'hash' then redis.hgetall(key)
      else type
    end
  end
  return result
end

class SomeJob
  def self.perform(*args)
  end
end
