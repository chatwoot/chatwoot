<script setup>
import { computed, ref, watch } from 'vue';
import InboxesAPI from 'dashboard/api/inboxes';
import NextButton from 'dashboard/components-next/button/Button.vue';
import {
  agentsConsoleBase,
  agentsConversationUrl,
  parseAgentsWebhook,
  routeTokenHash,
} from 'dashboard/helper/agentsConversationLink';

const props = defineProps({
  conversation: {
    type: Object,
    default: null,
  },
});

const target = ref(null);

watch(
  () => props.conversation?.inbox_id,
  async inboxId => {
    target.value = null;
    if (!inboxId) return;
    const { data } = await InboxesAPI.getAgentBot(inboxId);
    const agentBot = data?.agent_bot;
    const webhook = parseAgentsWebhook(agentBot?.outgoing_url);
    const botHash = webhook ? await routeTokenHash(webhook.routeToken) : null;
    // A reply for an inbox the panel has already left must not light the button up on the next one.
    if (props.conversation?.inbox_id !== inboxId || !webhook) return;
    target.value = {
      base: agentsConsoleBase(agentBot.bot_config?.console_url, webhook.base),
      botHash,
    };
  },
  { immediate: true }
);

const href = computed(() =>
  props.conversation && target.value
    ? agentsConversationUrl(target.value.base, target.value.botHash, {
        accountId: props.conversation.account_id,
        conversationId: props.conversation.id,
        inboxId: props.conversation.inbox_id,
      })
    : null
);

const open = () => window.open(href.value, '_blank', 'noopener');
</script>

<template>
  <div class="contents">
    <NextButton
      v-if="href"
      v-tooltip.top-end="$t('CONTACT_PANEL.OPEN_IN_AGENTS')"
      icon="i-lucide-bot"
      slate
      faded
      sm
      @click="open"
    />
  </div>
</template>
