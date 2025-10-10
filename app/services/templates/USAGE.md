# Templates::NameGeneratorService Usage

## Overview

The `Templates::NameGeneratorService` provides intelligent auto-generation of template names, shortcodes, categories, and descriptions from message data.

## Initialization

```ruby
service = Templates::NameGeneratorService.new(account_id)
```

## Methods

### 1. Generate Template Name

Extracts a meaningful name from message data and ensures uniqueness.

```ruby
# Quick Reply example
message_data = {
  'receivedMessage' => { 'title' => 'What would you like to know?' },
  'quickReply' => { 'replies' => [{}, {}] }
}

name = service.generate_name('quick_reply', message_data)
# => "what_would_you_like_to_know"
```

### 2. Generate Shortcode

Creates a unique shortcode for the template.

```ruby
shortcode = service.generate_shortcode('customer_feedback_form')
# => "customer_feedback_"

# With custom account_id
shortcode = service.generate_shortcode('product_list', another_account_id)
# => "product_list"
```

### 3. Detect Category

Automatically categorizes templates based on message type.

```ruby
category = service.detect_category('time_picker')
# => "scheduling"

category = service.detect_category('apple_pay')
# => "payment"

category = service.detect_category('form')
# => "support"
```

### 4. Generate Description

Creates descriptive text summarizing the template.

```ruby
message_data = {
  'receivedMessage' => { 'title' => 'Choose a product' },
  'listPicker' => {
    'sections' => [
      { 'items' => [{}, {}] },
      { 'items' => [{}, {}, {}] }
    ]
  }
}

description = service.generate_description('list_picker', message_data)
# => "List picker: Choose a product (2 sections, 5 items)"
```

## Message Type Support

### Quick Reply
- **Category**: `general`
- **Name extraction**: From `receivedMessage.title` or `subtitle`
- **Description**: Includes reply count

```ruby
message_data = {
  'receivedMessage' => { 'title' => 'How can we help?' },
  'quickReply' => { 'replies' => [{}, {}, {}] }
}
```

### List Picker
- **Category**: `sales`
- **Name extraction**: From `listPicker.sections[0].title` or `receivedMessage.title`
- **Description**: Includes section and item counts

```ruby
message_data = {
  'listPicker' => {
    'sections' => [
      { 'title' => 'Products', 'items' => [{}, {}] }
    ]
  }
}
```

### Time Picker
- **Category**: `scheduling`
- **Name extraction**: From `receivedMessage.title` or default to "appointment_scheduler"
- **Description**: Includes time slot count

```ruby
message_data = {
  'receivedMessage' => { 'title' => 'Book your appointment' },
  'timePicker' => { 'timeSlots' => [{}, {}, {}] }
}
```

### Form
- **Category**: `support`
- **Name extraction**: From `receivedMessage.title` or `form.title`
- **Description**: Includes field count

```ruby
message_data = {
  'receivedMessage' => { 'title' => 'Customer Feedback' },
  'form' => { 'fields' => [{}, {}, {}] }
}
```

### Apple Pay
- **Category**: `payment`
- **Name extraction**: Prefixed with "payment_" + merchant name
- **Description**: Includes merchant and amount

```ruby
message_data = {
  'payment' => {
    'merchantName' => 'Acme Store',
    'total' => { 'amount' => '99.99' }
  }
}
```

## Key Features

### Uniqueness Guarantees

The service ensures all generated names and shortcodes are unique:

```ruby
# If "customer_survey" exists, generates "customer_survey_1"
# If "customer_survey_1" exists, generates "customer_survey_2"
```

### Case Handling

Supports both camelCase and snake_case input:

```ruby
# Both work:
message_data = { 'receivedMessage' => { 'title' => 'Test' } }
message_data = { 'received_message' => { 'title' => 'Test' } }
```

### Special Character Handling

Automatically cleans and formats names:

```ruby
"What's your favorite product!?" => "whats_your_favorite_product"
"Sign-up for newsletter" => "sign_up_for_newsletter"
"Select    product    type" => "select_product_type"
```

### Length Limits

- **Names**: Max 100 characters
- **Shortcodes**: Max 20 characters
- **Descriptions**: Max 80 characters (with ellipsis)

## Integration Example

```ruby
# In your controller or service
class MessageTemplatesController < ApplicationController
  def create
    generator = Templates::NameGeneratorService.new(current_account.id)

    # Auto-generate template metadata
    template_params = {
      name: generator.generate_name(params[:message_type], params[:message_data]),
      category: generator.detect_category(params[:message_type]),
      description: generator.generate_description(params[:message_type], params[:message_data])
    }

    # Generate shortcode for canned response integration
    shortcode = generator.generate_shortcode(template_params[:name])

    # Create template with auto-generated data
    @template = MessageTemplate.create!(template_params)
  end
end
```

## Testing

Comprehensive RSpec tests are available in:
- `spec/services/templates/name_generator_service_spec.rb`

Run tests with:
```bash
bundle exec rspec spec/services/templates/name_generator_service_spec.rb
```
