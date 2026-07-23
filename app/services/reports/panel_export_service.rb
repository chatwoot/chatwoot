class Reports::PanelExportService
  TIME_COLUMNS = %w[
    avg_first_response_time
    avg_resolution_time
    avg_reply_time
    reply_time
  ].freeze

  HEADER_LABELS = {
    'rank' => 'Puesto',
    'id' => 'ID',
    'name' => 'Nombre',
    'contact_name' => 'Contacto',
    'phone_number' => 'Teléfono',
    'email' => 'Correo',
    'document_number' => 'Documento',
    'conversations_count' => 'Conversaciones',
    'resolved_conversations_count' => 'Resueltas',
    'avg_first_response_time' => '1ª respuesta',
    'avg_resolution_time' => 'Resolución',
    'avg_reply_time' => 'Tiempo de espera',
    'share_percent' => 'Participación %',
    'csat_avg' => 'CSAT promedio',
    'incoming_messages_count' => 'Mensajes entrantes',
    'outgoing_messages_count' => 'Mensajes salientes',
    'status' => 'Estado',
    'priority' => 'Prioridad',
    'labels' => 'Etiquetas',
    'inbox' => 'Bandeja',
    'assignee' => 'Agente',
    'created_at' => 'Creado',
    'last_activity_at' => 'Última actividad'
  }.freeze

  METRIC_LABELS = {
    'conversations_count' => 'Conversaciones',
    'incoming_messages_count' => 'Mensajes entrantes',
    'outgoing_messages_count' => 'Mensajes salientes',
    'avg_first_response_time' => '1ª respuesta',
    'avg_resolution_time' => 'Tiempo de resolución',
    'resolutions_count' => 'Resoluciones',
    'reply_time' => 'Tiempo de espera',
    'contacts_count' => 'Contactos creados',
    'unique_contacts_count' => 'Contactos únicos atendidos'
  }.freeze

  PRESET_LABELS = {
    'today' => 'Hoy',
    'yesterday' => 'Ayer',
    'last_7_days' => 'Últimos 7 días',
    'last_30_days' => 'Últimos 30 días',
    'custom' => 'Rango personalizado'
  }.freeze

  STATUS_LABELS = {
    'open' => 'Abierta',
    'resolved' => 'Resuelta',
    'pending' => 'Pendiente',
    'snoozed' => 'Pospuesta'
  }.freeze

  PRIORITY_LABELS = {
    'low' => 'Baja',
    'medium' => 'Media',
    'high' => 'Alta',
    'urgent' => 'Urgente'
  }.freeze

  def initialize(run_result)
    @result = run_result.with_indifferent_access
  end

  def to_xlsx
    package = Axlsx::Package.new
    workbook = package.workbook

    add_summary_sheet(workbook)

    Array(@result[:widgets]).each_with_index do |widget, index|
      widget = widget.with_indifferent_access
      add_widget_sheet(workbook, widget, index)
    end

    package.to_stream.read
  end

  private

  def add_summary_sheet(workbook)
    workbook.add_worksheet(name: sanitize_sheet_name('Resumen')) do |sheet|
      sheet.add_row %w[Campo Valor]
      sheet.add_row ['Panel', @result[:name].to_s]
      sheet.add_row ['Descripción', @result[:description].to_s]
      sheet.add_row ['Rango', PRESET_LABELS[@result[:date_preset].to_s] || @result[:date_preset].to_s]
      sheet.add_row ['Desde', format_unix_date(@result[:since])]
      sheet.add_row ['Hasta', format_unix_date(@result[:until])]
      sheet.add_row [
        'Horario laboral',
        ActiveModel::Type::Boolean.new.cast(@result[:business_hours]) ? 'Sí' : 'No'
      ]
    end
  end

  def add_widget_sheet(workbook, widget, index)
    title = widget[:title].presence || widget[:metric].presence || widget[:table_kind].presence || "Widget #{index + 1}"
    sheet_name = sanitize_sheet_name("#{index + 1}. #{title}")

    workbook.add_worksheet(name: sheet_name) do |sheet|
      case widget[:type].to_s
      when 'metric'
        sheet.add_row %w[Métrica Valor]
        sheet.add_row [
          METRIC_LABELS[widget[:metric].to_s] || widget[:metric].to_s,
          format_cell(widget[:metric], widget[:value])
        ]
      when 'chart'
        sheet.add_row %w[Fecha Valor]
        Array(widget[:points]).each do |point|
          point = point.with_indifferent_access
          sheet.add_row [format_unix_date(point[:timestamp]), point[:value]]
        end
      when 'table'
        rows = Array(widget[:rows])
        if rows.blank?
          sheet.add_row ['Sin datos para este periodo']
        else
          keys = rows.first.with_indifferent_access.keys.map(&:to_s)
          sheet.add_row(keys.map { |key| header_label_for(key) })
          rows.each do |row|
            row = row.with_indifferent_access
            sheet.add_row(keys.map { |key| format_cell(key, row[key]) })
          end
          totals = widget[:totals]
          if totals.present?
            totals = totals.with_indifferent_access
            column_sums = (totals[:columns] || {}).with_indifferent_access
            column_ops = (totals[:ops] || {}).with_indifferent_access
            sheet.add_row(
              keys.map.with_index do |key, index|
                if index.zero?
                  "Total (#{totals[:count]})"
                elsif column_sums.key?(key)
                  op = column_ops[key]
                  label = op.present? ? "#{op.to_s.upcase}: " : ''
                  "#{label}#{format_cell(key, column_sums[key])}"
                else
                  ''
                end
              end
            )
          end
        end
      else
        sheet.add_row ['Tipo de widget no soportado', widget[:type].to_s]
      end
    end
  end

  def header_label_for(key)
    key = key.to_s
    return HEADER_LABELS[key] if HEADER_LABELS.key?(key)

    if key.start_with?('ca:', 'contact_ca:') || key.include?('__pv__')
      if key.include?('__pv__')
        measure, encoded = key.split('__pv__', 2)
        segment = encoded == '__blank__' ? '(blank)' : begin
          URI.decode_www_form_component(encoded.to_s)
        rescue ArgumentError
          encoded.to_s
        end
        return "#{segment} · #{header_label_for(measure)}"
      end
      rest = key.delete_prefix('contact_ca:').delete_prefix('ca:')
      op = nil
      filter_value = nil
      filtered = rest.match(/\A(.+)__(count|sum|avg|min|max)__eq__(.+)\z/)
      if filtered
        rest = filtered[1]
        op = filtered[2]
        filter_value = begin
          URI.decode_www_form_component(filtered[3])
        rescue ArgumentError
          filtered[3]
        end
      else
        %w[count sum avg min max].each do |candidate|
          suffix = "__#{candidate}"
          next unless rest.end_with?(suffix) && rest.length > suffix.length

          op = candidate
          rest = rest.delete_suffix(suffix)
          break
        end
      end
      label = rest.humanize
      return "#{op.capitalize}(#{label} = #{filter_value})" if op.present? && filter_value.present?
      return op.present? ? "#{op.capitalize}(#{label})" : label
    end

    key.humanize
  end

  def format_cell(key, value)
    return '' if value.nil?

    key = key.to_s
    return Reports::TimeFormatPresenter.new(value).format if TIME_COLUMNS.include?(key)
    return "#{value}%" if key == 'share_percent'
    return STATUS_LABELS[value.to_s] || value.to_s if key == 'status'
    return PRIORITY_LABELS[value.to_s] || value.to_s if key == 'priority'
    return Array(value).join(', ') if key == 'labels'
    return format_unix_datetime(value) if %w[created_at last_activity_at].include?(key) && numeric_unix?(value)
    return format_iso_datetime(value) if (key.start_with?('ca:') || key.start_with?('contact_ca:')) && looks_like_iso_datetime?(value)

    value
  end

  def format_iso_datetime(value)
    text = value.to_s
    return text unless text.match?(/\A\d{4}-\d{2}-\d{2}/)

    parsed = Time.zone.parse(text)
    return text if parsed.blank?

    parsed.strftime('%d/%m/%Y %H:%M')
  rescue ArgumentError, TypeError
    value.to_s
  end

  def looks_like_iso_datetime?(value)
    value.to_s.match?(/\A\d{4}-\d{2}-\d{2}T/)
  end

  def format_unix_date(value)
    return '' if value.blank?
    return value.to_s unless numeric_unix?(value)

    Time.zone.at(value.to_i).strftime('%d/%m/%Y')
  end

  def format_unix_datetime(value)
    return '' if value.blank?
    return value.to_s unless numeric_unix?(value)

    Time.zone.at(value.to_i).strftime('%d/%m/%Y %H:%M')
  end

  def numeric_unix?(value)
    value.to_s.match?(/\A\d+\z/)
  end

  def sanitize_sheet_name(name)
    cleaned = name.to_s.gsub(%r{[\\/*?:\[\]]}, ' ').squish
    cleaned = cleaned.presence || 'Hoja'
    cleaned[0, 31]
  end
end
