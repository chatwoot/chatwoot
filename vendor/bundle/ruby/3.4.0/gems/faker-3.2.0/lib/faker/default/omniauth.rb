# frozen_string_literal: true

module Faker
  class Omniauth < Base
    require 'time'
    attr_reader :name,
                :first_name,
                :last_name,
                :email

    def initialize(name: nil, email: nil)
      super()

      @name = name || "#{Name.first_name} #{Name.last_name}"
      @email = email || Internet.email(name: self.name)
      @first_name, @last_name = self.name.split
    end

    class << self
      ##
      # Generate a mock Omniauth response from Google.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-google.
      #
      # @faker.version 1.8.0
      def google(name: nil, email: nil, uid: Number.number(digits: 9).to_s)
        auth = Omniauth.new(name: name, email: email)
        {
          provider: 'google_oauth2',
          uid: uid,
          info: {
            name: auth.name,
            first_name: auth.first_name,
            last_name: auth.last_name,
            email: auth.email,
            image: image
          },
          credentials: {
            token: Crypto.md5,
            refresh_token: Crypto.md5,
            expires_at: Time.forward.to_i,
            expires: true
          },
          extra: {
            raw_info: {
              sub: uid,
              email: auth.email,
              email_verified: random_boolean.to_s,
              name: auth.name,
              given_name: auth.first_name,
              family_name: auth.last_name,
              profile: "https://plus.google.com/#{uid}",
              picture: image,
              gender: gender,
              birthday: Date.backward(days: 36_400).strftime('%Y-%m-%d'),
              locale: 'en',
              hd: "#{Company.name.downcase}.com"
            },
            id_info: {
              iss: 'accounts.google.com',
              at_hash: Crypto.md5,
              email_verified: true,
              sub: Number.number(digits: 28).to_s,
              azp: 'APP_ID',
              email: auth.email,
              aud: 'APP_ID',
              iat: Time.forward.to_i,
              exp: Time.forward.to_i,
              openid_id: "https://www.google.com/accounts/o8/id?id=#{uid}"
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from Facebook.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param username [String] A specific username to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-facebook.
      #
      # @faker.version 1.8.0
      def facebook(name: nil, email: nil, username: nil, uid: Number.number(digits: 7).to_s)
        auth = Omniauth.new(name: name, email: email)
        username ||= "#{auth.first_name.downcase[0]}#{auth.last_name.downcase}"
        {
          provider: 'facebook',
          uid: uid,
          info: {
            email: auth.email,
            name: auth.name,
            first_name: auth.first_name,
            last_name: auth.last_name,
            image: image,
            verified: random_boolean
          },
          credentials: {
            token: Crypto.md5,
            expires_at: Time.forward.to_i,
            expires: true
          },
          extra: {
            raw_info: {
              id: uid,
              name: auth.name,
              first_name: auth.first_name,
              last_name: auth.last_name,
              link: "http://www.facebook.com/#{username}",
              username: username,
              location: {
                id: Number.number(digits: 9).to_s,
                name: city_state
              },
              gender: gender,
              email: auth.email,
              timezone: timezone,
              locale: 'en_US',
              verified: random_boolean,
              updated_time: Time.backward.iso8601
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from Twitter.
      #
      # @param name [String] A specific name to return in the response.
      # @param nickname [String] A specific nickname to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-twitter.
      #
      # @faker.version 1.8.0
      def twitter(name: nil, nickname: nil, uid: Number.number(digits: 6).to_s)
        auth = Omniauth.new(name: name)
        nickname ||= auth.name.downcase.delete(' ')
        location = city_state
        description = Lorem.sentence
        {
          provider: 'twitter',
          uid: uid,
          info: {
            nickname: nickname,
            name: auth.name,
            location: location,
            image: image,
            description: description,
            urls: {
              Website: nil,
              Twitter: "https://twitter.com/#{nickname}"
            }
          },
          credentials: {
            token: Crypto.md5,
            secret: Crypto.md5
          },
          extra: {
            access_token: '',
            raw_info: {
              name: auth.name,
              listed_count: random_number_from_range(1..10),
              profile_sidebar_border_color: Color.hex_color,
              url: nil,
              lang: 'en',
              statuses_count: random_number_from_range(1..1000),
              profile_image_url: image,
              profile_background_image_url_https: image,
              location: location,
              time_zone: Address.city,
              follow_request_sent: random_boolean,
              id: uid,
              profile_background_tile: random_boolean,
              profile_sidebar_fill_color: Color.hex_color,
              followers_count: random_number_from_range(1..10_000),
              default_profile_image: random_boolean,
              screen_name: '',
              following: random_boolean,
              utc_offset: timezone,
              verified: random_boolean,
              favourites_count: random_number_from_range(1..10),
              profile_background_color: Color.hex_color,
              is_translator: random_boolean,
              friends_count: random_number_from_range(1..10_000),
              notifications: random_boolean,
              geo_enabled: random_boolean,
              profile_background_image_url: image,
              protected: random_boolean,
              description: description,
              profile_link_color: Color.hex_color,
              created_at: Time.backward.strftime('%a %b %d %H:%M:%S %z %Y'),
              id_str: uid,
              profile_image_url_https: image,
              default_profile: random_boolean,
              profile_use_background_image: random_boolean,
              entities: {
                description: {
                  urls: []
                }
              },
              profile_text_color: Color.hex_color,
              contributors_enabled: random_boolean
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from LinkedIn.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-linkedin.
      #
      # @faker.version 1.8.0
      def linkedin(name: nil, email: nil, uid: Number.number(digits: 6).to_s)
        auth = Omniauth.new(name: name, email: email)
        first_name = auth.first_name.downcase
        last_name = auth.last_name.downcase
        location = city_state
        description = Lorem.sentence
        token = Crypto.md5
        secret = Crypto.md5
        industry = Commerce.department
        url = "http://www.linkedin.com/in/#{first_name}#{last_name}"
        {
          provider: 'linkedin',
          uid: uid,
          info: {
            name: auth.name,
            email: auth.email,
            nickname: auth.name,
            first_name: auth.first_name,
            last_name: auth.last_name,
            location: location,
            description: description,
            image: image,
            phone: PhoneNumber.phone_number,
            headline: description,
            industry: industry,
            urls: {
              public_profile: url
            }
          },
          credentials: {
            token: token,
            secret: secret
          },
          extra: {
            access_token: {
              token: token,
              secret: secret,
              consumer: nil,
              params: {
                oauth_token: token,
                oauth_token_secret: secret,
                oauth_expires_in: Time.forward.to_i,
                oauth_authorization_expires_in: Time.forward.to_i
              },
              response: nil
            },
            raw_info: {
              firstName: auth.first_name,
              headline: description,
              id: uid,
              industry: industry,
              lastName: auth.last_name,
              location: {
                country: { code: Address.country_code.downcase },
                name: city_state.split(', ').first
              },
              pictureUrl: image,
              publicProfileUrl: url
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from Github.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-github.
      #
      # @faker.version 1.8.0
      def github(name: nil, email: nil, uid: Number.number(digits: 8).to_s)
        auth = Omniauth.new(name: name, email: email)
        login = auth.name.downcase.tr(' ', '-')
        html_url = "https://github.com/#{login}"
        api_url = "https://api.github.com/users/#{login}"
        {
          provider: 'github',
          uid: uid,
          info: {
            nickname: login,
            email: auth.email,
            name: auth.name,
            image: image,
            urls: {
              GitHub: html_url
            }
          },
          credentials: {
            token: Crypto.md5,
            expires: false
          },
          extra: {
            raw_info: {
              login: login,
              id: uid,
              avatar_url: image,
              gravatar_id: '',
              url: api_url,
              html_url: html_url,
              followers_url: "#{api_url}/followers",
              following_url: "#{api_url}/following{/other_user}",
              gists_url: "#{api_url}/gists{/gist_id}",
              starred_url: "#{api_url}/starred{/owner}{/repo}",
              subscriptions_url: "#{api_url}/subscriptions",
              organizations_url: "#{api_url}/orgs",
              repos_url: "#{api_url}/repos",
              events_url: "#{api_url}/events{/privacy}",
              received_events_url: "#{api_url}/received_events",
              type: 'User',
              site_admin: random_boolean,
              name: auth.name,
              company: nil,
              blog: nil,
              location: city_state,
              email: auth.email,
              hireable: nil,
              bio: nil,
              public_repos: random_number_from_range(1..1000),
              public_gists: random_number_from_range(1..1000),
              followers: random_number_from_range(1..1000),
              following: random_number_from_range(1..1000),
              created_at: Time.backward(days: 36_400).iso8601,
              updated_at: Time.backward(days: 2).iso8601
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from Apple.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-apple.
      #
      # @faker.version 2.3.0
      def apple(name: nil, email: nil, uid: nil)
        uid ||= "#{Number.number(digits: 6)}.#{Number.hexadecimal(digits: 32)}.#{Number.number(digits: 4)}"
        auth = Omniauth.new(name: name, email: email)
        {
          provider: 'apple',
          uid: uid,
          info: {
            sub: uid,
            email: auth.email,
            first_name: auth.first_name,
            last_name: auth.last_name
          },
          credentials: {
            token: Crypto.md5,
            refresh_token: Crypto.md5,
            expires_at: Time.forward.to_i,
            expires: true
          },
          extra: {
            raw_info: {
              iss: 'https://appleid.apple.com',
              aud: 'CLIENT_ID',
              exp: Time.forward.to_i,
              iat: Time.forward.to_i,
              sub: uid,
              at_hash: Crypto.md5,
              auth_time: Time.forward.to_i,
              email: auth.email,
              email_verified: true
            }
          }
        }
      end

      ##
      # Generate a mock Omniauth response from Auth0.
      #
      # @param name [String] A specific name to return in the response.
      # @param email [String] A specific email to return in the response.
      # @param uid [String] A specific UID to return in the response.
      #
      # @return [Hash] An auth hash in the format provided by omniauth-auth0.
      #
      # @faker.version next
      def auth0(name: nil, email: nil, uid: nil)
        uid ||= "auth0|#{Number.hexadecimal(digits: 24)}"
        auth = Omniauth.new(name: name, email: email)
        {
          provider: 'auth0',
          uid: uid,
          info: {
            name: uid,
            nickname: auth.name,
            email: auth.email,
            image: image
          },
          credentials: {
            expires_at: Time.forward.to_i,
            expires: true,
            token_type: 'Bearer',
            id_token: Crypto.sha256,
            token: Crypto.md5,
            refresh_token: Crypto.md5
          },
          extra: {
            raw_info: {
              email: auth.email,
              email_verified: true,
              iss: 'https://auth0.com/',
              sub: uid,
              aud: 'Auth012345',
              iat: Time.forward.to_i,
              exp: Time.forward.to_i
            }
          }
        }
      end

      private

      def gender
        shuffle(%w[male female]).pop
      end

      def timezone
        shuffle((-12..12).to_a).pop
      end

      def image
        Placeholdit.image
      end

      def city_state
        "#{Address.city}, #{Address.state}"
      end

      def random_number_from_range(range)
        shuffle(range.to_a).pop
      end

      def random_boolean
        shuffle([true, false]).pop
      end
    end
  end
end
