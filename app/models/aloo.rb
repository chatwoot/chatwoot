# frozen_string_literal: true

module Aloo
  # CRITICAL: Do not change dimension without migration!
  # text-embedding-3-small uses 1536 dimensions
  EMBEDDING_DIMENSION = 1536

  SUPPORTED_SOURCE_TYPES = %w[file website].freeze

  SUPPORTED_LANGUAGES = {
    'en' => { name: 'English', dialects: [] },
    'ar' => {
      name: 'Arabic',
      dialects: %w[EG SA AE KW QA BH OM JO LB SY IQ MA DZ TN LY SD PS MSA]
    },
    'fr' => { name: 'French', dialects: [] },
    'es' => { name: 'Spanish', dialects: [] },
    'de' => { name: 'German', dialects: [] },
    'pt' => { name: 'Portuguese', dialects: %w[BR PT] },
    'it' => { name: 'Italian', dialects: [] },
    'nl' => { name: 'Dutch', dialects: [] },
    'ru' => { name: 'Russian', dialects: [] },
    'zh' => { name: 'Chinese', dialects: %w[CN TW] },
    'ja' => { name: 'Japanese', dialects: [] },
    'ko' => { name: 'Korean', dialects: [] },
    'hi' => { name: 'Hindi', dialects: [] },
    'tr' => { name: 'Turkish', dialects: [] }
  }.freeze
end
