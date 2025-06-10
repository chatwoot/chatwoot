class Digitaltolk::Openai::HtmlTranslation::BatchByContentLength
  CHARACTERS_LIMIT = 1000

  def self.perform(arrays)
    batches = []
    current_batch = []
    current_length = 0

    arrays.each do |msg|
      msg_length = msg.length

      if current_length + msg_length > CHARACTERS_LIMIT
        batches << current_batch
        current_batch = [msg]
        current_length = msg_length
      else
        current_batch << msg
        current_length += msg_length
      end
    end

    batches << current_batch unless current_batch.empty?
    batches
  end
end
