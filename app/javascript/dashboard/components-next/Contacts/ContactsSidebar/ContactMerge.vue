<script setup>
import { reactive, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useRoute } from 'vue-router';
import { useAlert, useTrack } from 'dashboard/composables';
import ContactAPI from 'dashboard/api/contacts';
import { debounce } from '@chatwoot/utils';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const state = reactive({
  primaryContactId: null,
});

const uiFlags = useMapGetter('contacts/getUIFlags');

const searchResults = ref([]);
const isSearching = ref(false);

const validationRules = {
  primaryContactId: { required },
};

const v$ = useVuelidate(validationRules, state);

const isMergingContact = computed(() => uiFlags.value.isMerging);

const primaryContactList = computed(
  () =>
    searchResults.value?.map(item => ({
      value: item.id,
      label: `(ID: ${item.id}) ${item.name}`,
    })) ?? []
);

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    searchResults.value = [];
    try {
      const {
        data: { payload },
      } = await ContactAPI.search(query);
      searchResults.value = payload.filter(
        contact => contact.id !== props.selectedContact.id
      );
      isSearching.value = false;
    } catch (error) {
      useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SEARCH_ERROR_MESSAGE'));
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const resetState = () => {
  state.primaryContactId = null;
  searchResults.value = [];
  isSearching.value = false;
};

const onMergeContacts = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);

  try {
    await store.dispatch('contacts/merge', {
      childId: props.selectedContact.id || route.params.contactId,
      parentId: state.primaryContactId,
    });
    emit('goToContactsList');
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.SUCCESS_MESSAGE'));
    resetState();
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.SIDEBAR.MERGE.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="flex flex-col gap-8 px-6 py-6">
    <div class="flex flex-col gap-2">
      <h4 class="text-base text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.TITLE') }}
      </h4>
      <p class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.SIDEBAR.MERGE.DESCRIPTION') }}
      </p>
    </div>
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
          v-model="state.primaryContactId"
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
          :has-error="!!v$.primaryContactId.$error"
          :message="
            v$.primaryContactId.$error
              ? t('CONTACTS_LAYOUT.SIDEBAR.MERGE.PRIMARY_REQUIRED_ERROR')
              : ''
          "
          class="[&>div>button]:bg-n-alpha-black2"
          @search="onContactSearch"
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
    <div class="flex items-center justify-between gap-3">
      <Button
        variant="faded"
        color="slate"
        :label="t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="resetState"
      />
      <Button
        :label="t('CONTACTS_LAYOUT.SIDEBAR.MERGE.BUTTONS.CONFIRM')"
        class="w-full"
        :is-loading="isMergingContact"
        :disabled="isMergingContact"
        @click="onMergeContacts"
      />
    </div>
  </div>
</template>
