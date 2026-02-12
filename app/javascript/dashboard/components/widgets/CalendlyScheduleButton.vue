<script setup>
import { ref, computed, onMounted } from 'vue';
import { useFunctionGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CalendlyAPI from 'dashboard/api/integrations/calendly';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const calendlyIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'calendly'
);

const isCalendlyConnected = computed(
  () => calendlyIntegration.value?.enabled || false
);

const showPopover = ref(false);
const eventTypes = ref([]);
const loadingEventTypes = ref(false);
const creatingLink = ref(false);

const fetchEventTypes = async () => {
  try {
    loadingEventTypes.value = true;
    const response = await CalendlyAPI.getEventTypes();
    eventTypes.value = response.data?.event_types || [];
  } catch (e) {
    useAlert(t('CONVERSATION_SIDEBAR.CALENDLY.EVENT_TYPES_ERROR'));
  } finally {
    loadingEventTypes.value = false;
  }
};

const closePopover = () => {
  showPopover.value = false;
};

const togglePopover = async () => {
  if (!showPopover.value && !eventTypes.value.length) {
    await fetchEventTypes();
  }
  showPopover.value = !showPopover.value;
};

const selectEventType = async eventType => {
  try {
    creatingLink.value = true;
    const response = await CalendlyAPI.createSchedulingLink(eventType.uri);
    const bookingUrl = response.data?.booking_url;

    if (bookingUrl) {
      const message = t('CONVERSATION_SIDEBAR.CALENDLY.SCHEDULING_MESSAGE', {
        name: eventType.name,
        url: bookingUrl,
      });

      await store.dispatch('sendMessage', {
        conversationId: props.conversationId,
        message,
      });

      useAlert(t('CONVERSATION_SIDEBAR.CALENDLY.LINK_SENT'));
    }
  } catch (e) {
    useAlert(t('CONVERSATION_SIDEBAR.CALENDLY.LINK_ERROR'));
  } finally {
    creatingLink.value = false;
    closePopover();
  }
};

onMounted(() => {
  store.dispatch('integrations/get', 'calendly');
});
</script>

<template>
  <div v-if="isCalendlyConnected" class="relative">
    <NextButton
      v-tooltip.top-end="$t('CONVERSATION_SIDEBAR.CALENDLY.SCHEDULE_MEETING')"
      icon="i-ph-calendar-plus"
      slate
      faded
      sm
      @click="togglePopover"
    />
    <div
      v-if="showPopover"
      v-on-clickaway="closePopover"
      class="absolute bottom-full left-0 mb-2 w-64 bg-n-solid-2 border border-n-weak rounded-lg shadow-lg z-50"
    >
      <div class="p-3 border-b border-n-weak">
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION_SIDEBAR.CALENDLY.SELECT_EVENT_TYPE') }}
        </h4>
      </div>
      <div class="max-h-48 overflow-y-auto">
        <div
          v-if="loadingEventTypes"
          class="flex justify-center items-center p-4"
        >
          <Spinner size="24" class="text-n-brand" />
        </div>
        <div v-else-if="!eventTypes.length" class="p-3 text-sm text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.CALENDLY.NO_EVENT_TYPES') }}
        </div>
        <template v-else>
          <button
            v-for="eventType in eventTypes"
            :key="eventType.uri"
            :disabled="creatingLink"
            class="w-full text-left px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-3 cursor-pointer disabled:opacity-50 transition-colors"
            @click="selectEventType(eventType)"
          >
            <div class="font-medium">
              {{ eventType.name }}
            </div>
            <div v-if="eventType.duration" class="text-xs text-n-slate-11">
              {{
                $t('CONVERSATION_SIDEBAR.CALENDLY.DURATION', {
                  duration: eventType.duration,
                })
              }}
            </div>
          </button>
        </template>
      </div>
    </div>
  </div>
</template>
