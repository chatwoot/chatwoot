<script setup>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, maxLength, helpers } from '@vuelidate/validators';
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import NextButton from 'dashboard/components-next/button/Button.vue';
import LanguageDropdown from 'dashboard/components-next/LanguageDropdown/LanguageDropdown.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['close']);

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const templateName = ref('');
const selectedLanguage = ref('en');
const selectedChannelType = ref('Channel::Whatsapp');
const selectedCategory = ref('utility');
const selectedInbox = ref(null);
const isInboxDropdownOpen = ref(false);
const isCategoryDropdownOpen = ref(false);

const channelTypes = [
  {
    value: 'Channel::Whatsapp',
    label: 'WhatsApp',
    icon: 'i-ri-whatsapp-fill',
  },
];

// Category options with icons
const categoryTypes = [
  {
    value: 'utility',
    label: t('SETTINGS.TEMPLATES.ADD.FORM.CATEGORY.OPTIONS.UTILITY'),
    icon: 'i-lucide-settings',
  },
  {
    value: 'marketing',
    label: t('SETTINGS.TEMPLATES.ADD.FORM.CATEGORY.OPTIONS.MARKETING'),
    icon: 'i-lucide-megaphone',
  },
  {
    value: 'authentication',
    label: t('SETTINGS.TEMPLATES.ADD.FORM.CATEGORY.OPTIONS.AUTHENTICATION'),
    icon: 'i-lucide-shield-check',
    disabled: true,
  },
];

// Transform categories for DropdownMenu format
const categoryMenuItems = computed(() => {
  return categoryTypes.map(category => ({
    action: 'categorySelect',
    value: category.value,
    label: category.label,
    icon: category.icon,
    isSelected: selectedCategory.value === category.value,
    disabled: category.disabled,
  }));
});

const selectedCategoryLabel = computed(() => {
  const selected = categoryTypes.find(
    cat => cat.value === selectedCategory.value
  );
  return selected
    ? selected.label
    : t('SETTINGS.TEMPLATES.ADD.FORM.CATEGORY.PLACEHOLDER');
});

// Get WhatsApp inboxes
const allInboxes = useMapGetter('inboxes/getInboxes');
const whatsappInboxes = computed(() =>
  allInboxes.value.filter(inbox => inbox.channel_type === 'Channel::Whatsapp')
);

// Transform inboxes for DropdownMenu format
const inboxMenuItems = computed(() => {
  const inboxOptions = whatsappInboxes.value.map(inbox => ({
    action: 'inboxSelect',
    value: inbox,
    label: inbox.name,
    icon: getInboxIconByType(inbox.channel_type, inbox.medium),
    isSelected: selectedInbox.value?.id === inbox.id,
  }));

  return inboxOptions;
});

const selectedInboxLabel = computed(() => {
  return selectedInbox.value
    ? selectedInbox.value.name
    : t('SETTINGS.TEMPLATES.ADD.FORM.INBOX.PLACEHOLDER');
});

const validationRules = {
  templateName: {
    required,
    minLength: minLength(2),
    maxLength: maxLength(512),
    templateNamePattern: helpers.withMessage(
      () => t('SETTINGS.TEMPLATES.ADD.FORM.NAME.VALIDATION.PATTERN'),
      helpers.regex(/^[a-z0-9_]+$/)
    ),
    noLeadingUnderscore: helpers.withMessage(
      () =>
        t('SETTINGS.TEMPLATES.ADD.FORM.NAME.VALIDATION.NO_LEADING_UNDERSCORE'),
      value => !value || !value.startsWith('_')
    ),
    noTrailingUnderscore: helpers.withMessage(
      () =>
        t('SETTINGS.TEMPLATES.ADD.FORM.NAME.VALIDATION.NO_TRAILING_UNDERSCORE'),
      value => !value || !value.endsWith('_')
    ),
  },
  selectedInbox: {
    required,
  },
};

const v$ = useVuelidate(validationRules, {
  templateName,
  selectedInbox,
});

const isBasicFormValid = computed(() => {
  return (
    !v$.value.$invalid &&
    templateName.value.trim().length > 0 &&
    selectedInbox.value
  );
});

const onClose = () => {
  emit('close');
};

const goToBuilder = () => {
  if (isBasicFormValid.value) {
    // Save configuration to store
    store.dispatch('messageTemplates/setBuilderConfig', {
      name: templateName.value.trim(),
      language: selectedLanguage.value,
      channelType: selectedChannelType.value,
      inboxId: selectedInbox.value.id,
      category: selectedCategory.value,
    });

    // Navigate to builder page without query params
    router.push({ name: 'template_builder' });
    onClose();
  }
};

const handleInboxAction = ({ value }) => {
  selectedInbox.value = value;
  isInboxDropdownOpen.value = false;
  v$.value.selectedInbox.$touch();
};

const toggleInboxDropdown = () => {
  isInboxDropdownOpen.value = !isInboxDropdownOpen.value;
};

const handleCategoryAction = ({ value }) => {
  selectedCategory.value = value;
  isCategoryDropdownOpen.value = false;
};

const toggleCategoryDropdown = () => {
  isCategoryDropdownOpen.value = !isCategoryDropdownOpen.value;
};

const closeCategoryDropdown = () => {
  isCategoryDropdownOpen.value = false;
};

