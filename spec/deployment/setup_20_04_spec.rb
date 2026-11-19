require 'spec_helper'
require 'open3'
require 'tmpdir'

# This exercises a Bash installer function, which has no Ruby class to describe.
RSpec.describe 'Linux installer Ruby selection' do # rubocop:disable RSpec/DescribeClass
  let(:installer_path) { File.expand_path('../../deployment/setup_20.04.sh', __dir__) }
  let(:setup_function) { File.read(installer_path, encoding: 'UTF-8').match(/^function setup_chatwoot\(\) \{.*?^\}/m)[0] }
  let(:installation_commands) do
    <<~'BASH'
      BRANCH=selected-branch
      get_pgpass() { pg_pass=test; }
      sudo() { bash -e; }

      git() {
        case "$1" in
          clone)
            mkdir chatwoot
            touch chatwoot/.env.example
            ;;
          checkout)
            printf '%s\n' "$EXPECTED_RUBY_VERSION" > .ruby-version
            ;;
        esac
      }

      rvm() {
        case "$1" in
          install) INSTALLED_RUBY_VERSION="${2#ruby-}" ;;
          use)
            test "$2" = "$INSTALLED_RUBY_VERSION"
            ACTIVE_RUBY_VERSION="$2"
            ;;
        esac
      }

      bundle() {
        required_ruby_version="$(cat .ruby-version)"
        if [ "$ACTIVE_RUBY_VERSION" != "$required_ruby_version" ]; then
          printf 'Ruby version mismatch: using %s, required %s\n' "$ACTIVE_RUBY_VERSION" "$required_ruby_version" >&2
          return 18
        fi
        printf 'Bundler accepted Ruby %s\n' "$ACTIVE_RUBY_VERSION"
      }

      pnpm() { :; }
      rake() { :; }
      export -f git rvm bundle pnpm rake
    BASH
  end

  %w[3.4.4 3.4.13].each do |ruby_version|
    it "installs the selected branch with Ruby #{ruby_version}" do
      Dir.mktmpdir do |directory|
        # The invoking shell can have a different version from the selected checkout.
        File.write(File.join(directory, '.ruby-version'), "3.3.0\n")
        stdout, stderr, status = Open3.capture3(
          { 'EXPECTED_RUBY_VERSION' => ruby_version, 'LC_ALL' => 'C' },
          'bash', '-s',
          stdin_data: "#{installation_commands}\n#{setup_function}\nsetup_chatwoot\n",
          chdir: directory
        )

        expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
        expect(stdout).to include("Bundler accepted Ruby #{ruby_version}")
      end
    end
  end
end
