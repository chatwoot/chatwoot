# Shared helper for controller actions that serve a rendered CSV template
# as a file download.
#
# The body is prefixed with a UTF-8 byte order mark so that spreadsheet
# applications (most notably Microsoft Excel) detect the encoding and render
# non-ASCII characters (Cyrillic, Arabic, CJK, accented Latin, ...) correctly.
# Account::ContactsExportJob applies the same treatment to the contacts export.
module CsvExportConcern
  extend ActiveSupport::Concern

  UTF8_BOM = "\xEF\xBB\xBF".freeze

  private

  def render_csv(filename:, template: nil)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}"

    render_options = { layout: false, formats: [:csv] }
    render_options[:template] = template if template.present?

    self.response_body = "#{UTF8_BOM}#{render_to_string(**render_options)}"
  end
end
