require 'test_helper'

require 'scout_apm/ignored_uris'

class IgnoredUrlsTest < Minitest::Test
  def test_ignores_prefix
    i = ScoutApm::IgnoredUris.new(["/slow", "/health"])
    assert_equal true, i.ignore?("/slow/foo/bar")
    assert_equal true, i.ignore?("/health?leeches=true")
  end

  def test_does_not_ignore_inner
    i = ScoutApm::IgnoredUris.new(["/slow", "/health"])
    assert_equal false, i.ignore?("/users/2/health")
  end

  def test_does_not_ignore_empty_string
    i = ScoutApm::IgnoredUris.new(["", "/admin"])
    assert_equal false, i.ignore?("/users/2/health")
    assert_equal true, i.ignore?("/admin/dashboard")
  end
end
