<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('NEW_CONVERSATION.TITLE')"
        :header-content="$t('NEW_CONVERSATION.DESC')"
      />
      <conversation-form
        :contacts="contacts"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import ConversationForm from './ConversationForm.vue';

export default {
  components: {
    ConversationForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    contacts: {
      type: Array,
      default: () => [],
    },
  },
  mounted() {
    if (!this.contacts || !this.contacts.length) {
      return;
    }

    const { id, contactableInboxes } = this.contacts[0];
    if (id && !contactableInboxes) {
      this.$store.dispatch('contacts/fetchContactableInbox', id);
    }
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(params, isFromWhatsApp) {
      const data = await this.$store.dispatch('contactConversations/create', {
        params,
        isFromWhatsApp,
      });
      return data;
    },
  },
};
</script>
