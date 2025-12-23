# frozen_string_literal: true

require "pathname"

class Tidewave::Tools::GetPackageLocation < Tidewave::Tools::Base
  tool_name "get_package_location"

  description <<~DESCRIPTION
    Returns the location of dependency packages.
    You can use this tool to get the location of any project dependency. Optionally,
    a specific dependency name can be provided to only return the location of that dependency.
    Use the result in combination with shell tools like grep to look for specific
    code inside dependencies.
  DESCRIPTION

  arguments do
    optional(:package).maybe(:string).description(
      "The name of the package to get the location of. If not provided, the location of all packages will be returned."
    )
  end

  def call(package: nil)
    raise "get_package_location only works with projects using Bundler" unless defined?(Bundler)
    specs = Bundler.load.specs

    if package
      spec = specs.find { |s| s.name == package }
      if spec
        spec.full_gem_path
      else
        raise "Package #{package} not found. Check your Gemfile for available packages."
      end
    else
      # For all packages, return a formatted string with package names and locations
      specs.map do |spec|
        relative_path = Pathname.new(spec.full_gem_path).relative_path_from(Pathname.new(Dir.pwd))
        "#{spec.name}: #{relative_path}"
      end.join("\n")
    end
  end
end
