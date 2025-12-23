# frozen_string_literal: true

module Launchy
  # Internal: Namespace for detecting the environment that Launchy is running in
  #
  module Detect
  end
end

require "launchy/detect/host_os"
require "launchy/detect/host_os_family"
require "launchy/detect/nix_desktop_environment"
