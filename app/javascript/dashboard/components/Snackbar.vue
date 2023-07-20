<template>
  <div>
    <div
      class="ui-snackbar"
      :class="{
        wide: wide,
      }"
    >
      <div class="ui-snackbar-text" v-html="message" />
      <div v-if="action" class="ui-snackbar-action">
        <router-link v-if="action.type == 'link'" :to="action.to">
          {{ action.message }}
        </router-link>
        <woot-button
          v-if="action.type == 'function'"
          size="small"
          :is-loading="actionLoading"
          @click="handleClick"
        >
          {{ action.message }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    message: { type: String, default: '' },
    action: {
      type: Object,
      default: () => {},
    },
    showButton: Boolean,
    duration: {
      type: [String, Number],
      default: 3000,
    },
    wide: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      toggleAfterTimeout: false,
      actionLoading: false,
    };
  },
  mounted() {},
  methods: {
    async handleClick() {
      try {
        this.actionLoading = true;
        await this.action.handler();
      } catch {
        // eslint-disable-next-line no-console
        console.error('Error while executing action');
      } finally {
        this.actionLoading = false;
      }
    },
  },
};
</script>
