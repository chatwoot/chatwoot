# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileService < StripeService
    # To upload a file to Stripe, you need to send a request of type multipart/form-data. Include the file you want to upload in the request, and the parameters for creating a file.
    #
    # All of Stripe's officially supported Client libraries support sending multipart/form-data.
    def create(params = {}, opts = {})
      if params[:file] && !params[:file].is_a?(String) && !params[:file].respond_to?(:read)
        raise ArgumentError, "file must respond to `#read`"
      end

      opts = { content_type: MultipartEncoder::MULTIPART_FORM_DATA }.merge(Util.normalize_opts(opts))

      request(method: :post, path: "/v1/files", params: params, opts: opts, base_address: :files)
    end

    # Returns a list of the files that your account has access to. Stripe sorts and returns the files by their creation dates, placing the most recently created files at the top.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/files", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing file object. After you supply a unique file ID, Stripe returns the corresponding file object. Learn how to [access file contents](https://docs.stripe.com/docs/file-upload#download-file-contents).
    def retrieve(file, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/files/%<file>s", { file: CGI.escape(file) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
