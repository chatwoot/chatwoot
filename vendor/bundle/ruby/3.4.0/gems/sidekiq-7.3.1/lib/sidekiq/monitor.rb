#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "sidekiq/api"

class Sidekiq::Monitor
  class Status
    VALID_SECTIONS = %w[all version overview processes queues]
    COL_PAD = 2

    def display(section = nil)
      section ||= "all"
      unless VALID_SECTIONS.include? section
        puts "I don't know how to check the status of '#{section}'!"
        puts "Try one of these: #{VALID_SECTIONS.join(", ")}"
        return
      end
      send(section)
    end

    def all
      version
      puts
      overview
      puts
      processes
      puts
      queues
    end

    def version
      puts "Sidekiq #{Sidekiq::VERSION}"
      puts Time.now.utc
    end

    def overview
      puts "---- Overview ----"
      puts "  Processed: #{delimit stats.processed}"
      puts "     Failed: #{delimit stats.failed}"
      puts "       Busy: #{delimit stats.workers_size}"
      puts "   Enqueued: #{delimit stats.enqueued}"
      puts "    Retries: #{delimit stats.retry_size}"
      puts "  Scheduled: #{delimit stats.scheduled_size}"
      puts "       Dead: #{delimit stats.dead_size}"
    end

    def processes
      puts "---- Processes (#{process_set.size}) ----"
      process_set.each_with_index do |process, index|
        # Keep compatibility with legacy versions since we don't want to break sidekiqmon during rolling upgrades or downgrades.
        #
        # Before:
        #   ["default", "critical"]
        #
        # After:
        #   {"default" => 1, "critical" => 10}
        queues =
          if process["weights"]
            process["weights"].sort_by { |queue| queue[0] }.map { |capsule| capsule.map { |name, weight| (weight > 0) ? "#{name}: #{weight}" : name }.join(", ") }
          else
            process["queues"].sort
          end

        puts "#{process["identity"]} #{tags_for(process)}"
        puts "  Started: #{Time.at(process["started_at"])} (#{time_ago(process["started_at"])})"
        puts "  Threads: #{process["concurrency"]} (#{process["busy"]} busy)"
        puts "   Queues: #{split_multiline(queues, pad: 11)}"
        puts "  Version: #{process["version"] || "Unknown"}" if process["version"] != Sidekiq::VERSION
        puts "" unless (index + 1) == process_set.size
      end
    end

    def queues
      puts "---- Queues (#{queue_data.size}) ----"
      columns = {
        name: [:ljust, (["name"] + queue_data.map(&:name)).map(&:length).max + COL_PAD],
        size: [:rjust, (["size"] + queue_data.map(&:size)).map(&:length).max + COL_PAD],
        latency: [:rjust, (["latency"] + queue_data.map(&:latency)).map(&:length).max + COL_PAD]
      }
      columns.each { |col, (dir, width)| print col.to_s.upcase.public_send(dir, width) }
      puts
      queue_data.each do |q|
        columns.each do |col, (dir, width)|
          print q.send(col).public_send(dir, width)
        end
        puts
      end
    end

    private

    def delimit(number)
      number.to_s.reverse.scan(/.{1,3}/).join(",").reverse
    end

    def split_multiline(values, opts = {})
      return "none" unless values
      pad = opts[:pad] || 0
      max_length = opts[:max_length] || (80 - pad)
      out = []
      line = +""
      values.each do |value|
        if (line.length + value.length) > max_length
          out << line
          line = " " * pad
        end
        line << value + ", "
      end
      out << line[0..-3]
      out.join("\n")
    end

    def tags_for(process)
      tags = [
        process["tag"],
        process["labels"],
        ((process["quiet"] == "true") ? "quiet" : nil)
      ].flatten.compact
      tags.any? ? "[#{tags.join("] [")}]" : nil
    end

    def time_ago(timestamp)
      seconds = Time.now - Time.at(timestamp)
      return "just now" if seconds < 60
      return "a minute ago" if seconds < 120
      return "#{seconds.floor / 60} minutes ago" if seconds < 3600
      return "an hour ago" if seconds < 7200
      "#{seconds.floor / 60 / 60} hours ago"
    end

    QUEUE_STRUCT = Struct.new(:name, :size, :latency)
    def queue_data
      @queue_data ||= Sidekiq::Queue.all.map { |q|
        QUEUE_STRUCT.new(q.name, q.size.to_s, sprintf("%#.2f", q.latency))
      }
    end

    def process_set
      @process_set ||= Sidekiq::ProcessSet.new
    end

    def stats
      @stats ||= Sidekiq::Stats.new
    end
  end
end
