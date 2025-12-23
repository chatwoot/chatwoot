lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "datadog/appsec/waf/version"

Gem::Specification.new do |spec|
  spec.name = "libddwaf"
  spec.version = Datadog::AppSec::WAF::VERSION::STRING
  spec.required_ruby_version = [">= #{Datadog::AppSec::WAF::VERSION::MINIMUM_RUBY_VERSION}"]
  spec.required_rubygems_version = ">= 2.0.0"
  spec.authors = ["Datadog, Inc."]
  spec.email = ["dev@datadoghq.com"]

  spec.summary = "Datadog WAF"
  spec.description = <<-EOS.gsub(/^[\s]+/, "")
    libddwaf packages a WAF implementation in C++, exposed to Ruby
  EOS

  spec.homepage = "https://github.com/DataDog/libddwaf-rb"
  spec.license = "BSD-3-Clause"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  libddwaf_version = Datadog::AppSec::WAF::VERSION::BASE_STRING

  spec.files = ["libddwaf.gemspec"]
  spec.files.concat(Dir.glob("lib/**/*.rb"))
  spec.files.concat(Dir.glob("{vendor/rbs,sig}/**/*.rbs"))
  spec.files.concat(Dir.glob("{README,CHANGELOG,LICENSE,NOTICE}*"))
  spec.files.concat(%W[
    vendor/libddwaf/libddwaf-#{libddwaf_version}-darwin-arm64/lib/libddwaf.dylib
    vendor/libddwaf/libddwaf-#{libddwaf_version}-darwin-x86_64/lib/libddwaf.dylib
    vendor/libddwaf/libddwaf-#{libddwaf_version}-linux-aarch64/lib/libddwaf.so
    vendor/libddwaf/libddwaf-#{libddwaf_version}-linux-x86_64/lib/libddwaf.so
  ])

  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.0"
end
