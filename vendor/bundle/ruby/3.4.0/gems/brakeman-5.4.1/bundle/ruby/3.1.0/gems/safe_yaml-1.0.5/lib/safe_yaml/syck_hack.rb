# Hack to JRuby 1.8's YAML Parser Yecht
#
# This file is always loaded AFTER either syck or psych are already
# loaded. It then looks at what constants are available and creates
# a consistent view on all rubys.
#
# Taken from rubygems and modified.
# See https://github.com/rubygems/rubygems/blob/master/lib/rubygems/syck_hack.rb

module YAML
  # In newer 1.9.2, there is a Syck toplevel constant instead of it
  # being underneith YAML. If so, reference it back under YAML as
  # well.
  if defined? ::Syck
    # for tests that change YAML::ENGINE
    # 1.8 does not support the second argument to const_defined?
    remove_const :Syck rescue nil

    Syck = ::Syck

  # JRuby's "Syck" is called "Yecht"
  elsif defined? YAML::Yecht
    Syck = YAML::Yecht
  end
end

# Sometime in the 1.9 dev cycle, the Syck constant was moved from under YAML
# to be a toplevel constant. So gemspecs created under these versions of Syck
# will have references to Syck::DefaultKey.
#
# So we need to be sure that we reference Syck at the toplevel too so that
# we can always load these kind of gemspecs.
#
if !defined?(Syck)
  Syck = YAML::Syck
end
