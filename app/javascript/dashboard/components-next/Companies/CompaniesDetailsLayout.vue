<script setup>
import { ref, useSlots } from 'vue';
import { vOnClickOutside } from '@vueuse/components';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  breadcrumbItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['back']);

const slots = useSlots();
const isSidebarOpen = ref(false);

const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value;
};

const closeMobileSidebar = () => {
  if (!isSidebarOpen.value) {
    return;
  }

  isSidebarOpen.value = false;
};
</script>

<template>
  <section
    class="flex w-full h-full overflow-hidden justify-evenly bg-n-surface-1"
  >
    <div
      class="flex flex-col w-full h-full transition-all duration-300 ltr:2xl:ml-56 rtl:2xl:mr-56"
    >
      <header class="sticky top-0 z-10 px-6 3xl:px-0">
        <div class="w-full mx-auto max-w-[40.625rem]">
          <div
            class="flex flex-col xs:flex-row items-start xs:items-center justify-between w-full py-7 gap-2"
          >
            <Breadcrumb :items="breadcrumbItems" @click="emit('back')" />
          </div>
        </div>
      </header>

      <main class="flex-1 px-6 overflow-y-auto 3xl:px-px">
        <div class="w-full py-4 mx-auto max-w-[40.625rem]">
          <slot />
        </div>
      </main>
    </div>

    <div
      v-if="slots.sidebar"
      class="hidden lg:flex flex-col min-w-52 w-full max-w-md border-l border-n-weak bg-n-solid-2"
    >
      <div class="shrink-0">
        <slot name="sidebarHeader" />
      </div>
      <div class="flex-1 overflow-y-auto pb-6 pt-3">
        <slot name="sidebar" />
      </div>
    </div>

    <div
      v-if="slots.sidebar"
      class="lg:hidden fixed top-0 ltr:right-0 rtl:left-0 h-full z-50 flex justify-end transition-all duration-200 ease-in-out"
      :class="isSidebarOpen ? 'w-full' : 'w-16'"
    >
      <div
        v-on-click-outside="[
          closeMobileSidebar,
          { ignore: ['#details-sidebar-content'] },
        ]"
        class="flex items-start p-1 w-fit h-fit relative order-1 xs:top-24 top-28 transition-all bg-n-solid-2 border border-n-weak duration-500 ease-in-out"
        :class="[
          isSidebarOpen
            ? 'justify-end ltr:rounded-l-full rtl:rounded-r-full ltr:rounded-r-none rtl:rounded-l-none'
            : 'justify-center rounded-full ltr:mr-6 rtl:ml-6',
        ]"
      >
        <Button
          ghost
          slate
          sm
          class="!rounded-full rtl:rotate-180"
          :class="{ 'bg-n-alpha-2': isSidebarOpen }"
          :icon="
            isSidebarOpen
              ? 'i-lucide-panel-right-close'
              : 'i-lucide-panel-right-open'
          "
          data-details-sidebar-toggle
          @click="toggleSidebar"
        />
      </div>

      <Transition
        enter-active-class="transition-transform duration-200 ease-in-out"
        leave-active-class="transition-transform duration-200 ease-in-out"
        enter-from-class="ltr:translate-x-full rtl:-translate-x-full"
        enter-to-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-from-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-to-class="ltr:translate-x-full rtl:-translate-x-full"
      >
        <div
          v-if="isSidebarOpen"
          id="details-sidebar-content"
          class="order-2 w-[85%] sm:w-[50%] flex flex-col bg-n-solid-2 ltr:border-l rtl:border-r border-n-weak shadow-lg"
        >
          <div class="shrink-0">
            <slot name="sidebarHeader" />
          </div>
          <div class="flex-1 overflow-y-auto pb-6 pt-3">
            <slot name="sidebar" />
          </div>
        </div>
      </Transition>
    </div>
  </section>
</template>
