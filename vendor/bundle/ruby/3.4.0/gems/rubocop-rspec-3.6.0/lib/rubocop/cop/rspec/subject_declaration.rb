# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Ensure that subject is defined using subject helper.
      #
      # @example
      #   # bad
      #   let(:subject) { foo }
      #   let!(:subject) { foo }
      #   subject(:subject) { foo }
      #   subject!(:subject) { foo }
      #
      #   # bad
      #   block = -> {}
      #   let(:subject, &block)
      #
      #   # good
      #   subject(:test_subject) { foo }
      #
      class SubjectDeclaration < Base
        MSG_LET = 'Use subject explicitly rather than using let'
        MSG_REDUNDANT = 'Ambiguous declaration of subject'

        # @!method offensive_subject_declaration?(node)
        def_node_matcher :offensive_subject_declaration?, <<~PATTERN
          (send nil? ${#Subjects.all #Helpers.all} ({sym str} #Subjects.all) ...)
        PATTERN

        def on_send(node)
          offense = offensive_subject_declaration?(node)
          return unless offense

          add_offense(node, message: message_for(offense))
        end

        private

        def message_for(offense)
          Helpers.all(offense) ? MSG_LET : MSG_REDUNDANT
        end
      end
    end
  end
end
