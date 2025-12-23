require 'test_helper'

require 'scout_apm/slow_request_policy'
require 'scout_apm/slow_policy/policy'
require 'scout_apm/layer'

class FakeRequest
  def initialize(name)
    @name = name
    @root_layer = ScoutApm::Layer.new("Controller", name)
    @root_layer.instance_variable_set("@stop_time", Time.now)
  end
  def unique_name; "Controller/foo/bar"; end
  def root_layer; @root_layer; end
  def set_duration(seconds)
    @root_layer.instance_variable_set("@start_time", Time.now - seconds)
  end
end

class FixedPolicy < ScoutApm::SlowPolicy::Policy
  attr_reader :stored

  def initialize(x)
    @x = x
  end

  def call(req)
    @x
  end

  def stored!(req)
    @stored = true
  end
end

class SlowRequestPolicyTest < Minitest::Test
  def setup
    @context = ScoutApm::AgentContext.new
  end

  def test_age_policy_stored_records_current_time
    test_start = Time.now
    policy = ScoutApm::SlowPolicy::AgePolicy.new(@context)
    request = FakeRequest.new("users/index")

    policy.stored!(request)
    assert policy.last_seen[request.unique_name] > test_start
  end

  def test_sums_up_score
    policy = ScoutApm::SlowRequestPolicy.new(@context)
    request = FakeRequest.new("users/index")

    policy.add(FixedPolicy.new(1))
    policy.add(FixedPolicy.new(2))

    assert_equal 3, policy.score(request)
  end

  def test_calls_store_on_policies
    policy = ScoutApm::SlowRequestPolicy.new(@context)
    request = FakeRequest.new("users/index")

    policy.add(fp1 = FixedPolicy.new(1))
    policy.add(fp2 = FixedPolicy.new(2))
    policy.stored!(request)

    assert_equal true, fp1.stored
    assert_equal true, fp2.stored
  end

  def test_checks_new_policy_api
    policy = ScoutApm::SlowRequestPolicy.new(@context)

    assert_raises { policy.add(Object.new) }
    assert_raises { policy.add(->(req){1}) } # only implements call
  end
end
