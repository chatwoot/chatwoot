require_relative 'lib/debug/version'

Gem::Specification.new do |spec|
  spec.name          = "debug"
  spec.version       = DEBUGGER__::VERSION
  spec.authors       = ["Koichi Sasada"]
  spec.email         = ["ko1@atdot.net"]

  spec.summary       = %q{Debugging functionality for Ruby}
  spec.description   = %q{Debugging functionality for Ruby. This is completely rewritten debug.rb which was contained by the ancient Ruby versions.}
  spec.homepage      = "https://github.com/ruby/debug"
  spec.licenses      = ["Ruby", "BSD-2-Clause"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ['ext/debug/extconf.rb']

  spec.add_dependency "irb", ">= 1.5.0" # for binding.irb(show_code: false)
  spec.add_dependency "reline", ">= 0.3.1"
end
