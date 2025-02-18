<script setup>
import { ref, computed } from 'vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';

const props = defineProps({
  allLabels: {
    type: Array,
    default: () => [],
  },
  savedLabels: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'remove']);

const { isAdmin } = useAdmin();

const showSearchDropdownLabel = ref(false);

const selectedLabels = computed(() => {
  return props.savedLabels.map(label => label.title);
});

const addItem = label => {
  emit('add', label);
};

const removeItem = label => {
  emit('remove', label);
};

const toggleLabels = () => {
  showSearchDropdownLabel.value = !showSearchDropdownLabel.value;
};

const closeDropdownLabel = () => {
  showSearchDropdownLabel.value = false;
};

const keyboardEvents = {
  KeyL: {
    action: e => {
      toggleLabels();
      e.preventDefault();
    },
  },
  Escape: {
    action: () => closeDropdownLabel(),
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div v-on-clickaway="closeDropdownLabel" class="relative leading-6">
    <AddLabel @add="toggleLabels" />
    <woot-label
      v-for="label in savedLabels"
      :key="label.id"
      :title="label.title"
      :description="label.description"
      show-close
      :color="label.color"
      variant="smooth"
      @remove="removeItem"
    />
    <div class="absolute w-full top-7">
      <div
        :class="{ 'dropdown-pane--open': showSearchDropdownLabel }"
        class="!box-border !w-full dropdown-pane"
      >
        <LabelDropdown
          v-if="showSearchDropdownLabel"
          :account-labels="allLabels"
          :selected-labels="selectedLabels"
          :allow-creation="isAdmin"
          @add="addItem"
          @remove="removeItem"
        />
      </div>
    </div>
  </div>
</template>
