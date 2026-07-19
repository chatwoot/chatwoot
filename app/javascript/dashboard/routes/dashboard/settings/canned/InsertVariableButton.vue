<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { MESSAGE_VARIABLES } from 'shared/constants/messages';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['insert']);

const { t } = useI18n();
const showMenu = ref(false);

const menuItems = computed(() =>
  MESSAGE_VARIABLES.map(variable => ({
    action: variable.key,
    label: `${variable.label} ({{${variable.key}}})`,
    value: variable.key,
  }))
);

const toggleMenu = () => {
  showMenu.value = !showMenu.value;
};

const closeMenu = () => {
  showMenu.value = false;
};

const onAction = item => {
  emit('insert', item.action);
  closeMenu();
};

const onDocumentClick = event => {
  if (!event.target.closest?.('[data-insert-variable]')) {
    closeMenu();
  }
};

onMounted(() => {
  document.addEventListener('click', onDocumentClick);
});

onBeforeUnmount(() => {
  document.removeEventListener('click', onDocumentClick);
});
</script>

<template>
  <div data-insert-variable class="relative inline-flex">
    <Button
      type="button"
      sm
      slate
      faded
      icon="i-lucide-braces"
      :label="label || t('CANNED_MGMT.ADD.FORM.INSERT_VARIABLE')"
      @click.prevent="toggleMenu"
    />
    <DropdownMenu
      v-if="showMenu"
      :menu-items="menuItems"
      :show-search="true"
      class="left-0 z-50 mt-1 top-full min-w-[16rem]"
      @action="onAction"
    />
  </div>
</template>
