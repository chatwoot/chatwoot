# -*- encoding: utf-8 -*-
# stub: nio4r 2.7.3 ruby lib
# stub: ext/nio4r/extconf.rb

Gem::Specification.new do |s|
  s.name = "nio4r".freeze
  s.version = "2.7.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/socketry/nio4r/issues", "changelog_uri" => "https://github.com/socketry/nio4r/blob/main/changes.md", "documentation_uri" => "https://www.rubydoc.info/gems/nio4r", "funding_uri" => "https://github.com/sponsors/ioquatix/", "source_code_uri" => "https://github.com/socketry/nio4r.git", "wiki_uri" => "https://github.com/socketry/nio4r/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tony Arcieri".freeze, "Samuel Williams".freeze, "Olle Jonsson".freeze, "Gregory Longtin".freeze, "Tiago Cardoso".freeze, "Joao Fernandes".freeze, "Thomas Dziedzic".freeze, "Boaz Segev".freeze, "Logan Bowers".freeze, "Pedro Paiva".freeze, "Jun Aruga".freeze, "Omer Katz".freeze, "Upekshe Jayasekera".freeze, "Tim Carey-Smith".freeze, "Benoit Daloze".freeze, "Sergey Avseyev".freeze, "Tomoya Ishida".freeze, "Usaku Nakamura".freeze, "C\u00E9dric Boutillier".freeze, "Daniel Berger".freeze, "Dirkjan Bussink".freeze, "Hiroshi Shibata".freeze, "Jes\u00FAs Burgos Maci\u00E1".freeze, "Luis Lavena".freeze, "Pavel Rosick\u00FD".freeze, "Sadayuki Furuhashi".freeze, "Stephen von Takach".freeze, "Vladimir Kochnev".freeze, "V\u00EDt Ondruch".freeze, "Anatol Pomozov".freeze, "Bernd Ahlers".freeze, "Charles Oliver Nutter".freeze, "Denis Washington".freeze, "Elad Eyal".freeze, "Jean byroot Boussier".freeze, "Jeffrey Martin".freeze, "John Thornton".freeze, "Jun Jiang".freeze, "Lars Kanis".freeze, "Marek Kowalcze".freeze, "Maxime Demolin".freeze, "Orien Madgwick".freeze, "Pavel Lobashov".freeze, "Per Lundberg".freeze, "Phillip Aldridge".freeze, "Ravil Bayramgalin".freeze, "Shannon Skipper".freeze, "Tao Luo".freeze, "Thomas Kuntz".freeze, "Tsimnuj Hawj".freeze, "Zhang Kang".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIE2DCCA0CgAwIBAgIBATANBgkqhkiG9w0BAQsFADBhMRgwFgYDVQQDDA9zYW11\nZWwud2lsbGlhbXMxHTAbBgoJkiaJk/IsZAEZFg1vcmlvbnRyYW5zZmVyMRIwEAYK\nCZImiZPyLGQBGRYCY28xEjAQBgoJkiaJk/IsZAEZFgJuejAeFw0yMjA4MDYwNDUz\nMjRaFw0zMjA4MDMwNDUzMjRaMGExGDAWBgNVBAMMD3NhbXVlbC53aWxsaWFtczEd\nMBsGCgmSJomT8ixkARkWDW9yaW9udHJhbnNmZXIxEjAQBgoJkiaJk/IsZAEZFgJj\nbzESMBAGCgmSJomT8ixkARkWAm56MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB\nigKCAYEAomvSopQXQ24+9DBB6I6jxRI2auu3VVb4nOjmmHq7XWM4u3HL+pni63X2\n9qZdoq9xt7H+RPbwL28LDpDNflYQXoOhoVhQ37Pjn9YDjl8/4/9xa9+NUpl9XDIW\nsGkaOY0eqsQm1pEWkHJr3zn/fxoKPZPfaJOglovdxf7dgsHz67Xgd/ka+Wo1YqoE\ne5AUKRwUuvaUaumAKgPH+4E4oiLXI4T1Ff5Q7xxv6yXvHuYtlMHhYfgNn8iiW8WN\nXibYXPNP7NtieSQqwR/xM6IRSoyXKuS+ZNGDPUUGk8RoiV/xvVN4LrVm9upSc0ss\nRZ6qwOQmXCo/lLcDUxJAgG95cPw//sI00tZan75VgsGzSWAOdjQpFM0l4dxvKwHn\ntUeT3ZsAgt0JnGqNm2Bkz81kG4A2hSyFZTFA8vZGhp+hz+8Q573tAR89y9YJBdYM\nzp0FM4zwMNEUwgfRzv1tEVVUEXmoFCyhzonUUw4nE4CFu/sE3ffhjKcXcY//qiSW\nxm4erY3XAgMBAAGjgZowgZcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0O\nBBYEFO9t7XWuFf2SKLmuijgqR4sGDlRsMC4GA1UdEQQnMCWBI3NhbXVlbC53aWxs\naWFtc0BvcmlvbnRyYW5zZmVyLmNvLm56MC4GA1UdEgQnMCWBI3NhbXVlbC53aWxs\naWFtc0BvcmlvbnRyYW5zZmVyLmNvLm56MA0GCSqGSIb3DQEBCwUAA4IBgQB5sxkE\ncBsSYwK6fYpM+hA5B5yZY2+L0Z+27jF1pWGgbhPH8/FjjBLVn+VFok3CDpRqwXCl\nxCO40JEkKdznNy2avOMra6PFiQyOE74kCtv7P+Fdc+FhgqI5lMon6tt9rNeXmnW/\nc1NaMRdxy999hmRGzUSFjozcCwxpy/LwabxtdXwXgSay4mQ32EDjqR1TixS1+smp\n8C/NCWgpIfzpHGJsjvmH2wAfKtTTqB9CVKLCWEnCHyCaRVuKkrKjqhYCdmMBqCws\nJkxfQWC+jBVeG9ZtPhQgZpfhvh+6hMhraUYRQ6XGyvBqEUe+yo6DKIT3MtGE2+CP\neX9i9ZWBydWb8/rvmwmX2kkcBbX0hZS1rcR593hGc61JR6lvkGYQ2MYskBveyaxt\nQ2K9NVun/S785AP05vKkXZEFYxqG6EW012U4oLcFl5MySFajYXRYbuUpH6AY+HP8\nvoD0MPg1DssDLKwXyt1eKD/+Fq0bFWhwVM/1XiAXL7lyYUyOq24KHgQ2Csg=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-05-07"
  s.extensions = ["ext/nio4r/extconf.rb".freeze]
  s.files = ["ext/nio4r/extconf.rb".freeze]
  s.homepage = "https://github.com/socketry/nio4r".freeze
  s.licenses = ["MIT".freeze, "BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "New IO for Ruby".freeze

  s.installed_by_version = "3.6.7".freeze
end
