class Captain::Llm::LanguageDetectionSchema < Schematist::Schema
  string :language, description: "Language tag, like en, pt-BR or zh-TW (region or script only when the text shows it); 'und' when it cannot be told"
end
