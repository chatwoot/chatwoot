<template>
  <div class="agent-placeholder">
    <spinner />
    <p>{{ $t('CONVERSATION.CARD_CONTEXT_MENU.AGENTS_LOADING') }}</p>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
};
</script>

<style scoped lang="scss">
.agent-placeholder {
  display: flex;
  align-items: center;
  flex-direction: column;
  justify-content: center;
  padding: var(--space-normal) 0;
  min-width: calc(var(--space-mega) * 2);

  p {
    margin: var(--space-small) 0 0 0;
  }
}
</style>
