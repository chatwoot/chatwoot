<script setup>
import { computed, useSlots } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';

const props = defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
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
    default: 15,
  },
  isDetailView: {
    type: Boolean,
    default: false,
  },
  selectedContact: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits([
  'filter',
  'more',
  'message',
  'update:currentPage',
  'goToContactsList',
  'search',
]);

const { t } = useI18n();
const slots = useSlots();

const selectedContactName = computed(() => {
  return props.selectedContact?.name;
});

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.HEADER.BREADCRUMB.CONTACTS'),
      link: '#',
    },
  ];
  if (props.selectedContact) {
    items.push({
      label: selectedContactName.value,
    });
  }
  return items;
});

const hasSidebar = computed(() => {
  return slots.sidebar && props.isDetailView;
});

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div
      class="flex flex-col w-full h-full transition-all duration-300"
      :class="hasSidebar && `ltr:2xl:ml-56 rtl:2xl:mr-56`"
    >
      <header class="sticky top-0 z-10 px-6 xl:px-0">
        <div
          class="w-full mx-auto"
          :class="hasSidebar ? `max-w-[650px]` : `max-w-[900px]`"
        >
          <div class="flex items-center justify-between w-full h-20 gap-2">
            <span
              v-if="!isDetailView"
              class="text-xl font-medium text-n-slate-12"
            >
              {{ headerTitle }}
            </span>
            <Breadcrumb
              v-else
              :items="breadcrumbItems"
              @click="handleBreadcrumbClick"
            />
            <div class="flex items-center gap-2">
              <div v-if="!isDetailView" class="flex items-center gap-2">
                <Input
                  :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
                  :custom-input-class="['h-8 ltr:!pl-8 rtl:!pr-8']"
                  @input="emit('search', $event.target.value)"
                >
                  <template #prefix>
                    <Icon
                      icon="i-lucide-search"
                      class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                    />
                  </template>
                </Input>
              </div>
              <Button
                v-if="!isDetailView"
                icon="i-lucide-list-filter"
                size="sm"
                color="slate"
                @click="emit('filter')"
              />
              <Button
                v-if="!isDetailView"
                icon="i-lucide-ellipsis-vertical"
                size="sm"
                color="slate"
                @click="emit('more')"
              />
              <Button :label="buttonLabel" size="sm" @click="emit('message')" />
            </div>
          </div>
        </div>
      </header>
      <main class="flex-1 px-6 overflow-y-auto xl:px-px">
        <div
          class="w-full py-4 mx-auto"
          :class="hasSidebar ? `max-w-[650px]` : `max-w-[900px]`"
        >
          <slot name="default" />
        </div>
      </main>
      <footer
        v-if="showPaginationFooter"
        class="sticky bottom-0 z-10 px-4 pb-4"
      >
        <PaginationFooter
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>

    <div
      v-if="slots.sidebar"
      class="overflow-y-auto justify-end min-w-[200px] w-full py-6 max-w-[440px] border-l border-n-weak bg-n-solid-2"
    >
      <slot name="sidebar" />
    </div>
  </section>
</template>
