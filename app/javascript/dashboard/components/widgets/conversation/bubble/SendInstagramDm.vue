<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" size="medium" :on-close="onCancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="`Send Instagram DM to ${displayName}`"
      />
      <instagram-dm-form
        :contact="contact"
        :on-submit="onSubmit"
        :comment-id="instagramCommentId"
        :message-id="messageId"
        @success="onSuccess"
        @cancel="onCancel"
      />
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import InstagramDmForm from './InstagramDmForm.vue';
import { getContactDisplayName } from 'shared/helpers/contactHelper';

export default {
  components: {
    InstagramDmForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    instagramCommentId: {
      type: String,
      default: '',
    },
    messageId: {
      type: Number,
      default: NaN,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      uiFlags: 'inboxAssignableAgents/getUIFlags',
    }),
    contactId() {
      return this.currentChat.meta?.sender?.id;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
    displayName() {
      return getContactDisplayName(this.contact);
    },
  },
  watch: {
    'contact.id'(id) {
      this.$store.dispatch('contacts/fetchContactableInbox', id);
    },
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
