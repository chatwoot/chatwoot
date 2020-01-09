<template>
  <button
    type="button"
    class="button nice resolve--button"
    :class="buttonClass"
    @click="toggleStatus"
  >
    <i v-if="!isLoading" class="icon" :class="buttonIconClass" />
    <spinner v-if="isLoading" />
    {{ currentStatus }}
  </button>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';

export default {
  props: ['conversationId'],
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    currentStatus() {
      const ButtonName = this.currentChat.status === 0 ? 'Resolve' : 'Reopen';
      return ButtonName;
    },
    buttonClass() {
      return this.currentChat.status === 0 ? 'success' : 'warning';
    },
    buttonIconClass() {
      return this.currentChat.status === 0 ? 'ion-checkmark' : 'ion-refresh';
    },
  },
  components: {
    Spinner,
  },
  methods: {
    toggleStatus() {
      this.isLoading = true;
      this.$store.dispatch('toggleStatus', this.currentChat.id).then(() => {
        bus.$emit('newToastMessage', this.$t('CONVERSATION.CHANGE_STATUS'));
        this.isLoading = false;
      });
    },
  },
};
</script>
