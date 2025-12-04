<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';

const { t } = useI18n();

const {
  activeLabels,
  accountLabels,
  addLabelToConversation,
  removeLabelFromConversation,
} = useConversationLabels();

const { isAdmin } = useAdmin();

const conversationUiFlags = useMapGetter('conversationLabels/getUIFlags');

const triggerRef = ref(null);
const dropdownRef = ref(null);
const searchQuery = ref('');

const [openLabelsList, toggleLabels] = useToggle(false);
const [createModalVisible, toggleCreateModal] = useToggle(false);
const [hasEmptySearchResults, setEmptySearchResults] = useToggle(false);

const { positionClasses, updatePosition } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  openLabelsList
);

// Update position of dropdown when labels change
watch(
  activeLabels,
  async () => {
    if (openLabelsList.value) {
      await nextTick();
      updatePosition();
    }
  },
  { deep: true }
);

const keyboardEvents = {
  KeyL: {
    action: e => {
      e.preventDefault();
      toggleLabels();
    },
  },
  Escape: {
    action: () => {
      if (openLabelsList.value) {
        toggleLabels();
      }
    },
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);

const labelMenuItems = computed(() => {
  return accountLabels.value.map(label => ({
    label: label.title,
    value: label.id,
    color: label.color,
    isSelected: activeLabels.value.some(active => active.id === label.id),
    action: 'toggleLabel',
  }));
});

const shouldShowCreateButton = computed(() => {
  return isAdmin.value && searchQuery.value && hasEmptySearchResults.value;
});

const handleLabelAction = ({ value }) => {
  const label = accountLabels.value.find(l => l.id === value);
  if (!label) return;

  const isSelected = activeLabels.value.some(active => active.id === value);

  if (isSelected) {
    removeLabelFromConversation(label.title);
  } else {
    addLabelToConversation(label);
  }
};

const handleSearchUpdate = query => {
  searchQuery.value = query;
  setEmptySearchResults(false);
};

const handleEmptyResults = () => {
  setEmptySearchResults(true);
};

const showCreateModal = () => {
  toggleCreateModal(true);
};

const hideCreateModal = () => {
  toggleCreateModal(false);
};
</script>

<template>
  <div class="flex flex-wrap gap-3 w-full items-start pt-3">
    <Spinner
      v-if="conversationUiFlags.isFetching"
      :size="22"
      class="text-n-slate-10"
    />
    <div v-else class="flex flex-wrap gap-2.5">
      <div
        v-for="(label, index) in activeLabels"
        :key="label ? label.id : index"
        data-label
        :title="label.description"
        class="bg-n-button-color px-2.5 h-8 gap-1.5 rounded-lg -outline-offset-1 outline outline-1 outline-n-container inline-flex items-center flex-shrink-0"
      >
        <span
          class="rounded-sm size-2 flex-shrink-0"
          :style="{ background: label.color }"
        />
        <span class="font-420 text-sm text-n-slate-12 whitespace-nowrap">
          {{ label.title }}
        </span>
      </div>
      <div
        v-on-click-outside="() => toggleLabels(false)"
        class="relative w-fit"
      >
        <Button
          ref="triggerRef"
          :label="$t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON')"
          slate
          sm
          icon="i-lucide-plus"
          :variant="openLabelsList ? 'faded' : 'solid'"
          class="font-460 !-outline-offset-1"
          @click="toggleLabels()"
        />
        <DropdownMenu
          v-if="openLabelsList"
          ref="dropdownRef"
          :menu-items="labelMenuItems"
          show-search
          :search-placeholder="
            $t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')
          "
          class="z-[100] w-56 overflow-y-auto max-h-60"
          :class="positionClasses"
          @action="handleLabelAction"
          @search="handleSearchUpdate"
          @empty="handleEmptyResults"
        >
          <template #thumbnail="{ item }">
            <span
              class="rounded-sm size-2 flex-shrink-0"
              :style="{ background: item.color }"
            />
          </template>
          <template #trailing-icon="{ item }">
            <Icon
              v-if="item.isSelected"
              icon="i-lucide-check"
              class="size-4 text-n-blue-11 flex-shrink-0"
            />
          </template>
          <template #footer>
            <div
              v-if="shouldShowCreateButton"
              class="flex pt-1 w-full border-t border-n-weak"
            >
              <Button
                icon="i-lucide-plus"
                slate
                sm
                ghost
                :label="`${t('CONTACT_PANEL.LABELS.LABEL_SELECT.CREATE_LABEL')}: ${searchQuery}`"
                class="w-full"
                @click="showCreateModal"
              />
            </div>
          </template>
        </DropdownMenu>
        <woot-modal
          v-model:show="createModalVisible"
          :on-close="hideCreateModal"
        >
          <AddLabelModal
            :prefill-title="searchQuery"
            @close="hideCreateModal"
          />
        </woot-modal>
      </div>
    </div>
  </div>
</template>
