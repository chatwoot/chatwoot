<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useFunctionGetter, useStore } from 'dashboard/composables/store';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import CalendarAPI from 'dashboard/api/integrations/calendar';
import {
  calendarDisplayName,
  connectionDisplayName,
} from 'dashboard/helper/calendarLabels';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const integration = useFunctionGetter(
  'integrations/getIntegration',
  'calendars'
);

const loaded = ref(false);
const connecting = ref(false);
const connections = ref([]);
const configured = ref(false);
const disconnectTarget = ref(null);
const disconnecting = ref(false);
const dialogRef = ref(null);
const setupId = computed(() => Number(route.query.setup) || null);
const calendarMap = ref({});
const loadingCalendars = ref({});
const savingCalendars = ref({});

const googleConnections = computed(() =>
  connections.value.filter(item => item.provider === 'google')
);

const loadConnections = async () => {
  try {
    const { data } = await CalendarAPI.getConnections();
    connections.value = data.payload || [];
    configured.value = Boolean(data.configured);
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.CALENDARS.LOAD_ERROR'));
  } finally {
    loaded.value = true;
  }
};

const loadCalendarsFor = async connectionId => {
  loadingCalendars.value = { ...loadingCalendars.value, [connectionId]: true };
  try {
    const { data } = await CalendarAPI.getCalendars(connectionId, {
      all: true,
    });
    calendarMap.value = {
      ...calendarMap.value,
      [connectionId]: data.payload || [],
    };
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.CALENDARS.LOAD_ERROR'));
  } finally {
    loadingCalendars.value = {
      ...loadingCalendars.value,
      [connectionId]: false,
    };
  }
};

const hourOptions = Array.from({ length: 24 }, (_, hour) => ({
  value: String(hour),
  label: `${String(hour).padStart(2, '0')}:00`,
}));

const calendarFilter = ref('');

const enabledCount = connectionId =>
  (calendarMap.value[connectionId] || []).filter(item => item.enabled).length;

const filteredCalendars = connectionId => {
  const query = calendarFilter.value.trim().toLowerCase();
  const list = [...(calendarMap.value[connectionId] || [])].sort((a, b) => {
    if (a.enabled !== b.enabled) return a.enabled ? -1 : 1;
    if (a.primary !== b.primary) return a.primary ? -1 : 1;
    return (a.summary || '').localeCompare(b.summary || '');
  });
  if (!query) return list;
  return list.filter(item => {
    const haystack =
      `${item.summary || ''} ${calendarDisplayName(item, t)}`.toLowerCase();
    return haystack.includes(query);
  });
};

const saveCalendars = async (connectionId, { silent = false } = {}) => {
  savingCalendars.value = { ...savingCalendars.value, [connectionId]: true };
  try {
    const calendars = (calendarMap.value[connectionId] || []).map(item => ({
      external_id: item.id,
      summary: item.summary,
      is_enabled: item.enabled,
      hour_start: item.hour_start ?? 8,
      hour_end: item.hour_end ?? 20,
    }));
    const { data } = await CalendarAPI.updateCalendars(connectionId, calendars);
    calendarMap.value = {
      ...calendarMap.value,
      [connectionId]: data.payload || [],
    };
    if (!silent) {
      useAlert(t('INTEGRATION_SETTINGS.CALENDARS.SAVE_SUCCESS'));
    }
    await loadConnections();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INTEGRATION_SETTINGS.CALENDARS.SAVE_ERROR')
    );
    await loadCalendarsFor(connectionId);
  } finally {
    savingCalendars.value = { ...savingCalendars.value, [connectionId]: false };
  }
};

const toggleCalendar = async (connectionId, calendarId, enabled) => {
  const list = (calendarMap.value[connectionId] || []).map(item =>
    item.id === calendarId ? { ...item, enabled } : item
  );
  calendarMap.value = { ...calendarMap.value, [connectionId]: list };
  await saveCalendars(connectionId, { silent: true });
};

const connectGoogle = async () => {
  connecting.value = true;
  try {
    const { data } = await CalendarAPI.startOAuth();
    if (data.url) {
      window.location.href = data.url;
      return;
    }
    useAlert(t('INTEGRATION_SETTINGS.CALENDARS.CONNECT_ERROR'));
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INTEGRATION_SETTINGS.CALENDARS.CONNECT_ERROR')
    );
  } finally {
    connecting.value = false;
  }
};

const openDisconnect = connection => {
  disconnectTarget.value = connection;
  dialogRef.value?.open();
};

const confirmDisconnect = async () => {
  if (!disconnectTarget.value || disconnecting.value) return;
  disconnecting.value = true;
  try {
    await CalendarAPI.disconnect(disconnectTarget.value.id);
    useAlert(t('INTEGRATION_SETTINGS.CALENDARS.DISCONNECT_SUCCESS'));
    disconnectTarget.value = null;
    dialogRef.value?.close();
    await loadConnections();
    await store.dispatch('integrations/get');
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.CALENDARS.DISCONNECT_ERROR'));
    dialogRef.value?.close();
  } finally {
    disconnecting.value = false;
  }
};

