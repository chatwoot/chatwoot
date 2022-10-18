# "not_change" is needed to support chaining "change" matchers
# see https://stackoverflow.com/a/34969429/58876
RSpec::Matchers.define_negated_matcher :not_change, :change
