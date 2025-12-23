require 'date'
require 'sass/util'

module Sass
  # Handles Sass version-reporting.
  # Sass not only reports the standard three version numbers,
  # but its Git revision hash as well,
  # if it was installed from Git.
  module Version
    # Returns a hash representing the version of Sass.
    # The `:major`, `:minor`, and `:teeny` keys have their respective numbers as Integers.
    # The `:name` key has the name of the version.
    # The `:string` key contains a human-readable string representation of the version.
    # The `:number` key is the major, minor, and teeny keys separated by periods.
    # The `:date` key, which is not guaranteed to be defined, is the `DateTime`
    #   at which this release was cut.
    # If Sass is checked out from Git, the `:rev` key will have the revision hash.
    # For example:
    #
    #     {
    #       :string => "2.1.0.9616393",
    #       :rev    => "9616393b8924ef36639c7e82aa88a51a24d16949",
    #       :number => "2.1.0",
    #       :date   => DateTime.parse("Apr 30 13:52:01 2009 -0700"),
    #       :major  => 2, :minor => 1, :teeny => 0
    #     }
    #
    # If a prerelease version of Sass is being used,
    # the `:string` and `:number` fields will reflect the full version
    # (e.g. `"2.2.beta.1"`), and the `:teeny` field will be `-1`.
    # A `:prerelease` key will contain the name of the prerelease (e.g. `"beta"`),
    # and a `:prerelease_number` key will contain the rerelease number.
    # For example:
    #
    #     {
    #       :string => "3.0.beta.1",
    #       :number => "3.0.beta.1",
    #       :date   => DateTime.parse("Mar 31 00:38:04 2010 -0700"),
    #       :major => 3, :minor => 0, :teeny => -1,
    #       :prerelease => "beta",
    #       :prerelease_number => 1
    #     }
    #
    # @return [{Symbol => String/Integer}] The version hash
    def version
      return @@version if defined?(@@version)

      numbers = File.read(Sass::Util.scope('VERSION')).strip.split('.').
        map {|n| n =~ /^[0-9]+$/ ? n.to_i : n}
      name = File.read(Sass::Util.scope('VERSION_NAME')).strip
      @@version = {
        :major => numbers[0],
        :minor => numbers[1],
        :teeny => numbers[2],
        :name => name
      }

      if (date = version_date)
        @@version[:date] = date
      end

      if numbers[3].is_a?(String)
        @@version[:teeny] = -1
        @@version[:prerelease] = numbers[3]
        @@version[:prerelease_number] = numbers[4]
      end

      @@version[:number] = numbers.join('.')
      @@version[:string] = @@version[:number].dup

      if (rev = revision_number)
        @@version[:rev] = rev
        unless rev[0] == ?(
          @@version[:string] << "." << rev[0...7]
        end
      end

      @@version
    end

    private

    def revision_number
      if File.exist?(Sass::Util.scope('REVISION'))
        rev = File.read(Sass::Util.scope('REVISION')).strip
        return rev unless rev =~ /^([a-f0-9]+|\(.*\))$/ || rev == '(unknown)'
      end

      return unless File.exist?(Sass::Util.scope('.git/HEAD'))
      rev = File.read(Sass::Util.scope('.git/HEAD')).strip
      return rev unless rev =~ /^ref: (.*)$/

      ref_name = $1
      ref_file = Sass::Util.scope(".git/#{ref_name}")
      info_file = Sass::Util.scope(".git/info/refs")
      return File.read(ref_file).strip if File.exist?(ref_file)
      return unless File.exist?(info_file)
      File.open(info_file) do |f|
        f.each do |l|
          sha, ref = l.strip.split("\t", 2)
          next unless ref == ref_name
          return sha
        end
      end
      nil
    end

    def version_date
      return unless File.exist?(Sass::Util.scope('VERSION_DATE'))
      DateTime.parse(File.read(Sass::Util.scope('VERSION_DATE')).strip)
    end
  end

  extend Sass::Version

  # A string representing the version of Sass.
  # A more fine-grained representation is available from Sass.version.
  # @api public
  VERSION = version[:string] unless defined?(Sass::VERSION)
end
