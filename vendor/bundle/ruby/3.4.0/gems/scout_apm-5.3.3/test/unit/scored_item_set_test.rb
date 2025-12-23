require 'test_helper'

require 'scout_apm/scored_item_set'

class FakeScoredItem
  def initialize(name, score)
    @name = name
    @score = score
  end
  def name; @name; end
  def score; @score; end
  def call; "called_#{@score}_#{@name}"; end
end

class ScoredItemSetTest < Minitest::Test
  def test_empty_set_always_adds_item
    set = ScoutApm::ScoredItemSet.new
    set << FakeScoredItem.new("users/index", 10)

    assert_equal set.to_a.first, "called_10_users/index"
    assert_equal set.count, 1
  end

  def test_repeated_additions_chooses_most_expensive
    set = ScoutApm::ScoredItemSet.new

    [ FakeScoredItem.new("users/index", 10),
      FakeScoredItem.new("users/index", 11),
      FakeScoredItem.new("users/index", 12)
    ].shuffle.each { |fsi| set << fsi }

    assert_equal set.to_a.first, "called_12_users/index"
    assert_equal set.count, 1
  end

  def test_multiple_items_occupy_different_buckets
    set = ScoutApm::ScoredItemSet.new

    [ FakeScoredItem.new("users/index", 10),
      FakeScoredItem.new("users/index", 11),
      FakeScoredItem.new("users/show", 12),
      FakeScoredItem.new("users/show", 10)
    ].shuffle.each { |fsi| set << fsi }

    assert_equal set.count, 2
    assert set.to_a.include?("called_11_users/index")
    assert set.to_a.include?("called_12_users/show")
  end

  def test_evicts_at_capacity
    set = ScoutApm::ScoredItemSet.new(3) # Force max_size to 3

    [ FakeScoredItem.new("users/index", 10),
      FakeScoredItem.new("users/show", 11),
      FakeScoredItem.new("posts/index", 12),
      FakeScoredItem.new("posts/move", 13)
    ].shuffle.each { |fsi| set << fsi }

    assert_equal set.count, 3
    assert !set.to_a.include?("called_10_users/index"), "Did not Expect to see users/index in #{set.to_a.inspect}"
    assert set.to_a.include?("called_11_users/show"),   "Expected to see users/show in #{set.to_a.inspect}"
    assert set.to_a.include?("called_12_posts/index"),  "Expected to see posts/index in #{set.to_a.inspect}"
    assert set.to_a.include?("called_13_posts/move"),   "Expected to see posts/move in #{set.to_a.inspect}"
  end
end
