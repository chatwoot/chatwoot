class AttachmentUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    if Rails.env.test?
      "#{Rails.root}/spec/support/uploads/attachments/#{model.class.to_s.underscore}/#{model.id}"
    else
      "uploads/attachments/#{model.class.to_s.underscore}/#{model.id}"
    end
  end

  version :thumb, if: :image? do
    process resize_to_fill: [280, 280]
  end

  protected

  def image?(_new_file)
    model.image?
  end
end
