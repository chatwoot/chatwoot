# frozen_string_literal: true

SimpleCov.profiles.define "hidden_filter" do
  add_filter %r{^/\..*}
end
