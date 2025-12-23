# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2008-2009, by McClain Looney.
# Copyright, 2009-2013, by Nick Sieger.
# Copyright, 2011, by Johannes Wagener.
# Copyright, 2011, by Gerrit Riessen.
# Copyright, 2011, by Jason Moore.
# Copyright, 2012, by Steven Davidovitz.
# Copyright, 2012, by hexfet.
# Copyright, 2013, by Vincent Pellé.
# Copyright, 2013, by Gustav Ernberg.
# Copyright, 2013, by Socrates Vicente.
# Copyright, 2017, by David Moles.
# Copyright, 2017, by Matt Colyer.
# Copyright, 2017, by Eric Hutzelman.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2019, by Ethan Turkeltaub.
# Copyright, 2022, by Samuel Williams.

warn "Top level ::Parts is deprecated, require 'multipart/post' and use `Multipart::Post::Parts` instead!"
require_relative 'multipart/post'

Parts = Multipart::Post::Parts
Object.deprecate_constant :Parts
