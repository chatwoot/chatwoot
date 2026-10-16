class Captain::Llm::MessageTranslationSchema < Schematist::Schema
  array :translations, of: :string, description: 'One translation per input message, in input order'
end
