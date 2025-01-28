<template>
  <woot-modal
    :show="show"
    :on-close="onCancel"
    size="medium"
    :full-height="false"
  >
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header :header-title="'Compose Email'" />
    </div>
    <one-click-contact-conversation-form
      :is-an-email-inbox="true"
      channel-to-compare="Channel::Email"
      @success="onSuccess"
      @cancel="onCancel"
    />
  </woot-modal>
</template>

<script>
import OneClickContactConversationForm from './OneClickContactConversationForm.vue';

export default {
  components: {
    OneClickContactConversationForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onCancel() {
      this.$emit('close-email-broadcast-modal');
    },
    onSuccess() {
      this.$emit('close-email-broadcast-modal');
    },
  },
};
</script>
