# frozen_string_literal: true
require 'rbconfig'
require 'parallel/version'

module Parallel
  Stop = Object.new.freeze

  class DeadWorker < StandardError
  end

  class Break < StandardError
    attr_reader :value

    def initialize(value = nil)
      super()
      @value = value
    end
  end

  class Kill < Break
  end

  class UndumpableException < StandardError
    attr_reader :backtrace

    def initialize(original)
      super("#{original.class}: #{original.message}")
      @backtrace = original.backtrace
    end
  end

  class ExceptionWrapper
    attr_reader :exception

    def initialize(exception)
      # Remove the bindings stack added by the better_errors gem,
      # because it cannot be marshalled
      if exception.instance_variable_defined? :@__better_errors_bindings_stack
        exception.send :remove_instance_variable, :@__better_errors_bindings_stack
      end

      @exception =
        begin
          Marshal.dump(exception) && exception
        rescue StandardError
          UndumpableException.new(exception)
        end
    end
  end

  class Worker
    attr_reader :pid, :read, :write
    attr_accessor :thread

    def initialize(read, write, pid)
      @read = read
      @write = write
      @pid = pid
    end

    def stop
      close_pipes
      wait # if it goes zombie, rather wait here to be able to debug
    end

    # might be passed to started_processes and simultaneously closed by another thread
    # when running in isolation mode, so we have to check if it is closed before closing
    def close_pipes
      read.close unless read.closed?
      write.close unless write.closed?
    end

    def work(data)
      begin
        Marshal.dump(data, write)
      rescue Errno::EPIPE
        raise DeadWorker
      end

      result = begin
        Marshal.load(read)
      rescue EOFError
        raise DeadWorker
      end
      raise result.exception if result.is_a?(ExceptionWrapper)
      result
    end

    private

    def wait
      Process.wait(pid)
    rescue Interrupt
      # process died
    end
  end

  class JobFactory
    def initialize(source, mutex)
      @lambda = (source.respond_to?(:call) && source) || queue_wrapper(source)
      @source = source.to_a unless @lambda # turn Range and other Enumerable-s into an Array
      @mutex = mutex
      @index = -1
      @stopped = false
    end

    def next
      if producer?
        # - index and item stay in sync
        # - do not call lambda after it has returned Stop
        item, index = @mutex.synchronize do
          return if @stopped
          item = @lambda.call
          @stopped = (item == Stop)
          return if @stopped
          [item, @index += 1]
        end
      else
        index = @mutex.synchronize { @index += 1 }
        return if index >= size
        item = @source[index]
      end
      [item, index]
    end

    def size
      if producer?
        Float::INFINITY
      else
        @source.size
      end
    end

    # generate item that is sent to workers
    # just index is faster + less likely to blow up with unserializable errors
    def pack(item, index)
      producer? ? [item, index] : index
    end

    # unpack item that is sent to workers
    def unpack(data)
      producer? ? data : [@source[data], data]
    end

    private

    def producer?
      @lambda
    end

    def queue_wrapper(array)
      array.respond_to?(:num_waiting) && array.respond_to?(:pop) && -> { array.pop(false) }
    end
  end

  class UserInterruptHandler
    INTERRUPT_SIGNAL = :SIGINT

    class << self
      # kill all these pids or threads if user presses Ctrl+c
      def kill_on_ctrl_c(pids, options)
        @to_be_killed ||= []
        old_interrupt = nil
        signal = options.fetch(:interrupt_signal, INTERRUPT_SIGNAL)

        if @to_be_killed.empty?
          old_interrupt = trap_interrupt(signal) do
            warn 'Parallel execution interrupted, exiting ...'
            @to_be_killed.flatten.each { |pid| kill(pid) }
          end
        end

        @to_be_killed << pids

        yield
      ensure
        @to_be_killed.pop # do not kill pids that could be used for new processes
        restore_interrupt(old_interrupt, signal) if @to_be_killed.empty?
      end

      def kill(thing)
        Process.kill(:KILL, thing)
      rescue Errno::ESRCH
        # some linux systems already automatically killed the children at this point
        # so we just ignore them not being there
      end

      private

      def trap_interrupt(signal)
        old = Signal.trap signal, 'IGNORE'

        Signal.trap signal do
          yield
          if !old || old == "DEFAULT"
            raise Interrupt
          else
            old.call
          end
        end

        old
      end

      def restore_interrupt(old, signal)
        Signal.trap signal, old
      end
    end
  end

  class << self
    def in_threads(options = { count: 2 })
      threads = []
      count, = extract_count_from_options(options)

      Thread.handle_interrupt(Exception => :never) do
        Thread.handle_interrupt(Exception => :immediate) do
          count.times do |i|
            threads << Thread.new { yield(i) }
          end
          threads.map(&:value)
        end
      ensure
        threads.each(&:kill)
      end
    end

    def in_processes(options = {}, &block)
      count, options = extract_count_from_options(options)
      count ||= processor_count
      map(0...count, options.merge(in_processes: count), &block)
    end

    def each(array, options = {}, &block)
      map(array, options.merge(preserve_results: false), &block)
    end

    def any?(*args, &block)
      raise "You must provide a block when calling #any?" if block.nil?
      !each(*args) { |*a| raise Kill if block.call(*a) }
    end

    def all?(*args, &block)
      raise "You must provide a block when calling #all?" if block.nil?
      !!each(*args) { |*a| raise Kill unless block.call(*a) }
    end

    def each_with_index(array, options = {}, &block)
      each(array, options.merge(with_index: true), &block)
    end

    def map(source, options = {}, &block)
      options = options.dup
      options[:mutex] = Mutex.new

      if options[:in_processes] && options[:in_threads]
        raise ArgumentError, "Please specify only one of `in_processes` or `in_threads`."
      elsif RUBY_PLATFORM =~ (/java/) && !options[:in_processes]
        method = :in_threads
        size = options[method] || processor_count
      elsif options[:in_threads]
        method = :in_threads
        size = options[method]
      elsif options[:in_ractors]
        method = :in_ractors
        size = options[method]
      else
        method = :in_processes
        if Process.respond_to?(:fork)
          size = options[method] || processor_count
        else
          warn "Process.fork is not supported by this Ruby"
          size = 0
        end
      end

      job_factory = JobFactory.new(source, options[:mutex])
      size = [job_factory.size, size].min

      options[:return_results] = (options[:preserve_results] != false || !!options[:finish])
      add_progress_bar!(job_factory, options)

      result =
        if size == 0
          work_direct(job_factory, options, &block)
        elsif method == :in_threads
          work_in_threads(job_factory, options.merge(count: size), &block)
        elsif method == :in_ractors
          work_in_ractors(job_factory, options.merge(count: size), &block)
        else
          work_in_processes(job_factory, options.merge(count: size), &block)
        end

      return result.value if result.is_a?(Break)
      raise result if result.is_a?(Exception)
      options[:return_results] ? result : source
    end

    def map_with_index(array, options = {}, &block)
      map(array, options.merge(with_index: true), &block)
    end

    def flat_map(...)
      map(...).flatten(1)
    end

    def filter_map(...)
      map(...).compact
    end

    # Number of physical processor cores on the current system.
    def physical_processor_count
      @physical_processor_count ||= begin
        ppc =
          case RbConfig::CONFIG["target_os"]
          when /darwin[12]/
            IO.popen("/usr/sbin/sysctl -n hw.physicalcpu").read.to_i
          when /linux/
            cores = {} # unique physical ID / core ID combinations
            phy = 0
            File.read("/proc/cpuinfo").scan(/^physical id.*|^core id.*/) do |ln|
              if ln.start_with?("physical")
                phy = ln[/\d+/]
              elsif ln.start_with?("core")
                cid = "#{phy}:#{ln[/\d+/]}"
                cores[cid] = true unless cores[cid]
              end
            end
            cores.count
          when /mswin|mingw/
            physical_processor_count_windows
          else
            processor_count
          end
        # fall back to logical count if physical info is invalid
        ppc > 0 ? ppc : processor_count
      end
    end

    # Number of processors seen by the OS or value considering CPU quota if the process is inside a cgroup,
    # used for process scheduling
    def processor_count
      @processor_count ||= Integer(ENV['PARALLEL_PROCESSOR_COUNT'] || available_processor_count)
    end

    def worker_number
      Thread.current[:parallel_worker_number]
    end

    # TODO: this does not work when doing threads in forks, so should remove and yield the number instead if needed
    def worker_number=(worker_num)
      Thread.current[:parallel_worker_number] = worker_num
    end

    private

    def physical_processor_count_windows
      # Get-CimInstance introduced in PowerShell 3 or earlier: https://learn.microsoft.com/en-us/previous-versions/powershell/module/cimcmdlets/get-ciminstance?view=powershell-3.0
      result = run(
        'powershell -command "Get-CimInstance -ClassName Win32_Processor -Property NumberOfCores ' \
        '| Select-Object -Property NumberOfCores"'
      )
      if !result || $?.exitstatus != 0
        # fallback to deprecated wmic for older systems
        result = run("wmic cpu get NumberOfCores")
      end
      if !result || $?.exitstatus != 0
        # Bail out if both commands returned something unexpected
        warn "guessing pyhsical processor count"
        processor_count
      else
        # powershell: "\nNumberOfCores\n-------------\n            4\n\n\n"
        # wmic:       "NumberOfCores  \n\n4              \n\n\n\n"
        result.scan(/\d+/).map(&:to_i).reduce(:+)
      end
    end

    def run(command)
      IO.popen(command, &:read)
    rescue Errno::ENOENT
      # Ignore
    end

    def add_progress_bar!(job_factory, options)
      if (progress_options = options[:progress])
        raise "Progressbar can only be used with array like items" if job_factory.size == Float::INFINITY
        require 'ruby-progressbar'

        if progress_options == true
          progress_options = { title: "Progress" }
        elsif progress_options.respond_to? :to_str
          progress_options = { title: progress_options.to_str }
        end

        progress_options = {
          total: job_factory.size,
          format: '%t |%E | %B | %a'
        }.merge(progress_options)

        progress = ProgressBar.create(progress_options)
        old_finish = options[:finish]
        options[:finish] = lambda do |item, i, result|
          old_finish.call(item, i, result) if old_finish
          progress.increment
        end
      end
    end

    def work_direct(job_factory, options, &block)
      self.worker_number = 0
      results = []
      exception = nil
      begin
        while (set = job_factory.next)
          item, index = set
          results << with_instrumentation(item, index, options) do
            call_with_index(item, index, options, &block)
          end
        end
      rescue StandardError
        exception = $!
      end
      exception || results
    ensure
      self.worker_number = nil
    end

    def work_in_threads(job_factory, options, &block)
      raise "interrupt_signal is no longer supported for threads" if options[:interrupt_signal]
      results = []
      results_mutex = Mutex.new # arrays are not thread-safe on jRuby
      exception = nil

      in_threads(options) do |worker_num|
        self.worker_number = worker_num
        # as long as there are more jobs, work on one of them
        while !exception && (set = job_factory.next)
          begin
            item, index = set
            result = with_instrumentation item, index, options do
              call_with_index(item, index, options, &block)
            end
            results_mutex.synchronize { results[index] = result }
          rescue StandardError
            exception = $!
          end
        end
      end

      exception || results
    end

    def work_in_ractors(job_factory, options)
      exception = nil
      results = []
      results_mutex = Mutex.new # arrays are not thread-safe on jRuby

      callback = options[:ractor]
      if block_given? || !callback
        raise ArgumentError, "pass the code you want to execute as `ractor: [ClassName, :method_name]`"
      end

      # build
      ractors = Array.new(options.fetch(:count)) do
        Ractor.new do
          loop do
            got = receive
            (klass, method_name), item, index = got
            break if index == :break
            begin
              Ractor.yield [nil, klass.send(method_name, item), item, index]
            rescue StandardError => e
              Ractor.yield [e, nil, item, index]
            end
          end
        end
      end

      # start
      ractors.dup.each do |ractor|
        if (set = job_factory.next)
          item, index = set
          instrument_start item, index, options
          ractor.send [callback, item, index]
        else
          ractor.send([[nil, nil], nil, :break]) # stop the ractor
          ractors.delete ractor
        end
      end

      # replace with new items
      while (set = job_factory.next)
        item_next, index_next = set
        done, (exception, result, item, index) = Ractor.select(*ractors)
        if exception
          ractors.delete done
          break
        end
        instrument_finish item, index, result, options
        results_mutex.synchronize { results[index] = (options[:preserve_results] == false ? nil : result) }

        instrument_start item_next, index_next, options
        done.send([callback, item_next, index_next])
      end

      # finish
      ractors.each do |ractor|
        (new_exception, result, item, index) = ractor.take
        exception ||= new_exception
        next if new_exception
        instrument_finish item, index, result, options
        results_mutex.synchronize { results[index] = (options[:preserve_results] == false ? nil : result) }
        ractor.send([[nil, nil], nil, :break]) # stop the ractor
      end

      exception || results
    end

    def work_in_processes(job_factory, options, &blk)
      workers = create_workers(job_factory, options, &blk)
      results = []
      results_mutex = Mutex.new # arrays are not thread-safe
      exception = nil

      UserInterruptHandler.kill_on_ctrl_c(workers.map(&:pid), options) do
        in_threads(options) do |i|
          worker = workers[i]
          worker.thread = Thread.current
          worked = false

          begin
            loop do
              break if exception
              item, index = job_factory.next
              break unless index

              if options[:isolation]
                worker = replace_worker(job_factory, workers, i, options, blk) if worked
                worked = true
                worker.thread = Thread.current
              end

              begin
                result = with_instrumentation item, index, options do
                  worker.work(job_factory.pack(item, index))
                end
                results_mutex.synchronize { results[index] = result } # arrays are not threads safe on jRuby
              rescue StandardError => e
                exception = e
                if exception.is_a?(Kill)
                  (workers - [worker]).each do |w|
                    w.thread&.kill
                    UserInterruptHandler.kill(w.pid)
                  end
                end
              end
            end
          ensure
            worker.stop
          end
        end
      end

      exception || results
    end

    def replace_worker(job_factory, workers, index, options, blk)
      options[:mutex].synchronize do
        # old worker is no longer used ... stop it
        worker = workers[index]
        worker.stop

        # create a new replacement worker
        running = workers - [worker]
        workers[index] = worker(job_factory, options.merge(started_workers: running, worker_number: index), &blk)
      end
    end

    def create_workers(job_factory, options, &block)
      workers = []
      Array.new(options[:count]).each_with_index do |_, i|
        workers << worker(job_factory, options.merge(started_workers: workers, worker_number: i), &block)
      end
      workers
    end

    def worker(job_factory, options, &block)
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = Process.fork do
        self.worker_number = options[:worker_number]

        begin
          options.delete(:started_workers).each(&:close_pipes)

          parent_write.close
          parent_read.close

          process_incoming_jobs(child_read, child_write, job_factory, options, &block)
        ensure
          child_read.close
          child_write.close
        end
      end

      child_read.close
      child_write.close

      Worker.new(parent_read, parent_write, pid)
    end

    def process_incoming_jobs(read, write, job_factory, options, &block)
      until read.eof?
        data = Marshal.load(read)
        item, index = job_factory.unpack(data)

        result =
          begin
            call_with_index(item, index, options, &block)
          # https://github.com/rspec/rspec-support/blob/673133cdd13b17077b3d88ece8d7380821f8d7dc/lib/rspec/support.rb#L132-L140
          rescue NoMemoryError, SignalException, Interrupt, SystemExit # rubocop:disable Lint/ShadowedException
            raise $!
          rescue Exception # # rubocop:disable Lint/RescueException
            ExceptionWrapper.new($!)
          end

        begin
          Marshal.dump(result, write)
        rescue Errno::EPIPE
          return # parent thread already dead
        end
      end
    end

    # options is either a Integer or a Hash with :count
    def extract_count_from_options(options)
      if options.is_a?(Hash)
        count = options[:count]
      else
        count = options
        options = {}
      end
      [count, options]
    end

    def call_with_index(item, index, options, &block)
      args = [item]
      args << index if options[:with_index]
      results = block.call(*args)
      if options[:return_results]
        results
      else
        nil # avoid GC overhead of passing large results around
      end
    end

    def with_instrumentation(item, index, options)
      instrument_start(item, index, options)
      result = yield
      instrument_finish(item, index, result, options)
      result unless options[:preserve_results] == false
    end

    def instrument_finish(item, index, result, options)
      return unless (on_finish = options[:finish])
      return instrument_finish_in_order(item, index, result, options) if options[:finish_in_order]
      options[:mutex].synchronize { on_finish.call(item, index, result) }
    end

    # yield results in the order of the input items
    # needs to use `options` to store state between executions
    # needs to use `done` index since a nil result would also be valid
    def instrument_finish_in_order(item, index, result, options)
      options[:mutex].synchronize do
        # initialize our state
        options[:finish_done] ||= []
        options[:finish_expecting] ||= 0 # we wait for item at index 0

        # store current result
        options[:finish_done][index] = [item, result]

        # yield all results that are now in order
        break unless index == options[:finish_expecting]
        index.upto(options[:finish_done].size).each do |i|
          break unless (done = options[:finish_done][i])
          options[:finish_done][i] = nil # allow GC to free this item and result
          options[:finish].call(done[0], i, done[1])
          options[:finish_expecting] += 1
        end
      end
    end

    def instrument_start(item, index, options)
      return unless (on_start = options[:start])
      options[:mutex].synchronize { on_start.call(item, index) }
    end

    def available_processor_count
      gem 'concurrent-ruby', '>= 1.3.4'
      require 'concurrent-ruby'
      Concurrent.available_processor_count.floor
    rescue LoadError
      require 'etc'
      Etc.nprocessors
    end
  end
end
