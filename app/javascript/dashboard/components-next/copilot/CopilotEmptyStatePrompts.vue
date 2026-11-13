<script setup>
import { computed } from 'vue';
import { useWindowSize } from '@vueuse/core';
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
import Button from '../button/Button.vue';
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

// The stack floats above the launcher while the empty-screen text stays centered, so a shorter window leaves less room
// between them. These heights fit that many two-line prompts without reaching the text, and the panel lists the rest.
const HEIGHT_FOR_THREE_PROMPTS = 820;
const HEIGHT_FOR_TWO_PROMPTS = 700;
const { height: windowHeight } = useWindowSize();
const floatingCount = computed(() => {
  if (windowHeight.value >= HEIGHT_FOR_THREE_PROMPTS) return 3;
  if (windowHeight.value >= HEIGHT_FOR_TWO_PROMPTS) return 2;
  return 1;
});
const floatingPrompts = computed(() =>
  prompts.value.slice(0, floatingCount.value)
);
const hasMorePrompts = computed(
  () => prompts.value.length > floatingPrompts.value.length
);

const askCopilot = key => {
  const message = selectPrompt(key);
  openCopilot(COPILOT_OPEN_SOURCES.EMPTY_STATE);
  emitter.emit(BUS_EVENTS.ASK_COPILOT, message);
};
</script>

<template>
  <div
    v-if="showPrompts"
    class="fixed bottom-20 end-4 z-50 flex flex-col items-end gap-1 max-w-xs"
  >
    <CopilotPromptPills
      :prompts="floatingPrompts"
      class="justify-end [&>button]:shadow-sm"
      @select="askCopilot"
    />
    <Button
      v-if="hasMorePrompts"
      :label="$t('CAPTAIN.COPILOT.MORE_PROMPTS')"
      link
      slate
      sm
      @click="openCopilot(COPILOT_OPEN_SOURCES.EMPTY_STATE_MORE)"
    />
  </div>
  <template v-else />
</template>
