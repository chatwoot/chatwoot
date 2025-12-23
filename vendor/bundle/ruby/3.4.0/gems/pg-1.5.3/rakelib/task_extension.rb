# This source code is borrowed from:
# https://github.com/oneclick/rubyinstaller2/blob/b3dcbf69f131e44c78ea3a1c5e0041c223f266ce/lib/ruby_installer/build/utils.rb#L104-L144

module TaskExtension
  # Extend rake's file task to be defined only once and to check the expected file is indeed generated
  #
  # The same as #task, but for #file.
  # In addition this file task raises an error, if the file that is expected to be generated is not present after the block was executed.
  def file(name, *args, &block)
    task_once(name, block) do
      super(name, *args) do |ta|
        block&.call(ta).tap do
          raise "file #{ta.name} is missing after task executed" unless File.exist?(ta.name)
        end
      end
    end
  end

  # Extend rake's task definition to be defined only once, even if called several times
  #
  # This allows to define common tasks next to specific tasks.
  # It is expected that any variation of the task's block is reflected in the task name or namespace.
  # If the task name is identical, the task block is executed only once, even if the file task definition is executed twice.
  def task(name, *args, &block)
    task_once(name, block) do
      super
    end
  end

  private def task_once(name, block)
    name = name.keys.first if name.is_a?(Hash)
    if block &&
        Rake::Task.task_defined?(name) &&
        Rake::Task[name].instance_variable_get('@task_block_location') == block.source_location
      # task is already defined for this target and the same block
      # So skip double definition of the same action
      Rake::Task[name]
    elsif block
      yield.tap do
        Rake::Task[name].instance_variable_set('@task_block_location', block.source_location)
      end
    else
      yield
    end
  end
end
