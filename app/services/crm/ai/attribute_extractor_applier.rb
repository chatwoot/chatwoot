module Crm
  module Ai
    class AttributeExtractorApplier
      MIN_CONFIDENCE_DEFAULT = 0.6

      Result = Struct.new(:applied, :rejected, keyword_init: true)

      def initialize(card:, extracted_attributes:, prefix:, min_confidence: MIN_CONFIDENCE_DEFAULT)
        @card = card
        @account = card.account
        @extracted_attributes = extracted_attributes.respond_to?(:with_indifferent_access) ? extracted_attributes.with_indifferent_access : {}
        @prefix = prefix.to_s
        @min_confidence = min_confidence.to_f
        @applied = []
        @rejected = []
      end

      def perform
        apply_group(:contact, @card.contact, :contact_attribute)
        apply_group(:conversation, @card.primary_conversation, :conversation_attribute)
        persist_audit!

        Result.new(applied: @applied, rejected: @rejected)
      end

      private

      def apply_group(target, record, attribute_model)
        return reject_group(target, 'missing_record') if record.blank?

        current = record.custom_attributes.to_h.deep_dup
        updates = {}

        Array(@extracted_attributes[target]).each do |item|
          normalized = normalize_item(item)
          key = normalized[:key]
          definition = definitions_for(attribute_model)[key]

          rejection = rejection_reason(normalized, definition, current.merge(updates))
          if rejection.present?
            reject_item(target, key, rejection)
            next
          end

          value = coerce_value(normalized[:value], definition)
          if value == :invalid
            reject_item(target, key, 'invalid_value')
            next
          end

          updates[key] = value
          track_applied(target, key, value, normalized)
        end

        record.update!(custom_attributes: current.merge(updates)) if updates.any?
      end

      def normalize_item(item)
        data = item.respond_to?(:with_indifferent_access) ? item.with_indifferent_access : {}
        {
          key: data[:key].to_s,
          value: data[:value],
          confidence: data[:confidence].to_f,
          evidence: data[:evidence].to_s
        }
      end

      def rejection_reason(item, definition, current)
        return 'unknown_key' if definition.blank?
        return 'not_whitelisted' unless item[:key].start_with?(@prefix)
        return 'low_confidence' if item[:confidence] < @min_confidence
        return 'already_filled' if filled?(current[item[:key]])

        nil
      end

      def filled?(value)
        return false if value.nil?
        return value.strip.present? if value.is_a?(String)

        true
      end

      def coerce_value(raw, definition)
        case definition.attribute_display_type
        when 'text', 'link'
          raw.to_s.strip.presence || :invalid
        when 'number', 'currency', 'percent'
          coerce_number(raw)
        when 'date'
          coerce_date(raw)
        when 'list'
          coerce_list(raw, definition)
        when 'checkbox'
          coerce_boolean(raw)
        else
          raw.to_s.strip.presence || :invalid
        end
      end

      def coerce_number(raw)
        number = Float(raw)
        number.modulo(1).zero? ? number.to_i : number
      rescue ArgumentError, TypeError
        :invalid
      end

      def coerce_date(raw)
        value = raw.to_s.strip
        return :invalid if value.blank?

        Date.iso8601(value).iso8601
      rescue ArgumentError
        :invalid
      end

      def coerce_list(raw, definition)
        value = raw.to_s.strip
        options = Array(definition.attribute_values).map(&:to_s)
        options.include?(value) ? value : :invalid
      end

      def coerce_boolean(raw)
        return raw if raw == true || raw == false
        return true if raw.to_s.strip.casecmp('true').zero?
        return false if raw.to_s.strip.casecmp('false').zero?

        :invalid
      end

      def definitions_for(attribute_model)
        @definitions_for ||= {}
        @definitions_for[attribute_model] ||= @account.custom_attribute_definitions
                                                 .where(attribute_model: attribute_model)
                                                 .index_by(&:attribute_key)
      end

      def reject_group(target, reason)
        Array(@extracted_attributes[target]).each do |item|
          key = item.respond_to?(:[]) ? item[:key] || item['key'] : nil
          reject_item(target, key, reason)
        end
      end

      def reject_item(target, key, reason)
        @rejected << { target: target.to_s, key: key.to_s, reason: reason }
      end

      def track_applied(target, key, value, item)
        @applied << {
          target: target.to_s,
          key: key,
          value: value,
          confidence: item[:confidence],
          evidence: item[:evidence]
        }
      end

      def persist_audit!
        return if @applied.empty?

        metadata = (@card.metadata || {}).deep_dup
        metadata['ai'] ||= {}
        metadata['ai']['extracted_attributes'] ||= {}
        @applied.each do |item|
          metadata['ai']['extracted_attributes'][item[:key]] = {
            'target' => item[:target],
            'value' => item[:value],
            'confidence' => item[:confidence],
            'evidence' => item[:evidence],
            'source' => 'ai',
            'updated_at' => Time.current.iso8601
          }
        end
        @card.update!(metadata: metadata)
      end
    end
  end
end
