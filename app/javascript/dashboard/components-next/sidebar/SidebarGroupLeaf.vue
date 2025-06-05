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
  beta: { type: Boolean, default: false },
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
    class="py-0.5 ltr:pl-3 rtl:pr-3 rtl:mr-3 ltr:ml-3 relative text-n-slate-11 child-item before:bg-n-slate-4 after:bg-transparent after:border-n-slate-4 before:left-0 rtl:before:right-0"
  >
    <!-- REVIEW:UP This was the style pre v4.0.3 -->
    <!-- class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[151px] group" -->
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"

      class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[9.438rem] hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70 group"
      :class="{
        'n-blue-text bg-n-alpha-2 active hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70':
          active,
        'bg-gray-50 text-gray-400 cursor-not-allowed opacity-60': !to,
      }"
    >
      <!-- class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[151px] hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70 group"
      :class="{
        'n-blue-text bg-n-alpha-2 active': active,
      }" -->
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

        <span
          v-if="beta"
          data-view-component="true"
          label="Beta"
          class="inline-block px-1 mx-1 leading-4 text-green-500 border border-green-400 rounded-lg text-xxs"
        >
          {{ $t('SIDEBAR.BETA') }}
        </span>
      </template>
    </component>
  </Policy>
</template>
