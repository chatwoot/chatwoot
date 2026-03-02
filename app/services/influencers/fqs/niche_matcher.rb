class Influencers::Fqs::NicheMatcher
  # Keywords for matching in bio, hashtags (lowercased, partial match)
  NICHE_KEYWORDS = {
    home: %w[homedecor homedesign wohnzimmer einrichtung wnetrza gallerywall],
    interior: %w[interior furniture livingroom bedroom interiordesign],
    family: %w[familylife familienleben rodzina motherhood parenting],
    photography: %w[photographer fotografin fotograf fotografka],
    diy: %w[diy crafts handmade renovation]
  }.freeze

  # Structured niche_class names from API (exact match on profile interests)
  NICHE_CLASS_MAP = {
    'Home & DIY' => :home,
    'Film & Photography' => :photography
  }.freeze

  # Audience interest IDs that map to niche categories
  TARGET_INTEREST_IDS = { 1560 => :home, 190 => :family }.freeze

  NICHE_HASHTAGS = %w[
    interior homedecor homedesign wnetrza einrichtung decoration
    gallerywall familylife familienleben rodzina photography
  ].freeze

  def initialize(profile)
    @profile = profile
  end

  def matched_categories_count
    matched_categories.size
  end

  def details
    {
      matched: matched_categories.to_a.map(&:to_s),
      from_niche_class: categories_from_niche_class.map(&:to_s),
      from_interest_ids: categories_from_interest_ids.map(&:to_s),
      from_hashtags: categories_from_hashtags.map(&:to_s),
      from_bio: categories_from_bio.map(&:to_s)
    }
  end

  private

  def matched_categories
    categories = Set.new
    categories.merge(categories_from_niche_class)
    categories.merge(categories_from_interest_ids)
    categories.merge(categories_from_hashtags)
    categories.merge(categories_from_bio)
    categories
  end

  # Match structured niche_class names from API (language-independent)
  def categories_from_niche_class
    interest_names = extract_profile_interest_names
    return [] if interest_names.empty?

    NICHE_CLASS_MAP.each_with_object([]) do |(name, category), matched|
      matched << category if interest_names.include?(name)
    end
  end

  def categories_from_interest_ids
    interest_ids = extract_interest_ids
    return [] if interest_ids.empty?

    TARGET_INTEREST_IDS.each_with_object([]) do |(id, category), matched|
      matched << category if interest_ids.include?(id)
    end
  end

  def categories_from_hashtags
    hashtags = extract_hashtags
    return [] if hashtags.empty?

    all_tags = hashtags.map { |t| t.to_s.downcase.delete('#') }

    NICHE_KEYWORDS.each_with_object([]) do |(category, keywords), matched|
      matched << category if all_tags.intersect?(keywords)
    end
  end

  def categories_from_bio
    bio = @profile.bio.to_s.downcase
    return [] if bio.blank?

    NICHE_KEYWORDS.each_with_object([]) do |(category, keywords), matched|
      hits = keywords.count { |kw| bio.include?(kw) }
      matched << category if hits >= 1
    end
  end

  def extract_profile_interest_names
    interests = @profile.interests
    return [] unless interests.is_a?(Array)

    interests.filter_map { |i| i['name'] || i[:name] }
  end

  def extract_interest_ids
    all_interests = collect_audience_interests
    all_interests.filter_map { |i| (i['id'] || i[:id])&.to_i }
  end

  def collect_audience_interests
    interests = @profile.audience_interests
    interests.is_a?(Array) ? interests : []
  end

  def extract_hashtags
    hashtags = @profile.top_hashtags
    return [] unless hashtags.is_a?(Array)

    hashtags.filter_map { |h| h.is_a?(Hash) ? (h['tag'] || h[:tag]) : h.to_s }
  end
end
