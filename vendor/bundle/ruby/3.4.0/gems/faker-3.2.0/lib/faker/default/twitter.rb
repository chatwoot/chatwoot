# frozen_string_literal: true

module Faker
  class Twitter < Base
    class << self
      ##
      # Produces a random Twitter user.
      #
      # @param include_status [Boolean] Include or exclude user status details
      # @param include_email [Boolean] Include or exclude user email details
      # @return [Hash]
      #
      # @example
      #   Faker::Twitter.user #=>  {:id=>8821452687517076614, :name=>"Lincoln Paucek", :screen_name=>"cody"...
      #   Faker::Twitter.user(include_status: false) # Just get a user object with no embed status
      #   Faker::Twitter.user(include_email: true) # Simulate an authenticated user with the email permission
      #
      # @faker.version 1.7.3
      def user(include_status: true, include_email: false)
        user_id = id
        background_image_url = Faker::LoremFlickr.image(size: '600x400')
        profile_image_url = Faker::Avatar.image(slug: user_id, size: '48x48')
        user = {
          id: user_id,
          id_str: user_id.to_s,
          contributors_enabled: Faker::Boolean.boolean(true_ratio: 0.1),
          created_at: created_at,
          default_profile_image: Faker::Boolean.boolean(true_ratio: 0.1),
          default_profile: Faker::Boolean.boolean(true_ratio: 0.1),
          description: Faker::Lorem.sentence,
          entities: user_entities,
          favourites_count: Faker::Number.between(to: 1, from: 100_000),
          follow_request_sent: false,
          followers_count: Faker::Number.between(to: 1, from: 10_000_000),
          following: false,
          friends_count: Faker::Number.between(to: 1, from: 100_000),
          geo_enabled: Faker::Boolean.boolean(true_ratio: 0.1),
          is_translation_enabled: Faker::Boolean.boolean(true_ratio: 0.1),
          is_translator: Faker::Boolean.boolean(true_ratio: 0.1),
          lang: Faker::Address.country_code,
          listed_count: Faker::Number.between(to: 1, from: 1000),
          location: "#{Faker::Address.city}, #{Faker::Address.state_abbr}, #{Faker::Address.country_code}",
          name: Faker::Name.name,
          notifications: false,
          profile_background_color: Faker::Color.hex_color,
          profile_background_image_url_https: background_image_url,
          profile_background_image_url: background_image_url.sub('https://', 'http://'),
          profile_background_tile: Faker::Boolean.boolean(true_ratio: 0.1),
          profile_banner_url: Faker::LoremFlickr.image(size: '1500x500'),
          profile_image_url_https: profile_image_url,
          profile_image_url: profile_image_url.sub('https://', 'http://'),
          profile_link_color: Faker::Color.hex_color,
          profile_sidebar_border_color: Faker::Color.hex_color,
          profile_sidebar_fill_color: Faker::Color.hex_color,
          profile_text_color: Faker::Color.hex_color,
          profile_use_background_image: Faker::Boolean.boolean(true_ratio: 0.4),
          protected: Faker::Boolean.boolean(true_ratio: 0.1),
          screen_name: screen_name,
          statuses_count: Faker::Number.between(to: 1, from: 100_000),
          time_zone: Faker::Address.time_zone,
          url: Faker::Internet.url(host: 'example.com'),
          utc_offset: utc_offset,
          verified: Faker::Boolean.boolean(true_ratio: 0.1)
        }
        user[:status] = Faker::Twitter.status(include_user: false) if include_status
        user[:email] = Faker::Internet.email if include_email
        user
      end

      ##
      # Produces a random Twitter user.
      #
      # @param include_user [Boolean] Include or exclude user details
      # @param include_photo [Boolean] Include or exclude user photo
      # @return [Hash]
      #
      # @example
      #   Faker::Twitter.status #=> {:id=>8821452687517076614, :text=>"Ea et laboriosam vel non."...
      #   Faker::Twitter.status(include_user: false) # Just get a status object with no embed user
      #   Faker::Twitter.status(include_photo: true) # Includes entities for an attached image
      #
      # @faker.version 1.7.3
      def status(include_user: true, include_photo: false)
        status_id = id
        status = {
          id: status_id,
          id_str: status_id.to_s,
          contributors: nil,
          coordinates: nil,
          created_at: created_at,
          entities: status_entities(include_photo: include_photo),
          favorite_count: Faker::Number.between(to: 1, from: 10_000),
          favorited: false,
          geo: nil,
          in_reply_to_screen_name: nil,
          in_reply_to_status_id: nil,
          in_reply_to_user_id_str: nil,
          in_reply_to_user_id: nil,
          is_quote_status: false,
          lang: Faker::Address.country_code,
          nil: nil,
          place: nil,
          possibly_sensitive: Faker::Boolean.boolean(true_ratio: 0.1),
          retweet_count: Faker::Number.between(to: 1, from: 10_000),
          retweeted_status: nil,
          retweeted: false,
          source: "<a href=\"#{Faker::Internet.url(host: 'example.com')}\" rel=\"nofollow\">#{Faker::Company.name}</a>",
          text: Faker::Lorem.sentence,
          truncated: false
        }
        status[:user] = Faker::Twitter.user(include_status: false) if include_user
        status[:text] = "#{status[:text]} #{status[:entities][:media].first[:url]}" if include_photo
        status
      end

      ##
      # Produces a random screen name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Twitter.screen_name #=> "audreanne_hackett"
      #
      # @faker.version 1.7.3
      def screen_name
        Faker::Internet.username(specifier: nil, separators: ['_'])[0...20]
      end

      private

      def id
        Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807)
      end

      def created_at
        Faker::Date.between(from: '2006-03-21', to: ::Date.today).strftime('%a %b %d %H:%M:%S %z %Y')
      end

      def utc_offset
        Faker::Number.between(to: -43_200, from: 50_400)
      end

      def user_entities
        {
          url: {
            urls: []
          },
          description: {
            urls: []
          }
        }
      end

      def status_entities(include_photo: false)
        entities = {
          hashtags: [],
          symbols: [],
          user_mentions: [],
          urls: []
        }
        entities[:media] = [photo_entity] if include_photo
        entities
      end

      def photo_entity
        media_url = Faker::LoremFlickr.image(size: '1064x600')
        media_id = id
        {
          id: media_id,
          id_str: media_id.to_s,
          indices: [
            103,
            126
          ],
          media_url: media_url.sub('https://', 'http://'),
          media_url_https: media_url,
          url: Faker::Internet.url(host: 'example.com'),
          display_url: 'example.com',
          expanded_url: Faker::Internet.url(host: 'example.com'),
          type: 'photo',
          sizes: {
            medium: {
              w: 1064,
              h: 600,
              resize: 'fit'
            },
            large: {
              w: 1064,
              h: 600,
              resize: 'fit'
            },
            small: {
              w: 680,
              h: 383,
              resize: 'fit'
            },
            thumb: {
              w: 150,
              h: 150,
              resize: 'crop'
            }
          }
        }
      end
    end
  end
end
