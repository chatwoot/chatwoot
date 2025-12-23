# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  class Inflector < Zeitwerk::GemInflector
    extend T::Sig

    sig { params(basename: String, abspath: String).returns(String) }
    def camelize(basename, abspath)
      if basename =~ /\Ashopify_api(.*)/
        "ShopifyAPI" + super(Regexp.last_match(1), abspath)
      else
        super
      end
    end
  end
end
