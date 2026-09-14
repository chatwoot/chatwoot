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
    color: {
      type: String,
      default: '#6e6f73',
    },
  },
};
</script>

<template>
  <button
    type="submit"
    :disabled="disabled"
    class="min-h-8 min-w-8 flex items-center justify-center ms-1"
  >
    <FluentIcon
      v-if="!loading"
      icon="send"
      class="rtl:-scale-x-100"
      :style="`color: ${color}`"
    />
    <Spinner v-else size="small" />
  </button>
</template>
