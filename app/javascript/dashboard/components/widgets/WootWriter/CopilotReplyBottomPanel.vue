<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

import NextButton from 'dashboard/components-next/button/Button.vue';
import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

defineProps({
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel', 'acceptAndSend']);

const ACCEPT_ACTIONS = {
  ACCEPT: 'accept',
  ACCEPT_AND_SEND: 'accept_and_send',
};

const { t } = useI18n();

const selectedAction = ref(ACCEPT_ACTIONS.ACCEPT);
const arrowDownButtonRef = ref(null);
const [showActionsDropdown, toggleDropdown] = useToggle();

const closeDropdown = () => toggleDropdown(false);
const openDropdown = () => toggleDropdown(true);

const handleCancel = () => {
  emit('cancel');
};

const shortcutKey = useKbd(['$mod', '+', 'enter']);

const acceptLabel = computed(() => {
  const label =
    selectedAction.value === ACCEPT_ACTIONS.ACCEPT
      ? t('GENERAL.ACCEPT')
      : t('GENERAL.ACCEPT_AND_SEND');
  return `${label}  (${shortcutKey.value})`;
});

const handleSubmit = () => {
  if (selectedAction.value === ACCEPT_ACTIONS.ACCEPT_AND_SEND) {
    emit('acceptAndSend');
  } else {
    emit('submit');
  }
};

const menuItems = computed(() => [
  {
    label: t('GENERAL.ACCEPT_SUGGESTION'),
    action: ACCEPT_ACTIONS.ACCEPT,
    value: ACCEPT_ACTIONS.ACCEPT,
    disabled: selectedAction.value === ACCEPT_ACTIONS.ACCEPT,
  },
  {
    label: t('GENERAL.ACCEPT_AND_SEND'),
    action: ACCEPT_ACTIONS.ACCEPT_AND_SEND,
    value: ACCEPT_ACTIONS.ACCEPT_AND_SEND,
    disabled: selectedAction.value === ACCEPT_ACTIONS.ACCEPT_AND_SEND,
  },
]);

const handleAction = ({ action }) => {
  selectedAction.value = action;
  LocalStorage.set(LOCAL_STORAGE_KEYS.COPILOT_ACCEPT_ACTION, action);
  closeDropdown();
};

onMounted(() => {
  const savedAction = LocalStorage.get(
    LOCAL_STORAGE_KEYS.COPILOT_ACCEPT_ACTION
  );
  if (savedAction && Object.values(ACCEPT_ACTIONS).includes(savedAction)) {
    selectedAction.value = savedAction;
  }
});
</script>

<template>
  <div class="flex justify-between items-center p-3 pt-0">
    <NextButton
      :label="t('GENERAL.DISCARD')"
      slate
      link
      class="!px-1 hover:!no-underline"
      sm
      :disabled="isGeneratingContent"
      @click="handleCancel"
    />
    <div class="relative flex items-center justify-end">
      <ButtonGroup
        class="rounded-lg shadow outline-1 outline flex-shrink-0 outline-n-container"
      >
        <NextButton
          :label="acceptLabel"
          class="bg-n-iris-9 text-white ltr:rounded-r-none rtl:rounded-l-none !outline-0"
          solid
          sm
          no-animation
          :disabled="isGeneratingContent"
          @click="handleSubmit"
        />
        <NextButton
          ref="arrowDownButtonRef"
          icon="i-lucide-chevron-down"
          :disabled="isGeneratingContent"
          size="sm"
          no-animation
          class="bg-n-iris-9 text-white ltr:rounded-l-none rtl:rounded-r-none !outline-0"
          trailing-icon
          @click="openDropdown"
        />
      </ButtonGroup>
      <DropdownMenu
        v-if="showActionsDropdown"
        v-on-clickaway="closeDropdown"
        :menu-items="menuItems"
        class="bottom-full mb-0.5 start-0 xl:start-auto xl:end-0"
        @action="handleAction"
      />
    </div>
  </div>
</template>
