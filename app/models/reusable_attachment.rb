# == Schema Information
#
# Table name: reusable_attachments
#
#  id            :bigint           not null, primary key
#  description   :text
#  extension     :string
#  file_type     :integer          default("image"), not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint
#
# Indexes
#
#  index_reusable_attachments_on_account_id           (account_id)
#  index_reusable_attachments_on_account_id_and_name  (account_id,name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#

class ReusableAttachment < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true
  # dependent: false prevents purging shared blobs on destroy.
  # Blobs used in message attachments must not be purged when the reusable handle is deleted.
  # Note: blobs never referenced by a message will remain in storage after destroy.
  has_one_attached :file, dependent: false

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
  before_update :capture_replaced_blob
  before_destroy :cleanup_file
  # after_commit (not after_update): ActiveStorage persists attachment_changes in its own
  # after_save, which runs after after_update. Using after_update would see the old
  # attachment row still present and incorrectly skip the purge.
  after_commit :purge_replaced_blob_if_unreferenced, on: :update

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

  def capture_replaced_blob
    return unless attachment_changes.key?('file')

    # file.blob already reflects the pending replacement; query the DB
    # directly to get the currently persisted blob before it is detached.
    @replaced_blob = ActiveStorage::Attachment.find_by(
      record_type: self.class.name, record_id: id, name: 'file'
    )&.blob
  end

  def purge_replaced_blob_if_unreferenced
    return unless @replaced_blob

    @replaced_blob.purge_later unless ActiveStorage::Attachment.exists?(blob_id: @replaced_blob.id)
    @replaced_blob = nil
  end

  def cleanup_file
    return unless file.attached?

    blob = file.blob
    other_refs = ActiveStorage::Attachment.where(blob_id: blob.id)
                                          .where.not('record_type = ? AND record_id = ?', 'ReusableAttachment', id)
                                          .exists?
    other_refs ? file.detach : file.purge
  end

  def set_file_metadata
    return unless file.attached?

    # Always detect file_type from content_type when file is attached
    self.file_type = detect_file_type(file.content_type)
    self.extension = file.filename.extension
  end

  def detect_file_type(content_type)
    return :image if image_content_type?(content_type)
    return :video if video_content_type?(content_type)
    return :audio if content_type&.include?('audio/')

    :file
  end

  def image_content_type?(content_type)
    %w[image/jpeg image/jpg image/png image/gif image/bmp image/webp image].include?(content_type)
  end

  def video_content_type?(content_type)
    %w[video/ogg video/mp4 video/webm video/quicktime video].include?(content_type)
  end

  def acceptable_file_size
    return unless file.attached?

    max_size = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', '40').to_i
    max_size = 40 if max_size <= 0

    return unless file.blob.byte_size > max_size.megabytes

    errors.add(:file, "size should be less than #{max_size}MB")
  end
end
