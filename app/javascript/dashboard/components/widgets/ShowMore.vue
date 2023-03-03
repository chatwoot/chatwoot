<template>
  <span>
    {{ textToBeDisplayed }}
    <button
      v-if="text.length > limit"
      class="show-more--button"
      @click="toggleShowMore"
    >
      {{ buttonLabel }}
    </button>
  </span>
</template>
<script>
export default {
  props: {
    text: {
      type: String,
      default: '',
    },
    limit: {
      type: Number,
      default: 120,
    },
  },
  data() {
    return {
      showMore: false,
    };
  },
  computed: {
    textToBeDisplayed() {
      if (this.showMore || this.text.length <= this.limit) {
        return this.text;
      }

      return this.text.slice(0, this.limit) + '...';
    },
    buttonLabel() {
      const i18nKey = !this.showMore ? 'SHOW_MORE' : 'SHOW_LESS';
      return this.$t(`COMPONENTS.SHOW_MORE_BLOCK.${i18nKey}`);
    },
  },
  methods: {
    toggleShowMore() {
      this.showMore = !this.showMore;
    },
  },
};
</script>
<style scoped>
.show-more--button {
  color: var(--w-500);
}
</style>
