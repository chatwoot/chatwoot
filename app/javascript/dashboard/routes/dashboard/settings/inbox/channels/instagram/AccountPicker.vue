<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import instagramClient from 'dashboard/api/channel/instagramClient';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const props = defineProps({
  connectionToken: { type: String, required: true },
});
defineEmits(['cancel']);

const { t } = useI18n();
const accounts = ref([]);
const selectedAccountId = ref('');
const isLoading = ref(true);
const errorMessage = ref('');
const options = computed(() =>
  accounts.value.map(account => ({
    value: account.id,
    label: account.username,
  }))
);

const showError = error => {
  errorMessage.value =
    error.response?.data?.error ||
    error.response?.data?.message ||
    t('INBOX_MGMT.ADD.INSTAGRAM.ERROR_AUTH');
};

const connectAccount = async () => {
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await instagramClient.connectAccount(
      props.connectionToken,
      selectedAccountId.value
    );
    window.location.href = data.redirect_url;
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
};

onMounted(async () => {
  try {
    const { data } = await instagramClient.fetchAccounts(props.connectionToken);
    accounts.value = data.accounts;
    if (accounts.value.length === 1) {
      selectedAccountId.value = accounts.value[0].id;
      await connectAccount();
    }
  } catch (error) {
    showError(error);
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <div class="flex flex-col items-center gap-4 w-full max-w-lg">
    <h6>{{ t('INBOX_MGMT.ADD.INSTAGRAM.SELECT_ACCOUNT') }}</h6>
    <p v-if="errorMessage" role="alert" class="text-n-ruby-9">
      {{ errorMessage }}
    </p>
    <Select
      v-if="accounts.length > 1"
      v-model="selectedAccountId"
      :options="options"
      :placeholder="t('INBOX_MGMT.ADD.INSTAGRAM.SELECT_ACCOUNT')"
      :aria-label="t('INBOX_MGMT.ADD.INSTAGRAM.SELECT_ACCOUNT')"
      :disabled="isLoading"
    />
    <Button
      :label="t('INBOX_MGMT.ADD.INSTAGRAM.CONNECT_ACCOUNT')"
      :disabled="isLoading || !selectedAccountId"
      :is-loading="isLoading"
      @click="connectAccount"
    />
    <Button
      v-if="!isLoading"
      :label="t('INBOX_MGMT.ADD.INSTAGRAM.START_AGAIN')"
      variant="link"
      @click="$emit('cancel')"
    />
  </div>
</template>
