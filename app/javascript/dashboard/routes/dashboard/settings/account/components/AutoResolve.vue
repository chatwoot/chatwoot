<script setup>
import { h, ref, watch, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextArea from 'next/textarea/TextArea.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DurationInput from 'next/input/DurationInput.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const { t } = useI18n();
const duration = ref(0);
const unit = ref(DURATION_UNITS.MINUTES);
const message = ref('');
const labelToApply = ref({});
const ignoreWaiting = ref(false);
const isEnabled = ref(false);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

const labels = useMapGetter('labels/getLabels');

const labelOptions = computed(() =>
  labels.value?.length
    ? labels.value.map(label => ({
        id: label.title,
        name: label.title,
        icon: h('span', {
          class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
          style: { backgroundColor: label.color },
        }),
      }))
    : []
);

const selectedLabelName = computed(() => {
  return labelToApply.value?.name ?? null;
});

watch(
  [currentAccount, labelOptions],
  () => {
    const {
      auto_resolve_after,
      auto_resolve_message,
      auto_resolve_ignore_waiting,
      auto_resolve_label,
    } = currentAccount.value?.settings || {};

    duration.value = auto_resolve_after;
    message.value = auto_resolve_message;
    ignoreWaiting.value = auto_resolve_ignore_waiting;
    // find the correct label option from the list
    // the single select component expects the full label object
    // in our case, the label id and name are both the same
    labelToApply.value = labelOptions.value.find(
      option => option.name === auto_resolve_label
    );

    // Set unit based on duration and its divisibility
    if (duration.value) {
      if (duration.value % (24 * 60) === 0) {
        unit.value = DURATION_UNITS.DAYS;
      } else if (duration.value % 60 === 0) {
        unit.value = DURATION_UNITS.HOURS;
      } else {
        unit.value = DURATION_UNITS.MINUTES;
      }
    }

    if (duration.value) {
      isEnabled.value = true;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    isSubmitting.value = true;
    await updateAccount(settings, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (duration.value < 10) {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings({
    auto_resolve_after: duration.value,
    auto_resolve_message: message.value,
    auto_resolve_ignore_waiting: ignoreWaiting.value,
    auto_resolve_label: selectedLabelName.value,
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
  });
};

const toggleAutoResolve = async () => {
  if (!isEnabled.value) handleDisable();
};
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.TITLE') }}
        </h3>
        <div class="flex justify-end">
          <Switch v-model="isEnabled" @change="toggleAutoResolve" />
        </div>
      </div>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.NOTE') }}
      </p>
    </div>

    <div v-if="isEnabled" class="px-5 py-4">
      <form class="grid gap-5" @submit.prevent="handleSubmit">
        <WithLabel
          :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.LABEL')"
          :help-message="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.DURATION.HELP')"
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
          :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.LABEL')"
          :help-message="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.HELP')"
        >
          <TextArea
            v-model="message"
            class="w-full"
            :placeholder="
              t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.MESSAGE.PLACEHOLDER')
            "
          />
        </WithLabel>
        <WithLabel :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.PREFERENCES')">
          <div
            class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
          >
            <div class="p-3 h-12 flex items-center justify-between">
              <span>
                {{
                  t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.IGNORE_WAITING.LABEL')
                }}
              </span>
              <Switch v-model="ignoreWaiting" />
            </div>
            <div class="p-3 h-12 flex items-center justify-between">
              <span>
                {{ t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.LABEL.LABEL') }}
              </span>
              <SingleSelect
                v-model="labelToApply"
                :options="labelOptions"
                :placeholder="
                  $t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.LABEL.PLACEHOLDER')
                "
                placeholder-icon="i-lucide-chevron-down"
                placeholder-trailing-icon
                variant="faded"
              />
            </div>
          </div>
        </WithLabel>
        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :label="t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE.UPDATE_BUTTON')"
          />
        </div>
      </form>
    </div>
  </div>
</template>
