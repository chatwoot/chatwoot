# -*- encoding: utf-8 -*-

Gem::Specification.new("statsd-ruby", "1.5.0") do |s|
  s.authors =  `git log --format='%aN' | sort -u`.split("\n")
  s.email = "reinh@reinh.com"

  s.summary = "A Ruby StatsD client"
  s.description = "A Ruby StatsD client (https://github.com/etsy/statsd)"

  s.homepage = "https://github.com/reinh/statsd"
  s.licenses = %w[MIT]

  s.extra_rdoc_files = %w[LICENSE.txt README.rdoc]

  if $0 =~ /gem/ # If running under rubygems (building), otherwise, just leave
    s.files         = `git ls-files`.split($\)
    s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  end

  s.add_development_dependency "minitest", ">= 5.6.0"
  s.add_development_dependency "yard"
  s.add_development_dependency "simplecov", ">= 0.6.4"
  s.add_development_dependency "rake"
end

