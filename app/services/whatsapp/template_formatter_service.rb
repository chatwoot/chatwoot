# Service to convert facebook enums to rails enum and vice versa
class Whatsapp::TemplateFormatterService
  def self.format_status_from_meta(status)
    case status
    when 'APPROVED' then 'approved'
    when 'PENDING' then 'pending'
    when 'REJECTED' then 'rejected'
    else 'draft'
    end
  end

  def self.format_category_from_meta(category)
    case category
    when 'MARKETING' then 'marketing'
    when 'AUTHENTICATION' then 'authentication'
    else 'utility'
    end
  end

  def self.format_parameter_format_from_meta(format)
    case format
    when 'NAMED' then 'named'
    when 'POSITIONAL' then 'positional'
    end
  end

  def self.format_status_for_meta(status)
    case status
    when 'approved' then 'APPROVED'
    when 'rejected' then 'REJECTED'
    else 'PENDING'
    end
  end

  def self.format_category_for_meta(category)
    case category
    when 'marketing' then 'MARKETING'
    when 'authentication' then 'AUTHENTICATION'
    else 'UTILITY'
    end
  end

  def self.format_parameter_format_for_meta(format)
    case format
    when 'named' then 'NAMED'
    when 'positional' then 'POSITIONAL'
    end
  end
end
