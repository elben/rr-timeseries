Timeseries for Redis
===================

Guide
===================

You specify a timestep in seconds:

  # Create a timeseries with a 5 second granuality
  ts = Timeseries(redis, "my_timeseries", timestep=5)

Then, you increment counters:

  ts.incr("user1_clicks")
  ts.decr("user1_points")

You can get the value, at a given time:

  ts.get("user1_clicks", Time.now)
  ts.get("user1_clicks", 5.years.ago)

How does it work? It's pretty simple, and borrows a lot of ideas from antirez's
ruby timeseries library. The redis key is calculated like this:

  t = Time.now - (Time.now % timestep)
  "tseries:YOUR_LABEL:t"

And the value is a hash, where the keys of the hash are the labels you pass in
to ts.incr, and the values are counts.

Notes
===================

Round-robining is on the roadmap but is not implemented. Triming does not work
properly.
