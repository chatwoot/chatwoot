#--
# Copyright (c) 2007-2012 Nick Sieger.
# See the file README.txt included with the distribution for
# software license details.
#++

require 'net/http'
require 'stringio'
require 'cgi'
require_relative '../../../multipart/post/parts'
require_relative '../../../multipart/post/composite_read_io'
require_relative '../../../multipart/post/multipartable'

module Datadog
  module Core
    module Vendor
      module Net
        class HTTP
          class Put
            class Multipart < ::Net::HTTP::Put
              include Vendor::Multipart::Post::Multipartable
            end
          end

          class Post
            class Multipart < ::Net::HTTP::Post
              include Vendor::Multipart::Post::Multipartable
            end
          end
        end
      end
    end
  end
end
