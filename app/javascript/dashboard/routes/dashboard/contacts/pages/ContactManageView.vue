<template>
  <div class="contact-manage-view row"></div>
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
.contact-manage-view {
  width: 100%;
}
</style>
