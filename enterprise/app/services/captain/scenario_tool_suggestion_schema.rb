class Captain::ScenarioToolSuggestionSchema < Schematist::Schema
  array :suggestions,
        description: 'Actions in the instruction that an available tool performs but the instruction does not reference. ' \
                     'Empty when none are missing.',
        max_items: 10 do
    object do
      string :phrase,
             description: 'The shortest span copied verbatim from the instruction that names the action, such as "add a private note".',
             max_length: 200
      string :tool_id, description: 'The id of the available tool that performs the action.'
    end
  end
end
