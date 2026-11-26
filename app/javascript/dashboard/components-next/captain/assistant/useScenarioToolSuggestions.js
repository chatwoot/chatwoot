import { ref } from 'vue';
import { useRoute } from 'vue-router';
import CaptainScenarios from 'dashboard/api/captain/scenarios';

// A scenario agent only gets the tools its instruction links, so a plain "add a private note" never runs.
// Before saving, the model finds such phrases; the form links them and lets the admin keep or remove each one.
const TOOL_LINK_REGEX = /(\[[^\]]+\]\(tool:\/\/[^)]+\))/;

const escapeRegExp = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const applyToolSuggestion = (instruction, { phrase, replacement }) => {
  const segments = instruction.split(TOOL_LINK_REGEX);
  // split with a capture group puts the existing tool links at odd indexes
  const index = segments.findIndex(
    (segment, position) => position % 2 === 0 && segment.includes(phrase)
  );
  if (index === -1) return instruction;

  segments[index] = segments[index].replace(phrase, replacement);
  return segments.join('');
};

export const revertToolSuggestion = (instruction, { phrase, toolId }) => {
  const linkedPhrase = new RegExp(
    `${escapeRegExp(phrase)} \\[[^\\]]*\\]\\(tool://${escapeRegExp(toolId)}\\)`
  );
  return instruction.replace(linkedPhrase, phrase);
};

export function useScenarioToolSuggestions(instruction) {
  const route = useRoute();
  const suggestions = ref([]);
  const isChecking = ref(false);
  let reviewedInstruction = null;

  // Returns true when the form should stay open: tools were linked for review, or the admin edited the
  // instruction while the check ran. A failed check never blocks saving.
  const linkMissingTools = async () => {
    if (instruction.value === reviewedInstruction) return false;

    const checkedInstruction = instruction.value;
    isChecking.value = true;
    try {
      const { data } = await CaptainScenarios.suggestTools({
        assistantId: route.params.assistantId,
        instruction: checkedInstruction,
      });
      // The editor stays editable during the check. Linking the old text would erase what the admin typed,
      // so drop this result and check the new text on the next save.
      if (instruction.value !== checkedInstruction) return true;

      const linked = [];
      let linkedInstruction = checkedInstruction;
      data.suggestions.forEach(suggestion => {
        const nextInstruction = applyToolSuggestion(
          linkedInstruction,
          suggestion
        );
        if (nextInstruction === linkedInstruction) return;

        linkedInstruction = nextInstruction;
        linked.push({
          toolId: suggestion.tool_id,
          toolTitle: suggestion.tool_title,
          phrase: suggestion.phrase,
        });
      });

      instruction.value = linkedInstruction;
      reviewedInstruction = linkedInstruction;
      suggestions.value = linked;
      return linked.length > 0;
    } catch {
      return false;
    } finally {
      isChecking.value = false;
    }
  };

  const keepSuggestion = toolId => {
    suggestions.value = suggestions.value.filter(
      suggestion => suggestion.toolId !== toolId
    );
  };

  const removeSuggestion = toolId => {
    const suggestion = suggestions.value.find(item => item.toolId === toolId);
    instruction.value = revertToolSuggestion(instruction.value, suggestion);
    reviewedInstruction = instruction.value;
    keepSuggestion(toolId);
  };

  const keepAllSuggestions = () => {
    suggestions.value = [];
  };

  const resetSuggestions = () => {
    suggestions.value = [];
    reviewedInstruction = null;
  };

  return {
    suggestions,
    isChecking,
    linkMissingTools,
    keepSuggestion,
    keepAllSuggestions,
    removeSuggestion,
    resetSuggestions,
  };
}
