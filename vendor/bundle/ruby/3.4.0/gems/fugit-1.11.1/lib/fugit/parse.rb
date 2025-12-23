# frozen_string_literal: true

module Fugit

  class << self

    def parse_cron(s); ::Fugit::Cron.parse(s); end
    def parse_duration(s); ::Fugit::Duration.parse(s); end
    def parse_nat(s, opts={}); ::Fugit::Nat.parse(s, opts); end
    def parse_at(s); ::Fugit::At.parse(s); end
    def parse_in(s); parse_duration(s); end

    def do_parse_cron(s); ::Fugit::Cron.do_parse(s); end
    def do_parse_duration(s); ::Fugit::Duration.do_parse(s); end
    def do_parse_nat(s, opts={}); ::Fugit::Nat.do_parse(s, opts); end
    def do_parse_at(s); ::Fugit::At.do_parse(s); end
    def do_parse_in(s); do_parse_duration(s); end

    def parse(s, opts={})

      opts[:at] = opts[:in] if opts.has_key?(:in)

      (opts[:cron] != false && parse_cron(s)) || # 542ms 616ms
      (opts[:duration] != false && parse_duration(s)) || # 645ms # 534ms
      (opts[:nat] != false && parse_nat(s, opts)) || # 2s # 35s
      (opts[:at] != false && parse_at(s)) || # 568ms 622ms
      nil
    end

    def do_parse(s, opts={})

      opts[:at] = opts[:in] if opts.has_key?(:in)

      result = nil
      errors = []

      %i[ cron duration nat at ]
        .each { |k|
          begin
            result ||= (opts[k] != false && self.send("do_parse_#{k}", s))
          rescue => err
            errors << err
          end }

      return result if result

      raise(
        errors.find { |r| r.class != ArgumentError } ||
        errors.first ||
        ArgumentError.new("found no time information in #{s.inspect}"))
    end

    def parse_cronish(s, opts={})

      r = parse_cron(s) || parse_nat(s, opts)

      r.is_a?(::Fugit::Cron) ? r : nil
    end

    def do_parse_cronish(s, opts={})

      parse_cronish(s) ||
      fail(ArgumentError.new("not cron or 'natural' cron string: #{s.inspect}"))
    end

    def determine_type(s)

      case self.parse(s)
      when ::Fugit::Cron then 'cron'
      when ::Fugit::Duration then 'in'
      when ::Time, ::EtOrbi::EoTime then 'at'
      else nil
      end
    end
  end
end

