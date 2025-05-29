<script setup>
import { ref, computed, onMounted, watchEffect } from 'vue';
import { useStore } from 'dashboard/composables/store';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

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

const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const topics = useMapGetter('aiagentTopics/getRecords');
const inboxTopic = useMapGetter('getCopilotTopic');
const { uiSettings, updateUISettings } = useUISettings();

const messages = ref([]);
const isAiagentTyping = ref(false);
const selectedTopicId = ref(null);

const activeTopic = computed(() => {
  const preferredId = uiSettings.value.preferred_aiagent_topic_id;

  // If the user has selected a specific topic, it takes first preference for Copilot.
  if (preferredId) {
    const preferredTopic = topics.value.find(a => a.id === preferredId);
    // Return the preferred topic if found, otherwise continue to next cases
    if (preferredTopic) return preferredTopic;
  }

  // If the above is not available, the topic connected to the inbox takes preference.
  if (inboxTopic.value) {
    const inboxMatchedTopic = topics.value.find(
      a => a.id === inboxTopic.value.id
    );
    if (inboxMatchedTopic) return inboxMatchedTopic;
  }
  // If neither of the above is available, the first topic in the account takes preference.
  return topics.value[0];
});

const setTopic = async topic => {
  selectedTopicId.value = topic.id;
  await updateUISettings({
    preferred_aiagent_topic_id: topic.id,
  });
};

const handleReset = () => {
  messages.value = [];
};

const sendMessage = async message => {
  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    role: 'user',
    content: message,
  });
  isAiagentTyping.value = true;

  try {
    const { data } = await ConversationAPI.requestCopilot(
      props.conversationId,
      {
        previous_history: messages.value
          .map(m => ({
            role: m.role,
            content: m.content,
          }))
          .slice(0, -1),
        message,
        topic_id: selectedTopicId.value,
      }
    );
    messages.value.push({
      id: new Date().getTime(),
      role: 'topic',
      content: data.message,
    });
  } catch (error) {
    // eslint-disable-next-line
    console.log(error);
  } finally {
    isAiagentTyping.value = false;
  }
};

onMounted(() => {
  store.dispatch('aiagentTopics/get');
});

watchEffect(() => {
  if (props.conversationId) {
    store.dispatch('getInboxAiagentTopicById', props.conversationId);
    selectedTopicId.value = activeTopic.value?.id;
  }
});
</script>

<template>
  <Copilot
    :messages="messages"
    :support-agent="currentUser"
    :is-aiagent-typing="isAiagentTyping"
    :conversation-inbox-type="conversationInboxType"
    :topics="topics"
    :active-topic="activeTopic"
    @set-topic="setTopic"
    @send-message="sendMessage"
    @reset="handleReset"
  />
</template>
