Gem::Specification.new do |spec|
  spec.name          = "weave-core"
  spec.version       = Weave::Core::VERSION
  spec.authors       = ["WeaveCode"]
  spec.email         = ["engineering@weavecode.co.uk"]

  spec.summary       = "WeaveSmart Chat Core Engine"
  spec.description   = "Extension engine for WeaveSmart Chat (WSC) over Chatwoot core."
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    Dir['{app,config,lib}/**/*', 'README.md']
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1", "< 8.0"
end

