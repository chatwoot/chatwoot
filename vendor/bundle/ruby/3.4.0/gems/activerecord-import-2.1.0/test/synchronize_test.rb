# frozen_string_literal: true

require File.expand_path('../test_helper', __FILE__)

describe ".synchronize" do
  let(:topics) { Generate(3, :topics) }
  let(:titles) { %w(one two three) }

  setup do
    # update records outside of ActiveRecord knowing about it
    Topic.connection.execute( "UPDATE #{Topic.table_name} SET title='#{titles[0]}_haha' WHERE id=#{topics[0].id}", "Updating record 1 without ActiveRecord" )
    Topic.connection.execute( "UPDATE #{Topic.table_name} SET title='#{titles[1]}_haha' WHERE id=#{topics[1].id}", "Updating record 2 without ActiveRecord" )
    Topic.connection.execute( "UPDATE #{Topic.table_name} SET title='#{titles[2]}_haha' WHERE id=#{topics[2].id}", "Updating record 3 without ActiveRecord" )
  end

  it "reloads data for the specified records" do
    Topic.synchronize topics

    actual_titles = topics.map(&:title)
    assert_equal "#{titles[0]}_haha", actual_titles[0], "the first record was not correctly updated"
    assert_equal "#{titles[1]}_haha", actual_titles[1], "the second record was not correctly updated"
    assert_equal "#{titles[2]}_haha", actual_titles[2], "the third record was not correctly updated"
  end

  it "the synchronized records aren't dirty" do
    # Update the in memory records so they're dirty
    topics.each { |topic| topic.title = 'dirty title' }

    Topic.synchronize topics

    assert_equal false, topics[0].changed?, "the first record was dirty"
    assert_equal false, topics[1].changed?, "the second record was dirty"
    assert_equal false, topics[2].changed?, "the third record was dirty"
  end

  it "ignores default scope" do
    # update records outside of ActiveRecord knowing about it
    Topic.connection.execute( "UPDATE #{Topic.table_name} SET approved='0' WHERE id=#{topics[0].id}", "Updating record 1 without ActiveRecord" )

    Topic.synchronize topics
    assert_equal false, topics[0].approved
  end
end
