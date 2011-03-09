require 'rubygems'
require 'redis'
require 'test/unit'
require './timeseries'

class TimeseriesTest < Test::Unit::TestCase
  def setup
    redis = Redis.new(:host => 'localhost',
                       :port => 6379,
                       :db => 9,
                       :timeout => 30)
    @ts = Timeseries.new(redis, 'test', 5)
  end

  def teardown
  end

  def test_1
    t = Time.now.to_f
    puts "Running... 6 seconds."
    60.times do |n|
      @ts.incr('test_stream')
      sleep 0.1
    end

    # The unfinished timestep should finish
    last = @ts.get_last('test_stream')
    unfinished = @ts.get('test_stream')
    sleep 5 # assuming @ts is 5 seconds
    last = @ts.get_last('test_stream')
    assert unfinished == last
  end
end

