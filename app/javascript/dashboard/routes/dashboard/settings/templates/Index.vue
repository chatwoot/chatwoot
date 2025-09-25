<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { useStore } from 'vuex';

import Button from 'dashboard/components-next/button/Button.vue';
import LanguageDropdown from 'dashboard/components-next/LanguageDropdown/LanguageDropdown.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { vOnClickOutside } from '@vueuse/components';
import AddTemplate from './AddTemplate.vue';

const { t } = useI18n();
const store = useStore();

const showAddPopup = ref(false);

// Filter states
const selectedStatus = ref('');
const selectedLanguage = ref('');
const selectedChannelType = ref('');

// Dropdown states
const isStatusDropdownOpen = ref(false);
const isChannelDropdownOpen = ref(false);

// Store-based computed properties
const templates = computed(
  () => store.getters['messageTemplates/getTemplates']
);
const uiFlags = computed(() => store.getters['messageTemplates/getUIFlags']);
const isLoading = computed(() => uiFlags.value.isFetching);
const isDeleting = computed(() => uiFlags.value.isDeleting);

// Filter options for dropdowns
const statusMenuItems = computed(() => [
  {
    action: 'statusSelect',
    value: '',
    label: t('SETTINGS.TEMPLATES.FILTERS.ALL_STATUSES'),
    isSelected: selectedStatus.value === '',
  },
  {
    action: 'statusSelect',
    value: 'approved',
    label: t('SETTINGS.TEMPLATES.FILTERS.APPROVED'),
    isSelected: selectedStatus.value === 'approved',
  },
  {
    action: 'statusSelect',
    value: 'pending',
    label: t('SETTINGS.TEMPLATES.FILTERS.PENDING'),
    isSelected: selectedStatus.value === 'pending',
  },
  {
    action: 'statusSelect',
    value: 'rejected',
    label: t('SETTINGS.TEMPLATES.FILTERS.REJECTED'),
    isSelected: selectedStatus.value === 'rejected',
  },
]);

const channelMenuItems = computed(() => [
  {
    action: 'channelSelect',
    value: '',
    label: t('SETTINGS.TEMPLATES.FILTERS.ALL_CHANNELS'),
    isSelected: selectedChannelType.value === '',
  },
  {
    action: 'channelSelect',
    value: 'Channel::Whatsapp',
    label: 'WhatsApp',
    isSelected: selectedChannelType.value === 'Channel::Whatsapp',
  },
]);

const selectedStatusLabel = computed(() => {
  const selected = statusMenuItems.value.find(
    item => item.value === selectedStatus.value
  );
  return selected
    ? selected.label
    : t('SETTINGS.TEMPLATES.FILTERS.ALL_STATUSES');
});

const selectedChannelLabel = computed(() => {
  const selected = channelMenuItems.value.find(
    item => item.value === selectedChannelType.value
  );
  return selected
    ? selected.label
    : t('SETTINGS.TEMPLATES.FILTERS.ALL_CHANNELS');
});

const filteredTemplates = computed(() => {
  return templates.value.filter(template => {
    const matchesStatus =
      !selectedStatus.value || template.status === selectedStatus.value;
    const matchesLanguage =
      !selectedLanguage.value || template.language === selectedLanguage.value;
    const matchesChannel =
      !selectedChannelType.value ||
      template.channel_type === selectedChannelType.value;

    return matchesStatus && matchesLanguage && matchesChannel;
  });
});

const fetchTemplates = async () => {
  try {
    await store.dispatch('messageTemplates/get');
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.API.FETCH_ERROR'));
  }
};

const openAddPopup = () => {
  showAddPopup.value = true;
};

const hideAddPopup = () => {
  showAddPopup.value = false;
};

const handleStatusAction = ({ value }) => {
  selectedStatus.value = value;
  isStatusDropdownOpen.value = false;
};

const handleChannelAction = ({ value }) => {
  selectedChannelType.value = value;
  isChannelDropdownOpen.value = false;
};

const toggleStatusDropdown = () => {
  isStatusDropdownOpen.value = !isStatusDropdownOpen.value;
};

const toggleChannelDropdown = () => {
  isChannelDropdownOpen.value = !isChannelDropdownOpen.value;
};

const closeStatusDropdown = () => {
  isStatusDropdownOpen.value = false;
};

const closeChannelDropdown = () => {
  isChannelDropdownOpen.value = false;
};

const getStatusColor = status => {
  switch (status) {
    case 'approved':
      return 'text-green-600';
    case 'pending':
      return 'text-yellow-600';
    case 'rejected':
      return 'text-red-600';
    default:
      return 'text-gray-600';
  }
};

const formatCategory = category => {
  return category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const getTemplateIcon = category => {
  switch (category) {
    case 'marketing':
      return 'i-lucide-megaphone';
    case 'authentication':
      return 'i-lucide-shield-check';
    case 'utility':
      return 'i-lucide-settings';
    default:
      return 'i-lucide-message-square';
  }
};

const onKeydown = e => {
  if (showAddPopup.value && e.code === 'Escape') {
    hideAddPopup();
    e.stopPropagation();
  }
};

useEventListener(document, 'keydown', onKeydown);

// Delete confirmation modal
const showDeletePopup = ref(false);
const selectedTemplate = ref({});

const openDelete = template => {
  showDeletePopup.value = true;
  selectedTemplate.value = template;
};

const closeDelete = () => {
  showDeletePopup.value = false;
  selectedTemplate.value = {};
};

const confirmDeletion = async () => {
  try {
    await store.dispatch('messageTemplates/delete', selectedTemplate.value.id);
    useAlert(t('SETTINGS.TEMPLATES.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.DELETE.API.ERROR_MESSAGE'));
  } finally {
    closeDelete();
  }
};

const confirmDeleteTitle = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.TITLE', {
    templateName: selectedTemplate.value.name,
  })
);

