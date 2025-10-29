module Enterprise::Captain::PromptRenderer
  private

  def candidate_paths(template_name)
    [
      Rails.root.join('enterprise', 'lib', 'captain', 'prompts', "#{template_name}.liquid")
    ] + super
  end
end
