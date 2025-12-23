require "foreman/engine"

class Foreman::Engine::CLI < Foreman::Engine

  module Color

    ANSI = {
      :reset          => 0,
      :black          => 30,
      :red            => 31,
      :green          => 32,
      :yellow         => 33,
      :blue           => 34,
      :magenta        => 35,
      :cyan           => 36,
      :white          => 37,
      :bright_black   => 30,
      :bright_red     => 31,
      :bright_green   => 32,
      :bright_yellow  => 33,
      :bright_blue    => 34,
      :bright_magenta => 35,
      :bright_cyan    => 36,
      :bright_white   => 37,
    }

    def self.enable(io, force=false)
      io.extend(self)
      @@color_force = force
    end

    def color?
      return true if @@color_force
      return false if Foreman.windows?
      return false unless self.respond_to?(:isatty)
      self.isatty && ENV["TERM"]
    end

    def color(name)
      return "" unless color?
      return "" unless ansi = ANSI[name.to_sym]
      "\e[#{ansi}m"
    end

  end

  FOREMAN_COLORS = %w( cyan yellow green magenta red blue bright_cyan bright_yellow
                       bright_green bright_magenta bright_red bright_blue )

  def startup
    @colors = map_colors
    proctitle "foreman: master" unless Foreman.windows?
    Color.enable($stdout, options[:color])
  end

  def output(name, data)
    data.to_s.lines.map(&:chomp).each do |message|
      output  = ""
      output += $stdout.color(@colors[name.split(".").first].to_sym)
      output += "#{Time.now.strftime("%H:%M:%S")} " if options[:timestamp]
      output += "#{pad_process_name(name)} | "
      output += $stdout.color(:reset)
      output += message
      $stdout.puts output
      $stdout.flush
    end
  rescue Errno::EPIPE
    terminate_gracefully
  end

  def shutdown
  end

private

  def name_padding
    @name_padding ||= begin
      index_padding = @names.values.map { |n| formation[n] }.max.to_s.length + 1
      name_padding  = @names.values.map { |n| n.length + index_padding }.sort.last
      [ 6, name_padding ].max
    end
  end

  def pad_process_name(name)
    name.ljust(name_padding, " ")
  end

  def map_colors
    colors = Hash.new("white")
    @names.values.each_with_index do |name, index|
      colors[name] = FOREMAN_COLORS[index % FOREMAN_COLORS.length]
    end
    colors["system"] = "bright_white"
    colors
  end

  def proctitle(title)
    $0 = title
  end

  def termtitle(title)
    printf("\033]0;#{title}\007") unless Foreman.windows?
  end

end
