module Captain::Apropos::QueryRequestBudget
  MAX_COMPLETIONS = 4

  def complete(&)
    @wootql_completions = (@wootql_completions || 0) + 1
    raise Captain::Apropos::Error, 'WootQL specialist exhausted its 4 generation attempts' if @wootql_completions > MAX_COMPLETIONS

    super
  end
end
