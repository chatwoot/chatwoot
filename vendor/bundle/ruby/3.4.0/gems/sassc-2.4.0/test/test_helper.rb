# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "minitest/around/unit"
require "test_construct"
require "pry"

require "sassc"

module FixtureHelper
  FIXTURE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))

  def fixture(path)
    IO.read(fixture_path(path))
  end

  def fixture_path(path)
    if path.match(FIXTURE_ROOT)
      path
    else
      File.join(FIXTURE_ROOT, path)
    end
  end
end

module TempFileTest
  include TestConstruct::Helpers

  def around
    within_construct do |construct|
      @construct = construct
      yield
    end
    @construct = nil
  end

  def temp_file(filename, contents)
    @construct.file(filename, contents)
  end

  def temp_dir(directory)
    @construct.directory(directory)
  end
end
