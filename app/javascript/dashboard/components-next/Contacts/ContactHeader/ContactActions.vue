<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import ContactSortMenu from './ContactSortMenu.vue';
import ContactMoreActions from './ContactMoreActions.vue';

defineProps({
  isDetailView: {
    type: Boolean,
    default: false,
  },
  activeSort: {
    type: String,
    default: 'last_activity_at',
  },
  activeOrdering: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['filter', 'more', 'update:sort']);
</script>

<template>
  <div class="flex items-center gap-2">
    <Button
      v-if="!isDetailView"
      icon="i-lucide-list-filter"
      color="slate"
      size="sm"
      variant="ghost"
      @click="emit('filter')"
    />
    <ContactSortMenu
      v-if="!isDetailView"
      :active-sort="activeSort"
      :active-ordering="activeOrdering"
      @update:sort="emit('update:sort', $event)"
    />
    <ContactMoreActions v-if="!isDetailView" />
  </div>
</template>
