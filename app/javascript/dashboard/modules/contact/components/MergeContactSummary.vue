<template>
  <div v-if="childContactName" class="merge-summary callout">
    <h5 class="text-block-title">
      {{ $t('MERGE_CONTACTS.SUMMARY.TITLE') }}
    </h5>
    <ul class="summary-items">
      <li>
        <span>❌</span>
        Contact of
        <strong>{{ childContactName }}</strong>
        will be deleted.
      </li>
      <li>
        <span>✅</span>
        Contact details of <strong>{{ childContactName }}</strong> will be
        copied to
        <strong>{{ primaryContactName }}</strong>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  props: {
    primaryContactName: {
      type: String,
      default: '',
    },
    childContactName: {
      type: String,
      default: '',
    },
  },

  computed: {},
};
</script>

<style lang="scss" scoped>
.merge-summary {
  margin-top: var(--space-normal);
}

.summary-items {
  margin-left: 0;
  list-style: none;

  li {
    margin-bottom: var(--space-smaller);
  }
}
</style>
