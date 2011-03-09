class Timeseries
  def initialize(redis, label, timestep=60)
    @redis = redis
    @label = label
    @timestep = timestep
  end

  def incr(field)
    incrby(field, 1)
  end
  
  def incrby(field, n)
    t = Time.now
    @redis.hincrby(getkey(t), field, n)
  end

  def get(field, start_time=nil)
    start_time ||= Time.now
    normalize_count(@redis.hget(getkey(start_time), field))
  end

  def get_last(field)
    t = Time.now
    t_prev = t - @timestep
    normalize_count(@redis.hget(getkey(t_prev), field))
  end

private

  def getkey(time)
    "tseries:#{@label}:#{normalize_time time}"
  end

  def normalize_time(time)
    t = time.to_i
    t - (t % @timestep)
  end
  
  def normalize_count(count)
      count.to_i # if nil, we get 0
  end
end
