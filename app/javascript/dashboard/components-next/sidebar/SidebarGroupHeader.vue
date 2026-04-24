<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  to: { type: [Object, String], default: '' },
  label: { type: String, default: '' },
  icon: { type: [String, Object], default: '' },
  expandable: { type: Boolean, default: false },
  isExpanded: { type: Boolean, default: false },
  isActive: { type: Boolean, default: false },
  hasActiveChild: { type: Boolean, default: false },
  getterKeys: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['toggle']);

const showBadge = useMapGetter(props.getterKeys.badge);
const dynamicCount = useMapGetter(props.getterKeys.count);
const count = computed(() =>
  dynamicCount.value > 99 ? '99+' : dynamicCount.value
);
</script>

<template>
  <component
    :is="to ? 'router-link' : 'div'"
    class="flex items-center gap-3 py-2.5 rounded-lg text-sm font-medium transition-colors min-w-0 relative"
    role="button"
    draggable="false"
    :to="to"
    :title="label"
    :class="{
      'bg-s-brand-800 text-s-on-dark ltr:pl-[9px] rtl:pr-[9px] ltr:pr-3 rtl:pl-3 ltr:border-l-[3px] rtl:border-r-[3px] border-s-accent-500':
        isActive && !hasActiveChild,
      'text-s-on-dark px-3': hasActiveChild,
      'text-s-on-dark-muted hover:bg-white/[0.06] hover:text-s-on-dark px-3':
        !isActive && !hasActiveChild,
    }"
    @click.stop="emit('toggle')"
  >
    <div v-if="icon" class="relative flex items-center">
      <Icon
        v-if="icon"
        :icon="icon"
        class="size-5"
        :class="{
          'text-s-on-dark': isActive || hasActiveChild,
          'text-s-on-dark-muted': !isActive && !hasActiveChild,
        }"
      />
      <span
        v-if="showBadge"
        class="size-2 -top-px ltr:-right-px rtl:-left-px bg-s-accent-500 absolute rounded-full border border-s-sidebar"
      />
    </div>
    <div class="flex items-center gap-1.5 flex-grow min-w-0 flex-1">
      <span class="truncate">{{ label }}</span>
      <span
        v-if="dynamicCount && !expandable"
        class="rounded-full text-xs leading-4 font-semibold text-center px-1.5 py-0.5 flex-shrink-0 bg-s-accent-500 text-s-brand-900"
      >
        {{ count }}
      </span>
    </div>
    <span
      v-if="expandable"
      class="size-4 text-s-on-dark-muted"
      :class="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
      @click.stop="emit('toggle')"
    />
  </component>
</template>
