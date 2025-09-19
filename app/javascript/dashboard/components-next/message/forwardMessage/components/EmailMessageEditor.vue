<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { Letter } from 'vue-letter';
import { allowedCssProperties } from 'lettersanitizer';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import EmailMeta from 'dashboard/components-next/message/bubbles/Email/EmailMeta.vue';

import FormattedContent from 'next/message/bubbles/Text/FormattedContent.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

defineProps({
  content: { type: String, default: '' },
  isPlainEmail: { type: Boolean, default: false },
  hasQuotedMessage: { type: Boolean, default: false },
  fullHtml: { type: String, default: '' },
  unquotedHtml: { type: String, default: '' },
  textToShow: { type: String, default: '' },
});

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});

const showQuotedMessage = ref(false);
</script>

<template>
  <div class="flex-1 h-full">
    <Editor
      v-model="modelValue"
      :placeholder="t('FORWARD_MESSAGE_FORM.EMAIL_EDITOR_PLACEHOLDER')"
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4 [&>div]:!bg-transparent h-full [&_.ProseMirror-woot-style]:!max-h-[200px] [&_.ProseMirror-woot-style]:!min-h-fit"
      enable-variables
      :show-character-count="false"
    />
    <div class="px-4 pb-4 flex flex-col gap-2">
      <div class="flex items-center gap-1.5">
        <span class="text-sm text-n-slate-12">
          {{ t('FORWARD_MESSAGE_FORM.FORWARDED_MESSAGE') }}
        </span>
      </div>
      <EmailMeta />
    </div>
    <div class="px-4 pb-4">
      <FormattedContent
        v-if="isPlainEmail"
        class="text-n-slate-12"
        :content="content"
      />
      <template v-else>
        <Letter
          v-if="showQuotedMessage"
          class-name="prose prose-bubble !max-w-none letter-render"
          :allowed-css-properties="[
            ...allowedCssProperties,
            'transform',
            'transform-origin',
          ]"
          :html="fullHtml"
          :text="textToShow"
        />
        <Letter
          v-else
          class-name="prose prose-bubble !max-w-none letter-render"
          :html="unquotedHtml"
          :allowed-css-properties="[
            ...allowedCssProperties,
            'transform',
            'transform-origin',
          ]"
          :text="textToShow"
        />
      </template>
      <button
        v-if="hasQuotedMessage"
        class="text-n-slate-11 px-1 leading-none text-sm bg-n-alpha-black2 text-center flex items-center gap-1 mt-2"
        @click="showQuotedMessage = !showQuotedMessage"
      >
        <template v-if="showQuotedMessage">
          {{ t('FORWARD_MESSAGE_FORM.HIDE_QUOTED_TEXT') }}
        </template>
        <template v-else>
          {{ t('FORWARD_MESSAGE_FORM.SHOW_QUOTED_TEXT') }}
        </template>
        <Icon
          :icon="
            showQuotedMessage ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
          "
        />
      </button>
    </div>
  </div>
</template>
