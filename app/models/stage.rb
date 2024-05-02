# == Schema Information
#
# Table name: stages
#
#  id             :bigint           not null, primary key
#  allow_disabled :boolean          default(FALSE), not null
#  code           :string           not null
#  description    :string
#  disabled       :boolean          default(FALSE), not null
#  name           :string           not null
#  stage_type     :integer          not null
#  status         :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer          not null
#
# Indexes
#
#  index_stages_on_account_id_and_code  (account_id,code) UNIQUE
#
class Stage < ApplicationRecord
  belongs_to :account
  has_many :contacts, dependent: :nullify
  validates :account_id, presence: true
  validates :stage_type, presence: true
  validates :code, presence: true
  validates :name, presence: true
  validates :status, presence: true
  enum stage_type: { leads: 0, deals: 1, both: 2 }
  enum status: { ongoing: 0, ended: 1 }

  STAGE_TYPE_MAPPING = {
    'leads' => 0,
    'deals' => 1,
    'both' => 2
  }.freeze

  def self.generate_template(account_id) # rubocop:disable Metrics/MethodLength
    Stage.create([
                   { account_id: account_id,
                     stage_type: :leads,
                     code: 'New',
                     name: 'Khách hàng mới',
                     description: 'Lead mới đến từ các kênh hội thoại hoặc tự nhập',
                     status: :ongoing },

                   { account_id: account_id,
                     stage_type: :leads,
                     code: 'Contacting',
                     name: 'Đang liên hệ',
                     description: 'Lead đang liên hệ để nuôi dưỡng, phát triển',
                     status: :ongoing },

                   { account_id: account_id,
                     stage_type: :leads,
                     code: 'Unqualified',
                     name: 'Không phù hợp',
                     description: 'Lead rác hoặc không có nhu cầu - cần nhập nguyên nhân cụ thể',
                     status: :ended,
                     allow_disabled: true },

                   { account_id: account_id,
                     stage_type: :both,
                     code: 'Converted',
                     name: 'Có quan tâm',
                     description: 'Lead đã được chuyển đổi để tiếp tục giai đoạn Deal',
                     status: :ongoing,
                     allow_disabled: true },

                   { account_id: account_id,
                     stage_type: :deals,
                     code: 'Qualified',
                     name: 'Có nhu cầu',
                     description: 'Deal mà khách hàng đã xác nhận nhu cầu',
                     status: :ongoing },

                   { account_id: account_id,
                     stage_type: :deals,
                     code: 'Working',
                     name: 'Đang trao đổi',
                     description: 'Trao đổi chi tiết về sản phẩm dịch vụ',
                     status: :ongoing,
                     allow_disabled: true },

                   { account_id: account_id,
                     stage_type: :deals,
                     code: 'Closure',
                     name: 'Đang chốt',
                     description: 'Thương lượng thêm để chốt deal',
                     status: :ongoing,
                     allow_disabled: true },

                   { account_id: account_id,
                     stage_type: :deals,
                     code: 'Won',
                     name: 'Đã chốt',
                     description: 'Deal thành công',
                     status: :ended },

                   { account_id: account_id,
                     stage_type: :deals,
                     code: 'Lost',
                     name: 'Đã mất',
                     description: 'Deal thất bại',
                     status: :ended }
                 ])
  end
end
