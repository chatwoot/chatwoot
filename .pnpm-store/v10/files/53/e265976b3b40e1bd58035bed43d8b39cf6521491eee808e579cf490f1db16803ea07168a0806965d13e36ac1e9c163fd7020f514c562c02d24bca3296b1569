import { inputRules } from 'prosemirror-inputrules';
import { safeInsert } from 'prosemirror-utils';
import { createInputRule } from '../utils';

function createHorizontalRuleInputRule(type) {
  return createInputRule(
    /^(?:---|___|\*\*\*)\s$/, // Ensures rule is triggered with space after "---", "___", or "***"
    (state, match, start, end) => {
      if (!match[0]) {
        return null; // If no match found, return null
      }

      // Deletes the matched sequence including the space
      let tr = state.tr.delete(start, end);
      const hrPos = start; // Position where the horizontal rule should be inserted

      // Insert the horizontal rule at the position
      tr = safeInsert(type.create(), hrPos)(tr);

      // Insert a paragraph node after the horizontal rule
      tr = safeInsert(state.schema.nodes.paragraph.create(), tr.mapping.map(hrPos + 1))(tr);

      return tr;
    }
  );
}

export function hrInputRules(schema) {
  if (!schema.nodes.horizontal_rule) {
    // Ensures that horizontal_rule is part of the schema
    return inputRules({
      rules: [],
    });
  }

  const hrRule = createHorizontalRuleInputRule(schema.nodes.horizontal_rule);

  return inputRules({
    rules: [hrRule],
  });
}

export default hrInputRules;
