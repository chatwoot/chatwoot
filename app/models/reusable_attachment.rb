# == Schema Information
#
# Table name: reusable_attachments
#
#  id          :bigint           not null, primary key
#  account_id  :bigint           not null
#  name        :string           not null
#  file_type   :integer          default(0), not null
#  extension   :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ReusableAttachment < ApplicationRecord
  belongs_to :account
  has_one_attached :file

  validates :name, presence: true, length: { maximum: 255 }
  validates :file, presence: true
  validate :acceptable_file_size

  enum file_type: {
    image: 0,
    audio: 1,
    video: 2,
    file: 3
  }

  before_save :set_file_metadata

  def file_url
    Rails.application.routes.url_helpers.url_for(file) if file.attached?
  end

  def download_url
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.attached? ? file.blob.url : nil
  end

  def thumb_url
    return unless file.attached? && image?

    Rails.application.routes.url_helpers.rails_representation_url(
      file.representation(resize_to_limit: [250, 250]),
      only_path: false
    )
  rescue ActiveStorage::UnrepresentableError
    nil
  end

  def file_size
    file.blob.byte_size if file.attached?
  end

  def as_json(*)
    {
      id: id,
      name: name,
      file_type: file_type,
      extension: extension,
      description: description,
      file_url: file_url,
      download_url: download_url,
      thumb_url: thumb_url,
      file_size: file_size,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def set_file_metadata
    return unless file.attached?

    # Always detect file_type from content_type when file is attached
    self.file_type = detect_file_type(file.content_type)
    self.extension = file.filename.extension if extension.blank?
  end

  def detect_file_type(content_type)
    return :image if image_content_type?(content_type)
    return :video if video_content_type?(content_type)
    return :audio if content_type&.include?('audio/')

    :file
  end

  def image_content_type?(content_type)
    %w[image/jpeg image/png image/gif image/bmp image/webp image].include?(content_type)
  end

  def video_content_type?(content_type)
    %w[video/ogg video/mp4 video/webm video/quicktime video].include?(content_type)
  end

  def acceptable_file_size
    return unless file.attached?

    max_size = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', '40').to_i.megabytes

    return unless file.blob.byte_size > max_size

    errors.add(:file, "size should be less than #{max_size / 1.megabyte}MB")
  end
end
