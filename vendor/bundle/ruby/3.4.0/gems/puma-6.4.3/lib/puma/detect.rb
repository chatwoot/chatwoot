# frozen_string_literal: true

# This file can be loaded independently of puma.rb, so it cannot have any code
# that assumes puma.rb is loaded.


module Puma
  # @version 5.2.1
  HAS_FORK = ::Process.respond_to? :fork

  HAS_NATIVE_IO_WAIT = ::IO.public_instance_methods(false).include? :wait_readable

  IS_JRUBY = Object.const_defined? :JRUBY_VERSION

  IS_OSX = RUBY_DESCRIPTION.include? 'darwin'

  IS_WINDOWS = RUBY_DESCRIPTION.match?(/mswin|ming|cygwin/)

  IS_LINUX = !(IS_OSX || IS_WINDOWS)

  # @version 5.2.0
  IS_MRI = RUBY_ENGINE == 'ruby'

  def self.jruby?
    IS_JRUBY
  end

  def self.osx?
    IS_OSX
  end

  def self.windows?
    IS_WINDOWS
  end

  # @version 5.0.0
  def self.mri?
    IS_MRI
  end

  # @version 5.0.0
  def self.forkable?
    HAS_FORK
  end
end
