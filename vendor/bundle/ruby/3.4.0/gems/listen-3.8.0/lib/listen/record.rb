# frozen_string_literal: true

require 'thread'
require 'listen/record/entry'
require 'listen/record/symlink_detector'

module Listen
  class Record
    # TODO: one Record object per watched directory?
    # TODO: deprecate

    attr_reader :root

    def initialize(directory, silencer)
      reset_tree
      @root = directory.to_s
      @silencer = silencer
    end

    def add_dir(rel_path)
      if !empty_dirname?(rel_path.to_s)
        @tree[rel_path.to_s]
      end
    end

    def update_file(rel_path, data)
      dirname, basename = Pathname(rel_path).split.map(&:to_s)
      _fast_update_file(dirname, basename, data)
    end

    def unset_path(rel_path)
      dirname, basename = Pathname(rel_path).split.map(&:to_s)
      _fast_unset_path(dirname, basename)
    end

    def file_data(rel_path)
      dirname, basename = Pathname(rel_path).split.map(&:to_s)
      if empty_dirname?(dirname)
        @tree[basename].dup
      else
        @tree[dirname][basename] ||= {}
        @tree[dirname][basename].dup
      end
    end

    def dir_entries(rel_path)
      rel_path_s = rel_path.to_s
      subtree = if empty_dirname?(rel_path_s)
        @tree
      else
        @tree[rel_path_s]
      end

      subtree.each_with_object({}) do |(key, values), result|
        # only return data for file entries inside the dir (which will each be sub-hashes)
        if values.is_a?(Hash)
          result[key] = values.has_key?(:mtime) ? values : {}
        end
      end
    end

    def build
      reset_tree
      # TODO: test with a file name given
      # TODO: test other permissions
      # TODO: test with mixed encoding
      symlink_detector = SymlinkDetector.new
      remaining = ::Queue.new
      remaining << Entry.new(root, nil, nil)
      _fast_build_dir(remaining, symlink_detector) until remaining.empty?
    end

    private

    def empty_dirname?(dirname)
      dirname == '.' || dirname == ''
    end

    def reset_tree
      @tree = Hash.new { |h, k| h[k] = {} }
    end

    def _fast_update_file(dirname, basename, data)
      if empty_dirname?(dirname.to_s)
        @tree[basename] = @tree[basename].merge(data)
      else
        @tree[dirname][basename] = (@tree[dirname][basename] || {}).merge(data)
      end
    end

    def _fast_unset_path(dirname, basename)
      # this may need to be reworked to properly remove
      # entries from a tree, without adding non-existing dirs to the record
      if empty_dirname?(dirname.to_s)
        if @tree.key?(basename)
          @tree.delete(basename)
        end
      elsif @tree.key?(dirname)
        @tree[dirname].delete(basename)
      end
    end

    def _fast_build_dir(remaining, symlink_detector)
      entry = remaining.pop
      return if @silencer.silenced?(entry.record_dir_key, :dir)

      children = entry.children # NOTE: children() implicitly tests if dir
      symlink_detector.verify_unwatched!(entry)
      children.each { |child| remaining << child }
      add_dir(entry.record_dir_key)
    rescue Errno::ENOTDIR
      _fast_try_file(entry)
    rescue SystemCallError, SymlinkDetector::Error
      _fast_unset_path(entry.relative, entry.name)
    end

    def _fast_try_file(entry)
      _fast_update_file(entry.relative, entry.name, entry.meta)
    rescue SystemCallError
      _fast_unset_path(entry.relative, entry.name)
    end
  end
end
