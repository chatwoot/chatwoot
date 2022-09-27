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
import { AUTOMATION_ACTION_TYPES } from 'dashboard/routes/dashboard/settings/automation/constants';

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
          actionName: this.getActionName(action.action_name),
          actionValue: this.getActionValue(
            action.action_name,
            action.action_params
          ),
        };
      });
    },
  },
  methods: {
    getActionName(key) {
      return AUTOMATION_ACTION_TYPES.find(i => i.key === key).label;
    },
    resolveTeamIds(ids) {
      const allTeams = this.$store.getters['teams/getTeams'];
      return ids
        .map(id => {
          const team = allTeams.find(i => i.id === id);
          return team ? team.name : '';
        })
        .join(', ');
    },
    resolveLabels(ids) {
      const allLabels = this.$store.getters['labels/getLabels'];
      return ids
        .map(id => {
          const label = allLabels.find(i => i.title === id);
          return label ? label.title : '';
        })
        .join(', ');
    },
    resolveSendEmailToTeam(obj) {
      return ` ${obj.message} - 
      ${this.resolveTeamIds(obj.team_ids)}`;
    },
    getActionValue(key, params) {
      switch (key) {
        case 'assign_team':
          return this.resolveTeamIds(params);
        case 'add_label':
          return this.resolveLabels(params);
        case 'send_email_to_team':
          return this.resolveSendEmailToTeam(params[0]);
        case 'send_email_transcript':
          return this.resolveSendEmailToTeam(params[0]);
        case 'mute_conversation':
        case 'snooze_conversation':
        case 'resolve_conversation':
          return null;
        case 'send_webhook_event':
        case 'send_message':
          return params[0];
        default:
          return '';
      }
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
