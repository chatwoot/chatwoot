# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileLinkCreateParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The link isn't usable after this future timestamp.
    attr_accessor :expires_at
    # The ID of the file. The file's `purpose` must be one of the following: `business_icon`, `business_logo`, `customer_signature`, `dispute_evidence`, `finance_report_run`, `financial_account_statement`, `identity_document_downloadable`, `issuing_regulatory_reporting`, `pci_document`, `selfie`, `sigma_scheduled_query`, `tax_document_user_upload`, `terminal_android_apk`, or `terminal_reader_splashscreen`.
    attr_accessor :file
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(expand: nil, expires_at: nil, file: nil, metadata: nil)
      @expand = expand
      @expires_at = expires_at
      @file = file
      @metadata = metadata
    end
  end
end
