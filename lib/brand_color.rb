# frozen_string_literal: true

# BRAND_COLOR is the one colour an installation configures, and email needs it in two
# roles that a single hex cannot fill. As a surface -- an accent bar, a button fill -- any
# hex works. As text it has to clear WCAG AA against the email's white card, and a brand
# colour rarely does: Chatwoot's own default sits at 3.15:1, and a bright green or yellow
# lands near 2:1, which is unreadable rather than merely off-brand.
module BrandColor
  DEFAULT = '#1F93FF'
  # WCAG 2.1 AA for body text.
  MIN_CONTRAST = 4.5
  HEX_PATTERN = /\A#(?:\h{3}|\h{6})\z/
  WHITE_LUMINANCE = 1.0

  def self.surface(hex = nil)
    normalize(hex) || DEFAULT
  end

  # The brand colour darkened just enough to be readable on the white card. Darkening keeps
  # the hue, so the result still reads as the brand rather than as an unrelated colour.
  def self.on_light(hex = nil)
    rgb = to_rgb(surface(hex))
    factor = 1.0
    factor -= 0.05 while factor.positive? && contrast_with_white(scale(rgb, factor)) < MIN_CONTRAST
    to_hex(scale(rgb, [factor, 0].max))
  end

  def self.normalize(hex)
    value = hex.to_s.strip
    return nil unless value.match?(HEX_PATTERN)

    value = "##{value[1..].chars.flat_map { |char| [char, char] }.join}" if value.length == 4
    value.upcase
  end

  def self.to_rgb(hex)
    hex[1..].scan(/\h{2}/).map { |pair| pair.to_i(16) }
  end

  def self.to_hex(rgb)
    "##{rgb.map { |channel| channel.to_s(16).rjust(2, '0') }.join.upcase}"
  end

  def self.scale(rgb, factor)
    rgb.map { |channel| (channel * factor).round.clamp(0, 255) }
  end

  def self.contrast_with_white(rgb)
    (WHITE_LUMINANCE + 0.05) / (relative_luminance(rgb) + 0.05)
  end

  def self.relative_luminance(rgb)
    linear = rgb.map do |channel|
      value = channel / 255.0
      value <= 0.03928 ? value / 12.92 : (((value + 0.055) / 1.055)**2.4)
    end
    (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2])
  end

  private_class_method :normalize, :to_rgb, :to_hex, :scale, :contrast_with_white, :relative_luminance
end
