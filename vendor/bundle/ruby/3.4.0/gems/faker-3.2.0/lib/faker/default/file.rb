# frozen_string_literal: true

module Faker
  class File < Base
    class << self
      ##
      # Produces a random directory name.
      #
      # @param segment_count [Integer] Specifies the number of nested folders in the generated string.
      # @param root [String] Specifies the root of the generated string.
      # @param directory_separator [String] Specifies the separator between the segments.
      # @return [String]
      #
      # @example
      #   Faker::File.dir #=> "et_error/sint_voluptas/quas_veritatis"
      #   Faker::File.dir(segment_count: 2) #=> "ea-suscipit/ut-deleniti"
      #   Faker::File.dir(segment_count: 3, root: nil, directory_separator: '/') #=> "est_porro/fugit_eveniet/incidunt-autem"
      #   Faker::File.dir(segment_count: 3, root: nil, directory_separator: '\\') #=> "aut-ullam\\quia_quisquam\\ut-eos"
      #
      # @faker.version 1.6.4
      def dir(segment_count: 3, root: nil, directory_separator: ::File::Separator)
        Array
          .new(segment_count) { Faker::Internet.slug }
          .unshift(root)
          .compact
          .join(directory_separator)
          .squeeze(directory_separator)
      end

      ##
      # Produces a random file extension.
      #
      # @return [String]
      #
      # @example
      #   Faker::File.extension #=> "mp3"
      #
      # @faker.version 1.6.4
      def extension
        fetch('file.extension')
      end

      ##
      # Produces a random mime type.
      #
      # @return [String]
      #
      # @example
      #   Faker::File.mime_type #=> "application/pdf"
      #
      # @faker.version next
      def mime_type(media_type: nil)
        media_type ? fetch("file.mime_type.#{media_type}") : sample(sample(translate('faker.file.mime_type').values))
      end

      ##
      # Produces a random file name.
      #
      # @param dir [String] Specifies the path used for the generated file.
      # @param name [String] Specifies the filename used for the generated file.
      # @param ext [String] Specifies the extension used the generated file.
      # @param directory_separator [String] Specifies the separator between the directory and name elements.
      # @return [String]
      #
      # @example
      #   Faker::File.file_name(dir: 'path/to') #=> "path/to/something_random.jpg"
      #   Faker::File.file_name(dir: 'foo/bar', name: 'baz') #=> "foo/bar/baz.zip"
      #   Faker::File.file_name(dir: 'foo/bar', name: 'baz', ext: 'doc') #=> "foo/bar/baz.doc"
      #   Faker::File.file_name(dir: 'foo/bar', name: 'baz', ext: 'mp3', directory_separator: '\\') #=> "foo/bar\\baz.mp3"
      #
      # @faker.version 1.6.4
      def file_name(dir: nil, name: nil, ext: nil, directory_separator: ::File::Separator)
        dir ||= dir(segment_count: 1)
        name ||= Faker::Lorem.word.downcase
        ext ||= extension

        [dir, name].join(directory_separator) + ".#{ext}"
      end
    end
  end
end
