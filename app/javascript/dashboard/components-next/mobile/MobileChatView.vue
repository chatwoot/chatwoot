<script setup>
import { computed, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import MobileChatHeader from './MobileChatHeader.vue';
import MessagesView from 'dashboard/components/widgets/conversation/MessagesView.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['back']);
const store = useStore();

const currentChat = useMapGetter('getSelectedChat');
const allConversations = useMapGetter('getAllConversations');

const chatLoaded = computed(() => {
  return currentChat.value && currentChat.value.id === props.conversationId;
});

const contactName = computed(() => {
  if (!chatLoaded.value) return '';
  const contact = currentChat.value.meta?.sender;
  return contact?.name || contact?.email || `#${props.conversationId}`;
});

const contactAvatar = computed(() => {
  if (!chatLoaded.value) return '';
  return currentChat.value.meta?.sender?.thumbnail || '';
});

const inboxId = computed(() => {
  return currentChat.value?.inbox_id || '';
});

const setActiveChat = () => {
  const conversationId = props.conversationId;
  const [chat] = allConversations.value.filter(c => c.id === conversationId);
  if (chat) {
    store.dispatch('setActiveChat', { data: chat });
  } else {
    store.dispatch('getConversation', conversationId).then(() => {
      const conversations = store.getters.getAllConversations;
      const [fetchedChat] = conversations.filter(c => c.id === conversationId);
      if (fetchedChat) {
        store.dispatch('setActiveChat', { data: fetchedChat });
      }
    });
  }
};

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('conversationLabels/get', props.conversationId);
  setActiveChat();
});

watch(
  () => props.conversationId,
  () => {
    setActiveChat();
  }
);
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-surface-1">
    <MobileChatHeader
      :name="contactName"
      :avatar="contactAvatar"
      @back="emit('back')"
    />
    <div class="flex flex-1 min-h-0">
      <MessagesView
        v-if="chatLoaded"
        :inbox-id="inboxId"
        :is-inbox-view="false"
      />
      <div
        v-else
        class="flex items-center justify-center w-full h-full"
      >
        <Spinner class="text-n-brand" />
      </div>
    </div>
  </div>
</template>
