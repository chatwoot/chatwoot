# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileCreateParams < ::Stripe::RequestParams
    class FileLinkData < ::Stripe::RequestParams
      # Set this to `true` to create a file link for the newly created file. Creating a link is only possible when the file's `purpose` is one of the following: `business_icon`, `business_logo`, `customer_signature`, `dispute_evidence`, `issuing_regulatory_reporting`, `pci_document`, `tax_document_user_upload`, `terminal_android_apk`, or `terminal_reader_splashscreen`.
      attr_accessor :create
      # The link isn't available after this future timestamp.
      attr_accessor :expires_at
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata

      def initialize(create: nil, expires_at: nil, metadata: nil)
        @create = create
        @expires_at = expires_at
        @metadata = metadata
      end
    end
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A file to upload. Make sure that the specifications follow RFC 2388, which defines file transfers for the `multipart/form-data` protocol.
    attr_accessor :file
    # Optional parameters that automatically create a [file link](https://stripe.com/docs/api#file_links) for the newly created file.
    attr_accessor :file_link_data
    # The [purpose](https://stripe.com/docs/file-upload#uploading-a-file) of the uploaded file.
    attr_accessor :purpose

    def initialize(expand: nil, file: nil, file_link_data: nil, purpose: nil)
      @expand = expand
      @file = file
      @file_link_data = file_link_data
      @purpose = purpose
    end
  end
end
