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
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';
import wootConstants from '../../constants';

export default {
  components: {
    Spinner,
  },
  props: { conversationId: { type: [String, Number], required: true } },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    isOpen() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.OPEN;
    },
    currentStatus() {
      return this.isOpen
        ? this.$t('CONVERSATION.HEADER.RESOLVE_ACTION')
        : this.$t('CONVERSATION.HEADER.REOPEN_ACTION');
    },
    buttonClass() {
      return this.isOpen ? 'success' : 'warning';
    },
    buttonIconClass() {
      return this.isOpen ? 'ion-checkmark' : 'ion-refresh';
    },
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
