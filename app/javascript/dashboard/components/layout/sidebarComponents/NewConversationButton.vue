<template>
  <div class="mb-4">
    <woot-button
      v-tooltip="$t('CONTACT_PANEL.NEW_MESSAGE')"
      title="$t('CONTACT_PANEL.NEW_MESSAGE')"
      icon="chat"
      size="small"
      @click="toggleConversationModal"
    />
    <new-conversation
      :show="showConversationModal"
      @cancel="toggleConversationModal"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import NewConversation from 'dashboard/routes/dashboard/conversation/contact/NewConversation.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  components: {
    NewConversation,
  },
  data() {
    return {
      showConversationModal: false,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    enableNewConversation() {
      return this.contact && this.contact.id;
    },
  },
  methods: {
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
      this.$emitter.emit(
        BUS_EVENTS.NEW_CONVERSATION_MODAL,
        this.showConversationModal
      );
    },
  },
};
</script>
