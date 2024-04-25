# == Schema Information
#
# Table name: sales_pipelines
#
#  id          :bigint           not null, primary key
#  description :string
#  disabled    :boolean          default(FALSE), not null
#  name        :string           not null
#  short_name  :string           not null
#  stage_type  :integer          not null
#  status      :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#
# Indexes
#
#  index_sales_pipelines_on_account_id_and_short_name  (account_id,short_name) UNIQUE
#
class SalesPipeline < ApplicationRecord
  validates :account_id, presence: true
  validates :stage_type, presence: true
  validates :short_name, presence: true
  validates :name, presence: true
  validates :status, presence: true
  enum stage_type: { leads: 0, deals: 1 }
  enum status: { ongoing: 0, ended: 1 }

  def self.generate_template(account_id) # rubocop:disable Metrics/MethodLength
    SalesPipeline.create([
                           { account_id: account_id,
                             stage_type: :leads,
                             short_name: 'New',
                             name: 'Khách hàng mới',
                             description: 'Lead mới đến từ các kênh hội thoại hoặc tự nhập',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :leads,
                             short_name: 'Working',
                             name: 'Đang theo dõi',
                             description: 'Lead đang trao đổi để nuôi dưỡng, phát triển',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :leads,
                             short_name: 'Converted',
                             name: 'Có quan tâm',
                             description: 'Lead đã được chuyển đổi để tiếp tục giai đoạn Deal',
                             status: :ended },

                           { account_id: account_id,
                             stage_type: :leads,
                             short_name: 'Unqualified',
                             name: 'Không phù hợp',
                             description: 'Lead rác hoặc không có nhu cầu - cần nhập nguyên nhân cụ thể',
                             status: :ended },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Prospecting',
                             name: 'Khách hàng tiềm năng',
                             description: 'Deal tiềm năng mới được chuyển đổi từ Lead',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Qualified',
                             name: 'Có nhu cầu',
                             description: 'Deal mà khách hàng đã xác nhận nhu cầu',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Quote',
                             name: 'Báo giá',
                             description: 'Gửi báo giá sang khách hàng',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Closure',
                             name: 'Đang chốt',
                             description: 'Thương lượng thêm để chốt deal',
                             status: :ongoing },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Won',
                             name: 'Đã chốt',
                             description: 'Deal thành công',
                             status: :ended },

                           { account_id: account_id,
                             stage_type: :deals,
                             short_name: 'Lost',
                             name: 'Không chốt được',
                             description: 'Deal thất bại',
                             status: :ended }
                         ])
  end
end
