<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
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
      <NextButton
        icon="i-lucide-chevron-up"
        xs
        slate
        faded
        :disabled="isUpDisabled"
        @click="handleUpClick"
      />
      <NextButton
        icon="i-lucide-chevron-down"
        xs
        slate
        faded
        :disabled="isDownDisabled"
        @click="handleDownClick"
      />
    </div>
    <div class="flex items-center gap-1 whitespace-nowrap">
      <span class="text-sm font-medium text-n-slate-12 tabular-nums">
        {{ totalLength <= 1 ? '1' : currentIndex }}
      </span>
      <span
        v-if="totalLength > 1"
        class="text-sm text-n-slate-9 relative -top-px"
      >
        /
      </span>
      <span v-if="totalLength > 1" class="text-sm text-n-slate-9 tabular-nums">
        {{ totalLength }}
      </span>
    </div>
  </div>
</template>
