require 'set'

module SassListen
  # TODO: refactor (turn it into a normal object, cache the stat, etc)
  class Directory
    def self.scan(snapshot, rel_path, options)
      record = snapshot.record
      dir = Pathname.new(record.root)
      previous = record.dir_entries(rel_path)

      record.add_dir(rel_path)

      # TODO: use children(with_directory: false)
      path = dir + rel_path
      current = Set.new(_children(path))

      SassListen::Logger.debug do
        format('%s: %s(%s): %s -> %s',
               (options[:silence] ? 'Recording' : 'Scanning'),
               rel_path, options.inspect, previous.inspect, current.inspect)
      end

      begin
        current.each do |full_path|
          type = ::File.lstat(full_path.to_s).directory? ? :dir : :file
          item_rel_path = full_path.relative_path_from(dir).to_s
          _change(snapshot, type, item_rel_path, options)
        end
      rescue Errno::ENOENT
        # The directory changed meanwhile, so rescan it
        current = Set.new(_children(path))
        retry
      end

      # TODO: this is not tested properly
      previous = previous.reject { |entry, _| current.include? path + entry }

      _async_changes(snapshot, Pathname.new(rel_path), previous, options)

    rescue Errno::ENOENT, Errno::EHOSTDOWN
      record.unset_path(rel_path)
      _async_changes(snapshot, Pathname.new(rel_path), previous, options)

    rescue Errno::ENOTDIR
      # TODO: path not tested
      record.unset_path(rel_path)
      _async_changes(snapshot, path, previous, options)
      _change(snapshot, :file, rel_path, options)
    rescue
      SassListen::Logger.warn do
        format('scan DIED: %s:%s', $ERROR_INFO, $ERROR_POSITION * "\n")
      end
      raise
    end

    def self._async_changes(snapshot, path, previous, options)
      fail "Not a Pathname: #{path.inspect}" unless path.respond_to?(:children)
      previous.each do |entry, data|
        # TODO: this is a hack with insufficient testing
        type = data.key?(:mtime) ? :file : :dir
        rel_path_s = (path + entry).to_s
        _change(snapshot, type, rel_path_s, options)
      end
    end

    def self._change(snapshot, type, path, options)
      return snapshot.invalidate(type, path, options) if type == :dir

      # Minor param cleanup for tests
      # TODO: use a dedicated Event class
      opts = options.dup
      opts.delete(:recursive)
      snapshot.invalidate(type, path, opts)
    end

    def self._children(path)
      return path.children unless RUBY_ENGINE == 'jruby'

      # JRuby inconsistency workaround, see:
      # https://github.com/jruby/jruby/issues/3840
      exists = path.exist?
      directory = path.directory?
      return path.children unless (exists && !directory)
      raise Errno::ENOTDIR, path.to_s
    end
  end
end
