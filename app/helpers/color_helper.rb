module ColorHelper
  def hex_to_rgb(hex_color)
    # Remove the '#' character if it's there
    hex_color = hex_color.tr('#', '')

    # Split the hex color string into the RGB components
    r = hex_color[0..1].to_i(16)
    g = hex_color[2..3].to_i(16)
    b = hex_color[4..5].to_i(16)

    [r, g, b]
  end

  def rgb_to_hex(red, green, blue)
    hex = [red, green, blue].map do |color|
      color = 255 if color > 255
      color = 0 if color.negative?

      color.round.to_s(16).rjust(2, '0')
    end.join.upcase

    "##{hex}".downcase
  end

  def get_luminance(color)
    return 0 if color == 'transparent'

    r, g, b = hex_to_rgb(color)
    (0.2126 * channel_to_luminance(r)) + (0.7152 * channel_to_luminance(g)) + (0.0722 * channel_to_luminance(b))
  end

  def get_contrast(color1, color2)
    luminance1 = get_luminance(color1)
    luminance2 = get_luminance(color2)

    if luminance1 > luminance2
      (luminance1 + 0.05) / (luminance2 + 0.05)
    else
      (luminance2 + 0.05) / (luminance1 + 0.05)
    end
  end

  def mix(color1, color2, weight)
    # Parse colors and normalize
    r1, g1, b1 = hex_to_rgb(color1).map { |c| c / 255.0 }
    r2, g2, b2 = hex_to_rgb(color2).map { |c| c / 255.0 }

    # Mixing algorithm from Sass implementation
    weight1, weight2 = get_weight_for_mixing(weight)

    # Calculate final color values
    r = ((r1 * weight1) + (r2 * weight2)) * 255
    g = ((g1 * weight1) + (g2 * weight2)) * 255
    b = ((b1 * weight1) + (b2 * weight2)) * 255

    # Convert final values to a CSS RGBA color string
    rgb_to_hex(r, g, b)
  end

  def adjust_color_for_contrast(color, background_color, target_ratio = 3.1)
    max_iterations = 20
    adjusted_color = color

    max_iterations.times do
      current_ratio = get_contrast(adjusted_color, background_color)
      break if current_ratio >= target_ratio

      adjustment_direction = get_luminance(adjusted_color) < 0.5 ? '#ffffff' : '#151718'
      adjusted_color = mix(adjusted_color, adjustment_direction, 0.05)
    end

    adjusted_color
  end

  private

  def get_weight_for_mixing(weight)
    normalized_weight = (weight * 2) - 1
    weight2 = (normalized_weight + 1) / 2
    weight1 = 1 - weight2

    [weight1, weight2]
  end

  def channel_to_luminance(channel)
    channel /= 255.0
    if channel <= 0.03928
      channel / 12.92
    else
      ((channel + 0.055) / 1.055)**2.4
    end
  end
end
