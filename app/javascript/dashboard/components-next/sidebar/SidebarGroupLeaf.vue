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
    class="py-0.5 ltr:pl-11 rtl:pr-11 relative text-s-on-dark-muted min-w-0"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"
      class="flex h-9 items-center gap-2 py-1 rounded-lg text-sm font-medium transition-colors group min-w-0"
      :class="{
        'bg-s-brand-800 text-s-on-dark ltr:pl-[9px] rtl:pr-[9px] ltr:pr-3 rtl:pl-3 ltr:border-l-[3px] rtl:border-r-[3px] border-s-accent-500':
          active,
        'text-s-on-dark-muted hover:bg-white/[0.06] hover:text-s-on-dark px-3':
          !active,
      }"
    >
      <component
        :is="component"
        v-if="shouldRenderComponent"
        :label
        :icon
        :active
      />
      <template v-else>
        <span v-if="icon" class="size-4 grid place-content-center">
          <Icon :icon="icon" class="size-4 inline-block" />
        </span>
        <div class="flex-1 truncate min-w-0 text-sm">{{ label }}</div>
      </template>
    </component>
  </Policy>
</template>
