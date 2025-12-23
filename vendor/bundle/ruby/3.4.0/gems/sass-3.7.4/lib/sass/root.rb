module Sass
  # The root directory of the Sass source tree.
  # This may be overridden by the package manager
  # if the lib directory is separated from the main source tree.
  # @api public
  ROOT_DIR = File.expand_path(File.join(__FILE__, "../../.."))
end
