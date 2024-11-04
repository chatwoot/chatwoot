<script setup>
import { computed } from 'vue';
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
]);

const { t } = useI18n();

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

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="sticky top-0 z-10 px-6 lg:px-0">
      <div class="w-full max-w-[900px] mx-auto">
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
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-[900px] mx-auto py-4">
        <slot name="default" />
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
  </section>
</template>
