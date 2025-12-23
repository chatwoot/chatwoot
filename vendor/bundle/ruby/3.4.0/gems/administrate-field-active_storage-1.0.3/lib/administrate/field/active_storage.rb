require 'administrate/field/base'
require 'rails'

module Administrate
  module Field
    class ActiveStorage < Administrate::Field::Base
      class Engine < ::Rails::Engine
        Administrate::Engine.add_stylesheet "administrate-field-active_storage/application"
      end

      def index_display_preview?
        options.fetch(:index_display_preview, true)
      end

      def index_preview_size
        options.fetch(:index_preview_size, [150, 150])
      end

      def index_preview_variant
        options.fetch(:index_preview_variant, nil)
      end

      def index_preview_only?
        options.fetch(:index_preview_only, false)
      end

      def index_display_count?
        options.fetch(:index_display_count) { attached? && attachments.count != 1 }
      end

      def show_display_preview?
        options.fetch(:show_display_preview, true)
      end

      def show_preview_size
        options.fetch(:show_preview_size, [800, 800])
      end

      def show_preview_variant
        options.fetch(:show_preview_variant, nil)
      end

      def many?
        data.is_a? ::ActiveStorage::Attached::Many
      end

      def direct?
        options.fetch(:direct_upload, false)
      end

      def destroy_url
        options.fetch(:destroy_url, nil)
      end

      # currently we are using Rails.application.routes.url_helpers
      # without including the namespace because it runs into an
      # exception

      # work around since calling data.preview(options)
      # returns "/images/<ActiveStorage::Preview>" which isnt the url
      def preview(attachment, options)
        Rails.application.routes.url_helpers.rails_representation_path(attachment.preview(options), only_path: true)
      end

      def variant(attachment, options)
        Rails.application.routes.url_helpers.rails_representation_path(attachment.variant(options), only_path: true)
      end

      def url(attachment)
        Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
      end

      def blob_url(attachment)
        Rails.application.routes.url_helpers.rails_blob_path(attachment, disposition: :attachment, only_path: true)
      end

      def can_add_attachment?
        many? || attachments.blank?
      end

      def attached?
        data.present? && data.attached?
      end

      def attachments
        many? ? data.attachments : [data.attachment] if attached?
      end
    end
  end
end
