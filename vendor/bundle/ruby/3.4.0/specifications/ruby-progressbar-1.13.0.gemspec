# -*- encoding: utf-8 -*-
# stub: ruby-progressbar 1.13.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-progressbar".freeze
  s.version = "1.13.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jfelchner/ruby-progressbar/issues", "changelog_uri" => "https://github.com/jfelchner/ruby-progressbar/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/jfelchner/ruby-progressbar/tree/releases/v1.13.0", "homepage_uri" => "https://github.com/jfelchner/ruby-progressbar", "source_code_uri" => "https://github.com/jfelchner/ruby-progressbar", "wiki_uri" => "https://github.com/jfelchner/ruby-progressbar/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["thekompanee".freeze, "jfelchner".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEdjCCAt6gAwIBAgIBATANBgkqhkiG9w0BAQsFADAyMTAwLgYDVQQDDCdhY2Nv\ndW50c19ydWJ5Z2Vtcy9EQz10aGVrb21wYW5lZS9EQz1jb20wHhcNMjMwMjI2MTcx\nMDI1WhcNMjYwMjI1MTcxMDI1WjAyMTAwLgYDVQQDDCdhY2NvdW50c19ydWJ5Z2Vt\ncy9EQz10aGVrb21wYW5lZS9EQz1jb20wggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAw\nggGKAoIBgQCqhYn5ODEoLvuBIF2M1GzoaZU28+ntP5QApvDE0Te04n0JbBC1cNYH\nmr71neeSx7tlZ9w9kJ/8GNcY5bm7pNJqhyhfc+uG9M7FttcxM8AYXogjcdUDP234\n+TdmZIz20JxtWBgAZK2I3ktlgLFLC3Pxq63yzhJ75Xok07Wh+ypwjGzDNofPhz+y\nXR+UeUTp2UGe7kDVoqu/AwwPVhk1qUIRFLfC8SLDTD0CuNW3/AnkwQrKSm8vkiIn\nq9GCnOq0+jQly0b6a1Gi3ZDYEEswnTzziw2gotUZnQkF5bcOcxK1CB/Okk2jtG7i\nztMEU785tERbOSszZrz9rBS/+GnMxlD0pxy50zFfHX3jY1hwnwGjE8Gg+0iYr/tm\neysjhcbZfKrMynoqAioCSwstIwtYYYYpYzCPZzwaIBaBqQmUTkuMeiGbAdOdFOrR\nlOgl5jxCYbNOOTaXbm0nGBFaTucB88+JLbsNAuoNGUf/ybDcZ1zKRkMr2vtb+OtL\nGoP81fN6l88CAwEAAaOBljCBkzAJBgNVHRMEAjAAMAsGA1UdDwQEAwIEsDAdBgNV\nHQ4EFgQUL4eV4OM9h7fkM27qf9p4ragHi6AwLAYDVR0RBCUwI4EhYWNjb3VudHMr\ncnVieWdlbXNAdGhla29tcGFuZWUuY29tMCwGA1UdEgQlMCOBIWFjY291bnRzK3J1\nYnlnZW1zQHRoZWtvbXBhbmVlLmNvbTANBgkqhkiG9w0BAQsFAAOCAYEAD/tBN1cM\n8Qu6u+rPM3SEtlEK/ZdVY0IowXtXMskkderNBJ4HY+xBfIWyAXLTr3Fy6xscVZ95\nraFCiWHqvR577u3/BsVZ5BoQ0g25oY2bwoamQSdx71ygs25Q+UFbg6lHq6olszj0\nHqKXUy/iPFb+OzGq7NOtKOD5pHl3ew8H7U5tfh0kx6B5TdL9BZLurjskW0n2G+kY\nNSGCTGYU8wY4Bsk/AmfoFT/ATwmrf68CTD+IBY5yvt2DGvcyuSrX1RQP8Vk//0EP\nJ2ezTNGIBeQFcyyo09gMfy1yxv9XAvwmy6pAx7/m/F2XzTiXuzmJ7zJ6J0OaHUG4\nsvJgf3o9Eor2okQND60Qdpdl4qdSy3KaNqvQQbTRB96e/+K8ksz4rras5jPaAs0p\nDV37k4cni6c/jUm2CqepsJ/dbzeWdkhcuO6hwEQV0jvFky5C6d5hHcrbJwxl1sTL\nV+pWW6L9MSZzKkjWVJXD43B3tWBjIDthQVTzS4j90PUkUXgBXjS7Jxj/\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2023-03-04"
  s.description = "Ruby/ProgressBar is an extremely flexible text progress bar library for Ruby. The output can be customized with a flexible formatting system including: percentage, bars of various formats, elapsed time and estimated time remaining.".freeze
  s.email = ["support@thekompanee.com".freeze]
  s.homepage = "https://github.com/jfelchner/ruby-progressbar".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Ruby/ProgressBar is a flexible text progress bar library for Ruby.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<rspectacular>.freeze, ["~> 0.70.6".freeze])
  s.add_development_dependency(%q<fuubar>.freeze, ["~> 2.3".freeze])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9".freeze])
end
