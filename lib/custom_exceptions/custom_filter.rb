module CustomExceptions::CustomFilter
  class InvalidAttribute < CustomExceptions::Base
    def message
      I18n.t('errors.custom_filters.invalid_attribute', key: @data[:key], allowed_keys: @data[:allowed_keys].join(','))
    end
  end

  class InvalidOperator < CustomExceptions::Base
    def message
      I18n.t('errors.custom_filters.invalid_operator', attribute_name: @data[:attribute_name], allowed_keys: @data[:allowed_keys].join(','))
    end
  end

  class InvalidQueryOperator < CustomExceptions::Base
    def message
      I18n.t('errors.custom_filters.invalid_query_operator')
    end
  end

  class InvalidValue < CustomExceptions::Base
    def message
      I18n.t('errors.custom_filters.invalid_value', attribute_name: @data[:attribute_name])
    end
  end
end
