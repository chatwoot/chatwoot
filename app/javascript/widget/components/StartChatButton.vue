<template>
  <button
    type="button"
    class="flex w-full justify-between items-center rounded-md bg-slate-900 px-4 py-2 leading-6 text-sm font-medium text-white box-shadow hover:bg-slate-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-600 start-chat-button"
    @click="$emit('start')"
  >
    {{ text }}
    <fluent-icon icon="send" size="14" />
  </button>
</template>

<script>
export default {
  props: {
    text: {
      type: String,
      default: 'Chat with us',
    },
  },
};
</script>

<style lang="scss" scoped>
.start-chat-button {
  color: var(--brand-textButton);
  background: var(--brand-primary);

  svg {
    color: var(--brand-textButton);
  }
}
</style>
