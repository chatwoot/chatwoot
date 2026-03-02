class Apify::ResponseParser
  # Parse instagram-profile-scraper output into InfluencerProfile attributes.
  # Input: single profile hash from Apify dataset items.
  def self.parse(data)
    return {} if data.blank?

    posts = data['latestPosts'] || []
    reels, regular_posts = partition_posts(posts)

    build_attrs(data, posts, reels, regular_posts).compact
  end

  def self.build_attrs(data, posts, reels, regular_posts)
    {
      bio: data['biography'],
      fullname: data['fullName'],
      is_verified: data['verified'] || false,
      followers_count: data['followersCount'],
      following_count: data['followsCount'],
      posts_count: data['postsCount'],
      profile_picture_url: data['profilePicUrlHD'].presence || data['profilePicUrl'],
      engagement_rate: calculate_er(posts, data['followersCount']),
      avg_likes: avg_metric(posts, 'likesCount'),
      avg_comments: avg_metric(posts, 'commentsCount'),
      avg_reel_views: avg_reel_views(reels),
      median_reel_views: median_reel_views(reels),
      recent_reels: extract_reels(reels),
      recent_posts: extract_posts(regular_posts),
      apify_data: data
    }
  end
  private_class_method :build_attrs

  def self.partition_posts(posts)
    reels = posts.select { |p| p['type'] == 'Video' && (p['videoViewCount'].to_i.positive? || p['isVideo']) }
    regular = posts.reject { |p| reels.include?(p) }
    [reels, regular]
  end
  private_class_method :partition_posts

  def self.calculate_er(posts, followers)
    return nil if posts.blank? || followers.to_i.zero?

    total_engagement = posts.sum { |p| p['likesCount'].to_i + p['commentsCount'].to_i }
    (total_engagement.to_f / posts.size / followers).round(6)
  end
  private_class_method :calculate_er

  def self.avg_metric(posts, key)
    return nil if posts.blank?

    posts.sum { |p| p[key].to_i }.to_f / posts.size
  end
  private_class_method :avg_metric

  def self.avg_reel_views(reels)
    return nil if reels.blank?

    reels.sum { |r| r['videoViewCount'].to_i }.to_f / reels.size
  end
  private_class_method :avg_reel_views

  def self.median_reel_views(reels)
    return nil if reels.blank?

    views = reels.map { |r| r['videoViewCount'].to_i }.sort
    mid = views.size / 2
    views.size.odd? ? views[mid] : ((views[mid - 1] + views[mid]) / 2.0).round
  end
  private_class_method :median_reel_views

  def self.extract_reels(reels)
    reels.first(6).map do |reel|
      {
        'url' => reel['url'],
        'thumbnail_url' => reel['displayUrl'],
        'views' => reel['videoViewCount'],
        'likes' => reel['likesCount'],
        'comments' => reel['commentsCount'],
        'timestamp' => reel['timestamp']
      }
    end
  end
  private_class_method :extract_reels

  def self.extract_posts(posts)
    posts.first(6).map do |post|
      {
        'url' => post['url'],
        'thumbnail_url' => post['displayUrl'],
        'type' => post['type'],
        'likes' => post['likesCount'],
        'comments' => post['commentsCount'],
        'timestamp' => post['timestamp']
      }
    end
  end
  private_class_method :extract_posts
end
