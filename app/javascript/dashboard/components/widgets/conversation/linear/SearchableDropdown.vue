<script setup>
import { ref, computed, defineOptions } from 'vue';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import FilterListDropdown from 'dashboard/components/ui/Dropdown/DropdownList.vue';

const props = defineProps({
  type: { type: String, required: true },
  label: { type: String, default: null },
  items: { type: Array, required: true },
  value: { type: [Number, String], default: null },
  placeholder: { type: String, default: null },
  error: { type: String, default: null },
});

const emit = defineEmits(['change']);

defineOptions({
  name: 'SearchableDropdown',
});

const shouldShowDropdown = ref(false);

const toggleDropdown = () => {
  shouldShowDropdown.value = !shouldShowDropdown.value;
};
const onSelect = item => {
  emit('change', item, props.type);
  toggleDropdown();
};

const hasError = computed(() => !!props.error);

const selectedItem = computed(() => {
  if (!props.value) return null;
  return props.items.find(i => i.id === props.value);
});

const selectedItemName = computed(
  () => selectedItem.value?.name || props.placeholder
);

const selectedItemId = computed(() => selectedItem.value?.id || null);
</script>

<template>
  <div
    class="flex w-full"
    :class="type === 'stateId' && shouldShowDropdown ? 'h-[150px]' : 'gap-2'"
  >
    <label class="w-full" :class="{ error: hasError }">
      {{ label }}
      <FilterButton
        trailing-icon
        icon="i-lucide-chevron-down"
        :button-text="selectedItemName"
        class="justify-between w-full h-[2.5rem] py-1.5 px-3 rounded-xl bg-n-alpha-black2 outline outline-1 outline-n-weak dark:outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6"
        @click="toggleDropdown"
      >
        <template v-if="shouldShowDropdown" #dropdown>
          <FilterListDropdown
            v-on-clickaway="toggleDropdown"
            :show-clear-filter="false"
            :list-items="items"
            :active-filter-id="selectedItemId"
            :input-placeholder="placeholder"
            enable-search
            class="left-0 flex flex-col w-full overflow-y-auto h-fit !max-h-[160px] md:left-auto md:right-0 top-10"
            @select="onSelect"
          />
        </template>
      </FilterButton>
      <span v-if="hasError" class="mt-1 message">{{ error }}</span>
    </label>
  </div>
</template>
