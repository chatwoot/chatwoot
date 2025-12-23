# frozen_string_literal: true

module RuboCop
  module AST
    # A parser builder, based on the one provided by prism,
    # which is capable of emitting AST for more recent Rubies.
    class BuilderPrism < Prism::Translation::Parser::Builder
      include BuilderExtensions
    end
  end
end
