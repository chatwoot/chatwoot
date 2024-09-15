<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('CONTACT_PANEL.NEW_ACTION.HEADER_TITLE')"
        :header-content="$t('CONTACT_PANEL.NEW_ACTION.HEADER_CONTENT')"
      />
      <new-action-form
        :contact="contact"
        :on-submit="onSubmit"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import NewActionForm from './NewActionForm.vue';

export default {
  components: {
    NewActionForm,
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
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    async onSubmit(params) {
      const data = await this.$store.dispatch(
        'contactConversations/createSnoozedConversation',
        params
      );
      // Fetch conversation plans
      await this.$store.dispatch(
        'contacts/fetchConversationPlans',
        this.contact.id
      );

      return data;
    },
  },
};
</script>
