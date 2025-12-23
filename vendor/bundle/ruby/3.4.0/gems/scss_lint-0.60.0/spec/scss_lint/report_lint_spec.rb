require 'spec_helper'
require 'rspec/matchers/fail_matchers'

RSpec.configure do |config|
  config.include RSpec::Matchers::FailMatchers
end

RSpec::Matchers.define_negated_matcher :succeed, :raise_error

# In these tests, we cover all of the combinations of successful and failed
# matches, expecting and _not_ expecting lints, specified and unspecified line
# numbers, specified and unspecified lint counts, and singular and multiple
# lints.
describe 'report_lint' do
  let(:subject) { SCSSLint::Linter::LeadingZero.new }

  def run_with(scss)
    subject.run(SCSSLint::Engine.new(code: scss), SCSSLint::Config.default.linter_options(subject))
  end

  context 'when expecting no lints' do
    it 'matches zero expected lints' do
      run_with('p { margin: .5em; }')

      expect do
        should_not report_lint
      end.to succeed
    end

    it 'fails to match one lint with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should_not report_lint
      end.to fail_with 'expected that a lint would not be reported'
    end
  end

  context 'when expecting no lints on a certain line' do
    it 'matches zero expected lints' do
      run_with('p { margin: .5em; }')

      expect do
        should_not report_lint line: 1
      end.to succeed
    end

    it 'matches zero expected lints on the specified line' do
      run_with('p { margin: 0.5em; }')

      expect do
        should_not report_lint line: 10
      end.to succeed
    end

    it 'fails to match one lint on the specified line with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should_not report_lint line: 1
      end.to fail_with 'expected that a lint would not be reported'
    end
  end

  context 'when expecting a lint' do
    it 'matches one expected lint' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint
      end.to succeed
    end

    it 'matches multiple lints' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint
      end.to fail_with 'expected that a lint would be reported'
    end
  end

  context 'when expecting a lint on a certain line' do
    it 'matches one expected lint' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 1
      end.to succeed
    end

    it 'matches multiple lints' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint line: 1
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint line: 1
      end.to fail_with 'expected that a lint would be reported on line 1'
    end

    it 'fails to match lints on the wrong line with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 10
      end.to fail_with 'expected that a lint would be reported on line 10, ' \
                       'but one lint was reported on line 1'
    end
  end

  context 'when expecting exactly one lint' do
    it 'matches one expected lint' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint count: 1
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported'
    end

    it 'fails to match multiple lints with a meaningful message' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported, ' \
                       'but lints were reported on lines 1 and 1'
    end

    it 'fails to match lints on the wrong line with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 10, count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported on ' \
                       'line 10, but one lint was reported on line 1'
    end
  end

  context 'when expecting multiple lints' do
    it 'matches multiple lints' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint count: 2
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported'
    end

    it 'fails to match one lint with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported'
    end

    it 'fails to match lints on the wrong line with a meaningful message' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint line: 10, count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported on ' \
                       'line 10, but lints were reported on lines 1 and 1'
    end
  end

  context 'when expecting exactly one lint on a certain line' do
    it 'matches one expected lint' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 1, count: 1
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint line: 1, count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported on line 1'
    end

    it 'fails to match multiple lints with a meaningful message' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint line: 1, count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported on ' \
                       'line 1, but lints were reported on lines 1 and 1'
    end

    it 'fails to match lints on the wrong line with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 10, count: 1
      end.to fail_with 'expected that exactly 1 lint would be reported on ' \
                       'line 10, but one lint was reported on line 1'
    end
  end

  context 'when expecting multiple lints on a certain line' do
    it 'matches one expected lint' do
      run_with('p { margin: 0.5em 0.5em; }')

      expect do
        should report_lint line: 1, count: 2
      end.to succeed
    end

    it 'fails to match zero lints with a meaningful message' do
      run_with('p { margin: .5em; }')

      expect do
        should report_lint line: 1, count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported on line 1'
    end

    it 'fails to match one lint with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 1, count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported on ' \
                       'line 1, but one lint was reported on line 1'
    end

    it 'fails to match lints on the wrong line with a meaningful message' do
      run_with('p { margin: 0.5em; }')

      expect do
        should report_lint line: 10, count: 2
      end.to fail_with 'expected that exactly 2 lints would be reported on ' \
                       'line 10, but one lint was reported on line 1'
    end
  end
end
