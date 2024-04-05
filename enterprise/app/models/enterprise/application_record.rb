module Enterprise::ApplicationRecord
  def droppables
    super + %w[SlaPolicy]
  end
end
