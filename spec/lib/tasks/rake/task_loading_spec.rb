require 'open3'
require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  describe 'task file loading' do
    # No other spec can catch this. `rails_helper` requires `config/environment` before it
    # calls `load_tasks`, so by the time any example runs, autoloading is set up and a task
    # file that names an application constant in a module or class body resolves fine. Rake
    # itself loads those files before the `:environment` prerequisite runs, so the same
    # reference raises NameError on *every* invocation, `rake -T` and `db:migrate` included.
    #
    # CI is not blind to it: its setup runs `rake db:create`, so all 16 backend shards fail
    # there. But they fail at "Create database" with nothing pointing at the task file, after
    # a full CI round trip. This turns that into a named local failure in 1.5s, and it covers
    # every file under `lib/tasks`, not just the one that prompted it.
    it 'does not reference application constants before the environment is loaded' do
      output, status = Open3.capture2e('bundle', 'exec', 'rake', '-T', chdir: Rails.root.to_s)

      expect(status).to be_success, "rake could not load its task files:\n#{output}"
    end
  end
end
