# frozen_string_literal: true

module RSpecHelpers
  def expect_deprecation_with_call_site(file, line, snippet=//)
    expect(RSpec.configuration.reporter).to receive(:deprecation).
      with(include(:deprecated => match(snippet), :call_site => include([file, line].join(':'))))
  end

  def expect_deprecation_without_call_site(snippet=//)
    expect(RSpec.configuration.reporter).to receive(:deprecation).
      with(include(:deprecated => match(snippet), :call_site => eq(nil)))
  end

  def expect_warn_deprecation_with_call_site(file, line, snippet=//)
    expect(RSpec.configuration.reporter).to receive(:deprecation).
      with(include(:message => match(snippet), :call_site => include([file, line].join(':'))))
  end

  def expect_warn_deprecation(snippet=//)
    expect(RSpec.configuration.reporter).to receive(:deprecation).
      with(include(:message => match(snippet)))
  end

  def allow_deprecation
    allow(RSpec.configuration.reporter).to receive(:deprecation)
  end

  def expect_no_deprecations
    expect(RSpec.configuration.reporter).not_to receive(:deprecation)
  end
  alias expect_no_deprecation expect_no_deprecations

  def expect_warning_without_call_site(expected=//)
    expect(::Kernel).to receive(:warn).
      with(match(expected).and(satisfy { |message| !(/Called from/ =~ message) }))
  end

  def expect_warning_with_call_site(file, line, expected=//)
    expect(::Kernel).to receive(:warn).
      with(match(expected).and(match(/Called from #{file}:#{line}/)))
  end

  def expect_no_warnings
    expect(::Kernel).not_to receive(:warn)
  end

  def allow_warning
    allow(::Kernel).to receive(:warn)
  end
end
