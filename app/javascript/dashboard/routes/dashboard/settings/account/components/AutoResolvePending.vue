<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Editor from 'next/Editor/Editor.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DurationInput from 'next/input/DurationInput.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();
const duration = ref(0);
const unit = ref(DURATION_UNITS.MINUTES);
const message = ref('');
const isEnabled = ref(false);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { auto_resolve_pending_after, auto_resolve_pending_message } =
      currentAccount.value?.settings || {};

    duration.value = auto_resolve_pending_after;
    message.value = auto_resolve_pending_message;

    // Set unit based on duration and its divisibility
    if (duration.value) {
      if (duration.value % (24 * 60) === 0) {
        unit.value = DURATION_UNITS.DAYS;
      } else if (duration.value % 60 === 0) {
        unit.value = DURATION_UNITS.HOURS;
      } else {
        unit.value = DURATION_UNITS.MINUTES;
      }
      isEnabled.value = true;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    isSubmitting.value = true;
    await updateAccount(settings, { silent: true });
    useAlert(
      t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.DURATION.API.SUCCESS')
    );
  } catch (error) {
    useAlert(
      t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.DURATION.API.ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (duration.value < 10) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.DURATION.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings({
    auto_resolve_pending_after: duration.value,
    auto_resolve_pending_message: message.value,
  });
};

const handleDisable = async () => {
  duration.value = null;
  message.value = '';

  return updateAccountSettings({
    auto_resolve_pending_after: null,
    auto_resolve_pending_message: '',
  });
};

const toggleAutoResolvePending = async () => {
  if (!isEnabled.value) handleDisable();
};
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-heading-2 text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.TITLE') }}
        </h3>
        <div class="flex justify-end">
          <Switch v-model="isEnabled" @change="toggleAutoResolvePending" />
        </div>
      </div>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.NOTE') }}
      </p>
    </div>

    <div v-if="isEnabled" class="px-5 py-4">
      <form class="grid gap-5" @submit.prevent="handleSubmit">
        <WithLabel
          :label="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.DURATION.LABEL')
          "
          :help-message="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.DURATION.HELP')
          "
        >
          <div class="gap-2 w-full grid grid-cols-[3fr_1fr]">
            <!-- allow 10 mins to 999 days -->
            <DurationInput
              v-model="duration"
              v-model:unit="unit"
              min="0"
              max="1438560"
              class="w-full"
            />
          </div>
        </WithLabel>
        <WithLabel
          :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.MESSAGE.LABEL')"
          :help-message="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.MESSAGE.HELP')
          "
        >
          <Editor
            v-model="message"
            class="w-full"
            channel-type="Context::NoToolbar"
            enable-variables
            :enable-canned-responses="false"
            :show-character-count="false"
            :placeholder="
              t(
                'GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.MESSAGE.PLACEHOLDER'
              )
            "
          />
        </WithLabel>
        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :label="
              t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_PENDING.UPDATE_BUTTON')
            "
          />
        </div>
      </form>
    </div>
  </div>
</template>
