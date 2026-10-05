<script setup>
import { useTemplateRef } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

defineProps({
  backLabel: { type: String, required: true },
  isLoading: { type: Boolean, default: false },
  tabs: { type: Array, default: () => [] },
});

const emit = defineEmits(['back']);

const isRTL = useMapGetter('accounts/isRTL');

const activeTab = defineModel('activeTab', { type: String, default: '' });

const tabsRef = useTemplateRef('tabsRef');

const scrollToTabs = () =>
  tabsRef.value?.scrollIntoView({ behavior: 'smooth', block: 'start' });

defineExpose({ scrollToTabs });
</script>

<template>
  <section class="w-full h-full px-6 overflow-y-auto bg-n-surface-1">
    <div class="flex flex-col w-full max-w-5xl gap-8 pt-6 pb-24 mx-auto">
      <Button
        :label="backLabel"
        :icon="isRTL ? 'i-lucide-arrow-right' : 'i-lucide-arrow-left'"
        variant="link"
        color="slate"
        size="sm"
        class="self-start -mb-4"
        @click="emit('back')"
      />

      <div v-if="isLoading" class="flex justify-center py-24 text-n-slate-11">
        <Spinner />
      </div>

      <slot v-else-if="$slots.state" name="state" />

      <template v-else>
        <section
          class="flex flex-col gap-5 p-6 border rounded-xl border-n-weak bg-n-solid-1"
        >
          <slot name="header" />
        </section>

        <div class="flex flex-col gap-4">
          <div
            ref="tabsRef"
            class="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 py-3 border-b bg-n-surface-1 border-n-weak"
          >
            <TabBar
              :tabs="tabs"
              class="min-w-0 max-w-full"
              :initial-active-tab="
                tabs.findIndex(tab => tab.value === activeTab)
              "
              @tab-changed="tab => (activeTab = tab.value)"
            />
            <div class="flex items-center w-full gap-2 sm:w-auto">
              <slot name="actions" />
            </div>
          </div>

          <slot />
        </div>
      </template>
    </div>
  </section>
</template>
