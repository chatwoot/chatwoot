<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  inbox: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const announcements = ref([]);
const isLoading = ref(false);
const isSaving = ref(false);

const emptyForm = () => ({
  title: '',
  message: '',
  level: 'info',
  action_url: '',
  starts_at: '',
  ends_at: '',
});

const form = reactive(emptyForm());

const levelOptions = [
  { label: t('INBOX_MGMT.ANNOUNCEMENTS.FORM.LEVEL_INFO'), value: 'info' },
  { label: t('INBOX_MGMT.ANNOUNCEMENTS.FORM.LEVEL_WARNING'), value: 'warning' },
  {
    label: t('INBOX_MGMT.ANNOUNCEMENTS.FORM.LEVEL_CRITICAL'),
    value: 'critical',
  },
];

const fetchAnnouncements = async () => {
  isLoading.value = true;
  try {
    const { data } = await InboxesAPI.getWidgetAnnouncements(props.inbox.id);
    announcements.value = data.payload;
  } catch {
    useAlert(t('INBOX_MGMT.ANNOUNCEMENTS.API.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchAnnouncements);

const createAnnouncement = async () => {
  if (!form.title) return;
  isSaving.value = true;
  try {
    await InboxesAPI.createWidgetAnnouncement(props.inbox.id, {
      ...form,
      action_url: form.action_url || null,
      starts_at: form.starts_at || null,
      ends_at: form.ends_at || null,
    });
    Object.assign(form, emptyForm());
    useAlert(t('INBOX_MGMT.ANNOUNCEMENTS.API.SUCCESS_MESSAGE'));
    await fetchAnnouncements();
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        t('INBOX_MGMT.ANNOUNCEMENTS.API.ERROR_MESSAGE')
    );
  } finally {
    isSaving.value = false;
  }
};

const toggleAnnouncement = async announcement => {
  try {
    await InboxesAPI.updateWidgetAnnouncement(props.inbox.id, announcement.id, {
      enabled: !announcement.enabled,
    });
    announcement.enabled = !announcement.enabled;
  } catch {
    useAlert(t('INBOX_MGMT.ANNOUNCEMENTS.API.ERROR_MESSAGE'));
  }
};

const deleteAnnouncement = async announcement => {
  try {
    await InboxesAPI.deleteWidgetAnnouncement(props.inbox.id, announcement.id);
    announcements.value = announcements.value.filter(
      item => item.id !== announcement.id
    );
    useAlert(t('INBOX_MGMT.ANNOUNCEMENTS.API.DELETE_SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('INBOX_MGMT.ANNOUNCEMENTS.API.ERROR_MESSAGE'));
  }
};

const scheduleLabel = announcement => {
  const format = value =>
    value
      ? new Date(value).toLocaleString()
      : t('INBOX_MGMT.ANNOUNCEMENTS.LIST.ALWAYS');
  if (!announcement.starts_at && !announcement.ends_at) {
    return t('INBOX_MGMT.ANNOUNCEMENTS.LIST.ALWAYS');
  }
  return `${format(announcement.starts_at)} → ${format(announcement.ends_at)}`;
};
</script>

<template>
  <div class="flex flex-col gap-8 mx-8">
    <div class="flex flex-col gap-1">
      <h2 class="text-base font-medium text-n-slate-12">
        {{ $t('INBOX_MGMT.ANNOUNCEMENTS.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ANNOUNCEMENTS.DESCRIPTION') }}
      </p>
    </div>

    <form
      class="flex flex-col gap-4 max-w-xl"
      @submit.prevent="createAnnouncement"
    >
      <Input
        v-model="form.title"
        :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.TITLE_LABEL')"
        :placeholder="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.TITLE_PLACEHOLDER')"
      />
      <TextArea
        v-model="form.message"
        :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.MESSAGE_LABEL')"
        :placeholder="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.MESSAGE_PLACEHOLDER')"
      />
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.ANNOUNCEMENTS.FORM.LEVEL_LABEL') }}
          </span>
          <Select v-model="form.level" :options="levelOptions" />
        </div>
        <Input
          v-model="form.action_url"
          :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.URL_LABEL')"
          placeholder="https://status.example.com"
        />
      </div>
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.starts_at"
          type="datetime-local"
          :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.STARTS_AT_LABEL')"
        />
        <Input
          v-model="form.ends_at"
          type="datetime-local"
          :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.ENDS_AT_LABEL')"
        />
      </div>
      <div>
        <NextButton
          :is-loading="isSaving"
          :disabled="!form.title"
          :label="$t('INBOX_MGMT.ANNOUNCEMENTS.FORM.SUBMIT')"
          type="submit"
        />
      </div>
    </form>

    <div class="flex flex-col gap-2 max-w-xl">
      <h3 class="text-sm font-medium text-n-slate-12">
        {{ $t('INBOX_MGMT.ANNOUNCEMENTS.LIST.TITLE') }}
      </h3>
      <div v-if="isLoading" class="flex justify-center py-6">
        <Spinner />
      </div>
      <p v-else-if="!announcements.length" class="text-sm text-n-slate-11 py-2">
        {{ $t('INBOX_MGMT.ANNOUNCEMENTS.LIST.EMPTY') }}
      </p>
      <div
        v-for="announcement in announcements"
        :key="announcement.id"
        class="flex items-center gap-3 px-4 py-3 border border-n-weak rounded-xl bg-n-solid-1"
      >
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium text-n-slate-12 truncate">
              {{ announcement.title }}
            </span>
            <span
              class="text-xs px-1.5 py-0.5 rounded-md capitalize"
              :class="{
                'bg-n-blue-3 text-n-blue-11': announcement.level === 'info',
                'bg-n-amber-3 text-n-amber-11':
                  announcement.level === 'warning',
                'bg-n-ruby-3 text-n-ruby-11': announcement.level === 'critical',
              }"
            >
              {{ announcement.level }}
            </span>
          </div>
          <p class="text-xs text-n-slate-11 truncate">
            {{ scheduleLabel(announcement) }}
          </p>
        </div>
        <Switch
          :model-value="announcement.enabled"
          @update:model-value="toggleAnnouncement(announcement)"
        />
        <NextButton
          ghost
          ruby
          icon="i-lucide-trash-2"
          @click="deleteAnnouncement(announcement)"
        />
      </div>
    </div>
  </div>
</template>
