<script setup>
import { ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import PageHeader from '../../SettingsSubPageHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const name = ref('');
const busy = ref(false);

async function createInbox() {
  if (!name.value.trim() || busy.value) return;
  busy.value = true;
  try {
    const inbox = await store.dispatch('inboxes/createChannel', {
      name: name.value.trim(),
      channel: { type: 'mobile_app' },
    });
    await router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: inbox.id },
    });
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.SDK_APPS.ERROR'));
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="t('INBOX_MGMT.MOBILE_APP.TITLE')"
      :header-content="t('INBOX_MGMT.MOBILE_APP.DESCRIPTION')"
    />
    <form class="flex flex-col gap-4 max-w-xl" @submit.prevent="createInbox">
      <Input v-model="name" :label="t('INBOX_MGMT.ADD.CHANNEL_NAME.LABEL')" />
      <Button
        type="submit"
        :disabled="!name.trim()"
        :is-loading="busy"
        :label="t('INBOX_MGMT.MOBILE_APP.CREATE')"
      />
    </form>
  </div>
</template>
