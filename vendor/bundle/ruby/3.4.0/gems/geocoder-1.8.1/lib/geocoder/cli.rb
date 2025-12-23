require 'geocoder'
require 'optparse'

module Geocoder
  class Cli

    def self.run(args, out = STDOUT)
      show_url  = false
      show_json = false

      # remove arguments that are probably coordinates so they are not
      # processed as arguments (eg: -31.96047031,115.84274631)
      coords = args.select{ |i| i.match(/^-\d/) }
      args -= coords

      OptionParser.new{ |opts|
        opts.banner = "Usage:\n    geocode [options] <location>"
        opts.separator "\nOptions: "

        opts.on("-k <key>", "--key <key>",
          "Key for geocoding API (usually optional). Enclose multi-part keys in quotes and separate parts by spaces") do |key|
          if (key_parts = key.split(/\s+/)).size > 1
            Geocoder.configure(:api_key => key_parts)
          else
            Geocoder.configure(:api_key => key)
          end
        end

        opts.on("-l <language>", "--language <language>",
          "Language of output (see API docs for valid choices)") do |language|
          Geocoder.configure(:language => language)
        end

        opts.on("-p <proxy>", "--proxy <proxy>",
          "HTTP proxy server to use (user:pass@host:port)") do |proxy|
          Geocoder.configure(:http_proxy => proxy)
        end

        opts.on("-s <service>", Geocoder::Lookup.all_services_except_test, "--service <service>",
          "Geocoding service: #{Geocoder::Lookup.all_services_except_test * ', '}") do |service|
          Geocoder.configure(:lookup => service.to_sym)
          Geocoder.configure(:ip_lookup => service.to_sym)
        end

        opts.on("-t <seconds>", "--timeout <seconds>",
          "Maximum number of seconds to wait for API response") do |timeout|
          Geocoder.configure(:timeout => timeout.to_i)
        end

        opts.on("-j", "--json", "Print API's raw JSON response") do
          show_json = true
        end

        opts.on("-u", "--url", "Print URL for API query instead of result") do
          show_url = true
        end

        opts.on_tail("-v", "--version", "Print version number") do
          require "geocoder/version"
          out << "Geocoder #{Geocoder::VERSION}\n"
          exit
        end

        opts.on_tail("-h", "--help", "Print this help") do
          out << "Look up geographic information about a location.\n\n"
          out << opts
          out << "\nCreated and maintained by Alex Reisner, available under the MIT License.\n"
          out << "Report bugs and contribute at http://github.com/alexreisner/geocoder\n"
          exit
        end
      }.parse!(args)

      # concatenate args with coords that might have been removed
      # before option processing
      query = (args + coords).join(" ")

      if query == ""
        out << "Please specify a location (run `geocode -h` for more info).\n"
        exit 1
      end

      if show_url and show_json
        out << "You can only specify one of -j and -u.\n"
        exit 2
      end

      if show_url
        q = Geocoder::Query.new(query)
        out << q.url + "\n"
        exit 0
      end

      if show_json
        q = Geocoder::Query.new(query)
        out << q.lookup.send(:fetch_raw_data, q) + "\n"
        exit 0
      end

      if (result = Geocoder.search(query).first)
        nominatim = Geocoder::Lookup.get(:nominatim)
        lines = [
          ["Latitude",       result.latitude],
          ["Longitude",      result.longitude],
          ["Full address",   result.address],
          ["City",           result.city],
          ["State/province", result.state],
          ["Postal code",    result.postal_code],
          ["Country",        result.country],
          ["Map",            nominatim.map_link_url(result.coordinates)],
        ]
        lines.each do |line|
          out << (line[0] + ": ").ljust(18) + line[1].to_s + "\n"
        end
        exit 0
      else
        out << "Location '#{query}' not found.\n"
        exit 1
      end
    end
  end
end
