# -*- encoding: utf-8 -*-
# stub: oauth-tty 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth-tty".freeze
  s.version = "1.0.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://gitlab.com/oauth-xx/oauth-tty/-/issues", "changelog_uri" => "https://gitlab.com/oauth-xx/oauth-tty/-/blob/v1.0.5/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/oauth-tty/1.0.5", "funding_uri" => "https://liberapay.com/pboling", "homepage_uri" => "https://gitlab.com/oauth-xx/oauth-tty", "mailing_list_uri" => "https://groups.google.com/g/oauth-ruby", "rubygems_mfa_required" => "true", "source_code_uri" => "https://gitlab.com/oauth-xx/oauth-tty/-/tree/v1.0.5", "wiki_uri" => "https://gitlab.com/oauth-xx/oauth-tty/-/wikis/home" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thiago Pinto".freeze, "Peter Boling".freeze]
  s.bindir = "exe".freeze
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEgDCCAuigAwIBAgIBATANBgkqhkiG9w0BAQsFADBDMRUwEwYDVQQDDAxwZXRl\nci5ib2xpbmcxFTATBgoJkiaJk/IsZAEZFgVnbWFpbDETMBEGCgmSJomT8ixkARkW\nA2NvbTAeFw0yMjA5MTgyMzEyMzBaFw0yMzA5MTgyMzEyMzBaMEMxFTATBgNVBAMM\nDHBldGVyLmJvbGluZzEVMBMGCgmSJomT8ixkARkWBWdtYWlsMRMwEQYKCZImiZPy\nLGQBGRYDY29tMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2Dn1GM3W\n8K2/rvN1zz+06bQMcxD16ZKTihVwi7Pb1v3T98rM4Omnxohm3s+CwpDWGeiB9pj6\n0I/CTce0e4e3s8GKJSOrg93veImPSoH2PfsMsRsuB8wtqyiOCjLbF5o6S29x87r0\nLA5EawH+Lh4xqrkkPjdffsmLk7TaCig/vlmNvnzxXKBdey/X/aEJZXzzBiWRfVdh\nO1fmMbVKyieGv9HK7+pLotIoT08bjDv8NP6V7zZslwQRqW27bQc6cqC2LGIbTYO3\n3jt1kQxfMWmhOictS6SzG9VtKSrXf0L4Neq0Gh7CLBZBvJFWJYZPfb92YNITDbd8\nemPOAQlXXNMN4mMXsEqtEhCPZRMnmwO+fOk/cC4AyglKi9lnQugCQoFV1XDMZST/\nCYbzdQyadOdPDInTntG6V+Uw51d2QGXZ6PDDfrx9+toc/3sl5h68rCUGgE6Q3jPz\nsrinqmBsxv2vTpmd4FjmiAtEnwH5/ooLpQYL8UdAjEoeysxS3AwIh+5dAgMBAAGj\nfzB9MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBQWU6D156a2cle+\nlb5RBfvVXlxTwjAhBgNVHREEGjAYgRZwZXRlci5ib2xpbmdAZ21haWwuY29tMCEG\nA1UdEgQaMBiBFnBldGVyLmJvbGluZ0BnbWFpbC5jb20wDQYJKoZIhvcNAQELBQAD\nggGBAJ4SqhPlgUiLYIrphGXIaxXScHyvx4kixuvdrwhI4VoQV2qXvO7R6ZjOXVwX\nf/z84BWPiTZ8lzThPbt1UV/BGwkvLw9I4RjOdzvUz3J42j9Ly6q63isall07bo3F\nQWe/OBvIMBF1IbjC3q5vKPg4rq8+TkNRJNoE86U2gfR+PkW3jYYs9uiy0GloHDCP\nk5xgaj0vSL0Uy5mTOPdk3K6a/sUGZyYniWK05zdhIi956ynhfGaFO988FFdVw5Jq\nLHtXfIpAU8F7ES04syZSslxOluw7VlcSKyRdVIr737J92ZTduppB4PRGSKRgBsWV\nhXTahRE72Kyw53Q7FAuzF3v102WxAAQ7BuMjW+MyCUT75fwPm3W4ELPL8HYkNGE7\n2oA5CPghFitRnvYS3GNrDG+9bNiRMEskeaBYwZ9UgReBQIwGYVj7LZk3UhiAsn44\ngwGrEXGQGDZ0NIgBcmvMOqlXjkGQwQvugKycJ024z89+fz2332vdZIKTrSxJrXGk\n4/bR9A==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2022-09-20"
  s.description = "OAuth 1.0 TTY Command Line Interface".freeze
  s.email = ["peter.boling@gmail.com".freeze, "oauth-ruby@googlegroups.com".freeze]
  s.executables = ["oauth".freeze]
  s.files = ["exe/oauth".freeze]
  s.homepage = "https://gitlab.com/oauth-xx/oauth-tty".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.3.22".freeze
  s.summary = "OAuth 1.0 TTY CLI".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<version_gem>.freeze, ["~> 1.1".freeze, ">= 1.1.1".freeze])
  s.add_development_dependency(%q<em-http-request>.freeze, ["~> 1.1.7".freeze])
  s.add_development_dependency(%q<iconv>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rest-client>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-lts>.freeze, ["~> 18.0".freeze])
  s.add_development_dependency(%q<typhoeus>.freeze, [">= 0.1.13".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["<= 3.19.0".freeze])
end
