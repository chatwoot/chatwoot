require 'brakeman/processors/lib/basic_processor'

#Processes Gemfile and Gemfile.lock
class Brakeman::GemProcessor < Brakeman::BasicProcessor

  def initialize *args
    super
    @gem_name_version = /^\s*([-_+.A-Za-z0-9]+) \((\w(\.\w+)*)\)/
    @ruby_version = /^\s+ruby (\d\.\d.\d+)/
  end

  def process_gems gem_files
    @gem_files = gem_files
    @gemfile = gem_files[:gemfile] && gem_files[:gemfile][:file]
    @gemspec = gem_files[:gemspec] && gem_files[:gemspec][:file]


    if @gemspec
      process gem_files[:gemspec][:src]
    end

    if @gemfile
      process gem_files[:gemfile][:src]
    end

    if gem_files[:gemlock]
      process_gem_lock
    end

    @tracker.config.set_rails_version
  end

  # Known issue: Brakeman does not yet support `gem` calls with multiple
  # "version requirements". Consider the following example from the ruby docs:
  #
  #     gem 'rake', '>= 1.1.a', '< 2'
  #
  # We are assuming that `second_arg` (eg. '>= 1.1.a') is the only requirement.
  # Perhaps we should instantiate an array of `::Gem::Requirement`s or even a
  # `::Gem::Dependency` and pass that to `Tracker::Config#add_gem`?
  def process_call exp
    if exp.target == nil
      if exp.method == :gem
        gem_name = exp.first_arg
        return exp unless string? gem_name

        gem_version = exp.second_arg

        version = if string? gem_version
                    gem_version.value
                  else
                    nil
                  end

        @tracker.config.add_gem gem_name.value, version, @gemfile, exp.line
      elsif exp.method == :ruby
        version = exp.first_arg
        if string? version
          @tracker.config.set_ruby_version version.value, @gemfile, exp.line
        end
      end
    elsif @inside_gemspec and exp.method == :add_dependency
      if string? exp.first_arg and string? exp.second_arg
        @tracker.config.add_gem exp.first_arg.value, exp.second_arg.value, @gemspec, exp.line
      end
    end

    exp
  end

  GEM_SPEC = s(:colon2, s(:const, :Gem), :Specification)

  def process_iter exp
    if exp.block_call.target == GEM_SPEC and exp.block_call.method == :new
      @inside_gemspec = true
      process exp.block if sexp? exp.block

      exp
    else
      process_default exp
    end
  ensure
    @inside_gemspec = false
  end

  def process_gem_lock
    line_num = 1
    file = @gem_files[:gemlock][:file]
    @gem_files[:gemlock][:src].each_line do |line|
      set_gem_version_and_file line, file, line_num
      line_num += 1
    end
  end

  # Supports .rc2 but not ~>, >=, or <=
  def set_gem_version_and_file line, file, line_num
    if line =~ @gem_name_version
      @tracker.config.add_gem $1, $2, file, line_num
    elsif line =~ @ruby_version
      @tracker.config.set_ruby_version $1, file, line_num
    end
  end
end
