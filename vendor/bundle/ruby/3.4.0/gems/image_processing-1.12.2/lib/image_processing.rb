require "image_processing/chainable"
require "image_processing/builder"
require "image_processing/pipeline"
require "image_processing/processor"
require "image_processing/version"

module ImageProcessing
  Error = Class.new(StandardError)

  autoload :MiniMagick, 'image_processing/mini_magick'
  autoload :Vips, 'image_processing/vips'
end
