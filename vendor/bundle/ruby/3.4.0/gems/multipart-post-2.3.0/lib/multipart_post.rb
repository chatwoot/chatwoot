# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2013, by Nick Sieger.
# Copyright, 2019-2022, by Samuel Williams.

warn "Top level ::MultipartPost is deprecated, require 'multipart/post' and use `Multipart::Post` instead!"
require_relative 'multipart/post'

MultipartPost = Multipart::Post
Object.deprecate_constant :MultipartPost
