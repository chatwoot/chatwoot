<template>
  <div class="suspended-page">
    <empty-state
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    />
  </div>
</template>
<script>
import EmptyState from 'dashboard/components/widgets/EmptyState';
export default {
  components: { EmptyState },
};
</script>
<style scoped>
.suspended-page {
  align-items: center;
  background: var(--s-50);
  display: flex;
  justify-content: center;
  height: 100%;
  width: 100%;
}
</style>
