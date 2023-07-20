<template>
  <button
    type="submit"
    :disabled="disabled"
    class="flex items-center justify-center px-2 py-1 send-button rounded shadow-sm"
    @click="onClick"
  >
    <fluent-icon v-if="!loading" icon="send" />
    <spinner v-else size="small" />
  </button>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: {
    FluentIcon,
    Spinner,
  },
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    onClick: {
      type: Function,
      default: () => {},
    },
    color: {
      type: String,
      default: '#6e6f73',
    },
  },
};
</script>
<style scoped lang="scss">
.send-button {
  background: var(--brand-primary);
  color: var(--brand-textButton);

  svg {
  }
}
</style>
