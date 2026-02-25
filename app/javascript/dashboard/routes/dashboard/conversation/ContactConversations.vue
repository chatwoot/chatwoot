<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import ConversationContextMenu from 'dashboard/components/widgets/conversation/contextMenu/Index.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
  conversationId: { type: [String, Number], required: true },
});

const store = useStore();
const router = useRouter();

const accountId = useMapGetter('getCurrentAccountId');
const currentChat = useMapGetter('getSelectedChat');
const uiFlags = useMapGetter('contactConversations/getUIFlags');

const getContact = id => store.getters['contacts/getContact'](id) || {};
const getInbox = id => store.getters['inboxes/getInbox'](id) || {};

const conversations = computed(() =>
  store.getters['contactConversations/getContactConversation'](props.contactId)
);

const previousConversations = computed(() =>
  conversations.value.filter(c => c.id !== Number(props.conversationId))
);

const activeContextChat = ref(null);
const showContextMenu = ref(false);
const contextMenu = ref({ x: null, y: null });

const conversationPath = computed(() => {
  if (!activeContextChat.value) return '';
  return frontendURL(
    conversationUrl({
      accountId: accountId.value,
      id: activeContextChat.value.id,
    })
  );
});

const onCardClick = (conversation, e) => {
  const path = frontendURL(
    conversationUrl({ accountId: accountId.value, id: conversation.id })
  );
  if (!path) return;

  if (e.metaKey || e.ctrlKey) {
    e.preventDefault();
    window.open(
      `${window.chatwootConfig.hostURL}${path}`,
      '_blank',
      'noopener,noreferrer'
    );
    return;
  }

  router.push({ path });
};

const openContextMenu = (conversation, e) => {
  e.preventDefault();
  activeContextChat.value = conversation;
  contextMenu.value.x = e.pageX || e.clientX;
  contextMenu.value.y = e.pageY || e.clientY;
  showContextMenu.value = true;
};

const closeContextMenu = () => {
  showContextMenu.value = false;
  contextMenu.value.x = null;
  contextMenu.value.y = null;
  activeContextChat.value = null;
};

watch(
  () => props.contactId,
  (newId, oldId) => {
    if (newId && newId !== oldId) {
      store.dispatch('contactConversations/get', newId);
    }
  }
);

onMounted(() => {
  store.dispatch('contactConversations/get', props.contactId);
});
</script>

<template>
  <div v-if="!uiFlags.isFetching" class="">
    <div v-if="!previousConversations.length" class="no-label-message px-4 p-3">
      <span>
        {{ $t('CONTACT_PANEL.CONVERSATIONS.NO_RECORDS_FOUND') }}
      </span>
    </div>
    <div v-else class="contact-conversation--list">
      <ConversationCard
        v-for="conversation in previousConversations"
        :key="conversation.id"
        :chat="conversation"
        :current-contact="getContact(conversation.meta?.sender?.id)"
        :assignee="conversation.meta?.assignee || {}"
        :inbox="getInbox(conversation.inbox_id)"
        :is-active-chat="currentChat.id === conversation.id"
        hide-thumbnail
        compact
        @click="onCardClick(conversation, $event)"
        @contextmenu="openContextMenu(conversation, $event)"
      />
    </div>
    <ContextMenu
      v-if="showContextMenu && activeContextChat"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <ConversationContextMenu
        :status="activeContextChat.status"
        :inbox-id="activeContextChat.inbox_id"
        :priority="activeContextChat.priority"
        :chat-id="activeContextChat.id"
        :has-unread-messages="activeContextChat.unread_count > 0"
        :conversation-labels="activeContextChat.labels"
        :conversation-url="conversationPath"
        :allowed-options="['open-new-tab', 'copy-link']"
        @close="closeContextMenu"
      />
    </ContextMenu>
  </div>
  <div v-else class="flex items-center justify-center py-5">
    <Spinner />
  </div>
</template>

<style lang="scss" scoped>
.no-label-message {
  @apply text-n-slate-11 mb-4;
}
</style>
