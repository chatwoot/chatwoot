module Regexp::Expression
  module Shared
    # default implementation, e.g. "atomic group", "hex escape", "word type", ..
    def human_name
      [token, type].compact.join(' ').tr('_', ' ')
    end
  end

  Alternation.class_eval                       { def human_name; 'alternation'                 end }
  Alternative.class_eval                       { def human_name; 'alternative'                 end }
  Anchor::BOL.class_eval                       { def human_name; 'beginning of line'           end }
  Anchor::BOS.class_eval                       { def human_name; 'beginning of string'         end }
  Anchor::EOL.class_eval                       { def human_name; 'end of line'                 end }
  Anchor::EOS.class_eval                       { def human_name; 'end of string'               end }
  Anchor::EOSobEOL.class_eval                  { def human_name; 'newline-ready end of string' end }
  Anchor::MatchStart.class_eval                { def human_name; 'match start'                 end }
  Anchor::NonWordBoundary.class_eval           { def human_name; 'no word boundary'            end }
  Anchor::WordBoundary.class_eval              { def human_name; 'word boundary'               end }
  Assertion::Lookahead.class_eval              { def human_name; 'lookahead'                   end }
  Assertion::Lookbehind.class_eval             { def human_name; 'lookbehind'                  end }
  Assertion::NegativeLookahead.class_eval      { def human_name; 'negative lookahead'          end }
  Assertion::NegativeLookbehind.class_eval     { def human_name; 'negative lookbehind'         end }
  Backreference::Name.class_eval               { def human_name; 'backreference by name'       end }
  Backreference::NameCall.class_eval           { def human_name; 'subexpression call by name'  end }
  Backreference::Number.class_eval             { def human_name; 'backreference'               end }
  Backreference::NumberRelative.class_eval     { def human_name; 'relative backreference'      end }
  Backreference::NumberCall.class_eval         { def human_name; 'subexpression call'          end }
  Backreference::NumberCallRelative.class_eval { def human_name; 'relative subexpression call' end }
  CharacterSet::IntersectedSequence.class_eval { def human_name; 'intersected sequence'        end }
  CharacterSet::Intersection.class_eval        { def human_name; 'intersection'                end }
  CharacterSet::Range.class_eval               { def human_name; 'character range'             end }
  CharacterType::Any.class_eval                { def human_name; 'match-all'                   end }
  Comment.class_eval                           { def human_name; 'comment'                     end }
  Conditional::Branch.class_eval               { def human_name; 'conditional branch'          end }
  Conditional::Condition.class_eval            { def human_name; 'condition'                   end }
  Conditional::Expression.class_eval           { def human_name; 'conditional'                 end }
  Group::Capture.class_eval                    { def human_name; "capture group #{number}"     end }
  Group::Named.class_eval                      { def human_name; 'named capture group'         end }
  Keep::Mark.class_eval                        { def human_name; 'keep-mark lookbehind'        end }
  Literal.class_eval                           { def human_name; 'literal'                     end }
  Root.class_eval                              { def human_name; 'root'                        end }
  WhiteSpace.class_eval                        { def human_name; 'free space'                  end }
end
