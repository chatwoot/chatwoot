module RailsExecution
  class FileReader < RailsExecution::Files::Reader

    # Output: {
    #   'File1' => 'url',
    #   'FileZ' => 'url',
    # }
    def call
      # YourAttachment.where(task: task).pluck(:name, :url).to_h
      return {}
    end

  end
end
