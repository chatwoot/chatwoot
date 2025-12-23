# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2006-2012, by Nick Sieger.
# Copyright, 2008, by McClain Looney.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2019, by Patrick Davey.
# Copyright, 2021-2022, by Samuel Williams.

require 'net/http'

require_relative '../../../multipart/post'

module Net
  class HTTP
    class Put
      class Multipart < Put
        include ::Multipart::Post::Multipartable
      end
    end

    class Post
      class Multipart < Post
        include ::Multipart::Post::Multipartable
      end
    end
  end
end
