<script setup>
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import IntegrationsAPI from 'dashboard/api/integrations';
import { useMapGetter } from 'dashboard/composables/store';
import { ref } from 'vue';
const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
});
const currentUser = useMapGetter('getCurrentUser');
const messages = ref([]);

const isCaptainTyping = ref(false);

const sendMessage = async message => {
  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    role: 'user',
    content: message,
  });
  isCaptainTyping.value = true;

  try {
    const { data } = await IntegrationsAPI.requestCaptainCopilot({
      previous_history: messages.value
        .map(m => ({
          role: m.role,
          content: m.content,
        }))
        .slice(0, -1),
      message,
      conversation_id: props.conversationId,
    });
    messages.value.push({
      id: new Date().getTime(),
      role: 'assistant',
      content: data.message,
    });
  } catch (error) {
    // eslint-disable-next-line
    console.log(error);
  } finally {
    isCaptainTyping.value = false;
  }
};
</script>

<template>
  <Copilot
    :messages="messages"
    :support-agent="currentUser"
    :is-captain-typing="isCaptainTyping"
    :conversation-inbox-type="conversationInboxType"
    @send-message="sendMessage"
  />
</template>
