<script setup>
import CompanySearchInput from 'dashboard/components-next/Companies/CompanySearchInput.vue';
import CompanySortMenu from './components/CompanySortMenu.vue';
import CompanyMoreActions from './components/CompanyMoreActions.vue';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
});

const emit = defineEmits(['search', 'update:sort', 'create']);
</script>

<template>
  <header class="sticky top-0 z-10 px-6">
    <div
      class="flex items-center justify-between w-full py-6 gap-4 mx-auto max-w-5xl"
    >
      <span class="text-xl font-medium shrink-0 text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div class="flex items-center min-w-0 gap-2 sm:gap-4">
        <CompanySearchInput
          v-if="showSearch"
          :model-value="searchValue"
          :placeholder="$t('COMPANIES.SEARCH_PLACEHOLDER')"
          class="flex-1 min-w-0"
          @update:model-value="emit('search', $event)"
        />
        <div class="flex items-center flex-shrink-0 gap-2">
          <CompanySortMenu
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />
          <CompanyMoreActions @create="emit('create')" />
        </div>
      </div>
    </div>
  </header>
</template>
