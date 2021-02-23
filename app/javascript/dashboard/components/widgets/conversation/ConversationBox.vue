<template>
  <div :class="conversationClass">
    <messages-view
      v-if="currentChat.id"
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contact-panel-toggle="onToggleContactPanel"
    />
    <empty-state v-else />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import EmptyState from './EmptyState';
import MessagesView from './MessagesView';

export default {
  components: {
    EmptyState,
    MessagesView,
  },

  props: {
    inboxId: {
      type: [Number, String],
      default: '',
      required: false,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    conversationClass() {
      return `medium-${
        this.isContactPanelOpen ? '5' : '8'
      } columns conversation-wrap`;
    },
  },
  methods: {
    onToggleContactPanel() {
      this.$emit('contact-panel-toggle');
    },
  },
};
</script>
