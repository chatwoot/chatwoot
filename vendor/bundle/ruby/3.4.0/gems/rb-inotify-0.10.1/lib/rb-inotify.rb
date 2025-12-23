require 'rb-inotify/version'
require 'rb-inotify/native'
require 'rb-inotify/native/flags'
require 'rb-inotify/notifier'
require 'rb-inotify/watcher'
require 'rb-inotify/event'
require 'rb-inotify/errors'

# The root module of the library, which is laid out as so:
#
# * {Notifier} -- The main class, where the notifications are set up
# * {Watcher} -- A watcher for a single file or directory
# * {Event} -- An filesystem event notification
module INotify
end
