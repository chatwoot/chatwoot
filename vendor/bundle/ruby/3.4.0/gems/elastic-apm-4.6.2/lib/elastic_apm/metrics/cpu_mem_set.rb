# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  module Metrics
    # @api private
    class CpuMemSet < Set
      include Logging

      # @api private
      class Sample
        # rubocop:disable Metrics/ParameterLists
        def initialize(
          page_size:,
          process_cpu_usage:,
          process_memory_rss:,
          process_memory_size:,
          system_cpu_total:,
          system_cpu_usage:,
          system_memory_free:,
          system_memory_total:
        )
          @page_size = page_size
          @process_cpu_usage = process_cpu_usage
          @process_memory_rss = process_memory_rss
          @process_memory_size = process_memory_size
          @system_cpu_total = system_cpu_total
          @system_cpu_usage = system_cpu_usage
          @system_memory_free = system_memory_free
          @system_memory_total = system_memory_total
        end
        # rubocop:enable Metrics/ParameterLists

        attr_accessor(
          :page_size,
          :process_cpu_usage,
          :process_memory_rss,
          :process_memory_size,
          :system_cpu_total,
          :system_cpu_usage,
          :system_memory_free,
          :system_memory_total
        )
      end

      def initialize(config)
        super

        @sampler = sampler_for_os(Metrics.os)
        read! # set initial values to calculate deltas from
      end

      attr_reader :config

      def collect
        read!
        super
      end

      private

      def sampler_for_os(os)
        case os
        when /^linux/ then Linux.new
        else
          warn "Disabling system metrics, unsupported host OS '#{os}'"
          disable!
          nil
        end
      end

      def read!
        return if disabled?

        current = @sampler.sample

        unless @previous
          @previous = current
          return
        end

        cpu_usage_pct, cpu_process_pct = calculate_deltas(current, @previous)

        gauge(:'system.cpu.total.norm.pct').value = cpu_usage_pct
        gauge(:'system.memory.actual.free').value = current.system_memory_free
        gauge(:'system.memory.total').value = current.system_memory_total
        gauge(:'system.process.cpu.total.norm.pct').value = cpu_process_pct
        gauge(:'system.process.memory.size').value = current.process_memory_size
        gauge(:'system.process.memory.rss.bytes').value =
          current.process_memory_rss * current.page_size

        @previous = current
      end

      def calculate_deltas(current, previous)
        system_cpu_total =
          current.system_cpu_total - previous.system_cpu_total
        system_cpu_usage =
          current.system_cpu_usage - previous.system_cpu_usage
        process_cpu_usage =
          current.process_cpu_usage - previous.process_cpu_usage

        # No change / avoid dividing by 0
        return [0, 0] if system_cpu_total == 0

        cpu_usage_pct = system_cpu_usage.to_f / system_cpu_total
        cpu_process_pct = process_cpu_usage.to_f / system_cpu_total

        [cpu_usage_pct, cpu_process_pct]
      end

      # @api private
      class Linux
        def sample
          proc_stat = ProcStat.new.read!
          proc_self_stat = ProcSelfStat.new.read!
          meminfo = Meminfo.new.read!

          Sample.new(
            system_cpu_total: proc_stat.total,
            system_cpu_usage: proc_stat.usage,
            system_memory_total: meminfo.total,
            system_memory_free: meminfo.available,
            process_cpu_usage: proc_self_stat.total,
            process_memory_size: proc_self_stat.vsize,
            process_memory_rss: proc_self_stat.rss,
            page_size: meminfo.page_size
          )
        end

        # @api private
        class ProcStat
          attr_reader :total, :usage

          CPU_FIELDS = %i[
            user
            nice
            system
            idle
            iowait
            irq
            softirq
            steal
            guest
            guest_nice
          ].freeze
          def read!
            stat =
              IO.readlines('/proc/stat')
                .lazy
                .find { |sp| sp.start_with?('cpu ') }
                .split
                .map(&:to_i)[1..-1]

            values =
              CPU_FIELDS.each_with_index.each_with_object({}) do |(key, i), v|
                v[key] = stat[i] || 0
              end

            @total =
              values[:user] +
              values[:nice] +
              values[:system] +
              values[:idle] +
              values[:iowait] +
              values[:irq] +
              values[:softirq] +
              values[:steal]

            @usage = @total - (values[:idle] + values[:iowait])

            self
          end
        end

        UTIME_POS = 13
        STIME_POS = 14
        VSIZE_POS = 22
        RSS_POS = 23

        # @api private
        class ProcSelfStat
          attr_reader :total, :vsize, :rss

          def read!
            stat =
              IO.readlines('/proc/self/stat')
                .lazy
                .first
                .split
                .map(&:to_i)

            @total = stat[UTIME_POS] + stat[STIME_POS]
            @vsize = stat[VSIZE_POS]
            @rss = stat[RSS_POS]

            self
          end
        end

        # @api private
        class Meminfo
          attr_reader :total, :available, :page_size

          # rubocop:disable Metrics/PerceivedComplexity
          # rubocop:disable Metrics/CyclomaticComplexity
          def read!
            # rubocop:disable Style/RescueModifier
            @page_size = `getconf PAGESIZE`.chomp.to_i rescue 4096
            # rubocop:enable Style/RescueModifier

            info =
              IO.readlines('/proc/meminfo')
                .lazy
                .each_with_object({}) do |line, hsh|
                  if line.start_with?('MemTotal:')
                    hsh[:total] = line.split[1].to_i * 1024
                  elsif line.start_with?('MemAvailable:')
                    hsh[:available] = line.split[1].to_i * 1024
                  elsif line.start_with?('MemFree:')
                    hsh[:free] = line.split[1].to_i * 1024
                  elsif line.start_with?('Buffers:')
                    hsh[:buffers] = line.split[1].to_i * 1024
                  elsif line.start_with?('Cached:')
                    hsh[:cached] = line.split[1].to_i * 1024
                  end

                  break hsh if hsh[:total] && hsh[:available]
                end

            @total = info[:total]
            @available =
              info[:available] || info[:free] + info[:buffers] + info[:cached]

            self
          end
          # rubocop:enable Metrics/CyclomaticComplexity
          # rubocop:enable Metrics/PerceivedComplexity
        end
      end
    end
  end
end
