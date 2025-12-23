# frozen_string_literal: true

require 'time'

require_relative 'constants'
require_relative 'utils'
require_relative 'head'
require_relative 'mime'
require_relative 'files'

module Rack
  # Rack::Directory serves entries below the +root+ given, according to the
  # path info of the Rack request. If a directory is found, the file's contents
  # will be presented in an html based index. If a file is found, the env will
  # be passed to the specified +app+.
  #
  # If +app+ is not specified, a Rack::Files of the same +root+ will be used.

  class Directory
    DIR_FILE = "<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>\n"
    DIR_PAGE_HEADER = <<-PAGE
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
    PAGE
    DIR_PAGE_FOOTER = <<-PAGE
</table>
<hr />
</body></html>
    PAGE

    # Body class for directory entries, showing an index page with links
    # to each file.
    class DirectoryBody < Struct.new(:root, :path, :files)
      # Yield strings for each part of the directory entry
      def each
        show_path = Utils.escape_html(path.sub(/^#{root}/, ''))
        yield(DIR_PAGE_HEADER % [ show_path, show_path ])

        unless path.chomp('/') == root
          yield(DIR_FILE % DIR_FILE_escape(files.call('..')))
        end

        Dir.foreach(path) do |basename|
          next if basename.start_with?('.')
          next unless f = files.call(basename)
          yield(DIR_FILE % DIR_FILE_escape(f))
        end

        yield(DIR_PAGE_FOOTER)
      end

      private

      # Escape each element in the array of html strings.
      def DIR_FILE_escape(htmls)
        htmls.map { |e| Utils.escape_html(e) }
      end
    end

    # The root of the directory hierarchy.  Only requests for files and
    # directories inside of the root directory are supported.
    attr_reader :root

    # Set the root directory and application for serving files.
    def initialize(root, app = nil)
      @root = ::File.expand_path(root)
      @app = app || Files.new(@root)
      @head = Head.new(method(:get))
    end

    def call(env)
      # strip body if this is a HEAD call
      @head.call env
    end

    # Internals of request handling.  Similar to call but does
    # not remove body for HEAD requests.
    def get(env)
      script_name = env[SCRIPT_NAME]
      path_info = Utils.unescape_path(env[PATH_INFO])

      if client_error_response = check_bad_request(path_info) || check_forbidden(path_info)
        client_error_response
      else
        path = ::File.join(@root, path_info)
        list_path(env, path, path_info, script_name)
      end
    end

    # Rack response to use for requests with invalid paths, or nil if path is valid.
    def check_bad_request(path_info)
      return if Utils.valid_path?(path_info)

      body = "Bad Request\n"
      [400, { CONTENT_TYPE => "text/plain",
        CONTENT_LENGTH => body.bytesize.to_s,
        "x-cascade" => "pass" }, [body]]
    end

    # Rack response to use for requests with paths outside the root, or nil if path is inside the root.
    def check_forbidden(path_info)
      return unless path_info.include? ".."
      return if ::File.expand_path(::File.join(@root, path_info)).start_with?(@root)

      body = "Forbidden\n"
      [403, { CONTENT_TYPE => "text/plain",
        CONTENT_LENGTH => body.bytesize.to_s,
        "x-cascade" => "pass" }, [body]]
    end

    # Rack response to use for directories under the root.
    def list_directory(path_info, path, script_name)
      url_head = (script_name.split('/') + path_info.split('/')).map do |part|
        Utils.escape_path part
      end

      # Globbing not safe as path could contain glob metacharacters
      body = DirectoryBody.new(@root, path, ->(basename) do
        stat = stat(::File.join(path, basename))
        next unless stat

        url = ::File.join(*url_head + [Utils.escape_path(basename)])
        mtime = stat.mtime.httpdate
        if stat.directory?
          type = 'directory'
          size = '-'
          url << '/'
          if basename == '..'
            basename = 'Parent Directory'
          else
            basename << '/'
          end
        else
          type = Mime.mime_type(::File.extname(basename))
          size = filesize_format(stat.size)
        end

        [ url, basename, size, type, mtime ]
      end)

      [ 200, { CONTENT_TYPE => 'text/html; charset=utf-8' }, body ]
    end

    # File::Stat for the given path, but return nil for missing/bad entries.
    def stat(path)
      ::File.stat(path)
    rescue Errno::ENOENT, Errno::ELOOP
      return nil
    end

    # Rack response to use for files and directories under the root.
    # Unreadable and non-file, non-directory entries will get a 404 response.
    def list_path(env, path, path_info, script_name)
      if (stat = stat(path)) && stat.readable?
        return @app.call(env) if stat.file?
        return list_directory(path_info, path, script_name) if stat.directory?
      end

      entity_not_found(path_info)
    end

    # Rack response to use for unreadable and non-file, non-directory entries.
    def entity_not_found(path_info)
      body = "Entity not found: #{path_info}\n"
      [404, { CONTENT_TYPE => "text/plain",
        CONTENT_LENGTH => body.bytesize.to_s,
        "x-cascade" => "pass" }, [body]]
    end

    # Stolen from Ramaze
    FILESIZE_FORMAT = [
      ['%.1fT', 1 << 40],
      ['%.1fG', 1 << 30],
      ['%.1fM', 1 << 20],
      ['%.1fK', 1 << 10],
    ]

    # Provide human readable file sizes
    def filesize_format(int)
      FILESIZE_FORMAT.each do |format, size|
        return format % (int.to_f / size) if int >= size
      end

      "#{int}B"
    end
  end
end
