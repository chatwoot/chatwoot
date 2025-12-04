<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import {
  resolveActionName,
  resolveTeamIds,
  resolveLabels,
  resolveAgents,
} from 'dashboard/routes/dashboard/settings/macros/macroHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
});

const labels = useMapGetter('labels/getLabels');
const teams = useMapGetter('teams/getTeams');
const agents = useMapGetter('agents/getAgents');

const getActionValue = (key, params) => {
  const actionsMap = {
    assign_team: resolveTeamIds(teams.value, params),
    add_label: resolveLabels(labels.value, params),
    remove_label: resolveLabels(labels.value, params),
    assign_agent: resolveAgents(agents.value, params),
    mute_conversation: null,
    snooze_conversation: null,
    resolve_conversation: null,
    remove_assigned_team: null,
    send_webhook_event: params[0],
    send_message: params[0],
    send_email_transcript: params[0],
    add_private_note: params[0],
  };
  return actionsMap[key] || '';
};

const resolvedMacro = computed(() => {
  return props.macro.actions.map(action => ({
    actionName: resolveActionName(action.action_name),
    actionValue: getActionValue(action.action_name, action.action_params),
  }));
});
</script>

<template>
  <div
    class="macro-preview absolute w-72 outline outline-n-weak max-h-72 z-50 rounded-xl bg-n-alpha-3 backdrop-blur-[50px] shadow-lg overflow-y-auto px-3 py-2"
  >
    <div class="flex items-center gap-3 h-9">
      <Icon icon="i-lucide-zap" class="text-n-slate-11 size-4 text-base" />
      <span class="text-sm font-medium text-n-slate-12">
        {{ macro.name }}
      </span>
    </div>

    <div
      v-for="(action, i) in resolvedMacro"
      :key="i"
      class="relative ltr:pl-7 rtl:pr-7 py-3 after:content-[''] after:absolute ltr:after:left-1.5 rtl:after:right-1.5 after:w-px after:bg-n-weak"
      :class="{
        'after:top-1 after:h-3.5': resolvedMacro.length === 1,
        'after:top-2 after:-bottom-5':
          resolvedMacro.length > 1 && i !== resolvedMacro.length - 1,
      }"
    >
      <div
        class="absolute ltr:left-[2.5px] rtl:right-[2.5px] top-[18px] w-2 h-2 rounded-full bg-n-surface-1 border-2 border-n-weak z-10"
      />

      <p class="mb-1 text-sm font-medium text-n-slate-11">
        {{ $t(`MACROS.ACTIONS.${action.actionName}`) }}
      </p>

      <p class="text-n-slate-12 text-sm font-420">{{ action.actionValue }}</p>
    </div>
  </div>
</template>
