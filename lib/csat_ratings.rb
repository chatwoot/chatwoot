# frozen_string_literal: true

# The scale the CSAT survey offers, mirroring CSAT_RATINGS in
# app/javascript/shared/constants/messages.js. The email templates render the scale
# server-side, so the values cannot live in the frontend bundle alone.
module CsatRatings
  STAR_GLYPH = '★'
  STAR_COLOR = '#F5A524'

  RATINGS = [
    { key: 'poor', value: 1, emoji: '😞' },
    { key: 'fair', value: 2, emoji: '😑' },
    { key: 'average', value: 3, emoji: '😐' },
    { key: 'good', value: 4, emoji: '😀' },
    { key: 'excellent', value: 5, emoji: '😍' }
  ].freeze

  VALUES = RATINGS.pluck(:value).freeze
end