const updateHours = async (connectionId, calendarId, field, value) => {
  const hour = Number(value);
  const list = (calendarMap.value[connectionId] || []).map(item => {
    if (item.id !== calendarId) return item;
    const next = { ...item, [field]: hour };
    if (next.hour_end <= next.hour_start) {
      next.hour_end = Math.min(23, next.hour_start + 1);
    }
    return next;
  });
  calendarMap.value = { ...calendarMap.value, [connectionId]: list };
  await saveCalendars(connectionId, { silent: true });
};

onMounted(async () => {
  await store.dispatch('integrations/get', 'calendars');
  await loadConnections();
  await Promise.all(
    googleConnections.value.map(connection => loadCalendarsFor(connection.id))
  );
});
</script>

<template>
  <SettingsLayout :is-loading="!loaded">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.CALENDARS.HEADER')"
        :description="$t('INTEGRATION_SETTINGS.CALENDARS.DESCRIPTION')"
        feature-name="calendar_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-4 max-w-3xl">
        <div
          v-if="!configured"
          class="rounded-xl border border-n-amber-6 bg-n-amber-3/40 px-4 py-3 text-sm text-n-slate-12"
        >
          {{ $t('INTEGRATION_SETTINGS.CALENDARS.NOT_CONFIGURED') }}
        </div>

        <div
          class="flex items-start gap-4 p-5 outline outline-n-container outline-1 bg-n-card rounded-xl"
        >
          <img
            src="dashboard/assets/images/integrations/google-calendar.svg"
            alt="Google Calendar"
            class="h-12 w-12 rounded-md border border-n-weak bg-n-alpha-3"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <h3 class="text-heading-3 text-n-slate-12">
                {{ $t('INTEGRATION_SETTINGS.CALENDARS.GOOGLE') }}
              </h3>
              <span
                v-if="googleConnections.length"
                class="text-xs px-2 py-0.5 rounded-full bg-n-teal-3 text-n-teal-11"
              >
                {{ $t('INTEGRATION_APPS.STATUS.ENABLED') }}
              </span>
            </div>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ integration.description }}
            </p>
          </div>
          <Button
            faded
            blue
            :label="$t('INTEGRATION_SETTINGS.CALENDARS.CONNECT_GOOGLE')"
            :disabled="!configured || connecting"
            :is-loading="connecting"
            @click="connectGoogle"
          />
        </div>

        <div
          v-if="googleConnections.length"
          class="p-5 outline outline-n-container outline-1 bg-n-card rounded-xl"
        >
          <h4 class="mb-3 text-sm font-medium text-n-slate-12">
            {{ $t('INTEGRATION_SETTINGS.CALENDARS.CONNECTED_ACCOUNTS') }}
          </h4>
          <p class="mb-3 text-sm text-n-slate-11">
            {{ $t('INTEGRATION_SETTINGS.CALENDARS.ENABLE_HINT') }}
          </p>
          <div
            v-if="setupId"
            class="mb-3 rounded-lg border border-n-amber-6 bg-n-amber-3/40 px-3 py-2 text-sm text-n-amber-11"
          >
            {{ $t('INTEGRATION_SETTINGS.CALENDARS.TEAM_SHARE_WARNING') }}
          </div>
          <div class="flex flex-col divide-y divide-n-weak">
            <div
              v-for="connection in googleConnections"
              :key="connection.id"
              class="py-4 first:pt-0 last:pb-0"
            >
              <div class="flex items-center justify-between gap-3">
                <div class="flex items-center gap-3 min-w-0">
                  <Avatar
                    :name="connectionDisplayName(connection, t)"
                    :size="36"
                    rounded-full
                    class="shrink-0"
                  />
                  <div class="min-w-0" :title="connection.email">
                    <p class="text-sm font-medium text-n-slate-12 truncate">
                      {{ connectionDisplayName(connection, t) }}
                    </p>
                    <p class="text-xs text-n-slate-11 truncate">
                      {{
                        $t('INTEGRATION_SETTINGS.CALENDARS.ENABLED_COUNT', {
                          count: calendarMap[connection.id]
                            ? enabledCount(connection.id)
                            : connection.enabled_calendars_count || 0,
                        })
                      }}
                    </p>
                  </div>
                </div>
                <Button
                  faded
                  ruby
                  xs
                  type="button"
                  :label="$t('INTEGRATION_SETTINGS.CALENDARS.DISCONNECT')"
                  @click="openDisconnect(connection)"
                />
              </div>
              <div class="mt-3">
                <div
                  v-if="loadingCalendars[connection.id]"
                  class="flex justify-center py-4"
                >
                  <Spinner />
                </div>
                <template v-else>
                  <p
                    v-if="!(calendarMap[connection.id] || []).length"
                    class="text-sm text-n-slate-11"
                  >
                    {{ $t('INTEGRATION_SETTINGS.CALENDARS.NO_WRITABLE') }}
                  </p>
                  <div v-else class="flex flex-col gap-3">
                    <p class="text-xs text-n-slate-11">
                      {{ $t('INTEGRATION_SETTINGS.CALENDARS.TEAM_ONLY_HINT') }}
                    </p>
                    <Input
                      v-model="calendarFilter"
                      size="sm"
                      :placeholder="
                        $t('INTEGRATION_SETTINGS.CALENDARS.SEARCH_CALENDARS')
                      "
                    />
                    <div class="flex flex-col gap-2 max-h-80 overflow-auto">
                      <div
                        v-for="calendar in filteredCalendars(connection.id)"
                        :key="calendar.id"
                        class="flex flex-col gap-2 rounded-lg border px-3 py-2"
                        :class="
                          calendar.enabled
                            ? 'border-n-teal-6 bg-n-teal-3/40'
                            : 'border-n-weak bg-n-alpha-1'
                        "
                      >
                        <div class="flex items-center gap-3">
                          <Checkbox
                            :model-value="calendar.enabled"
                            :disabled="savingCalendars[connection.id]"
                            @update:model-value="
                              toggleCalendar(connection.id, calendar.id, $event)
                            "
                          />
                          <div class="min-w-0 flex-1">
                            <p class="text-sm text-n-slate-12 truncate">
                              {{ calendarDisplayName(calendar, t) }}
                            </p>
                            <p class="text-xs text-n-slate-11">
                              <span v-if="calendar.enabled">
                                {{
                                  $t(
                                    'INTEGRATION_SETTINGS.CALENDARS.VISIBLE_TO_TEAM'
                                  )
                                }}
                              </span>
                              <span v-else>
                                {{
                                  $t(
                                    'INTEGRATION_SETTINGS.CALENDARS.HIDDEN_FROM_TEAM'
                                  )
                                }}
                              </span>
                              <span v-if="calendar.primary">
                                <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
                                ·
                                {{
                                  $t('INTEGRATION_SETTINGS.CALENDARS.PRIMARY')
                                }}
                              </span>
                            </p>
                          </div>
                        </div>
                        <div
                          v-if="calendar.enabled"
                          class="flex items-center gap-2 pl-8"
                        >
                          <span class="text-xs text-n-slate-11 shrink-0">
                            {{ $t('INTEGRATION_SETTINGS.CALENDARS.HOURS') }}
                          </span>
                          <SelectInput
                            :model-value="String(calendar.hour_start ?? 8)"
                            :options="hourOptions"
                            :disabled="savingCalendars[connection.id]"
                            @update:model-value="
                              updateHours(
                                connection.id,
                                calendar.id,
                                'hour_start',
                                $event
                              )
                            "
                          />
                          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
                          <span class="text-xs text-n-slate-11">–</span>
                          <SelectInput
                            :model-value="String(calendar.hour_end ?? 20)"
                            :options="hourOptions"
                            :disabled="savingCalendars[connection.id]"
                            @update:model-value="
                              updateHours(
                                connection.id,
                                calendar.id,
                                'hour_end',
                                $event
                              )
                            "
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </div>
        <p v-else class="text-sm text-n-slate-11">
          {{ $t('INTEGRATION_SETTINGS.CALENDARS.NO_ACCOUNTS') }}
        </p>

        <div
          class="flex items-start gap-4 p-5 outline outline-n-container outline-1 bg-n-card rounded-xl opacity-70"
        >
          <img
            src="dashboard/assets/images/integrations/microsoft.svg"
            alt="Microsoft"
            class="h-12 w-12 rounded-md border border-n-weak bg-n-alpha-3"
          />
          <div class="flex-1">
            <div class="flex items-center gap-2">
              <h3 class="text-heading-3 text-n-slate-12">
                {{ $t('INTEGRATION_SETTINGS.CALENDARS.MICROSOFT') }}
              </h3>
              <span
                class="text-xs px-2 py-0.5 rounded-full bg-n-slate-3 text-n-slate-11"
              >
                {{ $t('INTEGRATION_SETTINGS.CALENDARS.COMING_SOON') }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <Dialog
        ref="dialogRef"
        type="alert"
        :title="$t('INTEGRATION_SETTINGS.CALENDARS.DELETE.TITLE')"
        :description="
          $t('INTEGRATION_SETTINGS.CALENDARS.DELETE.MESSAGE', {
            name: connectionDisplayName(disconnectTarget, t),
          })
        "
        :confirm-button-label="
          $t('INTEGRATION_APPS.DELETE.CONFIRM_BUTTON_TEXT.ACCOUNT')
        "
        :cancel-button-label="$t('INTEGRATION_APPS.DELETE.CANCEL_BUTTON_TEXT')"
        :is-loading="disconnecting"
        @confirm="confirmDisconnect"
      />
    </template>
  </SettingsLayout>
</template>
