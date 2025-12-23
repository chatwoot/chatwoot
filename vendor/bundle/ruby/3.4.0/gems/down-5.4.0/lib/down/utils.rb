require "cgi"

module Down
  module Utils
    module_function

    # Retrieves potential filename from the "Content-Disposition" header.
    def filename_from_content_disposition(content_disposition)
      content_disposition = content_disposition.to_s

      escaped_filename =
        content_disposition[/filename\*=UTF-8''(\S+)/, 1] ||
        content_disposition[/filename="([^"]*)"/, 1] ||
        content_disposition[/filename=(\S+)/, 1]

      filename = CGI.unescape(escaped_filename.to_s)

      filename unless filename.empty?
    end

    # Retrieves potential filename from the URL path.
    def filename_from_path(path)
      filename = path.split("/").last
      CGI.unescape(filename) if filename
    end
  end
end
