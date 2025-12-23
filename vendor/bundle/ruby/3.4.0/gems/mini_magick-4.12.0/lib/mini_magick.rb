require 'mini_magick/version'
require 'mini_magick/configuration'

module MiniMagick

  extend MiniMagick::Configuration

  ##
  # You might want to execute only certain blocks of processing with a
  # different CLI, because for example that CLI does that particular thing
  # faster. After the block CLI resets to its previous value.
  #
  # @example
  #   MiniMagick.with_cli :graphicsmagick do
  #     # operations that are better done with GraphicsMagick
  #   end
  def self.with_cli(cli)
    old_cli = self.cli
    self.cli = cli
    yield
  ensure
    self.cli = old_cli
  end

  ##
  # Checks whether the CLI used is ImageMagick.
  #
  # @return [Boolean]
  def self.imagemagick?
    cli == :imagemagick
  end

  ##
  # Checks whether the CLI used is ImageMagick 7.
  #
  # @return [Boolean]
  def self.imagemagick7?
    cli == :imagemagick7
  end

  ##
  # Checks whether the CLI used is GraphicsMagick.
  #
  # @return [Boolean]
  def self.graphicsmagick?
    cli == :graphicsmagick
  end

  ##
  # Returns ImageMagick's/GraphicsMagick's version.
  #
  # @return [String]
  def self.cli_version
    output = MiniMagick::Tool::Identify.new(&:version)
    output[/\d+\.\d+\.\d+(-\d+)?/]
  end

  class Error < RuntimeError; end
  class Invalid < StandardError; end

end

require 'mini_magick/tool'
require 'mini_magick/image'
