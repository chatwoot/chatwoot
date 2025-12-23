require "foreman/vendor/thor/lib/thor/line_editor/basic"
require "foreman/vendor/thor/lib/thor/line_editor/readline"

class Foreman::Thor
  module LineEditor
    def self.readline(prompt, options = {})
      best_available.new(prompt, options).readline
    end

    def self.best_available
      [
        Foreman::Thor::LineEditor::Readline,
        Foreman::Thor::LineEditor::Basic
      ].detect(&:available?)
    end
  end
end
