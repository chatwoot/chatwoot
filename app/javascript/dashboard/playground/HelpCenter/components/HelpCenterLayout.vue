<script setup>
import { ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import PaginationFooter from 'dashboard/playground/components/PaginationFooter.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
import PortalSwitcher from './PortalSwitcher.vue';

defineProps({
  header: {
    type: String,
    default: 'Chatwoot Help Center',
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  totalItems: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update:currentPage']);

const showPortalSwitcher = ref(false);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const togglePortalSwitcher = () => {
  showPortalSwitcher.value = !showPortalSwitcher.value;
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <section
    class="flex flex-col w-full h-full overflow-hidden bg-white dark:bg-slate-900"
  >
    <header
      class="sticky top-0 z-10 px-6 pb-3 bg-white lg:px-0 dark:bg-slate-900"
    >
      <div class="w-full max-w-[900px] mx-auto">
        <div class="flex items-center justify-start h-20 gap-2">
          <span class="text-xl font-medium text-slate-900 dark:text-white">
            {{ header }}
          </span>
          <div class="relative group">
            <ButtonV4
              icon="more-vertical"
              variant="ghost"
              size="sm"
              class="group-hover:bg-slate-100 dark:group-hover:bg-slate-800"
              @click="togglePortalSwitcher"
            />
            <OnClickOutside @trigger="showPortalSwitcher = false">
              <PortalSwitcher
                v-if="showPortalSwitcher"
                class="absolute left-0 top-9"
              />
            </OnClickOutside>
          </div>
        </div>
        <slot name="header-actions" />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-[900px] mx-auto py-3">
        <slot name="content" />
      </div>
    </main>
    <footer
      v-if="showPaginationFooter"
      class="sticky bottom-0 z-10 px-4 pt-3 pb-4 bg-white dark:bg-slate-900"
    >
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        @update:current-page="updateCurrentPage"
      />
    </footer>
  </section>
</template>
