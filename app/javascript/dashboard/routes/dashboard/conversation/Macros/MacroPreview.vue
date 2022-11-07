<template>
  <div class="macro-preview">
    <p class="macro-title">{{ macro.name }}</p>
    <div v-for="(action, i) in resolvedMacro" :key="i" class="macro-block">
      <div v-if="i !== macro.actions.length - 1" class="macro-block-border" />
      <div class="macro-block-dot" />
      <p class="macro-action-name">{{ action.actionName }}</p>
      <p class="macro-action-params">{{ action.actionValue }}</p>
    </div>
  </div>
</template>

<script>
import {
  resolveActionName,
  resolveTeamIds,
  resolveLabels,
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
    }),
  },
  methods: {
    getActionValue(key, params) {
      const actionsMap = {
        assign_team: resolveTeamIds(this.teams, params),
        add_label: resolveLabels(this.labels, params),
        mute_conversation: null,
        snooze_conversation: null,
        resolve_conversation: null,
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
  position: absolute;
  max-height: calc(var(--space-giga) * 1.5);
  min-height: var(--space-jumbo);
  width: calc(var(--space-giga) + var(--space-large));
  border-radius: var(--border-radius-normal);
  background-color: var(--white);
  box-shadow: var(--shadow-dropdown-pane);
  bottom: calc(var(--space-three) + var(--space-half));
  right: calc(var(--space-three) + var(--space-half));
  overflow-y: auto;
  padding: var(--space-slab);

  .macro-title {
    margin-bottom: var(--space-slab);
    color: var(--s-900);
    font-weight: var(--font-weight-bold);
  }

  .macro-block {
    position: relative;
    padding-left: var(--space-slab);
    &:not(:last-child) {
      padding-bottom: var(--space-slab);
    }

    .macro-block-border {
      top: 0.625rem;
      position: absolute;
      bottom: var(--space-minus-half);
      left: 0;
      width: 1px;
      background-color: var(--s-100);
    }

    .macro-block-dot {
      position: absolute;
      left: -0.35rem;
      height: var(--space-small);
      width: var(--space-small);
      border: 2px solid var(--s-100);
      background-color: var(--white);
      border-radius: var(--border-radius-full);
      top: 0.4375rem;
    }
  }

  .macro-action-name {
    font-size: var(--font-size-mini);
    color: var(--s-500);
  }
}
</style>
