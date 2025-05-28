<script setup>
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: {
    type: Number,
    default: 0,
  },
  title: {
    type: String,
    default: 'Untitled',
  },
  url: {
    type: String,
    default: '',
  },
  category: {
    type: String,
    default: '',
  },
  locale: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['insert', 'preview']);

const { t } = useI18n();

const handleInsert = e => {
  e.stopPropagation();
  emit('insert', props.id);
};

const handlePreview = e => {
  e.stopPropagation();
  emit('preview', props.id);
};

const handleCopy = async e => {
  e.stopPropagation();
  await copyTextToClipboard(props.url);
  useAlert(t('CONTACT_PANEL.COPY_SUCCESSFUL'));
};
</script>

<template>
  <button
    class="flex flex-col w-full gap-1 px-2 py-1 bg-white border border-transparent border-solid rounded-md cursor-pointer dark:bg-slate-900 hover:bg-slate-25 hover:dark:bg-slate-800 group focus:outline-none focus:bg-slate-25 focus:border-slate-500 dark:focus:border-slate-400 dark:focus:bg-slate-800"
    @click="handlePreview"
  >
    <h4
      class="w-full mb-0 -mx-1 text-sm rounded-sm ltr:text-left rtl:text-right text-slate-900 dark:text-slate-25 hover:underline group-hover:underline"
    >
      {{ title }}
    </h4>

    <div class="flex content-between items-center gap-0.5 w-full">
      <p
        class="w-full mb-0 text-sm ltr:text-left rtl:text-right text-slate-600 dark:text-slate-300"
      >
        {{ locale }}
        {{ ` / ` }}
        {{ category || $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.UNCATEGORIZED') }}
      </p>
      <div class="flex gap-0.5">
        <Button
          :title="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.COPY_LINK')"
          faded
          slate
          xs
          type="reset"
          icon="i-lucide-copy"
          class="invisible group-hover:visible"
          @click="handleCopy"
        />
        <Button
          xs
          faded
          slate
          :label="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.INSERT_ARTICLE')"
          @click="handleInsert"
        />
      </div>
    </div>
  </button>
</template>
