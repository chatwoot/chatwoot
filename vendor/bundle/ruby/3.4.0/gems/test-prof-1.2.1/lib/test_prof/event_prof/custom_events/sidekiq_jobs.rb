# frozen_string_literal: true

TestProf::EventProf::CustomEvents.register("sidekiq.jobs") do
  if TestProf.require(
    "sidekiq/testing",
    <<~MSG
      Failed to load Sidekiq.

      Make sure that "sidekiq" gem is in your Gemfile.
    MSG
  )
    TestProf::EventProf.monitor(
      Sidekiq::Client,
      "sidekiq.jobs",
      :raw_push,
      guard: ->(*) { Sidekiq::Testing.inline? }
    )
    TestProf::EventProf.configure do |config|
      config.rank_by = :count
    end
  end
end
