# -*- encoding: utf-8 -*-
# stub: version_gem 1.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "version_gem".freeze
  s.version = "1.1.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://gitlab.com/oauth-xx/version_gem/-/issues", "changelog_uri" => "https://gitlab.com/oauth-xx/version_gem/-/blob/v1.1.4/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/version_gem/1.1.4", "funding_uri" => "https://liberapay.com/pboling", "homepage_uri" => "https://gitlab.com/oauth-xx/version_gem", "mailing_list_uri" => "https://groups.google.com/g/oauth-ruby", "rubygems_mfa_required" => "true", "source_code_uri" => "https://gitlab.com/oauth-xx/version_gem/-/tree/v1.1.4", "wiki_uri" => "https://gitlab.com/oauth-xx/version_gem/-/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Boling".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEgDCCAuigAwIBAgIBATANBgkqhkiG9w0BAQsFADBDMRUwEwYDVQQDDAxwZXRl\nci5ib2xpbmcxFTATBgoJkiaJk/IsZAEZFgVnbWFpbDETMBEGCgmSJomT8ixkARkW\nA2NvbTAeFw0yMzA5MjAxNzMwMjhaFw0yNDA5MTkxNzMwMjhaMEMxFTATBgNVBAMM\nDHBldGVyLmJvbGluZzEVMBMGCgmSJomT8ixkARkWBWdtYWlsMRMwEQYKCZImiZPy\nLGQBGRYDY29tMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA+a9UvHo3\n84k96WgU5Kk5HB+cLZs/modjorsTfqY67MJF5nNvAoqcKTUBW4uG+Zpfnm3jaDO5\nGxhJEIZWfndYzycHT2KMVQ1uTP82ba8ZaKrPlPIafkbui3mdds47qsmqHiblKERg\nU532lkwfqHDlJwE7OBZQ59EwWWLynlT/yAUHpOBbqIuHKUxdpmBI+sIjrZcD1e05\nWmjkO6fwIdC5oM757aoPxIgXD587VOViH11Vkm2doskj4T8yONtwVHlcrrhJ9Bzd\n/zdp6vEn7GZQrABvpOlqwWxQ72ZnFhJe/RJZf6CXOPOh69Ai0QKYl2a1sYuCJKS3\nnsBnxXJINEEznjR7rZjNUmYD+CZqfjzgPqedRxTlASe7iA4w7xZOqMDzcuhNwcUQ\ntMEH6BTktxKP3jXZPXRfHCf6s+HRVb6vezAonTBVyydf5Xp5VwWkd6cwm+2BzHl5\n7kc/3lLxKMcsyEUprAsk8LdHohwZdC267l+RS++AP6Cz6x+nB3oGob19AgMBAAGj\nfzB9MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBQCSSas60GqqMjt\nxR7LoY1gucEvtzAhBgNVHREEGjAYgRZwZXRlci5ib2xpbmdAZ21haWwuY29tMCEG\nA1UdEgQaMBiBFnBldGVyLmJvbGluZ0BnbWFpbC5jb20wDQYJKoZIhvcNAQELBQAD\nggGBAMl9ifcw5p+PdvB7dCPoNKoVdp/2LbC9ztETHuYL2gUMJB6UoS3o9c/piSuR\nV3ZMQaijmNu6ms1bWAtJ66LjmYrVflJtf9yp31Kierr9LpisMSUx2qbMOHGa8d2Z\nvCUWPF8E9Cg0mP3GAyZ6qql8jDh/anUKeksPXqJvNxNPDu2DVYsa/IWdl96whzS4\nBl7SwB1E7agps40UcshCSKaVDOU0M+XN6SrnJMElnBic+KSAkBkVFbzS0BE4ODZM\nBgE6nYzQ05qhuvbE+oGdACTlemNtDDWCh0uw+7x0q2PocGIDU5zsPn/WNTkCXPmB\nCHGvqDNWq4M7ncTKAaS2XExgyb7uPdq9fKiOW8nmH+zCiGzJXzBWwZlKf7L4Ht9E\na3f0e5C+zvee9Z5Ng9ciyfav9/fcXgYt5MjoBv27THr5XfBhgOCIHSYW2tqJmWKi\nKuxrfYrN+9HvMdm+nZ6TypmKftHY3Gj+/uu+g8Icm/zrvTWAEE0mcJOkfrIoNPJb\npF8dMA==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-03-21"
  s.description = "Versions are good. Versions are cool. Versions will win.".freeze
  s.email = ["peter.boling@gmail.com".freeze, "oauth-ruby@googlegroups.com".freeze]
  s.homepage = "https://gitlab.com/oauth-xx/version_gem".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.5.6".freeze
  s.summary = "Enhance your VERSION! Sugar for Version modules.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12".freeze])
  s.add_development_dependency(%q<rspec-block_is_expected>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.14".freeze])
end
