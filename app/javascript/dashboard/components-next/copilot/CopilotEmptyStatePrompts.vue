<script setup>
import { computed } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useConfig } from 'dashboard/composables/useConfig';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useCopilotPrompts } from 'dashboard/composables/useCopilotPrompts';
import {
  useCopilotDot,
  COPILOT_OPEN_SOURCES,
} from 'dashboard/composables/useCopilotDot';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import CopilotPromptPills from './CopilotPromptPills.vue';

const { isEnterprise } = useConfig();
const { uiSettings } = useUISettings();
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const assistants = useMapGetter('captainAssistants/getRecords');

const isFeatureEnabled = feature =>
  isFeatureEnabledonAccount.value(currentAccountId.value, feature);

// Copilot needs Captain and an assistant to answer. The prompts here are the workflows ones, so the older Copilot
// keeps this screen as it was. They float above the launcher, so they leave with it when the panel opens.
const showPrompts = computed(
  () =>
    isEnterprise &&
    !uiSettings.value.is_copilot_panel_open &&
    isFeatureEnabled(FEATURE_FLAGS.CAPTAIN) &&
    isFeatureEnabled(FEATURE_FLAGS.COPILOT_WORKFLOWS) &&
    assistants.value.length > 0
);

const { prompts, selectPrompt } = useCopilotPrompts({
  isWorkflowsEnabled: true,
  canSuggestReply: false,
});
const { openCopilot } = useCopilotDot();

const askCopilot = key => {
  const message = selectPrompt(key);
  openCopilot(COPILOT_OPEN_SOURCES.EMPTY_STATE);
  emitter.emit(BUS_EVENTS.ASK_COPILOT, message);
};
</script>

<template>
  <CopilotPromptPills
    v-if="showPrompts"
    :prompts="prompts"
    class="fixed bottom-20 end-4 z-50 flex-col items-end [&>button]:shadow-sm"
    @select="askCopilot"
  />
  <template v-else />
</template>
