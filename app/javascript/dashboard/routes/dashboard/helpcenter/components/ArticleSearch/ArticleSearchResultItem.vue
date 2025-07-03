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
    class="flex flex-col w-full gap-1 px-2 py-1 border border-transparent border-solid rounded-md cursor-pointer hover:bg-n-slate-3 group focus:outline-none focus:bg-n-slate-3"
    @click="handlePreview"
  >
    <h4
      class="w-full mb-0 -mx-1 text-sm rounded-sm ltr:text-left rtl:text-right text-n-slate-12 hover:underline group-hover:underline"
    >
      {{ title }}
    </h4>

    <div class="flex content-between items-center gap-0.5 w-full">
      <p
        class="w-full mb-0 text-sm ltr:text-left rtl:text-right text-n-slate-11"
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
