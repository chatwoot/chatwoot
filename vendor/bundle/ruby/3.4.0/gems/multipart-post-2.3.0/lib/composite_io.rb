# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2006-2013, by Nick Sieger.
# Copyright, 2010, by Tohru Hashimoto.
# Copyright, 2011, by Jeff Hodges.
# Copyright, 2011, by Alex Koppel.
# Copyright, 2011, by Christine Yen.
# Copyright, 2011, by Gerrit Riessen.
# Copyright, 2011, by Luke Redpath.
# Copyright, 2013, by Mislav Marohnić.
# Copyright, 2013, by Leo Cassarani.
# Copyright, 2019, by Olle Jonsson.
# Copyright, 2022, by Samuel Williams.

warn "Top level ::CompositeIO is deprecated, require 'multipart/post' and use `Multipart::Post::CompositeReadIO` instead!"
require_relative 'multipart/post'
