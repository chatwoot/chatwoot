<script setup>
import { ref, computed, watch } from 'vue';
import { useFunctionGetter, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CalendlyAPI from 'dashboard/api/integrations/calendly';
import CalendlyEventItem from './CalendlyEventItem.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const contactId = computed(() => currentChat.value?.meta?.sender?.id);
const contact = useFunctionGetter('contacts/getContact', contactId);

const events = ref([]);
const loading = ref(true);
const error = ref('');

const contactEmail = computed(() => contact.value?.email);

const fetchEvents = async () => {
  if (!contactEmail.value) {
    loading.value = false;
    return;
  }

  try {
    loading.value = true;
    error.value = '';
    const response = await CalendlyAPI.getScheduledEvents();
    events.value = response.data?.events || response.data?.collection || [];
  } catch (e) {
    error.value = t('CONVERSATION_SIDEBAR.CALENDLY.ERROR');
  } finally {
    loading.value = false;
  }
};

const handleCancelEvent = async eventUuid => {
  try {
    await CalendlyAPI.cancelEvent(eventUuid, 'Canceled from conversation');
    useAlert(t('CONVERSATION_SIDEBAR.CALENDLY.CANCEL_SUCCESS'));
    fetchEvents();
  } catch (e) {
    useAlert(t('CONVERSATION_SIDEBAR.CALENDLY.CANCEL_ERROR'));
  }
};

watch(
  () => props.conversationId,
  () => fetchEvents(),
  { immediate: true }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="!contactEmail" class="text-center text-sm text-n-slate-11">
      {{ $t('CONVERSATION_SIDEBAR.CALENDLY.NO_EMAIL') }}
    </div>
    <div v-else-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>
    <div v-else-if="error" class="text-center text-sm text-n-ruby-12">
      {{ error }}
    </div>
    <div v-else-if="!events.length" class="text-center text-sm text-n-slate-11">
      {{ $t('CONVERSATION_SIDEBAR.CALENDLY.NO_EVENTS') }}
    </div>
    <div v-else>
      <CalendlyEventItem
        v-for="event in events"
        :key="event.uri"
        :event="event"
        @cancel="handleCancelEvent"
      />
    </div>
  </div>
</template>
