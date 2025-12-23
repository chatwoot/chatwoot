# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderCollectInputsParams < ::Stripe::RequestParams
      class Input < ::Stripe::RequestParams
        class CustomText < ::Stripe::RequestParams
          # The description which will be displayed when collecting this input
          attr_accessor :description
          # Custom text for the skip button. Maximum 14 characters.
          attr_accessor :skip_button
          # Custom text for the submit button. Maximum 30 characters.
          attr_accessor :submit_button
          # The title which will be displayed when collecting this input
          attr_accessor :title

          def initialize(description: nil, skip_button: nil, submit_button: nil, title: nil)
            @description = description
            @skip_button = skip_button
            @submit_button = submit_button
            @title = title
          end
        end

        class Selection < ::Stripe::RequestParams
          class Choice < ::Stripe::RequestParams
            # The unique identifier for this choice
            attr_accessor :id
            # The style of the button which will be shown for this choice. Can be `primary` or `secondary`.
            attr_accessor :style
            # The text which will be shown on the button for this choice
            attr_accessor :text

            def initialize(id: nil, style: nil, text: nil)
              @id = id
              @style = style
              @text = text
            end
          end
          # List of choices for the `selection` input
          attr_accessor :choices

          def initialize(choices: nil)
            @choices = choices
          end
        end

        class Toggle < ::Stripe::RequestParams
          # The default value of the toggle. Can be `enabled` or `disabled`.
          attr_accessor :default_value
          # The description which will be displayed for the toggle. Maximum 50 characters. At least one of title or description must be provided.
          attr_accessor :description
          # The title which will be displayed for the toggle. Maximum 50 characters. At least one of title or description must be provided.
          attr_accessor :title

          def initialize(default_value: nil, description: nil, title: nil)
            @default_value = default_value
            @description = description
            @title = title
          end
        end
        # Customize the text which will be displayed while collecting this input
        attr_accessor :custom_text
        # Indicate that this input is required, disabling the skip button
        attr_accessor :required
        # Options for the `selection` input
        attr_accessor :selection
        # List of toggles to be displayed and customization for the toggles
        attr_accessor :toggles
        # The type of input to collect
        attr_accessor :type

        def initialize(custom_text: nil, required: nil, selection: nil, toggles: nil, type: nil)
          @custom_text = custom_text
          @required = required
          @selection = selection
          @toggles = toggles
          @type = type
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # List of inputs to be collected from the customer using the Reader. Maximum 5 inputs.
      attr_accessor :inputs
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata

      def initialize(expand: nil, inputs: nil, metadata: nil)
        @expand = expand
        @inputs = inputs
        @metadata = metadata
      end
    end
  end
end
