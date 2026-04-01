<script setup>
import { isVNode, computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';

const props = defineProps({
  label: { type: String, required: true },
  to: { type: [String, Object], required: true },
  icon: { type: [String, Object], default: null },
  active: { type: Boolean, default: false },
  component: { type: Function, default: null },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="py-0.5 ltr:pl-2 rtl:pr-2 rtl:mr-3 ltr:ml-3 relative text-n-slate-11 child-item before:bg-n-slate-4 after:bg-transparent after:border-n-slate-4 before:left-0 rtl:before:right-0 min-w-0"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"
      class="relative flex h-8 items-center gap-2 px-2 py-1 rounded-lg hover:bg-surface-container-low group min-w-0"
      :class="{
        'text-secondary bg-surface-bright/60 backdrop-blur-xl border border-white/5 active font-semibold shadow-[inset_0_0_12px_rgba(4,190,153,0.15)] !pl-4':
          active,
      }"
    >
      <span
        v-if="active"
        class="absolute ltr:left-0 rtl:right-0 top-1.5 bottom-1.5 w-1 rounded-r-full bg-secondary"
      />
      <component
        :is="component"
        v-if="shouldRenderComponent"
        :label
        :icon
        :active
      />
      <template v-else>
        <Icon v-if="icon" :icon="icon" class="size-4 inline-block" />
        <div class="flex-1 truncate min-w-0">{{ label }}</div>
      </template>
    </component>
  </Policy>
</template>
