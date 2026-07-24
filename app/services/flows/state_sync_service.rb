class Flows::StateSyncService
  ATTR_ESTADO = 'panel_ia_estado'
  ATTR_LABEL = 'panel_ia_estado_label'
  ATTR_UPDATED = 'panel_ia_updated_at'

  STATE_MAP = {
    'running' => 'activo',
    'waiting' => 'esperando',
    'handed_off' => 'solicita_ayuda',
    'failed' => 'solicita_ayuda'
  }.freeze

  def initialize(run:)
    @run = run
    @conversation = run.conversation
  end

  def perform
    attrs = (@conversation.custom_attributes || {}).dup
    mapped = STATE_MAP[@run.state]

    if mapped.present?
      attrs[ATTR_ESTADO] = mapped
      attrs[ATTR_LABEL] = label_for(mapped)
      attrs[ATTR_UPDATED] = Time.current.iso8601
    else
      attrs.delete(ATTR_ESTADO)
      attrs.delete(ATTR_LABEL)
      attrs.delete(ATTR_UPDATED)
    end

    @conversation.update!(custom_attributes: attrs)
  end

  private

  def label_for(estado)
    case estado
    when 'activo' then "Flow: #{@run.flow.name}"
    when 'esperando' then "Flow waiting: #{@run.flow.name}"
    when 'solicita_ayuda' then "Flow handoff: #{@run.flow.name}"
    else nil
    end
  end
end
