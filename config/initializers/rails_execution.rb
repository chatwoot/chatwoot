require 'rails_execution/file_uploader'
require 'rails_execution/file_reader'

RailsExecution.configuration do |config|
  config.solo_mode = true # Without reviewing process

  config.auto_suggestions = [
    'app/models',
    'app/jobs',
    'app/service',
    'app/workers'
  ]

  # Owner display
  config.owner_model = 'SuperAdmin'
  config.owner_method = :current_super_admin
  config.owner_name_method = :name
  config.owner_avatar = lambda do |owner|
    owner.avatar_url.presence
  end

  # Task control
  # config.reviewers = lambda do
  #   [{ name: '', id: '' }]
  # end

  # Accessible check: Default is TRUE
  # config.task_editable
  # config.task_closable
  # config.task_creatable
  # config.task_approvable
  # config.task_executable = lambda do |task, user|
  #   YourPolicy.new(user, task).executable?
  # end

  # Advanced
  config.file_upload = true
  config.file_uploader = RailsExecution::FileUploader
  config.file_reader = RailsExecution::FileReader
  # Defaults of acceptable_file_types: .png, .gif, .jpg, .jpeg, .pdf, .csv
  # config.acceptable_file_types = {
  #   '.jpeg': 'image/jpeg',
  #   '.pdf': 'application/pdf',
  #   '.csv': ['text/csv', 'text/plain'],
  # }

  # config.task_schedulable = true
  # config.task_scheduler = ->(scheduled_at, task_id) { }
  # config.scheduled_task_remover = ->(task_id) { }

  # config.task_background = true
  # config.task_background_executor = ->(task_id) { }

  # Logger
  # Using Paperclip
  # config.logging = lambda do |log_file, task|
  #   YourAttachment.create(file: log_file, task: task)
  # end
  # config.logging_files = lambda do |task|
  #   YourAttachment.where(task: task).map { |item| item.file.url }
  # end
  # Using ActiveStorage
  config.logging = lambda do |log_file, task|
    filename = Time.current.strftime('%Y%m%d_%H%M%S.log')
    RailsExecution::FileManage.create!(
      attachment_type: :log,
      task: task,
      name: filename
    ).file.attach(
      io: log_file,
      filename: filename
    )
  end
  config.logging_files = lambda do |task|
    RailsExecution::FileManage.log_file.where(task: task).to_h { |item| [item.file.url, item.created_at] }
  end

  # Paging
  # config.per_page = 30 # Default: 20

  # Notify
  # config.notifier = ::RailsExecution::Services::Notifier
end
