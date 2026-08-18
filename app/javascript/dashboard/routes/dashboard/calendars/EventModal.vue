<script setup>
import { computed, onUnmounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import CalendarAPI from 'dashboard/api/integrations/calendar';
import SearchAPI from 'dashboard/api/search';
import ContactAPI from 'dashboard/api/contacts';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import {
  SLOT_MINUTES,
  TIMEZONE,
  addMinutesToTime,
  dateAndTimeParts,
  formatTime,
  rangeFromStartEnd,
} from 'dashboard/helper/calendarTime';
import {
  calendarSelectOptions,
  connectionSelectOptions,
} from 'dashboard/helper/calendarLabels';

const props = defineProps({
  connections: {
    type: Array,
    default: () => [],
  },
  calendars: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['saved']);
const { t, locale } = useI18n();
const searchContacts = createContactSearcher();

const dialogRef = ref(null);
const saving = ref(false);
const deleting = ref(false);
const confirmingDelete = ref(false);
const deleteNote = ref('');
const readOnly = ref(false);
const lockHolder = ref('');
const isCreate = ref(true);
const eventId = ref(null);
const etag = ref('');
const connectionId = ref('');
const calendarId = ref('');
const summary = ref('');
const date = ref('');
const time = ref('09:00');
const endTime = ref('09:30');
const tabIndex = ref(0);
const includeMeet = ref(false);
const sendToContact = ref(false);
const contactId = ref(null);
const contactLabel = ref('');
const contactQuery = ref('');
const contactResults = ref([]);
const conversationId = ref('');
const conversationQuery = ref('');
const conversationResults = ref([]);
const createdBy = ref('');
const updatedBy = ref('');
const isDeleted = ref(false);
const activities = ref([]);
const existingMeet = ref(false);
const conversationLocked = ref(false);
const hideConversation = ref(true);
const contactEmail = ref('');
const inviteEmail = ref('');
const saveEmailOnContact = ref(true);
let heartbeatTimer = null;

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const resolveConversationId = (event, defaults) => {
  if (event?.conversation?.id) return String(event.conversation.id);
  if (defaults.conversationId) return String(defaults.conversationId);
  return '';
};

const connectionOptions = computed(() =>
  connectionSelectOptions(props.connections, t)
);

const calendarOptions = computed(() =>
  calendarSelectOptions(props.calendars, t)
);

const modalTabs = computed(() => [
  { label: t('SIDEBAR.CALENDAR_PAGE.MODAL.TAB_EVENT'), value: 'event' },
  {
    label: t('SIDEBAR.CALENDAR_PAGE.MODAL.TAB_ACTIVITY'),
    value: 'activity',
    count: activities.value.length,
  },
]);

const showEventTab = computed(() => isCreate.value || tabIndex.value === 0);

const showConversationField = computed(
  () => !hideConversation.value && !conversationLocked.value
);

const hasContactEmail = computed(() => Boolean(contactEmail.value));

const attendeeEmail = computed(() => {
  if (contactEmail.value) return contactEmail.value;
  const typed = inviteEmail.value.trim();
  return EMAIL_PATTERN.test(typed) ? typed : '';
});

const title = computed(() =>
  isCreate.value
    ? t('SIDEBAR.CALENDAR_PAGE.MODAL.CREATE_TITLE')
    : t('SIDEBAR.CALENDAR_PAGE.MODAL.EDIT_TITLE')
);

const activityLabel = item => {
  const name = item.user?.name || t('SIDEBAR.CALENDAR_PAGE.MODAL.SYSTEM');
  return t(`SIDEBAR.CALENDAR_PAGE.MODAL.ACTIVITY.${item.action}`, { name });
};

const activityStamp = value => {
  if (!value) return '';
  return new Date(value).toLocaleString(locale.value, {
    timeZone: TIMEZONE,
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const activityChange = item => {
  if (item.details?.note) return item.details.note;
  const times = item.details?.start_at;
  if (Array.isArray(times) && times.length === 2) {
    return `${formatTime(times[0])} â†’ ${formatTime(times[1])}`;
  }
  return '';
};

const activityIcon = action =>
  ({
    created: 'i-lucide-plus',
    updated: 'i-lucide-pencil',
    deleted: 'i-lucide-trash-2',
    moved_in_google: 'i-lucide-calendar',
  })[action] || 'i-lucide-dot';

const invalidRange = computed(() =>
  Boolean(time.value && endTime.value && endTime.value <= time.value)
);

const onTabChanged = tab => {
  tabIndex.value = modalTabs.value.findIndex(item => item.value === tab.value);
};

const onStartTimeInput = value => {
  time.value = value;
  if (!endTime.value || endTime.value <= value) {
    endTime.value = addMinutesToTime(value, SLOT_MINUTES);
  }
};

const confirmDisabled = computed(
  () =>
    readOnly.value ||
    saving.value ||
    !summary.value.trim() ||
    !connectionId.value ||
    !calendarId.value ||
    !date.value ||
    !time.value ||
    !endTime.value ||
    invalidRange.value
);

const payload = () => {
  const range = rangeFromStartEnd(date.value, time.value, endTime.value);
  return {
    connection_id: connectionId.value,
    calendar_id: calendarId.value,
    summary: summary.value.trim(),
    start: range.start,
    end: range.end,
    etag: etag.value,
    contact_id: contactId.value,
    conversation_id: conversationId.value || undefined,
    include_meet: includeMeet.value && !existingMeet.value,
    send_to_contact: sendToContact.value,
    attendee_email: attendeeEmail.value || undefined,
  };
};

const stopHeartbeat = () => {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
};

const releaseLock = async () => {
  stopHeartbeat();
  if (isCreate.value || !eventId.value || readOnly.value) return;
  try {
    await CalendarAPI.unlockEvent(eventId.value, {
      connection_id: connectionId.value,
    });
  } catch {
    // lock TTL covers abandoned edits
  }
};

const startHeartbeat = () => {
  stopHeartbeat();
  heartbeatTimer = setInterval(async () => {
    if (!eventId.value) return;
    try {
      await CalendarAPI.lockEvent(eventId.value, {
        connection_id: connectionId.value,
        heartbeat: true,
      });
    } catch {
      // ignore; save still uses etag
    }
  }, 60000);
};

const applyEvent = (event, defaults) => {
  isCreate.value = !event;
  eventId.value = event?.id || null;
  etag.value = event?.etag || '';
  connectionId.value = String(
    event?.connection_id ||
      defaults.connectionId ||
      props.connections[0]?.id ||
      ''
  );
  calendarId.value = event?.calendar_id || defaults.calendarId || '';
  summary.value = event?.summary || '';
  const parts = dateAndTimeParts(event?.start || defaults.start);
  date.value = parts.date;
  time.value = parts.time;
  endTime.value = event
    ? dateAndTimeParts(event.end).time
    : addMinutesToTime(parts.time, defaults.duration || SLOT_MINUTES);
  includeMeet.value = Boolean(event?.meet_link);
  existingMeet.value = Boolean(event?.meet_link);
  sendToContact.value = Boolean(defaults.sendToContact);
  contactId.value = event?.contact?.id || defaults.contactId || null;
  contactLabel.value = event?.contact?.name || defaults.contactName || '';
  contactQuery.value = contactLabel.value;
  conversationId.value = resolveConversationId(event, defaults);
  conversationLocked.value = Boolean(defaults.conversationId);
  hideConversation.value =
    Boolean(defaults.hideConversation) && !defaults.conversationId;
  contactEmail.value = event?.contact?.email || defaults.contactEmail || '';
  inviteEmail.value = contactEmail.value;
  saveEmailOnContact.value = !contactEmail.value;
  createdBy.value = event?.created_by?.name || '';
  updatedBy.value = event?.updated_by?.name || '';
  activities.value = event?.activities || [];
  isDeleted.value = Boolean(event?.deleted);
  deleteNote.value = event?.deleted_note || '';
  confirmingDelete.value = false;
  readOnly.value = isDeleted.value;
  lockHolder.value = event?.deleted_by?.name || '';
  tabIndex.value = isDeleted.value ? 1 : 0;
};

const acquireLock = async () => {
  if (isCreate.value || !eventId.value || isDeleted.value) return;
  try {
    await CalendarAPI.lockEvent(eventId.value, {
      connection_id: connectionId.value,
    });
    startHeartbeat();
  } catch (error) {
    if (error.response?.status === 423) {
      readOnly.value = true;
      lockHolder.value = error.response?.data?.payload?.name || '';
      useAlert(
        error.response?.data?.error ||
          t('SIDEBAR.CALENDAR_PAGE.MODAL.LOCKED', { name: lockHolder.value })
      );
      return;
    }
    useAlert(t('SIDEBAR.CALENDAR_PAGE.MODAL.LOCK_ERROR'));
  }
};

const open = async ({ event = null, defaults = {} } = {}) => {
  applyEvent(event, defaults);
  if (defaults.dateKey) {
    date.value = defaults.dateKey;
    time.value = `${String(defaults.hours ?? 9).padStart(2, '0')}:${String(defaults.minutes ?? 0).padStart(2, '0')}`;
    endTime.value = addMinutesToTime(time.value, SLOT_MINUTES);
  }
  if (defaults.startIso) {
    const parts = dateAndTimeParts(defaults.startIso);
    date.value = parts.date;
    time.value = parts.time;
    endTime.value = addMinutesToTime(parts.time, SLOT_MINUTES);
  }
  dialogRef.value?.open();
  await acquireLock();
};

const close = async () => {
  await releaseLock();
  dialogRef.value?.close();
};

const onSearchContacts = async query => {
  contactQuery.value = query;
  if (query !== contactLabel.value) {
    contactId.value = null;
    contactLabel.value = '';
    contactEmail.value = '';
  }
  contactResults.value = await searchContacts(query, {
    skipMinLength: false,
    reachableOnly: false,
  });
};

const selectContact = contact => {
  contactId.value = contact.id;
  contactLabel.value = contact.name;
  contactQuery.value = contact.name;
  contactEmail.value = contact.email || '';
  inviteEmail.value = contact.email || '';
  saveEmailOnContact.value = !contact.email;
  contactResults.value = [];
};

const onSearchConversations = async query => {
  conversationQuery.value = query;
  if (!query || query.length < 2) {
    conversationResults.value = [];
    return;
  }
  try {
    const { data } = await SearchAPI.conversations({ q: query });
    conversationResults.value = data.payload?.conversations || [];
  } catch {
    conversationResults.value = [];
  }
};

const selectConversation = conversation => {
  conversationId.value = String(conversation.id);
  conversationQuery.value = `#${conversation.id}`;
  conversationResults.value = [];
  if (conversation.contact && !contactId.value) {
    contactId.value = conversation.contact.id;
    contactLabel.value = conversation.contact.name;
    contactQuery.value = conversation.contact.name;
    contactEmail.value = conversation.contact.email || '';
    inviteEmail.value = contactEmail.value;
    saveEmailOnContact.value = !contactEmail.value;
  }
};

const persistContactEmail = async () => {
  if (
    !contactId.value ||
    contactEmail.value ||
    !saveEmailOnContact.value ||
    !attendeeEmail.value
  ) {
    return;
  }
  await ContactAPI.update(contactId.value, { email: attendeeEmail.value });
  contactEmail.value = attendeeEmail.value;
};

const save = async () => {
  if (confirmDisabled.value) return;
  saving.value = true;
  try {
    await persistContactEmail();
    let savedEvent = null;
    if (isCreate.value) {
      const { data } = await CalendarAPI.createEvent(payload());
      savedEvent = data.payload;
      useAlert(t('SIDEBAR.CALENDAR_PAGE.MODAL.CREATE_SUCCESS'));
    } else {
      const { data } = await CalendarAPI.updateEvent(eventId.value, payload());
      savedEvent = data.payload;
      useAlert(t('SIDEBAR.CALENDAR_PAGE.MODAL.UPDATE_SUCCESS'));
    }
    emit('saved', savedEvent);
    await close();
  } catch (error) {
    useAlert(
      error.response?.data?.error || t('SIDEBAR.CALENDAR_PAGE.MODAL.SAVE_ERROR')
    );
  } finally {
    saving.value = false;
  }
};

const remove = async () => {
  if (isCreate.value || readOnly.value) return;
  if (!confirmingDelete.value) {
    confirmingDelete.value = true;
    return;
  }
  if (!deleteNote.value.trim()) {
    useAlert(t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_NOTE_REQUIRED'));
    return;
  }
  deleting.value = true;
  try {
    const { data } = await CalendarAPI.deleteEvent(eventId.value, {
      connection_id: connectionId.value,
      calendar_id: calendarId.value,
      etag: etag.value,
      note: deleteNote.value.trim(),
    });
    useAlert(t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_SUCCESS'));
    emit('saved', {
      ...(data?.payload || { id: eventId.value }),
      deleted: true,
    });
    confirmingDelete.value = false;
    await close();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_ERROR')
    );
  } finally {
    deleting.value = false;
  }
};

onUnmounted(() => {
  stopHeartbeat();
});

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="lg"
    body-scroll
    :title="title"
    :is-loading="saving"
    :disable-confirm-button="confirmDisabled"
    :confirm-button-label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.SAVE')"
    :show-confirm-button="!readOnly && showEventTab && !confirmingDelete"
    @confirm="save"
    @close="releaseLock"
  >
    <div class="flex flex-col gap-4">
      <p
        v-if="isDeleted"
        class="rounded-lg bg-n-ruby-3/80 px-3 py-2 text-sm text-n-ruby-11"
      >
        <span class="block font-medium">
          {{ $t('SIDEBAR.CALENDAR_PAGE.DELETED') }}
        </span>
        <span v-if="lockHolder" class="block text-xs mt-0.5">
          {{
            $t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETED_BY', { name: lockHolder })
          }}
        </span>
        <span v-if="deleteNote" class="block text-xs mt-0.5">
          {{ deleteNote }}
        </span>
      </p>
      <p
        v-else-if="readOnly"
        class="rounded-lg bg-n-amber-3 px-3 py-2 text-sm text-n-amber-11"
      >
        {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.LOCKED', { name: lockHolder }) }}
      </p>
      <TabBar
        v-if="!isCreate"
        :tabs="modalTabs"
        :initial-active-tab="tabIndex"
        @tab-changed="onTabChanged"
      />
      <template v-if="showEventTab">
        <Input
          v-model="summary"
          :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.TITLE')"
          :placeholder="$t('SIDEBAR.CALENDAR_PAGE.MODAL.TITLE_PLACEHOLDER')"
          :disabled="readOnly"
        />
        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1 min-w-0">
            <span class="mb-0.5 text-sm font-medium text-n-slate-12">
              {{ $t('SIDEBAR.CALENDAR_PAGE.ACCOUNT') }}
            </span>
            <SelectInput
              v-model="connectionId"
              full-width
              :options="connectionOptions"
              :placeholder="$t('SIDEBAR.CALENDAR_PAGE.ACCOUNT')"
              disabled
            />
          </div>
          <div class="flex flex-col gap-1 min-w-0">
            <span class="mb-0.5 text-sm font-medium text-n-slate-12">
              {{ $t('SIDEBAR.CALENDAR_PAGE.CALENDAR') }}
            </span>
            <SelectInput
              v-model="calendarId"
              full-width
              :options="calendarOptions"
              :placeholder="$t('SIDEBAR.CALENDAR_PAGE.CALENDAR')"
              :disabled="readOnly || !isCreate"
            />
          </div>
        </div>
        <div class="grid grid-cols-3 gap-3">
          <Input
            v-model="date"
            type="date"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.DATE')"
            :disabled="readOnly"
          />
          <Input
            :model-value="time"
            type="time"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.START_TIME')"
            :disabled="readOnly"
            @update:model-value="onStartTimeInput"
          />
          <Input
            v-model="endTime"
            type="time"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.END_TIME')"
            :disabled="readOnly"
            :message="
              invalidRange
                ? $t('SIDEBAR.CALENDAR_PAGE.MODAL.INVALID_RANGE')
                : ''
            "
            :message-type="invalidRange ? 'error' : 'info'"
          />
        </div>
        <div class="relative">
          <Input
            :model-value="contactQuery"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.CONTACT')"
            :placeholder="$t('SIDEBAR.CALENDAR_PAGE.MODAL.CONTACT_PLACEHOLDER')"
            :disabled="readOnly"
            @update:model-value="onSearchContacts"
          />
          <ul
            v-if="contactResults.length"
            class="absolute z-20 mt-1 w-full list-none m-0 p-0 rounded-lg border border-n-weak bg-n-solid-2 max-h-40 overflow-auto"
          >
            <li v-for="contact in contactResults" :key="contact.id">
              <button
                type="button"
                class="w-full px-3 py-2 text-left text-sm hover:bg-n-alpha-2"
                @click="selectContact(contact)"
              >
                <span class="block truncate">{{ contact.name }}</span>
                <span
                  v-if="contact.email"
                  class="block text-xs text-n-slate-11 truncate"
                >
                  {{ contact.email }}
                </span>
              </button>
            </li>
          </ul>
        </div>
        <div v-if="!contactId" class="flex flex-col gap-1">
          <Input
            v-model="inviteEmail"
            type="email"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.INVITE_EMAIL')"
            :placeholder="
              $t('SIDEBAR.CALENDAR_PAGE.MODAL.INVITE_EMAIL_PLACEHOLDER')
            "
            :disabled="readOnly"
          />
        </div>
        <p
          v-if="contactId && hasContactEmail"
          class="rounded-lg bg-n-teal-3/50 px-3 py-2 text-sm text-n-teal-11"
        >
          {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.CONTACT_EMAIL') }}
          {{ contactEmail }}
        </p>
        <div
          v-else-if="contactId && !hasContactEmail"
          class="flex flex-col gap-2 rounded-lg border border-n-amber-6 bg-n-amber-3/40 px-3 py-3"
        >
          <p class="text-sm text-n-amber-11">
            {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.NO_EMAIL') }}
          </p>
          <Input
            v-model="inviteEmail"
            type="email"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.INVITE_EMAIL')"
            :placeholder="
              $t('SIDEBAR.CALENDAR_PAGE.MODAL.INVITE_EMAIL_PLACEHOLDER')
            "
            :disabled="readOnly"
          />
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <Checkbox v-model="saveEmailOnContact" :disabled="readOnly" />
            {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.SAVE_EMAIL_ON_CONTACT') }}
          </label>
        </div>
        <div v-if="showConversationField" class="relative">
          <Input
            :model-value="
              conversationQuery || (conversationId ? `#${conversationId}` : '')
            "
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.CONVERSATION')"
            :placeholder="
              $t('SIDEBAR.CALENDAR_PAGE.MODAL.CONVERSATION_PLACEHOLDER')
            "
            :disabled="readOnly"
            @update:model-value="onSearchConversations"
          />
          <ul
            v-if="conversationResults.length"
            class="absolute z-20 mt-1 w-full list-none m-0 p-0 rounded-lg border border-n-weak bg-n-solid-2 max-h-40 overflow-auto"
          >
            <li
              v-for="conversation in conversationResults"
              :key="conversation.id"
            >
              <button
                type="button"
                class="w-full px-3 py-2 text-left text-sm hover:bg-n-alpha-2"
                @click="selectConversation(conversation)"
              >
                #{{ conversation.id }}
                {{ conversation.contact?.name }}
              </button>
            </li>
          </ul>
        </div>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <Checkbox
            v-model="includeMeet"
            :disabled="readOnly || existingMeet"
          />
          {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.MEET') }}
        </label>
        <label
          v-if="conversationId"
          class="flex items-center gap-2 text-sm text-n-slate-12"
        >
          <Checkbox v-model="sendToContact" :disabled="readOnly" />
          {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.SEND_TO_CONTACT') }}
        </label>
      </template>
      <div v-else class="min-h-64 pt-1">
        <p v-if="createdBy || updatedBy" class="mb-4 text-sm text-n-slate-11">
          <span v-if="createdBy" class="block">
            {{
              $t('SIDEBAR.CALENDAR_PAGE.MODAL.CREATED_BY', { name: createdBy })
            }}
          </span>
          <span v-if="updatedBy" class="block text-xs text-n-slate-10">
            {{
              $t('SIDEBAR.CALENDAR_PAGE.MODAL.UPDATED_BY', { name: updatedBy })
            }}
          </span>
        </p>
        <p
          v-if="!activities.length"
          class="py-10 text-sm text-center text-n-slate-11"
        >
          {{ $t('SIDEBAR.CALENDAR_PAGE.MODAL.EMPTY_ACTIVITY') }}
        </p>
        <ol v-else class="flex flex-col list-none m-0 p-0">
          <li
            v-for="(item, index) in activities"
            :key="item.id"
            class="flex gap-3"
          >
            <div class="flex flex-col items-center">
              <span
                class="flex size-8 shrink-0 items-center justify-center rounded-full bg-n-blue-3"
              >
                <Icon
                  :icon="activityIcon(item.action)"
                  class="size-3.5 text-n-blue-11"
                />
              </span>
              <span
                v-if="index < activities.length - 1"
                class="w-px flex-1 bg-n-weak my-1"
              />
            </div>
            <div
              class="min-w-0 pb-5"
              :class="{ 'pb-0': index === activities.length - 1 }"
            >
              <p class="pt-1.5 text-sm font-medium text-n-slate-12">
                {{ activityLabel(item) }}
              </p>
              <p
                v-if="activityChange(item)"
                class="mt-0.5 text-xs text-n-slate-11"
              >
                {{ activityChange(item) }}
              </p>
              <p class="mt-0.5 text-xs text-n-slate-10">
                {{ activityStamp(item.created_at) }}
              </p>
            </div>
          </li>
        </ol>
      </div>
    </div>
    <template v-if="confirmingDelete" #footer>
      <div class="flex flex-col w-full gap-3">
        <Input
          v-model="deleteNote"
          :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_NOTE')"
          :placeholder="
            $t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_NOTE_PLACEHOLDER')
          "
        />
        <div class="flex items-center justify-between w-full gap-3">
          <Button
            faded
            slate
            class="w-full"
            :label="$t('DIALOG.BUTTONS.CANCEL')"
            type="button"
            @click="confirmingDelete = false"
          />
          <Button
            ruby
            class="w-full"
            :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE_CONFIRM')"
            :is-loading="deleting"
            :disabled="!deleteNote.trim()"
            type="button"
            @click="remove"
          />
        </div>
      </div>
    </template>
    <template v-else-if="!isCreate && !readOnly && showEventTab" #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          faded
          ruby
          class="w-full"
          :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.DELETE')"
          :is-loading="deleting"
          type="button"
          @click="remove"
        />
        <Button
          faded
          slate
          class="w-full"
          :label="$t('DIALOG.BUTTONS.CANCEL')"
          type="button"
          @click="close"
        />
        <Button
          blue
          class="w-full"
          :label="$t('SIDEBAR.CALENDAR_PAGE.MODAL.SAVE')"
          :is-loading="saving"
          :disabled="confirmDisabled"
          type="button"
          @click="save"
        />
      </div>
    </template>
  </Dialog>
</template>
