# frozen_string_literal: true

TestProf::EventProf::CustomEvents.register("sidekiq.inline") do
  if TestProf.require(
    "sidekiq/testing",
    <<~MSG
      Failed to load Sidekiq.

      Make sure that "sidekiq" gem is in your Gemfile.
    MSG
  )
    TestProf::EventProf.monitor(
      Sidekiq::Client,
      "sidekiq.inline",
      :raw_push,
      top_level: true,
      guard: ->(*) { Sidekiq::Testing.inline? }
    )
  end
end
