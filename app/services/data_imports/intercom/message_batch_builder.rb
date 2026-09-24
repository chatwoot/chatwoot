class DataImports::Intercom::MessageBatchBuilder < DataImports::MessageBatchBuilder
  def initialize(data_import:, conversation:, source_conversation:)
    super(data_import: data_import, conversation: conversation, source_conversation: source_conversation, provider: 'intercom')
  end
end
