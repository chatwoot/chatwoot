# DetailedTrace contains all details about a certain transaction, spans with
# start & stop times, tags, etc.

# {
# "version": 1,
# "identity": {
#   "transaction_id": "req-....",
#   "revision": "abcdef",
#   "start_instant": "01-01-01T00:00:00.0000Z",
#   "stop_instant": "01-01-01T00:00:01.0000Z",
#   "type": "Web",
#   "naming": {
#     "path": "/users",
#     "code": "UsersController#index",
#   },
#   "score": {
#     "total": 10.5,
#     "percentile": 4.5,
#     "age": 2.0,
#     "memory_delta": 3,
#     "allocations": 1
#   }
# },
#
# "tags": {
#   "allocations": 1000
# },
#
# "spans": [
#   ...
# ]

class DetailedTrace
  attr_reader :spans
  attr_reader :tags

  attr_reader :transaction_id
  attr_reader :revision
  attr_reader :start_instant
  attr_reader :stop_instant
  attr_reader :duration
  attr_reader :type # "Web" or "Job"
  attr_reader :host

  attr_reader :path # /users/1
  attr_reader :code # UsersController#show or similar

  attr_reader :total_score
  attr_reader :percentile_score
  attr_reader :age_score
  attr_reader :memory_delta_score
  attr_reader :memory_allocations_score

  VERSION = 1

  def initialize(transaction_id, revision, host, start_instant, stop_instant, type, path, code, spans, tags)
    @spans = spans
    @tags = DetailedTraceTags(tags)

    @transaction_id = transaction_id
    @revision = revision
    @host = host
    @start_instant = start_instant
    @stop_instant = stop_instant
    @type = type

    @path = path
    @code = code

    @total_score = 0
    @percentile_score = 0
    @age_score = 0
    @memory_delta_score = 0
    @memory_allocations_score = 0

  end

  def as_json(*)
    {
      :version => VERSION,
      :identity => {
        :transaction_id => transaction_id,
        :revision => revision,
        :host => host,
        :start_instant => start_instant.iso8601(6),
        :stop_instant => stop_instant.iso8601(6),
        :type => type,
        :naming => {
          :path => path,
          :code => code,
        },
        :score => {
          :total => total_score,
          :percentile => percentile_score,
          :age => age_score,
          :memory_delta => memory_delta_score,
          :allocations => memory_allocations_score,
        }
      },
      :tags => tags.as_json,
      :spans => spans.map{|span| span.as_json},
    }
  end

  ########################
  # Scorable interface
  #
  # Needed so we can merge ScoredItemSet instances
  def call
    self
  end

  def name
    code
  end

  def score
    @total_score
  end

end

##########
#  SPAN  #
##########

#
# {
#   "type": "Standard",
#   "identity": {
#     "id": "....",
#     "parent_id": "....",
#     "start_time": "01-01-01T00:00:00.0000Z",
#     "stop_time": "01-01-01T00:00:00.0001Z",
#     "operation": "SQL/User/find"
#   },
#   "tags": {
#     "allocations": 1000,
#     "db.statement": "SELECT * FROM users where id = 1",
#     "db.rows": 1,
#     "backtrace": [ {
#       "file": "app/controllers/users_controller.rb",
#       "line": 10,
#       "function": "index"
#     } ]
#   }
class DetailedTraceSpan
  attr_reader :tags

  attr_reader :span_type
  attr_reader :span_id, :parent_id
  attr_reader :start_instant, :stop_instant

  # What is the "name" of this span.
  #
  # Examples:
  #   SQL/User/find
  #   Controller/Users/index
  #   HTTP/GET/example.com
  attr_reader :operation

  def initialize(span_id, parent_id, start_instant, stop_instant, operation, tags)
    # This will be dynamic when we implement limited spans
    @span_type = "Standard"

    @span_id = span_id
    @parent_id = parent_id

    @start_instant = start_instant
    @stop_instant = stop_instant
    @operation = operation
    @tags = DetailedTraceTags(tags)
  end

  def as_json(*)
    {
      :type => @span_type,
      :identity => {
        :id => span_id,
        :parent_id => parent_id,
        :start_instant => start_instant.iso8601(6),
        :stop_instant => stop_instant.iso8601(6),
        :operation => operation,
      },
      :tags => @tags.as_json,
    }
  end
end


#############
#  content  #
#############

# Tags for either a request, or a span
class DetailedTraceTags
  attr_reader :tags

  def initialize(hash)
    @tags = hash
  end

  # @tags is already a hash, so no conversion needed
  def as_json(*)
    @tags
  end
end

# Converter function to turn an input into a DetailedTraceTags object
def DetailedTraceTags(arg)
  if DetailedTraceTags === arg
    arg
  elsif Hash === arg
    DetailedTraceTags.new(arg)
  end
end

