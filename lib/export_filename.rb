module ExportFilename
  module_function

  # e.g. dfit-conversaciones-2026-07-22.csv
  def build(account:, resource:, extension:)
    slug = account.name.to_s.parameterize.presence || "account-#{account.id}"
    "#{slug}-#{resource}-#{Time.zone.today.iso8601}.#{extension}"
  end
end
