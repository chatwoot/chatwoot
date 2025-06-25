class RailsExecution::FileUploader < RailsExecution::Files::Uploader
  def call
    files.each do |item|
      RailsExecution::FileManage.create!(
        attachment_type: :attachment,
        task: task,
        name: item.name,
        file: item.file
      )
    end
  end
end
