class Captain::Llm::LanguageDetectionSchema < Schematist::Schema
  string :language, description: "ISO 639-1 code of the language the message is written in, or 'und' when it cannot be told"
end
