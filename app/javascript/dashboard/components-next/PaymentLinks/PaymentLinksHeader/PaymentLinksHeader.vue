<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PaymentLinksSortMenu from './components/PaymentLinksSortMenu.vue';
import PaymentLinksMoreActions from './components/PaymentLinksMoreActions.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '' },
  hasActiveFilters: { type: Boolean, default: false },
});

const emit = defineEmits(['search', 'filter', 'update:sort', 'export']);
</script>

<template>
  <header class="sticky top-0 z-10">
    <div
      class="flex items-start sm:items-center justify-between w-full py-6 px-6 gap-2 mx-auto max-w-[60rem]"
    >
      <span class="text-xl font-medium truncate text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4">
        <div class="flex items-center gap-2 w-full">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('PAYMENT_LINKS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
            ]"
            class="w-full"
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
        <div class="flex items-center flex-shrink-0 gap-4">
          <div class="flex items-center gap-2">
            <div class="relative">
              <Button
                id="togglePaymentLinksFilterButton"
                icon="i-lucide-list-filter"
                color="slate"
                size="sm"
                class="relative w-8"
                variant="ghost"
                @click="emit('filter')"
              >
                <div
                  v-if="hasActiveFilters"
                  class="absolute top-0 right-0 w-2 h-2 rounded-full bg-n-brand"
                />
              </Button>
              <slot name="filter" />
            </div>
            <PaymentLinksSortMenu
              :active-sort="activeSort"
              :active-ordering="activeOrdering"
              @update:sort="emit('update:sort', $event)"
            />
            <PaymentLinksMoreActions @export="emit('export')" />
          </div>
        </div>
      </div>
    </div>
  </header>
</template>
