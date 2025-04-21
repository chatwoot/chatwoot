<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import DurationInput from 'next/input/DurationInput.vue';
import TextArea from 'next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const duration = ref(0);
const autoResolveMessage = ref('');

const { currentAccount, updateAccount } = useAccount();

const durationToDisplay = computed({
  get() {
    return currentAccount.value?.settings?.auto_resolve_after;
  },
  set(value) {
    duration.value = value;
  },
});

const messageToDisplay = computed({
  get() {
    return currentAccount.value?.settings?.auto_resolve_message;
  },
  set(value) {
    autoResolveMessage.value = value;
  },
});

const updateAccountSettings = async settings => {
  try {
    await updateAccount(settings);
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.API.ERROR'));
  }
};

const handleSubmit = async () => {
  return updateAccountSettings({
    auto_resolve_after: duration.value,
    auto_resolve_message: autoResolveMessage.value,
  });
};

const handleDisable = async () => {
  duration.value = null;

  return updateAccountSettings({
    auto_resolve_after: null,
    auto_resolve_message: autoResolveMessage.value,
  });
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE')"
    with-border
  >
    <form class="grid gap-4" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.HELP')"
      >
        <div class="gap-2 w-full grid grid-cols-[3fr_1fr]">
          <!-- allow 0 to 999 days -->
          <DurationInput
            v-model="durationToDisplay"
            min="0"
            max="1439856"
            class="w-full"
          />
        </div>
      </WithLabel>
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_LABEL')"
        :help-message="
          t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_HELP')
        "
      >
        <TextArea
          v-model="messageToDisplay"
          class="w-full"
          :placeholder="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_PLACEHOLDER')
          "
        />
      </WithLabel>
      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :label="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.UPDATE_BUTTON')
          "
        />
        <NextButton
          v-if="durationToDisplay"
          type="button"
          slate
          :label="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.DISABLE_BUTTON')
          "
          @click.prevent="handleDisable"
        />
      </div>
    </form>
  </SectionLayout>
</template>
