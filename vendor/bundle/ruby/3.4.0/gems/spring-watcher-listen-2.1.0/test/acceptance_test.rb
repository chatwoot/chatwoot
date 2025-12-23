require "helper"

class AcceptanceTest < Spring::Test::AcceptanceTest
  class ApplicationGenerator < Spring::Test::ApplicationGenerator
    def generate_files
      super
      File.write(application.gemfile, "#{application.gemfile.read}gem 'spring-watcher-listen'\n")
    end

    def manually_built_gems
      super + %w(spring-watcher-listen)
    end
  end

  def generator_klass
    ApplicationGenerator
  end

  test "uses the listen watcher" do
    assert_success "bin/rails runner 'puts Spring.watcher.class'", stdout: "Spring::Watcher::Listen"
  end
end
