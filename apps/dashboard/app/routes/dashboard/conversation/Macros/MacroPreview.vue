<template>
  <div
    class="macro-preview absolute max-h-[22.5rem] w-64 rounded-md bg-white dark:bg-slate-800 shadow-lg bottom-8 right-8 overflow-y-auto p-4 text-left rtl:text-right"
  >
    <h6 class="text-sm text-slate-800 dark:text-slate-100 mb-4">
      {{ macro.name }}
    </h6>
    <div
      v-for="(action, i) in resolvedMacro"
      :key="i"
      class="relative pl-4 macro-block"
    >
      <div
        v-if="i !== macro.actions.length - 1"
        class="top-[0.390625rem] absolute -bottom-1 left-0 w-px bg-slate-75 dark:bg-slate-600"
      />
      <div
        class="absolute -left-[0.21875rem] top-[0.2734375rem] w-2 h-2 rounded-full bg-white dark:bg-slate-200 border-2 border-solid border-slate-100 dark:border-slate-600"
      />
      <p class="text-xs text-slate-500 dark:text-slate-400 mb-1">
        {{ action.actionName }}
      </p>
      <p class="text-slate-800 dark:text-slate-100">{{ action.actionValue }}</p>
    </div>
  </div>
</template>

<script>
import {
  resolveActionName,
  resolveTeamIds,
  resolveLabels,
  resolveAgents,
} from 'dashboard/routes/dashboard/settings/macros/macroHelper';
import { mapGetters } from 'vuex';

export default {
  props: {
    macro: {
      type: Object,
      required: true,
    },
  },
  computed: {
    resolvedMacro() {
      return this.macro.actions.map(action => {
        return {
          actionName: resolveActionName(action.action_name),
          actionValue: this.getActionValue(
            action.action_name,
            action.action_params
          ),
        };
      });
    },
    ...mapGetters({
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
      agents: 'agents/getAgents',
    }),
  },
  methods: {
    getActionValue(key, params) {
      const actionsMap = {
        assign_team: resolveTeamIds(this.teams, params),
        add_label: resolveLabels(this.labels, params),
        remove_label: resolveLabels(this.labels, params),
        assign_agent: resolveAgents(this.agents, params),
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
    },
  },
};
</script>

<style lang="scss" scoped>
.macro-preview {
  .macro-block {
    &:not(:last-child) {
      @apply pb-2;
    }
  }
}
</style>
