<script setup>
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  href: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    required: true,
  },
  value: {
    type: String,
    default: '',
  },
  showCopy: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const onCopy = async e => {
  e.preventDefault();
  await copyTextToClipboard(props.value);
  useAlert(t('CONTACT_PANEL.COPY_SUCCESSFUL'));
};
</script>

<template>
  <div class="grid grid-cols-[30%_1fr] gap-4 w-full items-center h-9">
    <span class="text-body-main text-n-slate-11 truncate whitespace-nowrap">
      {{ title }}
    </span>

    <div class="min-w-0 flex items-center gap-1">
      <a
        v-if="href"
        :href="href"
        class="hover:underline min-w-0 truncate"
        :title="value"
      >
        <span v-if="value" class="text-body-main text-n-slate-12">
          {{ value }}
        </span>
        <span v-else class="text-body-main text-n-slate-10">
          {{ '---' }}
        </span>
      </a>

      <div v-else class="text-body-main text-n-slate-12 min-w-0 truncate">
        <span
          v-if="value"
          v-dompurify-html="value"
          class="text-body-main text-n-slate-12 [&>span]:ltr:ml-1.5 [&>span]:rtl:mr-1.5"
        />
        <span v-else class="text-body-main text-n-slate-10">{{ '---' }}</span>
      </div>

      <NextButton
        v-if="showCopy && value"
        ghost
        xs
        slate
        icon="i-lucide-clipboard"
        class="flex-shrink-0"
        @click="onCopy"
      />
    </div>
  </div>
</template>
