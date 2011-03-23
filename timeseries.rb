class Timeseries
  # Create a new Timeseries object.
  #   redis - the redis object used
  #   label - redis keys will be of the format "tseries:#{label}:..."
  #   timestep - number of seconds in a series. Pass in -1 for an infinite time
  #              step.
  #   history_size - the number of timesteps to keep around. Pass in -1 to keep
  #                  all history. Defaults to -1.
  def initialize(redis, label, timestep=60, history_size=-1)
    @redis = redis
    @label = label
    @timestep = [-1, timestep].max
    @history_size = history_size
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
    "tseries:#{@label}:#{normalize_time time}"
  end

  def normalize_time(time)
    return 'all_time' if infinite?(@timestep)
    t = time.to_i
    t - (t % @timestep)
  end
  
  def normalize_count(count)
      count.to_i # if nil, we get 0
  end

  # Given a time, remove the timestep that is one timestep out of the history
  # range. Returns the key trimmed.
  def trim(time=nil)
    time ||= Time.now
    return if infinite?(@history_size)
    prev_time = normalize_time(time) - @timestep * @history_size
    key = getkey(prev_time)
    @redis.del(key)
    key
  end

  private

  def infinite?(n)
    n == -1 || n == :infinite
  end
end

