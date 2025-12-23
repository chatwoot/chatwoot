require 'test_helper'

require 'scout_apm/git_revision'

class GitRevisionTest < Minitest::Test
  # TODO - other tests that would be nice:
  # * ensure we only detect once, on initialize.
  # * tests for reading cap files

  def test_sha_from_heroku
    ENV['HEROKU_SLUG_COMMIT'] = 'heroku_slug'
    revision = ScoutApm::GitRevision.new(ScoutApm::AgentContext.new)
    assert_equal 'heroku_slug', revision.sha
  end
end
