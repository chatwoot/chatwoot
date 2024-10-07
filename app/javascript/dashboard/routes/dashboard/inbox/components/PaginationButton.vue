<script>
export default {
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
  },
  emits: ['prev', 'next'],
  computed: {
    isUpDisabled() {
      return this.currentIndex === 1;
    },
    isDownDisabled() {
      return this.currentIndex === this.totalLength || this.totalLength <= 1;
    },
  },
  methods: {
    handleUpClick() {
      if (this.currentIndex > 1) {
        this.$emit('prev');
      }
    },
    handleDownClick() {
      if (this.currentIndex < this.totalLength) {
        this.$emit('next');
      }
    },
  },
};
</script>

<template>
  <div class="flex gap-2 items-center">
    <div class="flex gap-1 items-center">
      <woot-button
        size="tiny"
        variant="hollow"
        color-scheme="secondary"
        icon="chevron-up"
        :disabled="isUpDisabled"
        @click="handleUpClick"
      />
      <woot-button
        size="tiny"
        variant="hollow"
        color-scheme="secondary"
        icon="chevron-down"
        :disabled="isDownDisabled"
        @click="handleDownClick"
      />
    </div>
    <div class="flex items-center gap-1 whitespace-nowrap">
      <span class="text-sm font-medium text-gray-600 tabular-nums">
        {{ totalLength <= 1 ? '1' : currentIndex }}
      </span>
      <span
        v-if="totalLength > 1"
        class="text-sm text-slate-400 relative -top-px"
      >
        /
      </span>
      <span v-if="totalLength > 1" class="text-sm text-slate-400 tabular-nums">
        {{ totalLength }}
      </span>
    </div>
  </div>
</template>
