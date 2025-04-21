<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import DurationInput from 'next/input/DurationInput.vue';
import TextAreaNext from 'next/textarea/TextArea.vue';

const { t } = useI18n();

const duration = ref(0);

const handleSubmit = () => {
  // Add submit handling logic here
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
            v-model="duration"
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
        <TextAreaNext
          class="w-full"
          :placeholder="
            t('GENERAL_SETTINGS.FORM.AUTO_RESOLVE_DURATION.MESSAGE_PLACEHOLDER')
          "
        />
      </WithLabel>
    </form>
  </SectionLayout>
</template>
