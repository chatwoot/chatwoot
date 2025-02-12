module RailsExecution
  class FileUploader < RailsExecution::Files::Uploader

    def call
      files.each do |item|
        # YourAttachment.create!(task: task, name: item.name, file: item.file)
      end
    end

  end
end
