class Timeseries
  # Create a new Timeseries object.
  #   redis - the redis object used
  #   label - redis keys will be of the format "tseries:#{label}:..."
  #   timestep - number of seconds in a series. Pass in -1 for an infinite time
  #              step.
  #   history_size - the number of timesteps to keep around. Pass in -1 to keep
  #                  all history. Defaults to -1.
  #   auto_trim - when 
  def initialize(redis, label, timestep=60, history_size=-1, auto_trim=true)
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

    if infinite?(@timestep)
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

  # Given a time, remove the timesteps that are out of the history range.
  # Returns the latest key trimmed.
  #
  # If timesteps are skipped (e.g. if nothing happens, no keys are created),
  # then trim may not trim all old keys. This is a design problem that needs to
  # be fixed.
  def trim(time=nil)
    time ||= Time.now
    return if infinite?(@history_size)
    prev_time = normalize_time(time) - @timestep * @history_size
    first_key = getkey(prev_time)

    # Deletes older keys as long as they exist.
    loop do
      key = getkey(prev_time)
      break unless @redis.exists(key)
      @redis.del(key)
      prev_time -= @timestep
    end

    first_key
  end

  private

  def infinite?(n)
    n == -1 || n == :infinite
  end
end

