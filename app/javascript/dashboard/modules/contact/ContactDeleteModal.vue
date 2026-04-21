<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';

import Popover from 'dashboard/components-next/popover/Popover.vue';
import Button from 'dashboard/components-next/button/Button.vue';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from 'dashboard/helper/routeHelpers';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'deleted']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const uiFlags = useMapGetter('contacts/getUIFlags');

const confirmMessage = computed(
  () => `${t('DELETE_CONTACT.CONFIRM.MESSAGE')} ${props.contact.name}?`
);

const onDelete = async hide => {
  try {
    await store.dispatch('contacts/delete', props.contact.id);
    useAlert(t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));
    hide();
    emit('deleted');
    emit('close');

    if (isAConversationRoute(route.name)) {
      router.push({ name: getConversationDashboardRoute(route.name) });
    } else if (isAInboxViewRoute(route.name)) {
      router.push({ name: 'inbox_view' });
    } else if (route.name !== 'contacts_dashboard') {
      router.push({ name: 'contacts_dashboard' });
    }
  } catch (error) {
    useAlert(error.message || t('DELETE_CONTACT.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <Popover @hide="$emit('close')">
    <slot name="trigger" />
    <template #content="{ hide }">
      <div
        class="w-full md:w-80 p-6 flex flex-col gap-4 border-0 md:border rounded-xl md:border-n-strong"
      >
        <div class="flex flex-col gap-2">
          <h3 class="text-base font-medium leading-6 text-n-slate-12">
            {{ $t('DELETE_CONTACT.CONFIRM.TITLE') }}
          </h3>
          <p class="mb-0 text-sm text-n-slate-11">
            {{ confirmMessage }}
          </p>
        </div>
        <div class="flex items-center justify-end gap-2">
          <Button
            faded
            slate
            sm
            :label="$t('DELETE_CONTACT.CONFIRM.NO')"
            @click="hide"
          />
          <Button
            ruby
            sm
            :label="$t('DELETE_CONTACT.CONFIRM.YES')"
            :is-loading="uiFlags.isDeleting"
            :disabled="uiFlags.isDeleting"
            @click="onDelete(hide)"
          />
        </div>
      </div>
    </template>
  </Popover>
</template>
