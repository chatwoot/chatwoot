require 'fileutils'

require 'sass'
# XXX CE: is this still necessary now that we have the compiler class?
require 'sass/callbacks'
require 'sass/plugin/configuration'
require 'sass/plugin/staleness_checker'

module Sass::Plugin
  # The Compiler class handles compilation of multiple files and/or directories,
  # including checking which CSS files are out-of-date and need to be updated
  # and calling Sass to perform the compilation on those files.
  #
  # {Sass::Plugin} uses this class to update stylesheets for a single application.
  # Unlike {Sass::Plugin}, though, the Compiler class has no global state,
  # and so multiple instances may be created and used independently.
  #
  # If you need to compile a Sass string into CSS,
  # please see the {Sass::Engine} class.
  #
  # Unlike {Sass::Plugin}, this class doesn't keep track of
  # whether or how many times a stylesheet should be updated.
  # Therefore, the following `Sass::Plugin` options are ignored by the Compiler:
  #
  # * `:never_update`
  # * `:always_check`
  class Compiler
    include Configuration
    extend Sass::Callbacks

    # Creates a new compiler.
    #
    # @param opts [{Symbol => Object}]
    #   See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    def initialize(opts = {})
      @watched_files = Set.new
      options.merge!(opts)
    end

    # Register a callback to be run before stylesheets are mass-updated.
    # This is run whenever \{#update\_stylesheets} is called,
    # unless the \{file:SASS_REFERENCE.md#never_update-option `:never_update` option}
    # is enabled.
    #
    # @yield [files]
    # @yieldparam files [<(String, String, String)>]
    #   Individual files to be updated. Files in directories specified are included in this list.
    #   The first element of each pair is the source file,
    #   the second is the target CSS file,
    #   the third is the target sourcemap file.
    define_callback :updating_stylesheets

    # Register a callback to be run after stylesheets are mass-updated.
    # This is run whenever \{#update\_stylesheets} is called,
    # unless the \{file:SASS_REFERENCE.md#never_update-option `:never_update` option}
    # is enabled.
    #
    # @yield [updated_files]
    # @yieldparam updated_files [<(String, String)>]
    #   Individual files that were updated.
    #   The first element of each pair is the source file, the second is the target CSS file.
    define_callback :updated_stylesheets

    # Register a callback to be run after a single stylesheet is updated.
    # The callback is only run if the stylesheet is really updated;
    # if the CSS file is fresh, this won't be run.
    #
    # Even if the \{file:SASS_REFERENCE.md#full_exception-option `:full_exception` option}
    # is enabled, this callback won't be run
    # when an exception CSS file is being written.
    # To run an action for those files, use \{#on\_compilation\_error}.
    #
    # @yield [template, css, sourcemap]
    # @yieldparam template [String]
    #   The location of the Sass/SCSS file being updated.
    # @yieldparam css [String]
    #   The location of the CSS file being generated.
    # @yieldparam sourcemap [String]
    #   The location of the sourcemap being generated, if any.
    define_callback :updated_stylesheet

    # Register a callback to be run when compilation starts.
    #
    # In combination with on_updated_stylesheet, this could be used
    # to collect compilation statistics like timing or to take a
    # diff of the changes to the output file.
    #
    # @yield [template, css, sourcemap]
    # @yieldparam template [String]
    #   The location of the Sass/SCSS file being updated.
    # @yieldparam css [String]
    #   The location of the CSS file being generated.
    # @yieldparam sourcemap [String]
    #   The location of the sourcemap being generated, if any.
    define_callback :compilation_starting

    # Register a callback to be run when Sass decides not to update a stylesheet.
    # In particular, the callback is run when Sass finds that
    # the template file and none of its dependencies
    # have been modified since the last compilation.
    #
    # Note that this is **not** run when the
    # \{file:SASS_REFERENCE.md#never-update_option `:never_update` option} is set,
    # nor when Sass decides not to compile a partial.
    #
    # @yield [template, css]
    # @yieldparam template [String]
    #   The location of the Sass/SCSS file not being updated.
    # @yieldparam css [String]
    #   The location of the CSS file not being generated.
    define_callback :not_updating_stylesheet

    # Register a callback to be run when there's an error
    # compiling a Sass file.
    # This could include not only errors in the Sass document,
    # but also errors accessing the file at all.
    #
    # @yield [error, template, css]
    # @yieldparam error [Exception] The exception that was raised.
    # @yieldparam template [String]
    #   The location of the Sass/SCSS file being updated.
    # @yieldparam css [String]
    #   The location of the CSS file being generated.
    define_callback :compilation_error

    # Register a callback to be run when Sass creates a directory
    # into which to put CSS files.
    #
    # Note that even if multiple levels of directories need to be created,
    # the callback may only be run once.
    # For example, if "foo/" exists and "foo/bar/baz/" needs to be created,
    # this may only be run for "foo/bar/baz/".
    # This is not a guarantee, however;
    # it may also be run for "foo/bar/".
    #
    # @yield [dirname]
    # @yieldparam dirname [String]
    #   The location of the directory that was created.
    define_callback :creating_directory

    # Register a callback to be run when Sass detects
    # that a template has been modified.
    # This is only run when using \{#watch}.
    #
    # @yield [template]
    # @yieldparam template [String]
    #   The location of the template that was modified.
    define_callback :template_modified

    # Register a callback to be run when Sass detects
    # that a new template has been created.
    # This is only run when using \{#watch}.
    #
    # @yield [template]
    # @yieldparam template [String]
    #   The location of the template that was created.
    define_callback :template_created

    # Register a callback to be run when Sass detects
    # that a template has been deleted.
    # This is only run when using \{#watch}.
    #
    # @yield [template]
    # @yieldparam template [String]
    #   The location of the template that was deleted.
    define_callback :template_deleted

    # Register a callback to be run when Sass deletes a CSS file.
    # This happens when the corresponding Sass/SCSS file has been deleted
    # and when the compiler cleans the output files.
    #
    # @yield [filename]
    # @yieldparam filename [String]
    #   The location of the CSS file that was deleted.
    define_callback :deleting_css

    # Register a callback to be run when Sass deletes a sourcemap file.
    # This happens when the corresponding Sass/SCSS file has been deleted
    # and when the compiler cleans the output files.
    #
    # @yield [filename]
    # @yieldparam filename [String]
    #   The location of the sourcemap file that was deleted.
    define_callback :deleting_sourcemap

    # Updates out-of-date stylesheets.
    #
    # Checks each Sass/SCSS file in
    # {file:SASS_REFERENCE.md#template_location-option `:template_location`}
    # to see if it's been modified more recently than the corresponding CSS file
    # in {file:SASS_REFERENCE.md#css_location-option `:css_location`}.
    # If it has, it updates the CSS file.
    #
    # @param individual_files [Array<(String, String[, String])>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    #   The third string, if provided, is the location of the Sourcemap file.
    def update_stylesheets(individual_files = [])
      Sass::Plugin.checked_for_updates = true
      staleness_checker = StalenessChecker.new(engine_options)

      files = file_list(individual_files)
      run_updating_stylesheets(files)

      updated_stylesheets = []
      files.each do |file, css, sourcemap|
        # TODO: Does staleness_checker need to check the sourcemap file as well?
        if options[:always_update] || staleness_checker.stylesheet_needs_update?(css, file)
          # XXX For consistency, this should return the sourcemap too, but it would
          # XXX be an API change.
          updated_stylesheets << [file, css]
          update_stylesheet(file, css, sourcemap)
        else
          run_not_updating_stylesheet(file, css, sourcemap)
        end
      end
      run_updated_stylesheets(updated_stylesheets)
    end

    # Construct a list of files that might need to be compiled
    # from the provided individual_files and the template_locations.
    #
    # Note: this method does not cache the results as they can change
    # across invocations when sass files are added or removed.
    #
    # @param individual_files [Array<(String, String[, String])>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    #   The third string, if provided, is the location of the Sourcemap file.
    # @return [Array<(String, String, String)>]
    #   A list of [sass_file, css_file, sourcemap_file] tuples similar
    #   to what was passed in, but expanded to include the current state
    #   of the directories being updated.
    def file_list(individual_files = [])
      files = individual_files.map do |tuple|
        if engine_options[:sourcemap] == :none
          tuple[0..1]
        elsif tuple.size < 3
          [tuple[0], tuple[1], Sass::Util.sourcemap_name(tuple[1])]
        else
          tuple.dup
        end
      end

      template_location_array.each do |template_location, css_location|
        Sass::Util.glob(File.join(template_location, "**", "[^_]*.s[ca]ss")).sort.each do |file|
          # Get the relative path to the file
          name = Sass::Util.relative_path_from(file, template_location).to_s
          css = css_filename(name, css_location)
          sourcemap = Sass::Util.sourcemap_name(css) unless engine_options[:sourcemap] == :none
          files << [file, css, sourcemap]
        end
      end
      files
    end

    # Watches the template directory (or directories)
    # and updates the CSS files whenever the related Sass/SCSS files change.
    # `watch` never returns.
    #
    # Whenever a change is detected to a Sass/SCSS file in
    # {file:SASS_REFERENCE.md#template_location-option `:template_location`},
    # the corresponding CSS file in {file:SASS_REFERENCE.md#css_location-option `:css_location`}
    # will be recompiled.
    # The CSS files of any Sass/SCSS files that import the changed file will also be recompiled.
    #
    # Before the watching starts in earnest, `watch` calls \{#update\_stylesheets}.
    #
    # Note that `watch` uses the [Listen](http://github.com/guard/listen) library
    # to monitor the filesystem for changes.
    # Listen isn't loaded until `watch` is run.
    # The version of Listen distributed with Sass is loaded by default,
    # but if another version has already been loaded that will be used instead.
    #
    # @param individual_files [Array<(String, String[, String])>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    #   The third string, if provided, is the location of the Sourcemap file.
    # @param options [Hash] The options that control how watching works.
    # @option options [Boolean] :skip_initial_update
    #   Don't do an initial update when starting the watcher when true
    def watch(individual_files = [], options = {})
      @inferred_directories = []
      options, individual_files = individual_files, [] if individual_files.is_a?(Hash)
      update_stylesheets(individual_files) unless options[:skip_initial_update]

      directories = watched_paths
      individual_files.each do |(source, _, _)|
        source = File.expand_path(source)
        @watched_files << Sass::Util.realpath(source).to_s
        @inferred_directories << File.dirname(source)
      end

      directories += @inferred_directories
      directories = remove_redundant_directories(directories)

      # TODO: Keep better track of what depends on what
      # so we don't have to run a global update every time anything changes.
      # XXX The :additional_watch_paths option exists for Compass to use until
      # a deprecated feature is removed. It may be removed without warning.
      directories += Array(options[:additional_watch_paths])

      options = {
        :relative_paths => false,
        # The native windows listener is much slower than the polling option, according to
        # https://github.com/nex3/sass/commit/a3031856b22bc834a5417dedecb038b7be9b9e3e
        :force_polling => @options[:poll] || Sass::Util.windows?
      }

      listener = create_listener(*directories, options) do |modified, added, removed|
        on_file_changed(individual_files, modified, added, removed)
        yield(modified, added, removed) if block_given?
      end

      begin
        listener.start
        sleep
      rescue Interrupt
        # Squelch Interrupt for clean exit from Listen::Listener
      end
    end

    # Non-destructively modifies \{#options} so that default values are properly set,
    # and returns the result.
    #
    # @param additional_options [{Symbol => Object}] An options hash with which to merge \{#options}
    # @return [{Symbol => Object}] The modified options hash
    def engine_options(additional_options = {})
      opts = options.merge(additional_options)
      opts[:load_paths] = load_paths(opts)
      options[:sourcemap] = :auto if options[:sourcemap] == true
      options[:sourcemap] = :none if options[:sourcemap] == false
      opts
    end

    # Compass expects this to exist
    def stylesheet_needs_update?(css_file, template_file)
      StalenessChecker.stylesheet_needs_update?(css_file, template_file)
    end

    # Remove all output files that would be created by calling update_stylesheets, if they exist.
    #
    # This method runs the deleting_css and deleting_sourcemap callbacks for
    # the files that are deleted.
    #
    # @param individual_files [Array<(String, String[, String])>]
    #   A list of files to check for updates
    #   **in addition to those specified by the
    #   {file:SASS_REFERENCE.md#template_location-option `:template_location` option}.**
    #   The first string in each pair is the location of the Sass/SCSS file,
    #   the second is the location of the CSS file that it should be compiled to.
    #   The third string, if provided, is the location of the Sourcemap file.
    def clean(individual_files = [])
      file_list(individual_files).each do |(_, css_file, sourcemap_file)|
        if File.exist?(css_file)
          run_deleting_css css_file
          File.delete(css_file)
        end
        if sourcemap_file && File.exist?(sourcemap_file)
          run_deleting_sourcemap sourcemap_file
          File.delete(sourcemap_file)
        end
      end
      nil
    end

    private

    # This is mocked out in compiler_test.rb.
    def create_listener(*args, &block)
      require 'sass-listen'
      SassListen.to(*args, &block)
    end

    def remove_redundant_directories(directories)
      dedupped = []
      directories.each do |new_directory|
        # no need to add a directory that is already watched.
        next if dedupped.any? do |existing_directory|
          child_of_directory?(existing_directory, new_directory)
        end
        # get rid of any sub directories of this new directory
        dedupped.reject! do |existing_directory|
          child_of_directory?(new_directory, existing_directory)
        end
        dedupped << new_directory
      end
      dedupped
    end

    def on_file_changed(individual_files, modified, added, removed)
      recompile_required = false

      modified.uniq.each do |f|
        next unless watched_file?(f)
        recompile_required = true
        run_template_modified(relative_to_pwd(f))
      end

      added.uniq.each do |f|
        next unless watched_file?(f)
        recompile_required = true
        run_template_created(relative_to_pwd(f))
      end

      removed.uniq.each do |f|
        next unless watched_file?(f)
        run_template_deleted(relative_to_pwd(f))
        if (files = individual_files.find {|(source, _, _)| File.expand_path(source) == f})
          recompile_required = true
          # This was a file we were watching explicitly and compiling to a particular location.
          # Delete the corresponding file.
          try_delete_css files[1]
        else
          next unless watched_file?(f)
          recompile_required = true
          # Look for the sass directory that contained the sass file
          # And try to remove the css file that corresponds to it
          template_location_array.each do |(sass_dir, css_dir)|
            sass_dir = File.expand_path(sass_dir)
            next unless child_of_directory?(sass_dir, f)
            remainder = f[(sass_dir.size + 1)..-1]
            try_delete_css(css_filename(remainder, css_dir))
            break
          end
        end
      end

      return unless recompile_required

      # In case a file we're watching is removed and then recreated we
      # prune out the non-existant files here.
      watched_files_remaining = individual_files.select {|(source, _, _)| File.exist?(source)}
      update_stylesheets(watched_files_remaining)
    end

    def update_stylesheet(filename, css, sourcemap)
      dir = File.dirname(css)
      unless File.exist?(dir)
        run_creating_directory dir
        FileUtils.mkdir_p dir
      end

      begin
        File.read(filename) unless File.readable?(filename) # triggers an error for handling
        engine_opts = engine_options(:css_filename => css,
                                     :filename => filename,
                                     :sourcemap_filename => sourcemap)
        mapping = nil
        run_compilation_starting(filename, css, sourcemap)
        engine = Sass::Engine.for_file(filename, engine_opts)
        if sourcemap
          rendered, mapping = engine.render_with_sourcemap(File.basename(sourcemap))
        else
          rendered = engine.render
        end
      rescue StandardError => e
        compilation_error_occurred = true
        run_compilation_error e, filename, css, sourcemap
        raise e unless options[:full_exception]
        rendered = Sass::SyntaxError.exception_to_css(e, options[:line] || 1)
      end

      write_file(css, rendered)
      if mapping
        write_file(
          sourcemap,
          mapping.to_json(
            :css_path => css, :sourcemap_path => sourcemap, :type => options[:sourcemap]))
      end
      run_updated_stylesheet(filename, css, sourcemap) unless compilation_error_occurred
    end

    def write_file(fileName, content)
      flag = 'w'
      flag = 'wb' if Sass::Util.windows? && options[:unix_newlines]
      File.open(fileName, flag) do |file|
        file.set_encoding(content.encoding)
        file.print(content)
      end
    end

    def try_delete_css(css)
      if File.exist?(css)
        run_deleting_css css
        File.delete css
      end
      map = Sass::Util.sourcemap_name(css)

      return unless File.exist?(map)

      run_deleting_sourcemap map
      File.delete map
    end

    def watched_file?(file)
      @watched_files.include?(file) ||
        normalized_load_paths.any? {|lp| lp.watched_file?(file)} ||
        @inferred_directories.any? {|d| sass_file_in_directory?(d, file)}
    end

    def sass_file_in_directory?(directory, filename)
      filename =~ /\.s[ac]ss$/ && filename.start_with?(directory + File::SEPARATOR)
    end

    def watched_paths
      @watched_paths ||= normalized_load_paths.map {|lp| lp.directories_to_watch}.compact.flatten
    end

    def normalized_load_paths
      @normalized_load_paths ||=
        Sass::Engine.normalize_options(:load_paths => load_paths)[:load_paths]
    end

    def load_paths(opts = options)
      (opts[:load_paths] || []) + template_locations
    end

    def template_locations
      template_location_array.to_a.map {|l| l.first}
    end

    def css_locations
      template_location_array.to_a.map {|l| l.last}
    end

    def css_filename(name, path)
      "#{path}#{File::SEPARATOR unless path.end_with?(File::SEPARATOR)}#{name}".
        gsub(/\.s[ac]ss$/, '.css')
    end

    def relative_to_pwd(f)
      Sass::Util.relative_path_from(f, Dir.pwd).to_s
    rescue ArgumentError # when a relative path cannot be computed
      f
    end

    def child_of_directory?(parent, child)
      parent_dir = parent.end_with?(File::SEPARATOR) ? parent : (parent + File::SEPARATOR)
      child.start_with?(parent_dir) || parent == child
    end
  end
end
