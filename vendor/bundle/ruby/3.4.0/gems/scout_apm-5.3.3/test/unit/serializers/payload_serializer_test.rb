require 'test_helper'
require 'json' # to deserialize what has been manually serialized by the production code

class PayloadSerializerTest < Minitest::Test
  def test_serializes_metadata_as_json
    metadata = {
      :app_root => "/srv/app/rootz",
      :unique_id => "unique_idz",
      :agent_version => 123
    }
    payload = ScoutApm::Serializers::PayloadSerializerToJson.serialize(metadata, {}, {}, [], [], [], {}, {}, [])

    # symbol keys turn to strings
    formatted_metadata = {
      "app_root" => "/srv/app/rootz",
      "unique_id" => "unique_idz",
      "agent_version" => 123,
      "payload_version" => 2
    }
    assert_equal formatted_metadata, JSON.parse(payload)["metadata"]
  end

  def test_serializes_metrics_as_json
    metrics = {
      ScoutApm::MetricMeta.new('ActiveRecord/all').tap { |meta|
        meta.desc = "SELECT * from users where filter=?"
        meta.extra = {:user => 'cooluser'}
        meta.metric_id = nil
        meta.scope = "Controller/apps/checkin"
      } => ScoutApm::MetricStats.new.tap { |stats|
        stats.call_count = 16
        stats.max_call_time = 0.005338062
        stats.min_call_time = 0.000613518
        stats.sum_of_squares = 9.8040860751126e-05
        stats.total_call_time = 0.033245704
        stats.total_exclusive_time = 0.033245704
      },
      ScoutApm::MetricMeta.new("Controller/apps/checkin").tap { |meta|
        meta.desc = nil
        meta.extra = {}
        meta.metric_id = nil
        meta.scope = nil
      } => ScoutApm::MetricStats.new.tap { |stats|
        stats.call_count = 2
        stats.max_call_time = 0.078521419
        stats.min_call_time = 0.034881757
        stats.sum_of_squares = 0.007382350213180609
        stats.total_call_time = 0.113403176
        stats.total_exclusive_time = 0.078132088
      }
    }
    payload = ScoutApm::Serializers::PayloadSerializerToJson.serialize({}, metrics, {}, [], [], [], {}, {}, [])
    formatted_metrics = [
      {
        "key" => {
          "bucket" => "ActiveRecord",
          "name" => "all",
          "desc" => "SELECT * from users where filter=?",
          "extra" => {
            "user" => "cooluser",
          },
          "scope" => {
            "bucket" => "Controller",
            "name" => "apps/checkin",
          },
        },
        "call_count" => 16,
        "max_call_time" => 0.005338062,
        "min_call_time" => 0.000613518,
        "total_call_time" => 0.033245704,
        "total_exclusive_time" => 0.033245704,
      },
      {
        "key" => {
          "bucket" => "Controller",
          "name" => "apps/checkin",
          "desc" => nil,
          "extra" => {},
          "scope" => nil,
        },
        "call_count" => 2,
        "max_call_time" => 0.078521419,
        "min_call_time" => 0.034881757,
        "total_call_time" => 0.113403176,
        "total_exclusive_time" => 0.078132088,
      }
    ]
    assert_equal formatted_metrics,
      JSON.parse(payload)["metrics"].sort_by { |m| m["key"]["bucket"] }
  end

  def test_escapes_json_quotes
    metadata = {
      :quotie => "here are some \"quotes\"",
      :payload_version => 2,
    }
    payload = ScoutApm::Serializers::PayloadSerializerToJson.serialize(metadata, {}, {}, [], [], [], {}, {}, [])

    # symbol keys turn to strings
    formatted_metadata = {
      "quotie" => "here are some \"quotes\"",
      "payload_version" => 2
    }
    assert_equal formatted_metadata, JSON.parse(payload)["metadata"]
  end

  def test_escapes_newlines
    json = { "foo" => "\bbar\nbaz\r" }
    assert_equal json, JSON.parse(ScoutApm::Serializers::PayloadSerializerToJson.jsonify_hash(json))
  end

  def test_escapes_escaped_quotes
    # Some escapes haven't ever worked on 1.8.7, and is not the issue I'm
    # fixing now. Remove this when we drop support for ancient ruby
    skip if RUBY_VERSION == "1.8.7"

    json = {"foo" => %q|`additional_details` = '{\"amount\":1}'|}
    result = ScoutApm::Serializers::PayloadSerializerToJson.jsonify_hash(json)
    assert_equal json, JSON.parse(result)
  end

  def test_escapes_various_special_characters
    # Some escapes haven't ever worked on 1.8.7, and is not the issue I'm
    # fixing now. Remove this when we drop support for ancient ruby
    skip if RUBY_VERSION == "1.8.7"

    json = {"foo" => [
      %Q|\fbar|,
      %Q|\rbar|,
      %Q|\nbar|,
      %Q|\tbar|,
      %Q|"bar|,
      %Q|'bar|,
      %Q|{bar|,
      %Q|}bar|,
      %Q|\\bar|,
      if RUBY_VERSION == '1.8.7'
        ""
      else
        %Q|\\\nbar|
      end,
    ]}

    result = ScoutApm::Serializers::PayloadSerializerToJson.jsonify_hash(json)
    assert_equal json, JSON.parse(result)
  end
end
