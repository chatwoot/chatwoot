class OttivNotificationSetting < ApplicationRecord
  include FlagShihTzu

  belongs_to :account
  belongs_to :user

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  EMAIL_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "email_#{key}".to_sym }.invert.freeze
  PUSH_NOTIFICATION_FLAGS = ::Notification::NOTIFICATION_TYPES.transform_keys { |key| "push_#{key}".to_sym }.invert.freeze

  has_flags EMAIL_NOTIFICATION_FLAGS.merge(column: 'email_flags').merge(DEFAULT_QUERY_SETTING)
  has_flags PUSH_NOTIFICATION_FLAGS.merge(column: 'push_flags').merge(DEFAULT_QUERY_SETTING)

  def all_email_flags
    EMAIL_NOTIFICATION_FLAGS.values.map { |flag_symbol| flag_symbol.to_s }
  end

  def all_push_flags
    PUSH_NOTIFICATION_FLAGS.values.map { |flag_symbol| flag_symbol.to_s }
  end

  def selected_email_flags
    EMAIL_NOTIFICATION_FLAGS.values.select do |flag_symbol|
      respond_to?("#{flag_symbol}?") ? public_send("#{flag_symbol}?") : false
    end.map(&:to_s)
  end

  def selected_push_flags
    PUSH_NOTIFICATION_FLAGS.values.select do |flag_symbol|
      respond_to?("#{flag_symbol}?") ? public_send("#{flag_symbol}?") : false
    end.map(&:to_s)
  end

  def selected_email_flags=(flags_array)
    return if flags_array.nil?

    # Limpar todos os flags primeiro
    EMAIL_NOTIFICATION_FLAGS.values.each do |flag_symbol|
      setter_method = "#{flag_symbol}="
      public_send(setter_method, false) if respond_to?(setter_method)
    end

    # Ativar apenas os flags fornecidos
    flags_array.each do |flag_string|
      flag_symbol = flag_string.to_sym
      next unless EMAIL_NOTIFICATION_FLAGS.values.include?(flag_symbol)

      setter_method = "#{flag_symbol}="
      public_send(setter_method, true) if respond_to?(setter_method)
    end
  end

  def selected_push_flags=(flags_array)
    return if flags_array.nil?

    # Limpar todos os flags primeiro
    PUSH_NOTIFICATION_FLAGS.values.each do |flag_symbol|
      setter_method = "#{flag_symbol}="
      public_send(setter_method, false) if respond_to?(setter_method)
    end

    # Ativar apenas os flags fornecidos
    flags_array.each do |flag_string|
      flag_symbol = flag_string.to_sym
      next unless PUSH_NOTIFICATION_FLAGS.values.include?(flag_symbol)

      setter_method = "#{flag_symbol}="
      public_send(setter_method, true) if respond_to?(setter_method)
    end
  end
end
