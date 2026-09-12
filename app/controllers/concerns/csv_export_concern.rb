# frozen_string_literal: true

module CsvExportConcern
  extend ActiveSupport::Concern

  UTF8_BOM = "\xEF\xBB\xBF"

  def render_csv_with_bom(filename, template, formats: [:csv])
    response.headers['Content-Type'] = 'text/csv; charset=utf-8'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"

    csv_string = render_to_string(layout: false, template: template, formats: formats)
    send_data "#{UTF8_BOM}#{csv_string}", filename: "#{filename}.csv", type: 'text/csv; charset=utf-8', disposition: 'attachment'
  end
end
