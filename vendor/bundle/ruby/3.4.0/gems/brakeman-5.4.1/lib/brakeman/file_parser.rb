require 'parallel'

module Brakeman
  ASTFile = Struct.new(:path, :ast)

  # This class handles reading and parsing files.
  class FileParser
    attr_reader :file_list, :errors

    def initialize app_tree, timeout, parallel = true
      @app_tree = app_tree
      @timeout = timeout
      @file_list = []
      @errors = []
      @parallel = parallel
    end

    def parse_files list
      if @parallel
        parallel_options = {}
      else
        # Disable parallelism
        parallel_options = { in_threads: 0 }
      end

      # Parse the files in parallel.
      # By default, the parsing will be in separate processes.
      # So we map the result to ASTFiles and/or Exceptions
      # then partition them into ASTFiles and Exceptions
      # and add the Exceptions to @errors
      #
      # Basically just a funky way to deal with two possible
      # return types that are returned from isolated processes.
      #
      # Note this method no longer uses read_files
      @file_list, new_errors = Parallel.map(list, parallel_options) do |file_name|
        file_path = @app_tree.file_path(file_name)
        contents = file_path.read

        begin
          if ast = parse_ruby(contents, file_path.relative)
            ASTFile.new(file_name, ast)
          end
        rescue Exception => e
          e
        end
      end.compact.partition do |result|
        result.is_a? ASTFile
      end

      errors.concat new_errors
    end

    def read_files list
      list.each do |path|
        file = @app_tree.file_path(path)

        begin
          result = yield file, file.read

          if result
            @file_list << result
          end
        rescue Exception => e
          @errors << e
        end
      end
    end

    # _path_ can be a string or a Brakeman::FilePath
    def parse_ruby input, path
      if path.is_a? Brakeman::FilePath
        path = path.relative
      end

      begin
        Brakeman.debug "Parsing #{path}"
        RubyParser.new.parse input, path, @timeout
      rescue Racc::ParseError => e
        raise e.exception(e.message + "\nCould not parse #{path}")
      rescue Timeout::Error => e
        raise Exception.new("Parsing #{path} took too long (> #{@timeout} seconds). Try increasing the limit with --parser-timeout")
      rescue => e
        raise e.exception(e.message + "\nWhile processing #{path}")
      end
    end
  end
end
