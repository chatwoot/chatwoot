# frozen_string_literal: true

module Kernel
  module_function

  # Zeitwerk's main idea is to define autoloads for project constants, and then
  # intercept them when triggered in this thin `Kernel#require` wrapper.
  #
  # That allows us to complete the circle, invoke callbacks, autovivify modules,
  # define autoloads for just autoloaded namespaces, update internal state, etc.
  #
  # On the other hand, if you publish a new version of a gem that is now managed
  # by Zeitwerk, client code can reference directly your classes and modules and
  # should not require anything. But if someone has legacy require calls around,
  # they will work as expected, and in a compatible way. This feature is by now
  # EXPERIMENTAL and UNDOCUMENTED.
  alias_method :zeitwerk_original_require, :require
  class << self
    alias_method :zeitwerk_original_require, :require
  end

  # @sig (String) -> true | false
  def require(path)
    if loader = Zeitwerk::Registry.loader_for(path)
      if path.end_with?(".rb")
        required = zeitwerk_original_require(path)
        loader.__on_file_autoloaded(path) if required
        required
      else
        loader.__on_dir_autoloaded(path)
        true
      end
    else
      required = zeitwerk_original_require(path)
      if required
        abspath = $LOADED_FEATURES.last
        if loader = Zeitwerk::Registry.loader_for(abspath)
          loader.__on_file_autoloaded(abspath)
        end
      end
      required
    end
  end

  # By now, I have seen no way so far to decorate require_relative.
  #
  # For starters, at least in CRuby, require_relative does not delegate to
  # require. Both require and require_relative delegate the bulk of their work
  # to an internal C function called rb_require_safe. So, our require wrapper is
  # not executed.
  #
  # On the other hand, we cannot use the aliasing technique above because
  # require_relative receives a path relative to the directory of the file in
  # which the call is performed. If a wrapper here invoked the original method,
  # Ruby would resolve the relative path taking lib/zeitwerk as base directory.
  #
  # A workaround could be to extract the base directory from caller_locations,
  # but what if someone else decorated require_relative before us? You can't
  # really know with certainty where's the original call site in the stack.
  #
  # However, the main use case for require_relative is to load files from your
  # own project. Projects managed by Zeitwerk don't do this for files managed by
  # Zeitwerk, precisely.
end
