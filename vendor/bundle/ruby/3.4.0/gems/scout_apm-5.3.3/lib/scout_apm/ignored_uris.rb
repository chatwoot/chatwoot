# On first run, caches the regexes made by the `ignored` configuration setting
module ScoutApm
  class IgnoredUris
    attr_reader :regex

    def initialize(prefixes)
      regexes = Array(prefixes).
        reject{|prefix| prefix == ""}.
        map {|prefix| %r{\A#{prefix}} }
      @regex = Regexp.union(*regexes)
    end

    def ignore?(uri)
      !! regex.match(uri)
    end
  end
end
