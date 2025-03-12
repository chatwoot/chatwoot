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

<template>
  <div
    class="macro-preview absolute border border-n-weak max-h-[22.5rem] z-50 w-64 rounded-md bg-n-alpha-3 backdrop-blur-[100px] shadow-lg bottom-8 right-8 overflow-y-auto p-4 text-left rtl:text-right"
  >
    <h6 class="mb-4 text-sm text-n-slate-12">
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
        class="absolute -left-[0.21875rem] top-[0.2734375rem] w-2 h-2 rounded-full bg-n-solid-1 border-2 border-solid border-n-weak dark:border-slate-600"
      />
      <p class="mb-1 text-xs text-n-slate-11">
        {{ action.actionName }}
      </p>
      <p class="text-n-slate-12 text-sm">{{ action.actionValue }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.macro-preview {
  .macro-block {
    &:not(:last-child) {
      @apply pb-2;
    }
  }
}
</style>
