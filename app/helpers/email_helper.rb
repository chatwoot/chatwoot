module EmailHelper
  def extract_domain_without_tld(email)
    domain = email.split('@').last
    domain.split('.').first
  end
end
