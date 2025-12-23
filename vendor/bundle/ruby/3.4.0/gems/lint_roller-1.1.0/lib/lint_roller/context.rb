module LintRoller
  Context = Struct.new(
    :runner, # :standard, :rubocop
    :runner_version, # "1.2.3"
    :engine, # :rubocop
    :engine_version, # "2.3.4",
    :rule_format, # :rubocop
    :target_ruby_version, # Gem::Version.new("2.7.0")
    keyword_init: true
  )
end
