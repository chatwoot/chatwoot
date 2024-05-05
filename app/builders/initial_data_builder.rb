class InitialDataBuilder
  pattr_initialize [:account_id]
  def perform
    generate_pipelines
    build_custom_attributes
  end

  private

  def generate_pipelines # rubocop:disable Metrics/MethodLength
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

  def build_custom_attributes # rubocop:disable Metrics/MethodLength
    CustomAttributeDefinition.create([
                                       { attribute_display_name: 'Chi nhánh',
                                         attribute_key: 'branch',
                                         attribute_display_type: :list,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Chi nhánh',
                                         attribute_values: ['Trụ sở', 'Chi nhánh 1', 'Chi nhánh 2'] },

                                       { attribute_display_name: 'Nguồn thông tin',
                                         attribute_key: 'data_source',
                                         attribute_display_type: :list,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Nguồn thông tin',
                                         attribute_values: ['Online', 'Trực tiếp', 'Giới thiệu'] },

                                       { attribute_display_name: 'Địa chỉ',
                                         attribute_key: 'address',
                                         attribute_display_type: :text,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Địa chỉ' },

                                       { attribute_display_name: 'Số điện thoại phụ',
                                         attribute_key: 'secondary_phone_number',
                                         attribute_display_type: :text,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Số điện thoại phụ',
                                         regex_pattern: '^\+?\d+([\s.]?\d+)*$',
                                         regex_cue: 'Chỉ bao gồm số và các dấu + . hoặc khoảng trắng' },

                                       { attribute_display_name: 'Email phụ',
                                         attribute_key: 'secondary_email',
                                         attribute_display_type: :text,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Email phụ',
                                         regex_pattern: '/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/',
                                         regex_cue: 'Email hợp lệ nên là name@domain.xxx' },

                                       { attribute_display_name: 'Giới tính',
                                         attribute_key: 'gender',
                                         attribute_display_type: :list,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Giới tính',
                                         attribute_values: %w[Nam Nữ Khác] },

                                       { attribute_display_name: 'Ngày sinh',
                                         attribute_key: 'day_of_birth',
                                         attribute_display_type: :date,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Ngày sinh' },

                                       { attribute_display_name: 'Nghề nghiệp',
                                         attribute_key: 'occupation',
                                         attribute_display_type: :list,
                                         attribute_model: :contact_attribute,
                                         account_id: account_id,
                                         attribute_description: 'Nghề nghiệp',
                                         attribute_values: ['Học sinh', 'Sinh viên', 'Nhân viên văn phòng', 'Khác'] }
                                     ])
  end
end
