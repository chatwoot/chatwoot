<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';

import Popover from 'dashboard/components-next/popover/Popover.vue';
import MergeContact from 'dashboard/modules/contact/components/MergeContact.vue';
import ContactAPI from 'dashboard/api/contacts';
import { CONTACTS_EVENTS } from '../../helper/AnalyticsHelper/events';

const props = defineProps({
  primaryContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('contacts/getUIFlags');

const isSearching = ref(false);
const searchResults = ref([]);

watch(
  () => props.primaryContact.id,
  () => {
    isSearching.value = false;
    searchResults.value = [];
  }
);

const onContactSearch = async query => {
  isSearching.value = true;
  searchResults.value = [];

  try {
    const {
      data: { payload },
    } = await ContactAPI.search(query);
    searchResults.value = payload.filter(
      contact => contact.id !== props.primaryContact.id
    );
  } catch (error) {
    useAlert(t('MERGE_CONTACTS.SEARCH.ERROR_MESSAGE'));
  } finally {
    isSearching.value = false;
  }
};

const onMergeContacts = async (parentContactId, hide) => {
  useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);
  try {
    await store.dispatch('contacts/merge', {
      childId: props.primaryContact.id,
      parentId: parentContactId,
    });
    useAlert(t('MERGE_CONTACTS.FORM.SUCCESS_MESSAGE'));
    hide();
    emit('close');
  } catch (error) {
    useAlert(t('MERGE_CONTACTS.FORM.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <Popover @hide="$emit('close')">
    <slot name="trigger" />
    <template #content="{ hide }">
      <div class="w-full md:w-96 p-6 flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <h3 class="text-base font-medium leading-6 text-n-slate-12">
            {{ $t('MERGE_CONTACTS.TITLE') }}
          </h3>
          <p class="mb-0 text-sm text-n-slate-11">
            {{ $t('MERGE_CONTACTS.DESCRIPTION') }}
          </p>
        </div>
        <MergeContact
          :key="primaryContact.id"
          :primary-contact="primaryContact"
          :is-searching="isSearching"
          :is-merging="uiFlags.isMerging"
          :search-results="searchResults"
          @search="onContactSearch"
          @cancel="hide"
          @submit="id => onMergeContacts(id, hide)"
        />
      </div>
    </template>
  </Popover>
</template>
