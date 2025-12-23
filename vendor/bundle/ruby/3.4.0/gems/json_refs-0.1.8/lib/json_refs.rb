require 'json_refs/version'
require 'json_refs/dereference_handler'

module JsonRefs
  class << self
    def call(doc, options = {})
      Dereferencer.new(doc, options).call
    end

    alias_method :dereference, :call
  end

  class Dereferencer
    def initialize(doc, options = {})
      @doc = doc
      @options = options
    end

    def call(doc = @doc, keys = [])
      if doc.is_a?(Array)
        doc.each_with_index do |value, idx|
          call(value, keys + [idx])
        end
      elsif doc.is_a?(Hash)
        if doc.has_key?('$ref')
          dereference(keys, doc['$ref'])
        else
          doc.each do |key, value|
            call(value, keys + [key])
          end
        end
      end
      doc
    end

    private

    def dereference(paths, referenced_path)
      key = paths.pop
      target = paths.inject(@doc) do |obj, key|
        obj[key]
      end
      value = follow_referenced_value(referenced_path)
      target[key] = value
    end

    def follow_referenced_value(referenced_path)
      value = referenced_value(referenced_path)
      return referenced_value(value['$ref']) if value.is_a?(Hash) && value.has_key?('$ref')
      value
    end

    def referenced_value(referenced_path)
      if @options[:logging] == true
        puts "De-referencing #{referenced_path}"
      end

      filepath, pointer = referenced_path.split('#')
      pointer.prepend('#') if pointer
      return dereference_local(pointer) if filepath.empty?

      dereferenced_file = dereference_file(filepath)
      return dereferenced_file if pointer.nil?

      JsonRefs::DereferenceHandler::Local.new(
        doc: dereferenced_file,
        path: pointer
      ).call
    end

    def dereference_local(referenced_path)
      if @options[:resolve_local_ref] === false
        return { '$ref' => referenced_path }
      end

      klass = JsonRefs::DereferenceHandler::Local
      klass.new(path: referenced_path, doc: @doc).call
    end

    def dereference_file(referenced_path)
      if @options[:resolve_file_ref] === false
        return { '$ref' => referenced_path }
      end

      klass = JsonRefs::DereferenceHandler::File

      # Checking for "://" in a URL like http://something.com so as to determine if it's a remote URL
      remote_uri = referenced_path =~ /:\/\//

      if remote_uri
        klass.new(path: referenced_path, doc: @doc).call
      else
        recursive_dereference(referenced_path, klass)
      end
    end

    def recursive_dereference(referenced_path, klass)
      directory = File.dirname(referenced_path)
      filename = File.basename(referenced_path)

      dereferenced_doc = {}
      Dir.chdir(directory) do
        referenced_doc = klass.new(path: filename, doc: @doc).call
        dereferenced_doc = Dereferencer.new(referenced_doc, @options).call
      end
      dereferenced_doc
    end
  end
end
