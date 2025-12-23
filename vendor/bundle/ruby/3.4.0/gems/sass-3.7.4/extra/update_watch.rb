require 'rubygems'
require 'sinatra'
require 'json'
set :port, 3124
set :environment, :production
enable :lock
Dir.chdir(File.dirname(__FILE__) + "/..")

post "/" do
  puts "Received payload!"
  puts "Rev: #{`git name-rev HEAD`.strip}"
  system %{rake handle_update --trace REF=#{JSON.parse(params["payload"])["ref"].inspect}}
end
