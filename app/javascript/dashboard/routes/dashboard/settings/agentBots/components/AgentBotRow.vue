<template>
  <tr>
    <td class="agent-bot--details">
      <div class="agent-bot--link">
        {{ agentBot.name }}
        (<agent-bot-type :bot-type="agentBot.bot_type" />)
      </div>
      <div class="agent-bot--description">
        <show-more :text="agentBot.description" :limit="120" />
      </div>
    </td>
    <td class="button-wrapper">
      <woot-button
        v-if="isACSMLTypeBot"
        v-tooltip.top="$t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
        variant="smooth"
        size="tiny"
        color-scheme="secondary"
        icon="edit"
        @click="$emit('edit', agentBot)"
      />
      <woot-button
        v-tooltip.top="$t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
        variant="smooth"
        color-scheme="alert"
        size="tiny"
        icon="dismiss-circle"
        @click="$emit('delete', agentBot, index)"
      />
    </td>
  </tr>
</template>
<script>
import ShowMore from 'dashboard/components/widgets/ShowMore';
import AgentBotType from './AgentBotType.vue';

export default {
  components: { ShowMore, AgentBotType },
  props: {
    agentBot: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    isACSMLTypeBot() {
      const { bot_type: botType } = this.agentBot;
      return botType === 'csml';
    },
  },
};
</script>
<style scoped lang="scss">
.agent-bot--link {
  align-items: center;
  color: var(--s-800);
  display: flex;
  font-weight: var(--font-weight-medium);
  word-break: break-word;
}

.agent-bot--description {
  color: var(--s-700);
  font-size: var(--font-size-mini);
}

.agent-bot--type {
  color: var(--s-600);
  font-weight: var(--font-weight-medium);
  margin-bottom: var(--space-small);
}

.agent-bot--details {
  width: 90%;
}

.button-wrapper {
  max-width: var(--space-mega);
  min-width: auto;

  button:nth-child(2) {
    margin-left: var(--space-normal);
  }
}
</style>
