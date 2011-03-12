class Timeseries
  # Create a new Timeseries object.
  #   redis - the redis object used
  #   label - redis keys will be of the format "tseries:#{label}:..."
  #   timestep - number of seconds in a series. Pass in -1 for an infinite time
  #              step.
  def initialize(redis, label, timestep=60)
    @redis = redis
    @label = label
    @timestep = [-1, timestep].max

  end

  def incr(field)
    incrby(field, 1)
  end
  
  def incrby(field, n)
    @redis.hincrby(getkey, field, n)
  end

  # Get the count for the series at start_time.
  # By default, returns the current count.
  def get(field, start_time=nil)
    start_time ||= Time.now
    normalize_count(@redis.hget(getkey(start_time), field))
  end

  # Get the last `last` counts ordered from oldest to earliest in time.
  def get_last(field, last=1)
    t = Time.now

    if @timestep == -1
      return [normalize_count(@redis.hget(getkey(t), field))]
    end

    vals = []
    last.times do |l|
      t -= @timestep
      vals << normalize_count(@redis.hget(getkey(t), field))
    end
    vals.reverse
  end

  def getkey(time=nil)
    time ||= Time.now
    if @timestep == -1
      "tseries:#{@label}:all_time"
    else
      "tseries:#{@label}:#{normalize_time time}"
    end
  end

  def normalize_time(time)
    t = time.to_i
    t - (t % @timestep)
  end
  
  def normalize_count(count)
      count.to_i # if nil, we get 0
  end
end

