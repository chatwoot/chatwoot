# frozen_string_literal: true

require "erb"
require "fileutils"
require "digest/sha1"
require "time"

# Ensure we are using a compatible version of SimpleCov
major, minor, patch = SimpleCov::VERSION.scan(/\d+/).first(3).map(&:to_i)
if major < 0 || minor < 9 || patch < 0
  raise "The version of SimpleCov you are using is too old. " \
        "Please update with `gem install simplecov` or `bundle update simplecov`"
end

module SimpleCov
  module Formatter
    class HTMLFormatter
      # Only have a few content types, just hardcode them
      CONTENT_TYPES = {
        ".js" => "text/javascript",
        ".png" => "image/png",
        ".gif" => "image/gif",
        ".css" => "text/css",
      }.freeze

      def initialize
        @branchable_result = SimpleCov.branch_coverage?
        @templates = {}
        @inline_assets = !ENV["SIMPLECOV_INLINE_ASSETS"].nil?
        @public_assets_dir = File.join(File.dirname(__FILE__), "../public/")
      end

      def format(result)
        unless @inline_assets
          Dir[File.join(@public_assets_dir, "*")].each do |path|
            FileUtils.cp_r(path, asset_output_path, remove_destination: true)
          end
        end

        File.open(File.join(output_path, "index.html"), "wb") do |file|
          file.puts template("layout").result(binding)
        end
        puts output_message(result)
      end

    private

      def branchable_result?
        # cached in initialize because we truly look it up a whole bunch of times
        # and it's easier to cache here then in SimpleCov because there we might
        # still enable/disable branch coverage criterion
        @branchable_result
      end

      def line_status?(source_file, line)
        if branchable_result? && source_file.line_with_missed_branch?(line.number)
          "missed-branch"
        else
          line.status
        end
      end

      def output_message(result)
        output = "Coverage report generated for #{result.command_name} to #{output_path}."
        output += "\nLine Coverage: #{result.covered_percent.round(2)}% (#{result.covered_lines} / #{result.total_lines})"
        output += "\nBranch Coverage: #{result.coverage_statistics[:branch].percent.round(2)}% (#{result.covered_branches} / #{result.total_branches})" if branchable_result?
        output
      end

      # Returns the an erb instance for the template of given name
      def template(name)
        @templates[name] ||= ERB.new(File.read(File.join(File.dirname(__FILE__), "../views/", "#{name}.erb")))
      end

      def output_path
        SimpleCov.coverage_path
      end

      def asset_output_path
        return @asset_output_path if defined?(@asset_output_path) && @asset_output_path

        @asset_output_path = File.join(output_path, "assets", SimpleCov::Formatter::HTMLFormatter::VERSION)
        FileUtils.mkdir_p(@asset_output_path)
        @asset_output_path
      end

      def assets_path(name)
        return asset_inline(name) if @inline_assets

        File.join("./assets", SimpleCov::Formatter::HTMLFormatter::VERSION, name)
      end

      def asset_inline(name)
        path = File.join(@public_assets_dir, name)
        # Equivalent to `Base64.strict_encode64(File.read(path))` but without depending on Base64
        base64_content = [File.read(path)].pack("m0")

        content_type = CONTENT_TYPES[File.extname(name)]

        "data:#{content_type};base64,#{base64_content}"
      end

      # Returns the html for the given source_file
      def formatted_source_file(source_file)
        template("source_file").result(binding)
      rescue Encoding::CompatibilityError => e
        puts "Encoding problems with file #{source_file.filename}. Simplecov/ERB can't handle non ASCII characters in filenames. Error: #{e.message}."
      end

      # Returns a table containing the given source files
      def formatted_file_list(title, source_files)
        title_id = title.gsub(/^[^a-zA-Z]+/, "").gsub(/[^a-zA-Z0-9\-_]/, "")
        # Silence a warning by using the following variable to assign to itself:
        # "warning: possibly useless use of a variable in void context"
        # The variable is used by ERB via binding.
        title_id = title_id # rubocop:disable Lint/SelfAssignment
        template("file_list").result(binding)
      end

      def covered_percent(percent)
        template("covered_percent").result(binding)
      end

      def coverage_css_class(covered_percent)
        if covered_percent > 90
          "green"
        elsif covered_percent > 80
          "yellow"
        else
          "red"
        end
      end

      def strength_css_class(covered_strength)
        if covered_strength > 1
          "green"
        elsif covered_strength == 1
          "yellow"
        else
          "red"
        end
      end

      # Return a (kind of) unique id for the source file given. Uses SHA1 on path for the id
      def id(source_file)
        Digest::SHA1.hexdigest(source_file.filename)
      end

      def timeago(time)
        "<abbr class=\"timeago\" title=\"#{time.iso8601}\">#{time.iso8601}</abbr>"
      end

      def shortened_filename(source_file)
        source_file.filename.sub(SimpleCov.root, ".").gsub(/^\.\//, "")
      end

      def link_to_source_file(source_file)
        %(<a href="##{id source_file}" class="src_link" title="#{shortened_filename source_file}">#{shortened_filename source_file}</a>)
      end
    end
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require "simplecov-html/version"
