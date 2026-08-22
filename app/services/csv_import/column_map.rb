# frozen_string_literal: true

# Self-contained CSV column mapping for the Kiraid contact/company importer.
#
# This is the ONLY place that knows about the source CSV's column names. To
# support a different export format, swap this map (or add a new one) — nothing
# else in the importer hard-codes column names.
#
# `standard` keys map a CSV column -> a logical field the importer understands.
# Unknown/extra columns are captured verbatim into contact custom_attributes
# (and company custom_attributes), so the dashboard keeps the full record even
# if we don't surface every field in the UI.
#
# To REMOVE the CSV import feature, delete the whole app/services/csv_import
# directory, the CsvImportController, and the `csv_import` controller action /
# route. The rest of the app does not depend on it.
module CsvImport
  class ColumnMap
    # Logical field -> source CSV column header (exact, case-sensitive).
    STANDARD = {
      place_id: 'place_id',
      query: 'query',
      name: 'name',
      category: 'category',
      categories: 'categories',
      maps_url: 'maps_url',
      address: 'address',
      street: 'street',
      city: 'city',
      postal_code: 'postal_code',
      state: 'state',
      country: 'country',
      latitude: 'latitude',
      longitude: 'longitude',
      plus_code: 'plus_code',
      timezone: 'timezone',
      phone: 'phone',
      phone_e164: 'phone_e164',
      phones: 'phones',
      whatsapp: 'whatsapp',
      email: 'email',
      emails: 'emails',
      website: 'website',
      instagram: 'instagram',
      facebook: 'facebook',
      tiktok: 'tiktok',
      linkedin: 'linkedin',
      youtube: 'youtube',
      twitter: 'twitter',
      rating: 'rating',
      review_count: 'review_count',
      status: 'status',
      description: 'description',
      business_summary: 'business_summary',
      open_hours: 'open_hours',
      operating_hours_text: 'operating_hours_text',
      price_range: 'price_range',
      about: 'about',
      thumbnail: 'thumbnail',
      staff_count: 'staff_count',
      products: 'products',
      cuisine: 'cuisine',
      capacity: 'capacity',
      menu_highlights: 'menu_highlights',
      pic_name: 'pic_name',
      pic_role: 'pic_role',
      contacts: 'contacts',
      services: 'services',
      specialities: 'specialities',
      doctor_count: 'doctor_count',
      staff_names: 'staff_names',
      branch_count: 'branch_count',
      branches: 'branches',
      payment_methods: 'payment_methods',
      insurance_accepted: 'insurance_accepted',
      languages: 'languages',
      year_established: 'year_established',
      company_size: 'company_size',
      tags: 'tags',
      intents: 'intents',
      outreach_note: 'outreach_note',
      decision_makers: 'decision_makers',
      promos: 'promos',
      booking_channels: 'booking_channels',
      completeness: 'completeness',
      confidence: 'confidence',
      crawl_status: 'crawl_status',
      source: 'source'
    }.freeze

    # Logical fields whose raw value should be JSON-parsed before storage.
    JSON_FIELDS = %w[
      categories reviews_per_rating sample_reviews contacts services branches
      payment_methods open_hours operating_hours_text specialities staff_names
      decision_makers intents booking_channels products
    ].freeze

    class << self
      # Build a header->logical-field lookup from the actual CSV headers.
      # Returns {} for headers we don't recognise (those are still captured
      # verbatim as custom attributes in the importer).
      def lookup(headers)
        headers.map { |h| [h, STANDARD.key(h)&.to_s] }.to_h
      end
    end
  end
end
