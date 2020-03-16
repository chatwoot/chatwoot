<template>
  <a
    v-if="isLink"
    :key="action.uri"
    class="action-button button"
    :href="action.uri"
  >
    {{ action.text }}
  </a>
  <button
    v-else
    :key="action.payload"
    class="action-button button"
    @click="onClick"
  >
    {{ action.text }}
  </button>
</template>

<script>
export default {
  components: {},
  props: {
    action: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    isLink() {
      return this.action.type === 'link';
    },
  },
  methods: {
    onClick() {
      // Do postback here
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.action-button {
  width: 100%;
  padding: 0;
  max-height: 34px;
  margin-top: $space-smaller;
  border-radius: $space-micro;
  font-weight: $font-weight-medium;
}
</style>
