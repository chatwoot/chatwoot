# == Schema Information
#
# Table name: rails_execution_file_manages
#
#  id              :bigint           not null, primary key
#  attachment_type :string           default("attachment"), not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  task_id         :integer          not null
#
class RailsExecution::FileManage < ApplicationRecord
  has_one_attached :file

  belongs_to :task, class_name: 'RailsExecution::Task'

  enum attachment_type: {
    attachment: 'attachment',
    log: 'log'
  }, _suffix: :file
end