const deleteConfirmText = computed(
  () =>
    `${t('SETTINGS.TEMPLATES.DELETE.CONFIRM.YES')} ${selectedTemplate.value.name}`
);

const deleteRejectText = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.NO')
);

const confirmPlaceHolderText = computed(() =>
  t('SETTINGS.TEMPLATES.DELETE.CONFIRM.PLACE_HOLDER', {
    templateName: selectedTemplate.value.name,
  })
);

onMounted(() => {
  fetchTemplates();
});
</script>

<template>
  <div class="flex flex-col w-full h-full font-inter">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.HEADER.TITLE') }}
        </h1>
      </div>
      <div class="relative">
        <Button
          icon="i-lucide-plus"
          blue
          :label="t('SETTINGS.TEMPLATES.ACTIONS.NEW_TEMPLATE')"
          @click="openAddPopup"
        />
        <!-- Add Template Popover -->
        <div v-if="showAddPopup" class="absolute right-0 top-full mt-2 z-50">
          <div
            class="bg-n-alpha-3 border border-n-strong rounded-xl shadow-sm backdrop-blur-[100px] w-96 max-h-[80vh] overflow-auto"
            @click.stop
          >
            <AddTemplate @close="hideAddPopup" />
          </div>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-3 mb-6">
      <!-- Status Filter -->
      <div v-on-click-outside="closeStatusDropdown" class="relative w-48">
        <button
          type="button"
          class="flex items-center justify-between gap-2 h-10 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-2 focus:ring-n-blue-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
          @click="toggleStatusDropdown"
        >
          <span class="truncate">{{ selectedStatusLabel }}</span>
          <Icon
            icon="i-lucide-chevron-down"
            class="size-4 flex-shrink-0 transition-transform"
            :class="{ 'rotate-180': isStatusDropdownOpen }"
          />
        </button>
        <DropdownMenu
          v-if="isStatusDropdownOpen"
          :menu-items="statusMenuItems"
          class="absolute top-full mt-1 left-0 right-0 w-full z-50"
          @action="handleStatusAction"
        />
      </div>

      <!-- Channel Filter -->
      <div v-on-click-outside="closeChannelDropdown" class="relative w-48">
        <button
          type="button"
          class="flex items-center justify-between gap-2 h-10 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-2 focus:ring-n-blue-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
          @click="toggleChannelDropdown"
        >
          <span class="truncate">{{ selectedChannelLabel }}</span>
          <Icon
            icon="i-lucide-chevron-down"
            class="size-4 flex-shrink-0 transition-transform"
            :class="{ 'rotate-180': isChannelDropdownOpen }"
          />
        </button>
        <DropdownMenu
          v-if="isChannelDropdownOpen"
          :menu-items="channelMenuItems"
          class="absolute top-full mt-1 left-0 right-0 w-full z-50"
          @action="handleChannelAction"
        />
      </div>

      <!-- Language Filter -->
      <div class="relative w-48">
        <LanguageDropdown
          v-model="selectedLanguage"
          :placeholder="t('SETTINGS.TEMPLATES.FILTERS.ALL_LANGUAGES')"
          size="md"
          variant="outline"
          show-search
        />
      </div>
    </div>

    <!-- Templates List -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('SETTINGS.TEMPLATES.LOADING')" />
    </div>

    <div
      v-else-if="!filteredTemplates.length"
      class="flex items-center justify-center py-12 text-n-slate-11"
    >
      {{ t('SETTINGS.TEMPLATES.LIST.404') }}
    </div>

    <div v-else class="flex-1 space-y-3">
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="flex items-center justify-between p-4 border border-n-weak rounded-lg bg-n-solid-2 hover:bg-n-solid-3 transition-colors"
      >
        <div class="flex items-center gap-4 flex-1">
          <!-- Template Icon -->
          <div
            class="flex items-center justify-center w-8 h-8 bg-n-solid-3 rounded"
          >
            <span
              :class="getTemplateIcon(template.category)"
              class="size-4 text-n-slate-11"
            />
          </div>

          <!-- Template Details -->
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-1">
              <h3 class="text-sm font-medium text-n-slate-12">
                {{ template.name }}
              </h3>
              <span
                class="text-xs font-medium"
                :class="getStatusColor(template.status)"
              >
                {{
                  template.status.charAt(0).toUpperCase() +
                  template.status.slice(1)
                }}
              </span>
            </div>
            <div class="flex items-center gap-4 text-sm text-n-slate-11">
              <div class="flex items-center gap-1">
                <span
                  :class="getTemplateIcon(template.category)"
                  class="size-3"
                />
                <span>{{ formatCategory(template.category) }}</span>
              </div>
              <div class="flex items-center gap-1">
                <span class="i-lucide-globe size-3" />
                <span>{{ template.language.toUpperCase() }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-1">
          <Button
            v-tooltip.top="$t('SETTINGS.TEMPLATES.ACTIONS.DELETE')"
            icon="i-lucide-trash-2"
            ruby
            xs
            faded
            @click="openDelete(template)"
          />
        </div>
      </div>
    </div>

    <!-- Backdrop for mobile/overlay when popover is open -->
    <div v-if="showAddPopup" class="fixed inset-0 z-40" @click="hideAddPopup" />

    <!-- Delete Confirmation Modal -->
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="confirmDeleteTitle"
      :message="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
      :confirm-value="selectedTemplate.name"
      :confirm-place-holder-text="confirmPlaceHolderText"
      :is-loading="isDeleting"
      @on-confirm="confirmDeletion"
      @on-close="closeDelete"
    />
  </div>
</template>
