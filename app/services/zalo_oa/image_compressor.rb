# Zalo OA rejects images over ~1MB. Tries progressively smaller dimensions, then
# progressively lower JPEG quality, returning the first encoding that fits the byte
# budget. Images with an alpha channel are kept as PNG (JPEG would flatten
# transparency); everything else becomes JPEG. Returns nil if no combination fits,
# or if the input cannot be decoded as an image, so callers can fall back to the
# original (which will then hit Zalo's own size rejection).
class ZaloOa::ImageCompressor
  # The 800px floor balances "still legible on a phone" against the ~1MB target.
  DIMENSIONS = [1600, 1280, 1024, 800].freeze
  JPEG_QUALITIES = [82, 72, 60].freeze
  MAX_BYTES = 900_000

  pattr_initialize [:path!]

  def call
    image = Vips::Image.new_from_file(path, access: :sequential).autorot
    has_alpha = image.has_alpha?

    DIMENSIONS.each do |dim|
      resized = image.thumbnail_image(dim, height: dim, size: :down)

      if has_alpha
        out = resized.write_to_buffer('.png', compression: 9)
        return { data: out, ext: 'png' } if out.bytesize <= MAX_BYTES

        next
      end

      JPEG_QUALITIES.each do |quality|
        out = resized.write_to_buffer('.jpg', Q: quality)
        return { data: out, ext: 'jpg' } if out.bytesize <= MAX_BYTES
      end
    end

    nil
  rescue Vips::Error
    nil
  end
end
