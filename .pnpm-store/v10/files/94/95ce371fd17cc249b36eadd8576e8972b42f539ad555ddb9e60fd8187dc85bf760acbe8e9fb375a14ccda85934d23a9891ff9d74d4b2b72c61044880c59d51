class Turbolinks.SnapshotCache
  constructor: (@size) ->
    @keys = []
    @snapshots = {}

  has: (location) ->
    key = keyForLocation(location)
    key of @snapshots

  get: (location) ->
    return unless @has(location)
    snapshot = @read(location)
    @touch(location)
    snapshot

  put: (location, snapshot) ->
    @write(location, snapshot)
    @touch(location)
    snapshot

  # Private

  read: (location) ->
    key = keyForLocation(location)
    @snapshots[key]

  write: (location, snapshot) ->
    key = keyForLocation(location)
    @snapshots[key] = snapshot

  touch: (location) ->
    key = keyForLocation(location)
    index = @keys.indexOf(key)
    @keys.splice(index, 1) if index > -1
    @keys.unshift(key)
    @trim()

  trim: ->
    for key in @keys.splice(@size)
      delete @snapshots[key]

  keyForLocation = (location) ->
    Turbolinks.Location.wrap(location).toCacheKey()
