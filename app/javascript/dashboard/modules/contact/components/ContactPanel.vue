<template>
  <div class="panel">
    <contact-intro
      :contact="contact"
      @message="toggleConversationModal"
      @edit="toggleEditModal"
    />
    <contact-fields :contact="contact" :edit="null" />
    <edit-contact
      v-if="showEditModal"
      :show="showEditModal"
      :contact="contact"
      @cancel="toggleEditModal"
    />
    <new-conversation
      :show="showConversationModal"
      :contact="contact"
      @cancel="toggleConversationModal"
    />
  </div>
</template>
<script>
import EditContact from 'dashboard/routes/dashboard/conversation/contact/EditContact';
import NewConversation from 'dashboard/routes/dashboard/conversation/contact/NewConversation';
import ContactIntro from './ContactIntro';
import ContactFields from './ContactFields';

export default {
  components: {
    EditContact,
    NewConversation,
    ContactIntro,
    ContactFields,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showEditModal: false,
      showConversationModal: false,
    };
  },
  methods: {
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    toggleConversationModal() {
      this.showConversationModal = !this.showConversationModal;
    },
  },
};
</script>

<style scoped lang="scss">
.panel {
  padding: var(--space-normal) var(--space-normal);
}
</style>
