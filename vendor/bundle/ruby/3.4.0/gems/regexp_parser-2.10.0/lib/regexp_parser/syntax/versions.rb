# Ruby 1.x is no longer a supported runtime,
# but its regex features are still recognized.
#
# Aliases for the latest patch version are provided as 'ruby/n.n',
# e.g. 'ruby/1.9' refers to Ruby v1.9.3.
Dir[File.expand_path('../versions/*.rb', __FILE__)].sort.each { |f| require_relative f }

Regexp::Syntax::CURRENT = Regexp::Syntax.for("ruby/#{RUBY_VERSION}")
