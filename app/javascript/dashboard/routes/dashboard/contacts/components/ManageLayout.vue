<template>
  <div class="wrap">
    <div class="left"></div>
    <div class="center"></div>
    <div class="right"></div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  components: {},
  props: {
    contactId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
  },
  mounted() {},
  methods: {},
};
</script>

<style lang="scss" scoped>
.wrap {
  width: 100%;
  height: 100%;

  background: var(--color-background);
  border-top: 1px solid var(--color-border);

  display: grid;
  grid-template-columns: minmax(27.2rem, 3fr) 6fr minmax(25.6rem, 3fr);
}

.center {
  border-right: 1px solid var(--color-border);
  border-left: 1px solid var(--color-border);
}
</style>
