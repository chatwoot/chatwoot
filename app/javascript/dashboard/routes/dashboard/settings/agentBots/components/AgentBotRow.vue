<script>
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';
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
  emits: ['edit', 'delete'],
  computed: {
    isACSMLTypeBot() {
      const { bot_type: botType } = this.agentBot;
      return botType === 'csml';
    },
  },
};
</script>

<template>
  <tr class="space-x-2">
    <td class="agent-bot--details">
      <div class="agent-bot--link">
        {{ agentBot.name }}
        (<AgentBotType :bot-type="agentBot.bot_type" />)
      </div>
      <div class="agent-bot--description">
        <ShowMore :text="agentBot.description || ''" :limit="120" />
      </div>
    </td>
    <td class="flex justify-end gap-1">
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

<style scoped lang="scss">
.agent-bot--link {
  align-items: center;
  display: flex;
  font-weight: var(--font-weight-medium);
  word-break: break-word;
}

.agent-bot--description {
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
</style>
