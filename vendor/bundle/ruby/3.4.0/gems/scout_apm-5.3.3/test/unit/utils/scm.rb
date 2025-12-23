require 'test_helper'
require 'scout_apm/utils/scm'

class ScmTest < Minitest::Test

  def test_relative_scm_path_blank
    assert_equal 'app/models/person.rb', ScoutApm::Utils::Scm.relative_scm_path('app/models/person.rb', '')
  end

  def test_relative_scm_path_not_blank
    assert_equal 'src/app/models/person.rb', ScoutApm::Utils::Scm.relative_scm_path('app/models/person.rb', 'src')
  end

  def test_relative_scm_path_not_blank_with_slashes
    assert_equal 'src/app/models/person.rb', ScoutApm::Utils::Scm.relative_scm_path('app/models/person.rb', '/src/')
  end
end
