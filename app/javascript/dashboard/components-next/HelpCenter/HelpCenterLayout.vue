<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store.js';

import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PortalSwitcher from 'dashboard/components-next/HelpCenter/PortalSwitcher/PortalSwitcher.vue';
import CreatePortalDialog from 'dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue';

defineProps({
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
  showHeaderTitle: {
    type: Boolean,
    default: true,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update:currentPage']);

const route = useRoute();

const createPortalDialogRef = ref(null);

const showPortalSwitcher = ref(false);

const portals = useMapGetter('portals/allPortals');

const currentPortalSlug = computed(() => route.params.portalSlug);

const activePortalName = computed(() => {
  return portals.value?.find(portal => portal.slug === currentPortalSlug.value)
    ?.name;
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
const togglePortalSwitcher = () => {
  showPortalSwitcher.value = !showPortalSwitcher.value;
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="sticky top-0 z-10 px-6 pb-3 lg:px-0">
      <div class="w-full max-w-[960px] mx-auto">
        <div
          v-if="showHeaderTitle"
          class="flex items-center justify-start h-20 gap-2"
        >
          <span
            v-if="activePortalName"
            class="text-xl font-medium text-n-slate-12"
          >
            {{ activePortalName }}
          </span>
          <div v-if="activePortalName" class="relative group">
            <OnClickOutside @trigger="showPortalSwitcher = false">
              <Button
                icon="i-lucide-chevron-down"
                variant="ghost"
                size="xs"
                class="rounded-md group-hover:bg-n-slate-3 hover:bg-n-slate-3"
                @click="togglePortalSwitcher"
              />

              <PortalSwitcher
                v-if="showPortalSwitcher"
                class="absolute ltr:left-0 rtl:right-0 top-9"
                @close="showPortalSwitcher = false"
                @create-portal="createPortalDialogRef.dialogRef.open()"
              />
            </OnClickOutside>
            <CreatePortalDialog ref="createPortalDialogRef" />
          </div>
        </div>
        <slot name="header-actions" />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-[960px] mx-auto py-3">
        <slot name="content" />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10 px-4 pb-4">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        @update:current-page="updateCurrentPage"
      />
    </footer>
    <!-- Do not remove this slot. It can be used to add dialogs. -->
    <slot />
  </section>
</template>
