module SassListen
  # @private api
  class Record
    # Represents a directory entry (dir or file)
    class Entry
      # file: "/home/me/watched_dir", "app/models", "foo.rb"
      # dir, "/home/me/watched_dir", "."
      def initialize(root, relative, name = nil)
        @root, @relative, @name = root, relative, name
      end

      attr_reader :root, :relative, :name

      def children
        child_relative = _join
        (_entries(sys_path) - %w(. ..)).map do |name|
          Entry.new(@root, child_relative, name)
        end
      end

      def meta
        lstat = ::File.lstat(sys_path)
        { mtime: lstat.mtime.to_f, mode: lstat.mode }
      end

      # record hash is e.g.
      # if @record["/home/me/watched_dir"]["project/app/models"]["foo.rb"]
      # if @record["/home/me/watched_dir"]["project/app"]["models"]
      # record_dir_key is "project/app/models"
      def record_dir_key
        ::File.join(*[@relative, @name].compact)
      end

      def sys_path
        # Use full path in case someone uses chdir
        ::File.join(*[@root, @relative, @name].compact)
      end

      def real_path
        @real_path ||= ::File.realpath(sys_path)
      end

      private

      def _join
        args = [@relative, @name].compact
        args.empty? ? nil : ::File.join(*args)
      end

      def _entries(dir)
        return Dir.entries(dir) unless RUBY_ENGINE == 'jruby'

        # JRuby inconsistency workaround, see:
        # https://github.com/jruby/jruby/issues/3840
        exists = ::File.exist?(dir)
        directory = ::File.directory?(dir)
        return Dir.entries(dir) unless (exists && !directory)
        raise Errno::ENOTDIR, dir
      end
    end
  end
end
