class AppleMessagesForBusiness::FormBuilderService
  include ApplicationHelper

  def initialize(form_template: nil)
    @form_template = form_template || {}
    @form_id = SecureRandom.uuid
    @pages = []
  end

  # Build a complete form configuration
  def build_form(title:, description: nil)
    {
      form_id: @form_id,
      title: title,
      description: description,
      pages: @pages,
      version: '1.0',
      use_live_layout: true,
      submit_button: { title: 'Submit', style: 'primary' },
      cancel_button: { title: 'Cancel', style: 'secondary' }
    }
  end

  # Add a new page to the form
  def add_page(title:, description: nil, page_id: nil)
    page_id ||= "page_#{@pages.length + 1}"

    page = {
      page_id: page_id,
      title: title,
      description: description,
      items: []
    }

    @pages << page
    FormPageBuilder.new(page, self)
  end

  # Predefined form templates
  def self.contact_form_template
    builder = new

    page = builder.add_page(title: 'Contact Information', description: 'Please provide your contact details')

    page.add_text_field(
      item_id: 'full_name',
      title: 'Full Name',
      required: true,
      placeholder: 'Enter your full name'
    )

    page.add_email_field(
      item_id: 'email',
      title: 'Email Address',
      required: true,
      placeholder: 'your.email@example.com'
    )

    page.add_phone_field(
      item_id: 'phone',
      title: 'Phone Number',
      required: false,
      placeholder: '+1 (555) 123-4567'
    )

    page.add_select_field(
      item_id: 'preferred_contact',
      title: 'Preferred Contact Method',
      required: true,
      options: [
        { value: 'email', title: 'Email' },
        { value: 'phone', title: 'Phone Call' },
        { value: 'text', title: 'Text Message' }
      ]
    )

    builder.build_form(
      title: 'Contact Form',
      description: 'We\'d love to hear from you'
    )
  end

  def self.feedback_form_template
    builder = new

    page = builder.add_page(title: 'Feedback', description: 'Help us improve our service')

    page.add_select_field(
      item_id: 'rating',
      title: 'Overall Rating',
      required: true,
      options: (1..5).map { |i| { value: i.to_s, title: "#{i} #{'★' * i}" } }
    )

    page.add_text_area(
      item_id: 'comments',
      title: 'Comments',
      required: false,
      placeholder: 'Tell us about your experience...',
      max_length: 500
    )

    page.add_toggle_field(
      item_id: 'recommend',
      title: 'Would you recommend us to others?',
      required: false,
      default_value: true
    )

    builder.build_form(
      title: 'Customer Feedback',
      description: 'Your opinion matters to us'
    )
  end

  def self.appointment_form_template
    builder = new

    page = builder.add_page(title: 'Book Appointment', description: 'Schedule your visit')

    page.add_text_field(
      item_id: 'customer_name',
      title: 'Name',
      required: true
    )

    page.add_datetime_field(
      item_id: 'appointment_date',
      title: 'Preferred Date & Time',
      required: true,
      min_date: Date.current.iso8601,
      max_date: (Date.current + 30.days).iso8601
    )

    page.add_select_field(
      item_id: 'service_type',
      title: 'Service Type',
      required: true,
      options: [
        { value: 'consultation', title: 'Consultation' },
        { value: 'follow_up', title: 'Follow-up' },
        { value: 'urgent', title: 'Urgent Care' }
      ]
    )

    page.add_text_area(
      item_id: 'notes',
      title: 'Additional Notes',
      required: false,
      placeholder: 'Any specific requirements or concerns?'
    )

    builder.build_form(
      title: 'Appointment Booking',
      description: 'Book your appointment in just a few steps'
    )
  end

  def self.survey_form_template
    builder = new

    # Page 1: Demographics
    page1 = builder.add_page(title: 'About You', description: 'Basic information')

    page1.add_select_field(
      item_id: 'age_range',
      title: 'Age Range',
      required: false,
      options: [
        { value: '18-24', title: '18-24' },
        { value: '25-34', title: '25-34' },
        { value: '35-44', title: '35-44' },
        { value: '45-54', title: '45-54' },
        { value: '55+', title: '55+' }
      ]
    )

    page1.add_select_field(
      item_id: 'usage_frequency',
      title: 'How often do you use our service?',
      required: true,
      options: [
        { value: 'daily', title: 'Daily' },
        { value: 'weekly', title: 'Weekly' },
        { value: 'monthly', title: 'Monthly' },
        { value: 'rarely', title: 'Rarely' }
      ]
    )

    # Page 2: Preferences
    page2 = builder.add_page(title: 'Preferences', description: 'Tell us what you think')

    page2.add_multi_select_field(
      item_id: 'favorite_features',
      title: 'Favorite Features',
      required: false,
      options: [
        { value: 'easy_to_use', title: 'Easy to Use' },
        { value: 'fast_response', title: 'Fast Response' },
        { value: 'helpful_support', title: 'Helpful Support' },
        { value: 'good_pricing', title: 'Good Pricing' }
      ]
    )

    page2.add_stepper_field(
      item_id: 'satisfaction_score',
      title: 'Satisfaction Score (1-10)',
      required: true,
      min_value: 1,
      max_value: 10,
      default_value: 5
    )

    builder.build_form(
      title: 'Customer Survey',
      description: 'Help us understand your needs better'
    )
  end

  def self.order_form_template
    builder = new

    page = builder.add_page(title: 'Place Order', description: 'Complete your purchase')

    page.add_select_field(
      item_id: 'product',
      title: 'Product',
      required: true,
      options: [
        { value: 'basic', title: 'Basic Plan - $9.99/month' },
        { value: 'premium', title: 'Premium Plan - $19.99/month' },
        { value: 'enterprise', title: 'Enterprise Plan - $49.99/month' }
      ]
    )

    page.add_stepper_field(
      item_id: 'quantity',
      title: 'Quantity',
      required: true,
      min_value: 1,
      max_value: 10,
      default_value: 1
    )

    page.add_text_field(
      item_id: 'billing_name',
      title: 'Billing Name',
      required: true
    )

    page.add_email_field(
      item_id: 'billing_email',
      title: 'Billing Email',
      required: true
    )

    page.add_toggle_field(
      item_id: 'terms_accepted',
      title: 'I accept the terms and conditions',
      required: true,
      default_value: false
    )

    builder.build_form(
      title: 'Order Form',
      description: 'Complete your purchase securely'
    )
  end

  # Create form from JSON configuration
  def self.from_json(json_config)
    config = JSON.parse(json_config) if json_config.is_a?(String)
    config ||= json_config

    builder = new

    config['pages']&.each do |page_config|
      page = builder.add_page(
        title: page_config['title'],
        description: page_config['description'],
        page_id: page_config['page_id']
      )

      page_config['items']&.each do |item_config|
        case item_config['item_type']
        when 'text'
          page.add_text_field(item_config.symbolize_keys)
        when 'textArea'
          page.add_text_area(item_config.symbolize_keys)
        when 'email'
          page.add_email_field(item_config.symbolize_keys)
        when 'phone'
          page.add_phone_field(item_config.symbolize_keys)
        when 'singleSelect'
          page.add_select_field(item_config.symbolize_keys)
        when 'multiSelect'
          page.add_multi_select_field(item_config.symbolize_keys)
        when 'dateTime'
          page.add_datetime_field(item_config.symbolize_keys)
        when 'toggle'
          page.add_toggle_field(item_config.symbolize_keys)
        when 'stepper'
          page.add_stepper_field(item_config.symbolize_keys)
        when 'richLink'
          page.add_rich_link(item_config.symbolize_keys)
        when 'button'
          page.add_button(item_config.symbolize_keys)
        end
      end
    end

    builder.build_form(
      title: config['title'],
      description: config['description']
    )
  end

  # Validate form configuration
  def self.validate_form_config(config)
    errors = []

    errors << 'Form must have a title' unless config['title'].present?
    errors << 'Form must have at least one page' unless config['pages'].present?

    config['pages']&.each_with_index do |page, page_index|
      errors << "Page #{page_index + 1} must have a title" unless page['title'].present?
      errors << "Page #{page_index + 1} must have at least one item" unless page['items'].present?

      page['items']&.each_with_index do |item, item_index|
        item_errors = validate_form_item(item)
        item_errors.each do |error|
          errors << "Page #{page_index + 1}, Item #{item_index + 1}: #{error}"
        end
      end
    end

    errors
  end

  def self.validate_form_item(item)
    errors = []

    errors << 'Item must have an item_id' unless item['item_id'].present?
    errors << 'Item must have an item_type' unless item['item_type'].present?
    errors << 'Item must have a title' unless item['title'].present?

    case item['item_type']
    when 'singleSelect', 'multiSelect'
      errors << 'Select item must have options' unless item['options'].present?
    when 'stepper'
      errors << 'Stepper must have min_value' unless item['min_value'].present?
      errors << 'Stepper must have max_value' unless item['max_value'].present?
    when 'richLink'
      errors << 'Rich link must have a URL' unless item['url'].present?
    end

    errors
  end

  # Inner class to handle page building
  class FormPageBuilder
    def initialize(page, parent_builder)
      @page = page
      @parent_builder = parent_builder
    end

    def add_text_field(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'text', title: title, required: required, **options)
    end

    def add_text_area(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'textArea', title: title, required: required, **options)
    end

    def add_email_field(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'email', title: title, required: required, **options)
    end

    def add_phone_field(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'phone', title: title, required: required, **options)
    end

    def add_select_field(item_id:, title:, options:, required: false, **other_options)
      add_item(item_id: item_id, item_type: 'singleSelect', title: title, required: required, options: options, **other_options)
    end

    def add_multi_select_field(item_id:, title:, options:, required: false, **other_options)
      add_item(item_id: item_id, item_type: 'multiSelect', title: title, required: required, options: options, **other_options)
    end

    def add_datetime_field(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'dateTime', title: title, required: required, **options)
    end

    def add_toggle_field(item_id:, title:, required: false, **options)
      add_item(item_id: item_id, item_type: 'toggle', title: title, required: required, **options)
    end

    def add_stepper_field(item_id:, title:, min_value:, max_value:, required: false, **options)
      add_item(item_id: item_id, item_type: 'stepper', title: title, required: required, min_value: min_value, max_value: max_value, **options)
    end

    def add_rich_link(item_id:, title:, url:, required: false, **options)
      add_item(item_id: item_id, item_type: 'richLink', title: title, required: required, url: url, **options)
    end

    def add_button(item_id:, title:, action:, required: false, **options)
      add_item(item_id: item_id, item_type: 'button', title: title, required: required, action: action, **options)
    end

    private

    def add_item(**item_config)
      @page[:items] << item_config.compact
      self
    end
  end
end