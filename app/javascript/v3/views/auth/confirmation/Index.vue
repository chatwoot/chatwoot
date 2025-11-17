<script setup>
import { onMounted } from 'vue';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  confirmationToken: {
    type: String,
    default: '',
  },
});

const confirmToken = async () => {
  try {
    await verifyPasswordToken({
      confirmationToken: props.confirmationToken,
    });
    window.location = DEFAULT_REDIRECT_URL;
  } catch (error) {
    window.location = DEFAULT_REDIRECT_URL;
  }
};

onMounted(() => {
  confirmToken();
});
</script>

<template>
  <div
    class="flex items-center justify-center min-h-screen h-full bg-n-background w-full"
  >
    <Spinner color-scheme="primary" size="" />
    <div class="ml-2 text-n-slate-11">{{ $t('CONFIRM_EMAIL') }}</div>
  </div>
</template>
