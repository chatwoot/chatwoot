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
import Spinner from 'shared/components/Spinner';
import wootConstants from '../../constants';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    Spinner,
  },
  mixins: [alertMixin],
  props: {
    conversationId: {
      type: [String, Number],
      default: '',
    },
    status: {
      type: [String],
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    currentStatus() {
      const ButtonName =
        this.status === wootConstants.STATUS_TYPE.OPEN
          ? this.$t('CONVERSATION.HEADER.RESOLVE_ACTION')
          : this.$t('CONVERSATION.HEADER.REOPEN_ACTION');
      return ButtonName;
    },
    buttonClass() {
      return this.status === wootConstants.STATUS_TYPE.OPEN
        ? 'success'
        : 'warning';
    },
    buttonIconClass() {
      return this.status === wootConstants.STATUS_TYPE.OPEN
        ? 'ion-checkmark'
        : 'ion-refresh';
    },
  },
  methods: {
    toggleStatus() {
      this.isLoading = true;
      this.$store.dispatch('toggleStatus', this.conversationId).then(() => {
        this.showAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
        this.isLoading = false;
      });
    },
  },
};
</script>
