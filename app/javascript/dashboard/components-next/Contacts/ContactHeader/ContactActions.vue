<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import ContactSortMenu from './ContactSortMenu.vue';

defineProps({
  buttonLabel: {
    type: String,
    default: '',
  },
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

const emit = defineEmits(['filter', 'more', 'message', 'update:sort']);
</script>

<template>
  <div class="flex items-center gap-2">
    <Button
      v-if="!isDetailView"
      icon="i-lucide-list-filter"
      color="slate"
      variant="ghost"
      @click="emit('filter')"
    />
    <ContactSortMenu
      v-if="!isDetailView"
      :active-sort="activeSort"
      :active-ordering="activeOrdering"
      @update:sort="emit('update:sort', $event)"
    />
    <Button
      v-if="!isDetailView"
      icon="i-lucide-ellipsis-vertical"
      color="slate"
      variant="ghost"
      @click="emit('more')"
    />
    <Button :label="buttonLabel" size="sm" @click="emit('message')" />
  </div>
</template>
