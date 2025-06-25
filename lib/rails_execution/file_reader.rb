class RailsExecution::FileReader < RailsExecution::Files::Reader
  def call
    RailsExecution::FileManage
      .attachment_file
      .where(task: task)
      .to_h { |item| [item.name, item.file.url] }
  end
end
