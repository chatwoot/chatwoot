# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008, by McClain Looney.
# Copyright, 2008-2013, by Nick Sieger.
# Copyright, 2011, by Gerrit Riessen.
# Copyright, 2013, by Vincent Pellé.
# Copyright, 2013, by Gustav Ernberg.
# Copyright, 2013, by Socrates Vicente.
# Copyright, 2013, by Steffen Grunwald.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2019-2022, by Samuel Williams.
# Copyright, 2019, by Patrick Davey.

warn "Top level ::Multipartable is deprecated, require 'multipart/post' and use `Multipart::Post::Multipartable` instead!"
require_relative 'multipart/post'

Multipartable = Multipart::Post::Multipartable
Object.deprecate_constant :Multipartable
