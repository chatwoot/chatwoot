module Regexp::Syntax
  VERSION_FORMAT = '\Aruby/\d+\.\d+(\.\d+)?\z'
  VERSION_REGEXP = /#{VERSION_FORMAT}/
  VERSION_CONST_REGEXP = /\AV\d+_\d+(?:_\d+)?\z/

  class InvalidVersionNameError < Regexp::Syntax::SyntaxError
    def initialize(name)
      super "Invalid version name '#{name}'. Expected format is '#{VERSION_FORMAT}'"
    end
  end

  class UnknownSyntaxNameError < Regexp::Syntax::SyntaxError
    def initialize(name)
      super "Unknown syntax name '#{name}'."
    end
  end

  module_function

  # Returns the syntax specification class for the given syntax
  # version name. The special names 'any' and '*' return Syntax::Any.
  def for(name)
    (@alias_map ||= {})[name] ||= version_class(name)
  end

  def new(name)
    warn 'Regexp::Syntax.new is deprecated in favor of Regexp::Syntax.for. '\
         'It does not return distinct instances and will be removed in v3.0.0.'
    self.for(name)
  end

  def supported?(name)
    name =~ VERSION_REGEXP && comparable(name) >= comparable('1.8.6')
  end

  def version_class(version)
    return Regexp::Syntax::Any if ['*', 'any'].include?(version.to_s)

    version =~ VERSION_REGEXP || raise(InvalidVersionNameError, version)
    version_const_name = "V#{version.to_s.scan(/\d+/).join('_')}"
    const_get(version_const_name) || raise(UnknownSyntaxNameError, version)
  end

  def const_missing(const_name)
    if const_name =~ VERSION_CONST_REGEXP
      return fallback_version_class(const_name)
    end
    super
  end

  def fallback_version_class(version)
    sorted = (specified_versions + [version]).sort_by { |ver| comparable(ver) }
    index = sorted.index(version)
    index > 0 && const_get(sorted[index - 1])
  end

  def specified_versions
    constants.select { |const_name| const_name =~ VERSION_CONST_REGEXP }
  end

  def comparable(name)
    # add .99 to treat versions without a patch value as latest patch version
    Gem::Version.new((name.to_s.scan(/\d+/) << 99).join('.'))
  end
end
