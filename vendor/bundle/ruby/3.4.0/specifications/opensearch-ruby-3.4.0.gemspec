# -*- encoding: utf-8 -*-
# stub: opensearch-ruby 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "opensearch-ruby".freeze
  s.version = "3.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/opensearch-project/opensearch-ruby/issues", "changelog_uri" => "https://github.com/opensearch-project/opensearch-ruby/blob/main/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/gems/opensearch-ruby", "homepage_uri" => "https://github.com/opensearch-project/opensearch-ruby", "source_code_uri" => "https://github.com/opensearch-project/opensearch-ruby/tree/main" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Elastic".freeze, "OpenSearch Contributors".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDfDCCAmSgAwIBAgIBATANBgkqhkiG9w0BAQsFADBCMRMwEQYDVQQDDApvcGVu\nc2VhcmNoMRYwFAYKCZImiZPyLGQBGRYGYW1hem9uMRMwEQYKCZImiZPyLGQBGRYD\nY29tMB4XDTIzMDgyNDIwNDIwNFoXDTI0MDgyMzIwNDIwNFowQjETMBEGA1UEAwwK\nb3BlbnNlYXJjaDEWMBQGCgmSJomT8ixkARkWBmFtYXpvbjETMBEGCgmSJomT8ixk\nARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM1z3/jcitjV\numXwRFn+JSBBd36qZB54Dtucf6+E2fmNPzBRhgYN5XJy/+clQJ9NIJV7C8H52P3V\ndsce/VXcNAcgfUdlN57nM0ksjFFNlnHWXea8Ub9/6R1K0p1RBizEINzUneoJLvqe\n7w/KfvBJStj7AmJgZmzCiu98j75YLcdLhZQykRyJdB03wZsMQUvxPFkhTZn+Qi8k\n0U909l9JD0i1PC0xVukYlskUA2xeo36kMMllABJGN536Z0aIT2KX2XTiKK7hILoP\n+flNmgA4eyXa5Ki9q4HBN6QhsTKdEinqGngQnUI35YTu2AHsvfjn1wP/nUa9aRVH\nzfR37/NQFkECAwEAAaN9MHswCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0O\nBBYEFJJ2myhLXK742btavNbG0IWrMNBIMCAGA1UdEQQZMBeBFW9wZW5zZWFyY2hA\nYW1hem9uLmNvbTAgBgNVHRIEGTAXgRVvcGVuc2VhcmNoQGFtYXpvbi5jb20wDQYJ\nKoZIhvcNAQELBQADggEBABAQpnELuY5AgdNUIlIVRVATO6iZOXTbt3a9oVbQdLPe\nBfMObZyJydg0+leyR3oFyN9ZIFiEFwpd0biFf39DuC0M6Oge0Rv4oO9GRI3yyv77\n9m59he+5DI3hbqtGje108oqRe61NZMlKcy/DCBVkzzZFsJ17GC09tY/gwhmNRtLV\n3vYIEY6vmn57wrGn1NUzWdG+x/XVjYPw5Kwo+/rCxxZqpVTklMqVWV43N/lFrUOe\n1DlemA1SsUBIoF7CwtVd/RTG/K1iT6nBD08fdKxodMhI5ujkP3N7gkxzRf6aKN4z\nglnDJYZjluKBUsKTOLdPW1CZpb0AHLpNqDf8SVHsPFk=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-07-11"
  s.description = "OpenSearch Ruby is a Ruby client for OpenSearch. You can use the client to\nexecute OpenSearch API commands, and build OpenSearch queries and aggregations\nusing the included OpenSearch DSL.\n".freeze
  s.email = "opensearch@amazon.com".freeze
  s.executables = ["opensearch_ruby_console".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "USER_GUIDE.md".freeze, "LICENSE.txt".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "USER_GUIDE.md".freeze, "bin/opensearch_ruby_console".freeze]
  s.homepage = "https://github.com/opensearch-project/opensearch-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Ruby Client for OpenSearch".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.0".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.0".freeze])
end
