# frozen_string_literal: true
require_relative 'template'
require 'commonmarker'

aliases = {
  :smartypants => :SMART
}.freeze
parse_opts = [
  :FOOTNOTES,
  :LIBERAL_HTML_TAG,
  :SMART,
  :smartypants,
  :STRIKETHROUGH_DOUBLE_TILDE,
  :UNSAFE,
  :VALIDATE_UTF8,
].freeze
render_opts = [
  :FOOTNOTES,
  :FULL_INFO_STRING,
  :GITHUB_PRE_LANG,
  :HARDBREAKS,
  :NOBREAKS,
  :SAFE, # Removed in v0.18.0 (2018-10-17)
  :SOURCEPOS,
  :TABLE_PREFER_STYLE_ATTRIBUTES,
  :UNSAFE,
].freeze
exts = [
  :autolink,
  :strikethrough,
  :table,
  :tagfilter,
  :tasklist,
].freeze


Tilt::CommonMarkerTemplate = Tilt::StaticTemplate.subclass do
  extensions = exts.select do |extension|
    @options[extension]
  end

  parse_options, render_options = [parse_opts, render_opts].map do |opts|
    opts = opts.select do |option|
      @options[option]
    end.map! do |option|
      aliases[option] || option
    end

    opts = :DEFAULT unless opts.any?
    opts
  end

  CommonMarker.render_doc(@data, parse_options, extensions).to_html(render_options, extensions)
end
