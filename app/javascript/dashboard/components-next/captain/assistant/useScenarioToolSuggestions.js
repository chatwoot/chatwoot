import { ref } from 'vue';
import { useRoute } from 'vue-router';
import CaptainScenarios from 'dashboard/api/captain/scenarios';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';

// A scenario agent only gets the tools its instruction links, so a plain "add a private note" never runs.
// Before saving, the model finds such phrases; the form links them and lets the admin keep or remove each one.
const TOOL_LINK_REGEX = /(\[[^\]]+\]\(tool:\/\/[^)]+\))/;

const escapeRegExp = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const CHECK_CANCELLED = Symbol('checkCancelled');

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

// Removes the tool's link wherever it now sits, so it still works after the admin rewords the phrase before it.
// The backend never suggests a tool the instruction already links, so this link is the one the check added.
export const revertToolSuggestion = (instruction, toolId) => {
  const toolLink = new RegExp(
    ` ?\\[[^\\]]*\\]\\(tool://${escapeRegExp(toolId)}\\)`,
    'g'
  );
  return instruction.replace(toolLink, '');
};

export function useScenarioToolSuggestions(instruction) {
  const route = useRoute();
  const suggestions = ref([]);
  const { run, abort, isPending: isChecking } = useAbortableRequest();
  let reviewedInstruction = null;

  // Returns true when the form must not save: tools were linked for review, the admin edited the instruction
  // while the check ran, or the admin cancelled. A failed check never blocks saving.
  const linkMissingTools = async () => {
    if (instruction.value === reviewedInstruction) return false;

    const checkedInstruction = instruction.value;
    try {
      const response = await run(
        signal =>
          CaptainScenarios.suggestTools({
            assistantId: route.params.assistantId,
            instruction: checkedInstruction,
            signal,
          }),
        { onAbort: CHECK_CANCELLED }
      );
      if (response === CHECK_CANCELLED) return true;

      // The editor stays editable during the check. Linking the old text would erase what the admin typed,
      // so drop this result and check the new text on the next save.
      if (instruction.value !== checkedInstruction) return true;

      const linked = [];
      let linkedInstruction = checkedInstruction;
      response.data.suggestions.forEach(suggestion => {
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
    }
  };

  const keepSuggestion = toolId => {
    suggestions.value = suggestions.value.filter(
      suggestion => suggestion.toolId !== toolId
    );
  };

  const removeSuggestion = toolId => {
    instruction.value = revertToolSuggestion(instruction.value, toolId);
    reviewedInstruction = instruction.value;
    keepSuggestion(toolId);
  };

  const keepAllSuggestions = () => {
    suggestions.value = [];
  };

  // Also cancels a pending check, so a form the admin closed never saves when the check returns.
  const resetSuggestions = () => {
    abort();
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
