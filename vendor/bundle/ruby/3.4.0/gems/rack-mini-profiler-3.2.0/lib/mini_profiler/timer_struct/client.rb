# frozen_string_literal: true

module Rack
  class MiniProfiler
    module TimerStruct

      # This class holds the client timings
      class Client < TimerStruct::Base

        def self.init_instrumentation
          %Q{
            <script type="text/javascript">
              mPt=function(){var t=[];return{t:t,probe:function(n){t.push({d:new Date(),n:n})}}}()
            </script>
          }
        end

        # used by Railtie to instrument asset_tag for JS / CSS
        def self.instrument(name, orig)
          probe = "<script>mPt.probe('#{name}')</script>".dup
          wrapped = probe
          wrapped << orig
          wrapped << probe
          wrapped
        end

        def initialize(env = {})
          super
        end

        def redirect_count
          self[:redirect_count]
        end

        def timings
          self[:timings]
        end

        def self.init_from_form_data(env, page_struct)
          timings = []
          clientTimes, clientPerf, baseTime = nil
          form = env['rack.request.form_hash']

          clientPerf  = form['clientPerformance']           if form
          clientTimes = clientPerf['timing']                if clientPerf
          baseTime    = clientTimes['navigationStart'].to_i if clientTimes
          return unless clientTimes && baseTime

          probes     = form['clientProbes']
          translated = {}
          if probes && !["null", ""].include?(probes)
            probes.each do |id, val|
              name = val["n"]
              translated[name] ||= {}
              if translated[name][:start]
                translated[name][:finish] = val["d"]
              else
                translated[name][:start]  = val["d"]
              end
            end
          end

          translated.each do |name, data|
            h = { "Name" => name, "Start" => data[:start].to_i - baseTime }
            h["Duration"] = data[:finish].to_i - data[:start].to_i if data[:finish]
            timings.push(h)
          end

          clientTimes.keys.find_all { |k| k =~ /Start$/ }.each do |k|
            start    = clientTimes[k].to_i - baseTime
            finish   = clientTimes[k.sub(/Start$/, "End")].to_i - baseTime
            duration = 0
            duration = finish - start if finish > start
            name     = k.sub(/Start$/, "").split(/(?=[A-Z])/).map { |s| s.capitalize }.join(' ')
            timings.push("Name" => name, "Start" => start, "Duration" => duration) if start >= 0
          end

          clientTimes.keys.find_all { |k| !(k =~ /(End|Start)$/) }.each do |k|
            timings.push("Name" => k, "Start" => clientTimes[k].to_i - baseTime, "Duration" => -1)
          end

          TimerStruct::Client.new.tap do |rval|
            rval[:redirect_count] = env['rack.request.form_hash']['clientPerformance']['navigation']['redirect_count']
            rval[:timings]        = timings
          end
        end
      end
    end
  end
end
