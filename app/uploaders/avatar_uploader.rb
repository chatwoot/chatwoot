class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    if Rails.env.test?
      "#{Rails.root}/spec/support/uploads/avatar/#{model.class.to_s.underscore}/#{model.id}"
    else
      "uploads/avatar/#{model.class.to_s.underscore}/#{model.id}"
    end
  end

  version :thumb do
    process resize_to_fill: [64, 64]
  end

  version :profile_thumb do
    process resize_to_fill: [128, 128]
  end
end
