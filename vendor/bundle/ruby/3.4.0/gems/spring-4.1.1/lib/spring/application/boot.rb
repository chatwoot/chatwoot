# This is necessary for the terminal to work correctly when we reopen stdin.
Process.setsid

require "spring/application"

app = Spring::Application.new(
  UNIXSocket.for_fd(3),
  Spring::JSON.load(ENV.delete("SPRING_ORIGINAL_ENV").dup),
  Spring::Env.new(log_file: IO.for_fd(4))
)

Signal.trap("TERM") { app.terminate }

Spring::ProcessTitleUpdater.run { |distance|
  "spring app    | #{app.app_name} | started #{distance} ago | #{app.app_env} mode"
}

app.eager_preload if ENV.delete("SPRING_PRELOAD") == "1"
app.run
