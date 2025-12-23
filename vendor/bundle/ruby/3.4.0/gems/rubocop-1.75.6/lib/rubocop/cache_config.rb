# frozen_string_literal: true

module RuboCop
  # This class represents the cache config of the caching RuboCop runs.
  # @api private
  class CacheConfig
    def self.root_dir
      root = ENV.fetch('RUBOCOP_CACHE_ROOT', nil)
      root ||= yield
      root ||= if ENV.key?('XDG_CACHE_HOME')
                 # Include user ID in the path to make sure the user has write
                 # access.
                 File.join(ENV.fetch('XDG_CACHE_HOME'), Process.uid.to_s)
               else
                 # On FreeBSD, the /home path is a symbolic link to /usr/home
                 # and the $HOME environment variable returns the /home path.
                 #
                 # As $HOME is a built-in environment variable, FreeBSD users
                 # always get a warning message.
                 #
                 # To avoid raising warn log messages on FreeBSD, we retrieve
                 # the real path of the home folder.
                 File.join(File.realpath(Dir.home), '.cache')
               end

      File.join(root, 'rubocop_cache')
    end
  end
end
