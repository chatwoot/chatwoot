<template>
  <div>
    <div class="ui-snackbar">
      <div class="ui-snackbar-text">
        {{ message }}
      </div>
      <div v-if="action" class="ui-snackbar-action">
        <router-link v-if="action.type == 'link'" :to="action.to">
          {{ action.message }}
        </router-link>
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
  },
  data() {
    return {
      toggleAfterTimeout: false,
    };
  },
  mounted() {},
  methods: {},
};
</script>
