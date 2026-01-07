<script setup>
import { ref, computed, useTemplateRef } from 'vue';
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
  headerTitle: {
    type: String,
    default: '',
  },
  createButtonLabel: {
    type: String,
    default: '',
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

const emit = defineEmits(['update:currentPage', 'create']);

const route = useRoute();

const createPortalDialogRef = ref(null);
const createButtonRef = useTemplateRef('createButtonRef');

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

const onClickCreateButton = () => {
  emit('create');
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="sticky top-0 z-10 px-6 pb-3 lg:px-0 after:absolute after:inset-x-0 after:-bottom-4 after:bg-gradient-to-b after:from-n-surface-1 after:from-10% after:dark:from-0% after:to-transparent after:h-4 after:pointer-events-none"
    >
      <div class="w-full max-w-5xl mx-auto lg:px-6">
        <div class="flex items-center justify-between gap-3">
          <div
            v-if="showHeaderTitle"
            class="flex items-center justify-start h-20 gap-1"
          >
            <span
              v-if="activePortalName"
              class="text-lg font-520 text-n-slate-12 ltr:mr-1 rtl:ml-1"
            >
              {{ activePortalName }}
            </span>
            <div v-if="activePortalName" class="relative group">
              <OnClickOutside @trigger="showPortalSwitcher = false">
                <Button
                  icon="i-lucide-chevron-down"
                  variant="ghost"
                  color="slate"
                  size="xs"
                  class="rounded-md group-hover:bg-n-slate-3 hover:bg-n-slate-3 [&>span]:size-4"
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
            <div
              v-if="activePortalName && headerTitle"
              class="flex items-center gap-1"
            >
              <div
                v-if="activePortalName"
                class="w-px h-3 rounded-2xl bg-n-strong ltr:ml-2 ltr:mr-3 rtl:mr-2 rtl:ml-3"
              />
              <span v-if="headerTitle" class="text-body-main text-n-slate-12">
                {{ headerTitle }}
              </span>
            </div>
          </div>
          <div ref="createButtonRef" class="relative z-20">
            <Button
              v-if="createButtonLabel"
              :label="createButtonLabel"
              size="sm"
              @click="onClickCreateButton"
            />
            <slot name="modal" :button-ref="createButtonRef" />
          </div>
        </div>
        <slot name="header-actions" />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-5xl mx-auto py-3 lg:px-6">
        <slot name="content" />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        class="max-w-[105rem]"
        @update:current-page="updateCurrentPage"
      />
    </footer>
    <!-- Do not remove this slot. It can be used to add dialogs. -->
    <slot />
  </section>
</template>
