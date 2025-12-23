# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # This object represents files hosted on Stripe's servers. You can upload
  # files with the [create file](https://stripe.com/docs/api#create_file) request
  # (for example, when uploading dispute evidence). Stripe also
  # creates files independently (for example, the results of a [Sigma scheduled
  # query](https://docs.stripe.com/api#scheduled_queries)).
  #
  # Related guide: [File upload guide](https://stripe.com/docs/file-upload)
  class File < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List

    OBJECT_NAME = "file"
    def self.object_name
      "file"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The file expires and isn't available at this time in epoch seconds.
    attr_reader :expires_at
    # The suitable name for saving the file to a filesystem.
    attr_reader :filename
    # Unique identifier for the object.
    attr_reader :id
    # A list of [file links](https://stripe.com/docs/api#file_links) that point at this file.
    attr_reader :links
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The [purpose](https://stripe.com/docs/file-upload#uploading-a-file) of the uploaded file.
    attr_reader :purpose
    # The size of the file object in bytes.
    attr_reader :size
    # A suitable title for the document.
    attr_reader :title
    # The returned file type (for example, `csv`, `pdf`, `jpg`, or `png`).
    attr_reader :type
    # Use your live secret API key to download the file from this URL.
    attr_reader :url

    # To upload a file to Stripe, you need to send a request of type multipart/form-data. Include the file you want to upload in the request, and the parameters for creating a file.
    #
    # All of Stripe's officially supported Client libraries support sending multipart/form-data.
    def self.create(params = {}, opts = {})
      if params[:file] && !params[:file].is_a?(String) && !params[:file].respond_to?(:read)
        raise ArgumentError, "file must respond to `#read`"
      end

      opts = { content_type: MultipartEncoder::MULTIPART_FORM_DATA }.merge(Util.normalize_opts(opts))

      request_stripe_object(
        method: :post,
        path: "/v1/files",
        params: params,
        opts: opts,
        base_address: :files
      )
    end

    # Returns a list of the files that your account has access to. Stripe sorts and returns the files by their creation dates, placing the most recently created files at the top.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/files", params: params, opts: opts)
    end

    # This resource can have two different object names. In latter API
    # versions, only `file` is used, but since stripe-ruby may be used with
    # any API version, we need to support deserializing the older
    # `file_upload` object into the same class.
    OBJECT_NAME_ALT = "file_upload"
    def self.object_name_alt
      "file_upload"
    end

    def self.resource_url
      "/v1/files"
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
