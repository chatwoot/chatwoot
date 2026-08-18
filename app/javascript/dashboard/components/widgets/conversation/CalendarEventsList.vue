<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import CalendarAPI from 'dashboard/api/integrations/calendar';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EventModal from 'dashboard/routes/dashboard/calendars/EventModal.vue';
import { formatTime } from 'dashboard/helper/calendarTime';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contactId: {
    type: [Number, String],
    default: null,
  },
  contactName: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const events = ref([]);
const connections = ref([]);
const calendars = ref([]);
const isLoading = ref(false);
const modalRef = ref(null);
const selectedConnectionId = ref('');

const hasEvents = computed(() => events.value.length > 0);

const loadConnections = async () => {
  const { data } = await CalendarAPI.getConnections();
  connections.value = (data.payload || []).filter(
    item => item.provider === 'google'
  );
  selectedConnectionId.value = connections.value[0]
    ? String(connections.value[0].id)
    : '';
  if (selectedConnectionId.value) {
    const calendarsResponse = await CalendarAPI.getCalendars(
      selectedConnectionId.value
    );
    calendars.value = calendarsResponse.data.payload || [];
  }
};

const loadEvents = async () => {
  isLoading.value = true;
  try {
    const { data } = await CalendarAPI.getConversationEvents(
      props.conversationId
    );
    events.value = data.payload || [];
  } catch (error) {
    events.value = [];
  } finally {
    isLoading.value = false;
  }
};

const openCreate = () => {
  modalRef.value?.open({
    defaults: {
      connectionId: selectedConnectionId.value,
      calendarId: calendars.value[0]?.id,
      conversationId: props.conversationId,
      contactId: props.contactId,
      contactName: props.contactName,
      sendToContact: true,
    },
  });
};

const openEvent = event => {
  modalRef.value?.open({
    event,
    defaults: {
      conversationId: props.conversationId,
      contactId: props.contactId,
      contactName: props.contactName,
    },
  });
};

watch(
  () => props.conversationId,
  () => {
    loadEvents();
  }
);

onMounted(async () => {
  try {
    await loadConnections();
  } catch (error) {
    useAlert(t('SIDEBAR.CALENDAR_PAGE.LOAD_ERROR'));
  }
  await loadEvents();
});
</script>

<template>
  <div>
    <div class="px-4 pt-3 pb-2">
      <Button
        ghost
        xs
        icon="i-lucide-plus"
        :label="$t('CONVERSATION_SIDEBAR.CALENDAR.NEW')"
        :disabled="!calendars.length"
        @click="openCreate"
      />
    </div>
    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>
    <div v-else-if="!hasEvents" class="flex justify-center p-4">
      <p class="text-sm text-n-slate-11">
        {{ $t('CONVERSATION_SIDEBAR.CALENDAR.EMPTY') }}
      </p>
    </div>
    <ul v-else class="max-h-[300px] overflow-y-auto list-none m-0 p-0">
      <li
        v-for="event in events"
        :key="event.id"
        class="px-4 py-3 border-b border-n-weak last:border-b-0"
        :class="{ 'bg-n-ruby-3/40': event.deleted }"
      >
        <button
          type="button"
          class="w-full text-left"
          @click="openEvent(event)"
        >
          <p
            v-if="event.deleted"
            class="text-[10px] font-medium text-n-ruby-11"
          >
            {{ $t('CONVERSATION_SIDEBAR.CALENDAR.DELETED') }}
          </p>
          <p
            class="text-sm truncate"
            :class="
              event.deleted ? 'text-n-ruby-11 line-through' : 'text-n-slate-12'
            "
          >
            {{ event.summary }}
          </p>
          <p
            class="text-xs"
            :class="event.deleted ? 'text-n-ruby-11/80' : 'text-n-slate-11'"
          >
            {{ formatTime(event.start) }}
            <span v-if="event.deleted_by?.name || event.created_by">
              <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
              · {{ event.deleted_by?.name || event.created_by.name }}
            </span>
          </p>
          <p
            v-if="event.deleted && event.deleted_note"
            class="text-xs text-n-ruby-11 truncate"
          >
            {{ event.deleted_note }}
          </p>
        </button>
      </li>
    </ul>
    <EventModal
      ref="modalRef"
      :connections="connections"
      :calendars="calendars"
      @saved="loadEvents"
    />
  </div>
</template>
