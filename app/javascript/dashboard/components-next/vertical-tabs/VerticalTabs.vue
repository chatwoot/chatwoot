<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  tabs: {
    type: Array,
    required: true,
    validator: value => value.every(tab => tab.id && tab.label),
  },
  contentClass: {
    type: String,
    default: '',
  },
});

const activeTab = defineModel({ type: String, required: true });
</script>

<template>
  <div class="flex flex-col w-full gap-4 md:flex-row md:items-start md:gap-8">
    <!-- Horizontal scrollable tab row on small screens; vertical rail from md up. -->
    <nav
      class="flex flex-row w-full gap-1 pb-2 overflow-x-auto no-scrollbar border-b shrink-0 border-n-weak md:sticky md:top-0 md:flex-col md:w-48 md:gap-0.5 md:border-b-0 md:overflow-visible"
    >
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        class="flex items-center gap-2 px-2.5 py-2 text-sm text-start transition-colors rounded-lg shrink-0 min-h-9 md:w-full"
        :class="
          activeTab === tab.id
            ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
            : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
        "
        :aria-current="activeTab === tab.id ? 'page' : undefined"
        @click="activeTab = tab.id"
      >
        <Icon v-if="tab.icon" :icon="tab.icon" class="shrink-0 size-4" />
        <span class="min-w-0 whitespace-nowrap md:whitespace-normal">
          {{ tab.label }}
        </span>
      </button>
    </nav>

    <div class="flex flex-col flex-1 w-full min-w-0" :class="contentClass">
      <!-- Keep every panel mounted and toggle visibility so unsaved drafts survive tab switches. -->
      <div
        v-for="tab in tabs"
        v-show="activeTab === tab.id"
        :key="tab.id"
        class="flex flex-col w-full min-w-0"
      >
        <slot :name="tab.id" />
      </div>
    </div>
  </div>
</template>
