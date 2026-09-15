<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const isCreating = ref(false);
const errorMessage = ref('');
const form = reactive({
  name: '',
  corpId: '',
  corpSecret: '',
  openKfid: '',
  callbackToken: '',
  encodingAesKey: '',
});

const canCreate = computed(
  () =>
    Object.values(form).every(value => value.trim()) &&
    form.encodingAesKey.length === 43 &&
    form.callbackToken.length <= 32
);

const createChannel = async () => {
  if (!canCreate.value || isCreating.value) return;

  isCreating.value = true;
  errorMessage.value = '';
  try {
    const inbox = await store.dispatch('inboxes/createChannel', {
      name: form.name.trim(),
      channel: {
        type: 'wechat_kf',
        corp_id: form.corpId.trim(),
        corp_secret: form.corpSecret.trim(),
        open_kfid: form.openKfid.trim(),
        callback_token: form.callbackToken.trim(),
        encoding_aes_key: form.encodingAesKey.trim(),
      },
    });
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: inbox.id },
    });
  } catch (error) {
    errorMessage.value = error.message || t('INBOX_MGMT.ADD.WECHAT_KF.ERROR');
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-5 p-6 max-w-2xl">
    <div class="flex flex-col gap-2">
      <h2 class="text-heading-1 text-n-slate-12">
        {{ t('INBOX_MGMT.ADD.WECHAT_KF.TITLE') }}
      </h2>
      <p class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.WECHAT_KF.DESCRIPTION') }}
      </p>
    </div>
    <form class="flex flex-col gap-4" @submit.prevent="createChannel">
      <Input
        v-model="form.name"
        required
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.NAME')"
      />
      <Input
        v-model="form.corpId"
        required
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.CORP_ID')"
      />
      <Input
        v-model="form.openKfid"
        required
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.OPEN_KFID')"
      />
      <Input
        v-model="form.corpSecret"
        required
        type="password"
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.CORP_SECRET')"
      />
      <Input
        v-model="form.callbackToken"
        required
        type="password"
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.CALLBACK_TOKEN')"
      />
      <Input
        v-model="form.encodingAesKey"
        required
        type="password"
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.ENCODING_AES_KEY')"
      />
      <p class="text-body-small text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.WECHAT_KF.CREDENTIALS_HELP') }}
      </p>
      <p v-if="errorMessage" role="alert" class="text-body-small text-n-ruby-9">
        {{ errorMessage }}
      </p>
      <Button
        type="submit"
        :label="t('INBOX_MGMT.ADD.WECHAT_KF.SUBMIT')"
        :disabled="!canCreate || isCreating"
        :is-loading="isCreating"
        class="self-start"
      />
    </form>
  </div>
</template>
