<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
};
</script>

<template>
  <div class="agent-placeholder">
    <Spinner />
    <p>{{ $t('CONVERSATION.CARD_CONTEXT_MENU.AGENTS_LOADING') }}</p>
  </div>
</template>

<style scoped lang="scss">
.agent-placeholder {
  display: flex;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  padding: 1rem 0;
  min-width: calc(6.25rem * 2);

  p {
    margin: 0.5rem 0 0 0;
  }
}
</style>
