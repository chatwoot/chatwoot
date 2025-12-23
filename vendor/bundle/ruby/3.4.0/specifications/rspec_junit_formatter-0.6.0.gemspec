# -*- encoding: utf-8 -*-
# stub: rspec_junit_formatter 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec_junit_formatter".freeze
  s.version = "0.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/sj26/rspec_junit_formatter/blob/HEAD/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Cochran".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDXDCCAkSgAwIBAgIBATANBgkqhkiG9w0BAQsFADA6MQ0wCwYDVQQDDARzajI2\nMRQwEgYKCZImiZPyLGQBGRYEc2oyNjETMBEGCgmSJomT8ixkARkWA2NvbTAeFw0y\nMjA3MDQwMDQwNDZaFw0yMzA3MDQwMDQwNDZaMDoxDTALBgNVBAMMBHNqMjYxFDAS\nBgoJkiaJk/IsZAEZFgRzajI2MRMwEQYKCZImiZPyLGQBGRYDY29tMIIBIjANBgkq\nhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsr60Eo/ttCk8GMTMFiPr3GoYMIMFvLak\nxSmTk9YGCB6UiEePB4THSSA5w6IPyeaCF/nWkDp3/BAam0eZMWG1IzYQB23TqIM0\n1xzcNRvFsn0aQoQ00k+sj+G83j3T5OOV5OZIlu8xAChMkQmiPd1NXc6uFv+Iacz7\nkj+CMsI9YUFdNoU09QY0b+u+Rb6wDYdpyvN60YC30h0h1MeYbvYZJx/iZK4XY5zu\n4O/FL2ChjL2CPCpLZW55ShYyrzphWJwLOJe+FJ/ZBl6YXwrzQM9HKnt4titSNvyU\nKzE3L63A3PZvExzLrN9u09kuWLLJfXB2sGOlw3n9t72rJiuBr3/OQQIDAQABo20w\nazAJBgNVHRMEAjAAMAsGA1UdDwQEAwIEsDAdBgNVHQ4EFgQU99dfRjEKFyczTeIz\nm3ZsDWrNC80wGAYDVR0RBBEwD4ENc2oyNkBzajI2LmNvbTAYBgNVHRIEETAPgQ1z\najI2QHNqMjYuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQCsa7k3TABBcyXotr3yCq6f\nxsgbMG9FR71c4wRgVNQi9O3jN64fQBbxo//BQlHfPCjs1CeU4es9xdQFfhqXAPXG\nP7mK3+qd5jObjh6l3/rDKrTXNS+P+YO/1frlZ6xPjCA8XgGc4y0rhAjZnVBDV6t1\nkmdtEmue1s1OxaMakr78XRZDxEuAeLM5fg8MYnlOFygEcAH6lZkTjXavY7s9MXRB\nAAMioxgB6J5QhXQ42OSWIzwHZIbSv3DV9Lf5sde50HIW5f9u5jn29TUGDhSWYKkh\nLDvy9dfwMMOdIZi75Q8SBBib84AuwhMHIlUv9FcHhh3dXsDDYkrVrpUAwCsG6yCm\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2022-09-29"
  s.description = "RSpec results that your continuous integration service can read.".freeze
  s.email = "sj26@sj26.com".freeze
  s.homepage = "https://github.com/sj26/rspec_junit_formatter".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "RSpec JUnit XML formatter".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rspec-core>.freeze, [">= 2".freeze, "< 4".freeze, "!= 2.12.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.8".freeze, ">= 1.8.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<coderay>.freeze, [">= 0".freeze])
end
