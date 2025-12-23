# coding: utf-8

name = File.basename(__FILE__, '.*')
source_version = ["", "ext/#{name}/"].find do |dir|
  begin
    break File.foreach(File.join(__dir__, "#{dir}#{name}.c")) {|line|
      break $1.sub("-", ".") if /^#define\s+#{name.upcase}_VERSION\s+"(.+)"/o =~ line
    }
  rescue Errno::ENOENT
  end
end or raise "can't find #{name.upcase}_VERSION"

Gem::Specification.new do |s|
  s.name          = name
  s.version       = source_version
  s.authors       = ["Kenta Murata", "Zachary Scott", "Shigeo Kobayashi"]
  s.email         = ["mrkn@mrkn.jp"]

  s.summary       = "Arbitrary-precision decimal floating-point number library."
  s.description   = "This library provides arbitrary-precision decimal floating-point number class."
  s.homepage      = "https://github.com/ruby/bigdecimal"
  s.licenses       = ["Ruby", "BSD-2-Clause"]

  s.require_paths = %w[lib]
  s.files         = %w[
    LICENSE
    bigdecimal.gemspec
    lib/bigdecimal.rb
    lib/bigdecimal/jacobian.rb
    lib/bigdecimal/ludcmp.rb
    lib/bigdecimal/math.rb
    lib/bigdecimal/newton.rb
    lib/bigdecimal/util.rb
    sample/linear.rb
    sample/nlsolve.rb
    sample/pi.rb
  ]
  if Gem::Platform === s.platform and s.platform =~ 'java' or RUBY_ENGINE == 'jruby'
    s.platform      = 'java'
  else
    s.extensions    = %w[ext/bigdecimal/extconf.rb]
    s.files += %w[
      ext/bigdecimal/bigdecimal.c
      ext/bigdecimal/bigdecimal.h
      ext/bigdecimal/bits.h
      ext/bigdecimal/feature.h
      ext/bigdecimal/missing.c
      ext/bigdecimal/missing.h
      ext/bigdecimal/missing/dtoa.c
      ext/bigdecimal/static_assert.h
    ]
  end

  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  s.metadata["changelog_uri"] = s.homepage + "/blob/master/CHANGES.md"
end
