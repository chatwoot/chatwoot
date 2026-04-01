<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  showStepIndex: {
    type: Boolean,
    default: false,
  },
  stepLabelKey: {
    type: String,
    default: '',
  },
});

const route = useRoute();
const { t } = useI18n();

const activeIndex = computed(() => {
  const index = props.items.findIndex(i => i.route === route.name);
  return index === -1 ? 0 : index;
});

const steps = computed(() =>
  props.items.map((item, index) => {
    const isActive = index === activeIndex.value;
    const isOver = index < activeIndex.value;
    const isLast = index === props.items.length - 1;
    return {
      ...item,
      index,
      isActive,
      isOver,
      isLast,
    };
  })
);

const stepLabel = index => {
  if (!props.showStepIndex || !props.stepLabelKey) return '';
  return t(props.stepLabelKey, { n: index + 1 });
};
</script>

<template>
  <div class="flex flex-col gap-12">
    <div
      v-for="(step, idx) in steps"
      :key="step.route"
      class="relative flex items-start gap-4"
    >
      <!-- Line: from this circle’s center through gap to next step (gap-12 = 3rem) -->
      <div
        v-if="idx < steps.length - 1"
        class="pointer-events-none absolute start-[15px] top-4 z-0 h-[calc(100%+3rem)] w-0.5 bg-outline-variant/35"
        aria-hidden="true"
      />

      <div
        class="relative z-10 flex size-8 shrink-0 items-center justify-center rounded-full transition-all duration-300"
        :class="{
          'bg-secondary text-on-secondary shadow-[0_0_18px_rgba(4,190,153,0.4)]':
            step.isOver || step.isActive,
          'border border-outline-variant/25 bg-surface-container-highest/50 text-on-surface-variant':
            !step.isActive && !step.isOver,
        }"
      >
        <Icon
          v-if="step.isOver"
          icon="i-lucide-check"
          class="size-4 stroke-[2.5] text-on-secondary"
        />
        <Icon
          v-else-if="step.isActive && step.isLast"
          icon="i-lucide-party-popper"
          class="size-4 text-on-secondary"
        />
        <span
          v-else-if="step.isActive"
          class="text-xs font-bold tabular-nums text-on-secondary"
        >
          {{ step.index + 1 }}
        </span>
        <Icon
          v-else-if="step.isLast"
          icon="i-lucide-party-popper"
          class="size-4 text-on-surface-variant/80"
        />
        <span
          v-else
          class="text-xs font-bold tabular-nums text-on-surface-variant/90"
        >
          {{ step.index + 1 }}
        </span>
      </div>

      <div class="flex min-w-0 flex-col pt-0.5">
        <span
          v-if="showStepIndex && stepLabelKey"
          class="text-[11px] font-bold uppercase tracking-widest"
          :class="
            step.isActive || step.isOver
              ? 'text-secondary'
              : 'text-on-surface-variant/55'
          "
        >
          {{ stepLabel(step.index) }}
        </span>
        <h3
          class="mt-0.5 text-sm font-bold leading-snug sm:max-w-none"
          :class="
            step.isActive || step.isOver
              ? 'text-on-surface'
              : 'text-on-surface-variant/65'
          "
        >
          {{ step.title }}
        </h3>
        <p
          class="m-0 mt-1 text-sm leading-relaxed"
          :class="
            step.isActive || step.isOver
              ? 'text-on-primary-container'
              : 'text-on-surface-variant/50'
          "
        >
          {{ step.body }}
        </p>
      </div>
    </div>
  </div>
</template>
