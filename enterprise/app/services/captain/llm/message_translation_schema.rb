class Captain::Llm::MessageTranslationSchema < Schematist::Schema
  array :messages, description: 'One entry per input message, in input order' do
    object do
      string :id, description: 'The id of the input message'
      string :text, description: 'The message content translated into the target language'
    end
  end
end
