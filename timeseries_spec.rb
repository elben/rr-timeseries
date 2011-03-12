require 'rubygems'
require 'redis'
require 'timecop'
require './timeseries'

describe Timeseries do
  before :all do
    @redis = Redis.new(:host => 'localhost',
                       :port => 6379,
                       :db => 9,
                       :timeout => 30)
  end

  before :each do
    # TODO clear database of all 'test'
  end

  after :each do
    # So rspec will correctly calculate time spent
    Timecop.return
  end

  describe "getkey" do
    it "returns 'all_time' when timestep is infinity" do
      @ts = Timeseries.new(@redis, 'test', -1)
      @ts.getkey.should == 'tseries:test:all_time'
    end

    it "doesn't return 'all_time' when timestep not infinity" do
      @ts = Timeseries.new(@redis, 'test', 5)
      @ts.getkey.should_not == 'tseries:test:all_time'
    end

    it "returns correct key at beginning of time" do
      t = Time.now
      t_unix = t.to_i
      Timecop.freeze(t)
      @ts = Timeseries.new(@redis, 'test', 5)
      @ts.getkey.should == "tseries:test:#{t_unix - t_unix % 5}"
    end

    it "returns correct key seconds later in time" do
      t = Time.now
      Timecop.freeze(t)
      @ts = Timeseries.new(@redis, 'test', 5)
      Timecop.travel(t + 123)
      t_unix = t.to_i + 123
      @ts.getkey.should == "tseries:test:#{t_unix - t_unix % 5}"
    end
  end

  describe "normalize_count" do
    it "returns 0 if count is nil" do
      @ts = Timeseries.new(@redis, 'test', 5)
      @ts.normalize_count(nil).should == 0
    end

    it "returns n if count is n" do
      @ts = Timeseries.new(@redis, 'test', 5)
      @ts.normalize_count(1234).should == 1234
    end
  end
end

#class TimeseriesTest < Test::Unit::TestCase
  #def setup
    #redis = Redis.new(:host => 'localhost',
                       #:port => 6379,
                       #:db => 9,
                       #:timeout => 30)
    #@ts = Timeseries.new(redis, 'test', 5)
  #end

  #def teardown
  #end

  #def test_1
  #end
#end

