class RailsExecution::FileReader < RailsExecution::Files::Reader
  # Output: {
  #   'File1' => 'url',
  #   'FileZ' => 'url',
  # }
  def call
    # YourAttachment.where(task: task).pluck(:name, :url).to_h
    {}
  end
end