const closeInboxDropdown = () => {
  isInboxDropdownOpen.value = false;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto w-full">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-n-weak">
      <h2 class="text-lg font-semibold text-n-slate-12 mb-1">
        {{ $t('SETTINGS.TEMPLATES.ADD.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ $t('SETTINGS.TEMPLATES.ADD.DESC') }}
      </p>
    </div>

    <!-- Basic Information Form -->
    <div class="flex flex-col w-full p-6 space-y-4">
      <!-- Template Name -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.LABEL') }}
        </label>
        <input
          v-model="templateName"
          type="text"
          :placeholder="$t('SETTINGS.TEMPLATES.ADD.FORM.NAME.PLACEHOLDER')"
          class="w-full px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-5 focus:border-n-blue-5"
          :class="{
            'border-red-500': v$.templateName.$error,
          }"
          @blur="v$.templateName.$touch"
        />
        <span
          v-if="v$.templateName.$error"
          class="text-xs text-red-500 mt-1 block"
        >
          {{ v$.templateName.$errors[0].$message }}
        </span>

        <span
          v-if="!v$.templateName.$error && templateName"
          class="text-xs text-n-slate-11 mt-1 block"
        >
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.NAME.HELP') }}
        </span>
      </div>

      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.LANGUAGE.LABEL') }}
        </label>
        <LanguageDropdown
          v-model="selectedLanguage"
          variant="outline"
          size="md"
          show-search
          :show-all-option="false"
        />
      </div>

      <!-- Category -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.CATEGORY.LABEL') }}
        </label>
        <div v-on-click-outside="closeCategoryDropdown" class="relative w-full">
          <button
            type="button"
            class="flex items-center justify-between gap-2 h-10 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-2 focus:ring-n-blue-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
            @click="toggleCategoryDropdown"
          >
            <div class="flex items-center gap-2">
              <span
                v-if="selectedCategory"
                :class="
                  categoryTypes.find(cat => cat.value === selectedCategory)
                    ?.icon
                "
                class="size-4"
              />
              <span class="truncate">{{ selectedCategoryLabel }}</span>
            </div>
            <Icon
              icon="i-lucide-chevron-down"
              class="size-4 flex-shrink-0 transition-transform"
              :class="{ 'rotate-180': isCategoryDropdownOpen }"
            />
          </button>
          <DropdownMenu
            v-if="isCategoryDropdownOpen"
            :menu-items="categoryMenuItems"
            class="absolute top-full mt-1 left-0 right-0 w-full z-50 max-h-60 overflow-y-auto"
            @action="handleCategoryAction"
          />
        </div>
      </div>

      <!-- Channel Type -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-3">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.CHANNEL_TYPE.LABEL') }}
        </label>

        <!-- Channel Type Selection -->
        <div class="space-y-2">
          <NextButton
            v-for="type in channelTypes"
            :key="type.value"
            :label="type.label"
            :icon="type.icon"
            variant="outline"
            :color="selectedChannelType === type.value ? 'blue' : 'slate'"
            size="sm"
            justify="start"
            class="h-12"
            @click="selectedChannelType = type.value"
          />
        </div>
      </div>

      <!-- Inbox Selection -->
      <div class="w-full">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.INBOX.LABEL') }}
        </label>
        <div v-on-click-outside="closeInboxDropdown" class="relative w-full">
          <button
            type="button"
            class="flex items-center justify-between gap-2 h-10 px-3 text-sm rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-2 focus:ring-n-blue-5 w-full border border-n-weak bg-n-solid-1 hover:bg-n-solid-2"
            :class="{
              'border-red-500': v$.selectedInbox.$error,
            }"
            @click="toggleInboxDropdown"
            @blur="v$.selectedInbox.$touch"
          >
            <span
              class="truncate"
              :class="{ 'text-n-slate-9': !selectedInbox }"
            >
              {{ selectedInboxLabel }}
            </span>
            <Icon
              icon="i-lucide-chevron-down"
              class="size-4 flex-shrink-0 transition-transform"
              :class="{ 'rotate-180': isInboxDropdownOpen }"
            />
          </button>
          <DropdownMenu
            v-if="isInboxDropdownOpen && whatsappInboxes.length > 0"
            :menu-items="inboxMenuItems"
            class="absolute top-full mt-1 left-0 right-0 w-full z-50 max-h-60 overflow-y-auto"
            @action="handleInboxAction"
          />
        </div>
        <span
          v-if="v$.selectedInbox.$error"
          class="text-xs text-red-500 mt-1 block"
        >
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.INBOX.ERROR') }}
        </span>
        <span
          v-if="whatsappInboxes.length === 0"
          class="text-xs text-orange-500 mt-1 block"
        >
          {{ t('SETTINGS.TEMPLATES.ADD.FORM.INBOX.NO_WHATSAPP_INBOX') }}
        </span>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-row justify-end w-full gap-3 pt-4">
        <NextButton
          faded
          slate
          :label="$t('SETTINGS.TEMPLATES.ADD.CANCEL')"
          @click="onClose"
        />
        <NextButton
          :label="$t('SETTINGS.TEMPLATES.ADD.CONTINUE')"
          :disabled="!isBasicFormValid"
          @click="goToBuilder"
        />
      </div>
    </div>
  </div>
</template>
