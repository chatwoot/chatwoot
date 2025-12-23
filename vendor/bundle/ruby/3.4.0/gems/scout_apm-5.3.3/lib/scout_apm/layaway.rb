# Stores StoreReportingPeriod objects in a per-process file before sending them to the server.
# Coordinates a single process to collect up all individual files, merge them, then send.
#
# Each layaway file is named basedir/scout_#{timestamp}_#{pid}.data
#   Where timestamp is in the format:
#   And PID is the process id of the running process
#
module ScoutApm
  class Layaway
    # How long to let a stale file sit before deleting it.
    # Letting it sit a bit may be useful for debugging
    STALE_AGE = 10 * 60

    # Failsafe to prevent writing layaway files if for some reason they are not being cleaned up
    MAX_FILES_LIMIT = 5000

    # A strftime format string for how we render timestamps in filenames.
    # Must be sortable as an integer
    TIME_FORMAT = "%Y%m%d%H%M"

    attr_reader :context
    def initialize(context)
      @context = context
    end

    def logger
      context.logger
    end

    # Returns a Pathname object with the fully qualified directory where the layaway files can be placed.
    # That directory must be writable by this process.
    #
    # Don't set this in initializer, since it relies on agent instance existing to figure out the value.
    #
    def directory
      return @directory if @directory

      data_file = context.config.value("data_file")
      data_file = File.dirname(data_file) if data_file && !File.directory?(data_file)

      candidates = [
        data_file,
        "#{context.environment.root}/tmp",
        "/tmp"
      ].compact

      found = candidates.detect { |dir| File.writable?(dir) }
      logger.debug("Storing Layaway Files in #{found}")
      @directory = Pathname.new(found)
    end

    def write_reporting_period(reporting_period, files_limit = MAX_FILES_LIMIT)
      if at_layaway_file_limit?(files_limit)
        # This will happen constantly once we hit this case, so only log the first time
        @wrote_layaway_limit_error_message ||= logger.error("Layaway: Hit layaway file limit. Not writing to layaway file")
        return false
      end
      logger.debug("Layaway: wrote time period: #{reporting_period.timestamp}")
      filename = file_for(reporting_period.timestamp)
      layaway_file = LayawayFile.new(context, filename)
      layaway_file.write(reporting_period)
    rescue => e
      logger.debug("Layaway: error writing: #{e.message}, #{e.backtrace.inspect}")
      raise e
    end

    # Claims a given timestamp by getting an exclusive lock on a timestamped
    # coordinator file. The coordinator file never contains data, it's just a
    # syncronization mechanism.
    #
    # Once the 'claim' is obtained:
    #   * load and yield each ReportingPeriod from the layaway files.
    #   * if there are reporting periods:
    #     * yields any ReportingPeriods collected up from all the files.
    #     * deletes all of the layaway files (including the coordinator) for the timestamp
    #   * if not
    #     * delete the coordinator
    #   * remove any stale layaway files that may be hanging around.
    #   * Finally unlock and ensure the coordinator file is cleared.
    #
    # If a claim file can't be obtained, return false without doing any work
    # Another process is handling the reporting.
    def with_claim(timestamp)
      coordinator_file = glob_pattern(timestamp, :coordinator)

      begin
        # This file gets deleted only by a process that successfully created and obtained the exclusive lock
        f = File.open(coordinator_file, File::RDWR | File::CREAT | File::EXCL | File::NONBLOCK)
      rescue Errno::EEXIST
        false
      end

      begin
        if f
          begin
            logger.debug("Obtained Reporting Lock")

            log_layaway_file_information

            files = all_files_for(timestamp).reject{|l| l.to_s == coordinator_file.to_s }
            rps = files.map{ |layaway| LayawayFile.new(context, layaway).load }.compact
            if rps.any?
              yield rps

              logger.debug("Layaway: Deleting the now-reported files for #{timestamp.to_s}")
              delete_files_for(timestamp) # also removes the coodinator_file
            else
              File.unlink(coordinator_file)
              logger.debug("Layaway: No files to report")
            end

            logger.debug("Layaway: Checking for any stale files")
            delete_stale_files(timestamp.to_time - STALE_AGE)

            true
          rescue Exception => e
            logger.debug("Layaway: Caught an exception in with_claim, with the coordination file locked: #{e.message}, #{e.backtrace.inspect}")
            raise
          ensure
            # Unlock the file when done!
            f.flock(File::LOCK_UN | File::LOCK_NB)
            f.close
          end
        else
          # Didn't obtain lock, another process is reporting. Return false from this function, but otherwise no work
          false
        end
      end
    end

    def delete_files_for(timestamp)
      all_files_for(timestamp).each { |layaway|
        logger.debug("Layaway: Deleting file: #{layaway}")
        File.unlink(layaway)
      }
    end

    def delete_stale_files(older_than)
      all_files_for(:all).
        map { |filename| timestamp_from_filename(filename) }.
        compact.
        uniq.
        select { |timestamp| timestamp.to_i < older_than.strftime(TIME_FORMAT).to_i }.
          tap  { |timestamps| logger.debug("Layaway: Deleting stale files with timestamps: #{timestamps.inspect}") }.
        map    { |timestamp| delete_files_for(timestamp) }
    rescue => e
      logger.debug("Layaway: Problem deleting stale files: #{e.message}, #{e.backtrace.inspect}")
    end

    private

    ##########################################
    # Looking up files

    def file_for(timestamp)
      glob_pattern(timestamp)
    end

    def all_files_for(timestamp)
      Dir[glob_pattern(timestamp, :all)]
    end

    # Timestamp should be either :all or a Time-ish object that responds to strftime (StoreReportingPeriodTimestamp does)
    # if timestamp == :all then find all timestamps, otherwise format it.
    # if pid == :all, get the files for all
    def glob_pattern(timestamp, pid=$$)
      timestamp_pattern = format_timestamp(timestamp)
      pid_pattern = format_pid(pid)
      directory + "scout_#{timestamp_pattern}_#{pid_pattern}.data"
    end

    def format_timestamp(timestamp)
      if timestamp == :all
        "*"
      elsif timestamp.respond_to?(:strftime)
        timestamp.strftime(TIME_FORMAT)
      else
        timestamp.to_s
      end
    end

    def format_pid(pid)
      if pid == :all
        "*"
      else
        pid.to_s
      end
    end

    def timestamp_from_filename(filename)
      match = filename.match(%r{scout_(\d+)_\d+\.data\z})
      if match
        match[1]
      else
        nil
      end
    end

    def at_layaway_file_limit?(files_limit = MAX_FILES_LIMIT)
      all_files_for(:all).count >= files_limit
    end

    def log_layaway_file_information
      files_in_temp = Dir["#{directory}/*"].count

      all_filenames = all_files_for(:all)
      count_per_timestamp = Hash[
        all_filenames.
        group_by {|f| timestamp_from_filename(f) }.
        map{ |timestamp, list| [timestamp, list.length] }
      ]

      logger.debug("Layaway: Total Files in #{directory}: #{files_in_temp}. Total Layaway Files: #{all_filenames.size}.  By Timestamp: #{count_per_timestamp.inspect}")
    end
  end
end

