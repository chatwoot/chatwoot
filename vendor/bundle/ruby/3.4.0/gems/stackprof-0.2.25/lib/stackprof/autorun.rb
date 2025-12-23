require "stackprof"

options = {}
options[:mode] = ENV["STACKPROF_MODE"].to_sym if ENV.key?("STACKPROF_MODE")
options[:interval] = Integer(ENV["STACKPROF_INTERVAL"]) if ENV.key?("STACKPROF_INTERVAL")
options[:raw] = true if ENV["STACKPROF_RAW"]
options[:ignore_gc] = true if ENV["STACKPROF_IGNORE_GC"]

at_exit do
  StackProf.stop
  output_path = ENV.fetch("STACKPROF_OUT") do
    require "tempfile"
    Tempfile.create(["stackprof", ".dump"]).path
  end
  StackProf.results(output_path)
  $stderr.puts("StackProf results dumped at: #{output_path}")
end

StackProf.start(**options)
