# frozen_string_literal: true

# Test fixtures for Instagram Rich Message payloads
# Used for testing Messages::InstagramRendererMapper

module InstagramRichPayloads
  # Valid Generic Template payload
  GENERIC_TEMPLATE_PAYLOAD = {
    'template_type' => 'generic',
    'elements' => [
      {
        'title' => 'Product 1',
        'subtitle' => 'Amazing product description',
        'image_url' => 'https://example.com/image1.jpg',
        'buttons' => [
          {
            'type' => 'web_url',
            'title' => 'View More',
            'url' => 'https://example.com/product1'
          },
          {
            'type' => 'postback',
            'title' => 'Buy Now',
            'payload' => 'BUY_PRODUCT_1'
          }
        ]
      },
      {
        'title' => 'Product 2',
        'subtitle' => 'Another great product',
        'image_url' => 'https://example.com/image2.jpg',
        'buttons' => [
          {
            'type' => 'postback',
            'title' => 'Select',
            'payload' => 'SELECT_PRODUCT_2'
          }
        ]
      }
    ]
  }.freeze

  # Valid Button Template payload
  BUTTON_TEMPLATE_PAYLOAD = {
    'template_type' => 'button',
    'text' => 'Choose an option:',
    'buttons' => [
      {
        'type' => 'postback',
        'title' => 'Yes',
        'payload' => 'YES'
      },
      {
        'type' => 'postback',
        'title' => 'No',
        'payload' => 'NO'
      },
      {
        'type' => 'web_url',
        'title' => 'Learn More',
        'url' => 'https://example.com/info'
      }
    ]
  }.freeze

  # Valid Quick Replies payload
  QUICK_REPLIES_PAYLOAD = {
    'text' => 'What would you like to do?',
    'quick_replies' => [
      {
        'content_type' => 'text',
        'title' => 'Option 1',
        'payload' => 'OPTION_1'
      },
      {
        'content_type' => 'text',
        'title' => 'Option 2',
        'payload' => 'OPTION_2'
      },
      {
        'content_type' => 'text',
        'title' => 'Option 3',
        'payload' => 'OPTION_3'
      }
    ]
  }.freeze

  # Payload with invalid URLs for security testing
  INVALID_URLS_PAYLOAD = {
    'template_type' => 'generic',
    'elements' => [
      {
        'title' => 'Test Card with Invalid URLs',
        'subtitle' => 'Testing URL sanitization',
        'image_url' => 'javascript:alert("XSS")',  # Invalid: JavaScript URL
        'buttons' => [
          {
            'type' => 'web_url',
            'title' => 'Localhost Attack',
            'url' => 'http://localhost:3000/admin'  # Invalid: Localhost
          },
          {
            'type' => 'web_url',
            'title' => 'IP Attack',
            'url' => 'https://127.0.0.1:8080/secret'  # Invalid: IP address
          },
          {
            'type' => 'web_url',
            'title' => 'FTP Protocol',
            'url' => 'ftp://example.com/file.txt'  # Invalid: Non-HTTP protocol
          },
          {
            'type' => 'web_url',
            'title' => 'Malformed URL',
            'url' => 'not-a-valid-url'  # Invalid: Malformed
          },
          {
            'type' => 'web_url',
            'title' => 'Empty URL',
            'url' => ''  # Invalid: Empty
          },
          {
            'type' => 'web_url',
            'title' => 'Valid URL',
            'url' => 'https://example.com/safe'  # Valid: Should be kept
          }
        ]
      }
    ]
  }.freeze

  # Oversized payload that exceeds MAX_PAYLOAD_SIZE (25KB)
  OVERSIZED_PAYLOAD = {
    'template_type' => 'generic',
    'elements' => (1..100).map do |i|
      {
        'title' => "Product #{i} with very long title " + ('A' * 500),
        'subtitle' => "Very long description for product #{i} " + ('B' * 800),
        'image_url' => "https://example.com/very-long-image-url-#{i}.jpg?" + ('param=' + 'C' * 200),
        'buttons' => [
          {
            'type' => 'web_url',
            'title' => "View Product #{i}",
            'url' => "https://example.com/product/#{i}?" + ('tracking=' + 'D' * 300)
          },
          {
            'type' => 'postback',
            'title' => "Buy Product #{i}",
            'payload' => "BUY_PRODUCT_#{i}_" + ('E' * 400)
          },
          {
            'type' => 'postback',
            'title' => "Add to Cart #{i}",
            'payload' => "ADD_TO_CART_#{i}_" + ('F' * 400)
          }
        ]
      }
    end
  }.freeze

  # Payload with excessive elements (more than MAX_CARDS)
  EXCESSIVE_ELEMENTS_PAYLOAD = {
    'template_type' => 'generic',
    'elements' => (1..50).map do |i|
      {
        'title' => "Product #{i}",
        'subtitle' => "Description for product #{i}",
        'image_url' => "https://example.com/image#{i}.jpg",
        'buttons' => [
          {
            'type' => 'postback',
            'title' => 'Select',
            'payload' => "SELECT_#{i}"
          }
        ]
      }
    end
  }.freeze

  # Payload with excessive buttons (more than MAX_BTNS)
  EXCESSIVE_BUTTONS_PAYLOAD = {
    'template_type' => 'button',
    'text' => 'Choose from many options:',
    'buttons' => (1..10).map do |i|
      {
        'type' => 'postback',
        'title' => "Option #{i}",
        'payload' => "OPTION_#{i}"
      }
    end
  }.freeze

  # Payload with very long titles and descriptions for truncation testing
  LONG_TEXT_PAYLOAD = {
    'template_type' => 'generic',
    'elements' => [
      {
        'title' => 'A' * 300,  # Exceeds TITLE_LIMIT (120)
        'subtitle' => 'B' * 500,  # Exceeds DESCRIPTION_LIMIT (200)
        'image_url' => 'https://example.com/image.jpg',
        'buttons' => [
          {
            'type' => 'web_url',
            'title' => 'C' * 100,  # Long button title
            'url' => 'https://example.com/long-url'
          }
        ]
      }
    ]
  }.freeze

  # Malformed payloads for error handling testing
  MALFORMED_PAYLOADS = [
    nil,
    '',
    [],
    { 'invalid' => 'structure' },
    { 'template_type' => 'unknown' },
    { 'template_type' => 'generic' },  # Missing elements
    { 'template_type' => 'generic', 'elements' => [] },  # Empty elements
    { 'template_type' => 'generic', 'elements' => [{}] },  # Empty element
    { 'template_type' => 'button' },  # Missing text and buttons
    { 'template_type' => 'button', 'text' => '', 'buttons' => [] },  # Empty text and buttons
    { 'quick_replies' => [] },  # Empty quick replies
    { 'quick_replies' => [{ 'title' => '', 'payload' => '' }] }  # Invalid quick reply
  ].freeze

  # Edge case payloads
  EDGE_CASE_PAYLOADS = {
    # Generic template with minimal data
    minimal_generic: {
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => 'Minimal'
        }
      ]
    },

    # Button template with only text
    text_only_button: {
      'template_type' => 'button',
      'text' => 'Just text, no buttons'
    },

    # Quick replies with minimal data
    minimal_quick_replies: {
      'text' => 'Choose:',
      'quick_replies' => [
        {
          'title' => 'Option',
          'payload' => 'PAYLOAD'
        }
      ]
    },

    # Mixed valid and invalid buttons
    mixed_buttons: {
      'template_type' => 'button',
      'text' => 'Mixed buttons:',
      'buttons' => [
        {
          'type' => 'postback',
          'title' => 'Valid Postback',
          'payload' => 'VALID'
        },
        {
          'type' => 'web_url',
          'title' => 'Invalid URL',
          'url' => 'not-a-url'
        },
        {
          'type' => 'postback',
          'title' => '',  # Invalid: empty title
          'payload' => 'EMPTY_TITLE'
        },
        {
          'type' => 'web_url',
          'title' => 'Valid URL',
          'url' => 'https://example.com'
        }
      ]
    },

    # Unicode and special characters
    unicode_payload: {
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => '🎉 Special Product 特別な製品',
          'subtitle' => 'Description with émojis and àccénts',
          'image_url' => 'https://example.com/unicode-image.jpg',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => '✅ Confirm',
              'payload' => 'CONFIRM_UNICODE'
            }
          ]
        }
      ]
    }
  }.freeze
end