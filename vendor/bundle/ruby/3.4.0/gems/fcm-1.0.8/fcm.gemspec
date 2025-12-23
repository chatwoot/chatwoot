# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "fcm"
  s.version = "1.0.8"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Kashif Rasul", "Shoaib Burq"]
  s.email = ["kashif@decision-labs.com", "shoaib@decision-labs.com"]
  s.homepage = "https://github.com/decision-labs/fcm"
  s.summary = %q{Reliably deliver messages and notifications via FCM}
  s.description = %q{fcm provides ruby bindings to Firebase Cloud Messaging (FCM) a cross-platform messaging solution that lets you reliably deliver messages and notifications at no cost to Android, iOS or Web browsers.}
  s.license = "MIT"

  s.required_ruby_version = ">= 2.4.0"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency("faraday", ">= 1.0.0", "< 3.0")
  s.add_runtime_dependency("googleauth", "~> 1")
end
