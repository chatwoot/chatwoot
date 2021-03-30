<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('NEW_CONVERSATION.TITLE')"
        :header-content="$t('NEW_CONVERSATION.DESC')"
      />
      <conversation-form
        :contact="contact"
        :in-progress="uiFlags.isCreating"
        :on-submit="onSubmit"
        :inboxes="inboxes"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import ConversationForm from './ConversationForm';

export default {
  components: {
    ConversationForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contact: {
      type: Object,
      default: () => ({}),
    },
    inboxes: {
      type: Object,
      default: () => [],
    },
  },

  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
  },

  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(contactItem) {
      await this.$store.dispatch('contactConversations/create', contactItem);
    },
  },
};
</script>
