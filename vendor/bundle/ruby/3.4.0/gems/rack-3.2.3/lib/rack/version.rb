# frozen_string_literal: true

# Copyright (C) 2007-2019 Leah Neukirchen <http://leahneukirchen.org/infopage.html>
#
# Rack is freely distributable under the terms of an MIT-style license.
# See MIT-LICENSE or https://opensource.org/licenses/MIT.

module Rack
  VERSION = "3.2.3"

  RELEASE = VERSION

  # Return the Rack release as a dotted string.
  def self.release
    VERSION
  end
end
