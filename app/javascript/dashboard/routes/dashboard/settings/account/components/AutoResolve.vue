<script setup>
import { ref, watch, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextArea from 'next/textarea/TextArea.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DurationInput from 'next/input/DurationInput.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();
const duration = ref(0);
const unit = ref(DURATION_UNITS.MINUTES);
const message = ref('');
const labelToApply = ref('');
const ignoreWaiting = ref(false);
const isEnabled = ref(false);

const { currentAccount, updateAccount } = useAccount();

const labels = useMapGetter('labels/getLabels');

const labelOptions = computed(() =>
  labels.value?.length
    ? labels.value.map(label => ({ label: label.title, value: label.title }))
    : []
);

watch(
  currentAccount,
  () => {
    const {
      auto_resolve_after,
      auto_resolve_message,
      auto_resolve_ignore_waiting,
      auto_resolve_unit,
      auto_resolve_label,
    } = currentAccount.value?.settings || {};

    duration.value = auto_resolve_after;
    message.value = auto_resolve_message;
    ignoreWaiting.value = auto_resolve_ignore_waiting;
    labelToApply.value = auto_resolve_label;

    if (
      auto_resolve_unit &&
      Object.values(DURATION_UNITS).includes(auto_resolve_unit)
    ) {
      unit.value = auto_resolve_unit;
    }

    if (duration.value) {
      isEnabled.value = true;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    await updateAccount(settings);
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.API.ERROR'));
  }
};

const handleSubmit = async () => {
  if (duration.value < 10) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings({
    auto_resolve_after: duration.value,
    auto_resolve_message: message.value,
    auto_resolve_ignore_waiting: ignoreWaiting.value,
    auto_resolve_label: labelToApply.value,
    auto_resolve_unit: unit.value,
  });
};

const handleDisable = async () => {
  duration.value = null;
  message.value = '';

  return updateAccountSettings({
    auto_resolve_after: null,
    auto_resolve_message: '',
    auto_resolve_ignore_waiting: false,
    auto_resolve_label: null,
    auto_resolve_unit: DURATION_UNITS.minutes,
  });
};

const toggleAutoResolve = async () => {
  if (!isEnabled.value) handleDisable();
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="toggleAutoResolve" />
      </div>
    </template>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.HELP')"
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
        :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_LABEL')"
        :help-message="
          t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_HELP')
        "
      >
        <TextArea
          v-model="message"
          class="w-full"
          :placeholder="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_PLACEHOLDER')
          "
        />
      </WithLabel>
      <div class="grid grid-cols-5">
        <WithLabel
          class="col-span-3"
          :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_LABEL.TITLE')"
          :help-message="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_LABEL.DESCRIPTION')
          "
        />

        <div class="flex justify-end items-start gap-1 col-span-2">
          <FilterSelect
            v-model="labelToApply"
            :options="labelOptions"
            :label="$t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_LABEL.PLACEHOLDER')"
            variant="faded"
            class="inline-flex shrink-0"
          />
          <NextButton
            v-if="labelToApply"
            v-tooltip="$t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_LABEL.REMOVE')"
            type="button"
            faded
            sm
            slate
            icon="i-lucide-x"
            @click="labelToApply = ''"
          />
        </div>
      </div>
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_IGNORE_WAITING.LABEL')"
      >
        <template #rightOfLabel>
          <Switch v-model="ignoreWaiting" />
        </template>
        <p class="text-sm ml-px text-n-slate-10 max-w-lg">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_IGNORE_WAITING.HELP') }}
        </p>
      </WithLabel>
      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :label="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.UPDATE_BUTTON')
          "
        />
      </div>
    </form>
  </SectionLayout>
</template>
