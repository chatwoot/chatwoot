<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { MESSAGE_VARIABLES } from 'shared/constants/messages';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['insert']);

const { t, te } = useI18n();
const store = useStore();
const customAttributes = useMapGetter('attributes/getAttributes');

const resolveLabel = variable => {
  const labelKey = `VARIABLES.LABELS.${variable.key}`;
  return te(labelKey) ? t(labelKey) : variable.label;
};

const menuItems = computed(() => {
  const standard = MESSAGE_VARIABLES.map(variable => ({
    key: variable.key,
    label: resolveLabel(variable),
    description: variable.label,
  }));

  const custom = (customAttributes.value || []).map(attribute => {
    const prefix =
      attribute.attribute_model === 'conversation_attribute'
        ? 'conversation'
        : 'contact';
    const key = `${prefix}.custom_attribute.${attribute.attribute_key}`;
    return {
      key,
      label: attribute.attribute_display_name || attribute.attribute_key,
      description:
        attribute.attribute_description ||
        attribute.attribute_display_name ||
        attribute.attribute_key,
    };
  });

  return [...standard, ...custom].map(variable => ({
    action: variable.key,
    label: `${variable.label} ({{${variable.key}}})`,
    value: variable.key,
  }));
});

const showMenu = ref(false);

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
  if (!customAttributes.value?.length) {
    store.dispatch('attributes/get');
  }
});

onBeforeUnmount(() => {
  document.removeEventListener('click', onDocumentClick);
});
</script>

<template>
  <div data-insert-variable class="relative inline-flex">
    <NextButton
      type="button"
      sm
      slate
      faded
      icon="i-lucide-braces"
      :label="label || t('VARIABLES.INSERT')"
      @click.prevent="toggleMenu"
    />
    <DropdownMenu
      v-if="showMenu"
      :menu-items="menuItems"
      show-search
      :search-placeholder="t('VARIABLES.SEARCH_PLACEHOLDER')"
      class="left-0 z-50 mt-1 top-full min-w-[16rem]"
      @action="onAction"
    />
  </div>
</template>
