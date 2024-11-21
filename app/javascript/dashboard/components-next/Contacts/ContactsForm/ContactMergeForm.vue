<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { useI18n } from 'vue-i18n';

defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
  primaryContactId: {
    type: [Number, null],
    default: null,
  },
  primaryContactList: {
    type: Array,
    default: () => [],
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  hasError: {
    type: Boolean,
    default: false,
  },
  errorMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:primaryContactId', 'search']);

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col">
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between h-5 gap-2">
        <label class="text-sm text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PRIMARY') }}
        </label>
        <span
          class="flex items-center justify-center w-24 h-5 text-xs rounded-md text-n-teal-11 bg-n-alpha-2"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PRIMARY_HELP_LABEL') }}
        </span>
      </div>
      <ComboBox
        id="inbox"
        :model-value="primaryContactId"
        :options="primaryContactList"
        :empty-state="
          isSearching
            ? t('CONTACTS_LAYOUT.SIDEBAR.MERGE.IS_SEARCHING')
            : t('CONTACTS_LAYOUT.SIDEBAR.MERGE.EMPTY_STATE')
        "
        :search-placeholder="
          t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_PLACEHOLDER')
        "
        :placeholder="t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PLACEHOLDER')"
        :has-error="hasError"
        :message="errorMessage"
        class="[&>div>button]:bg-n-alpha-black2"
        @update:model-value="value => emit('update:primaryContactId', value)"
        @search="query => emit('search', query)"
      />
    </div>
    <div class="relative flex justify-center gap-2 top-4">
      <div v-for="i in 3" :key="i" class="relative w-4 h-8">
        <div
          class="absolute w-0 h-0 border-l-[4px] border-r-[4px] border-b-[6px] border-l-transparent border-r-transparent border-n-strong ltr:translate-x-[4px] rtl:-translate-x-[4px] -translate-y-[4px]"
        />
        <div
          class="absolute w-[1px] h-full bg-n-strong left-1/2 transform -translate-x-1/2"
        />
      </div>
    </div>
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between h-5 gap-2">
        <label class="text-sm text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PARENT') }}
        </label>
        <span
          class="flex items-center justify-center w-24 h-5 text-xs rounded-md text-n-ruby-11 bg-n-alpha-2"
        >
          {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PARENT_HELP_LABEL') }}
        </span>
      </div>
      <div
        class="border border-n-strong h-[60px] gap-2 flex items-center rounded-xl p-3"
      >
        <Avatar
          :name="selectedContact.name || ''"
          :src="selectedContact.thumbnail || ''"
          :size="32"
          rounded-full
        />
        <div class="flex flex-col gap-1">
          <span class="text-sm leading-4 truncate text-n-slate-11">
            {{ selectedContact.name }}
          </span>
          <span class="text-sm leading-4 truncate text-n-slate-11">
            {{ selectedContact.email }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
