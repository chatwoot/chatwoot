<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import WhatsAppInteractivePreview from './WhatsAppInteractivePreview.vue';
import { computed } from 'vue';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({ body: '', buttons: [''] }),
  },
  limits: {
    type: Object,
    default: () => ({
      bodyMaxLength: 1024,
      headerMaxLength: 60,
      footerMaxLength: 60,
      headerTypes: ['text', 'image', 'video', 'document'],
      buttonTitleMaxLength: 20,
      buttonMinCount: 1,
      buttonMaxCount: 3,
    }),
  },
});

const emit = defineEmits(['update:modelValue', 'close', 'upload']);
const mediaHeader = computed(() =>
  ['image', 'video', 'document'].includes(props.modelValue.headerType)
);
const duplicateTitles = computed(() => {
  const titles = props.modelValue.buttons.map(title => title.trim());
  return titles.some(
    (title, index) => title && titles.indexOf(title) !== index
  );
});
const updateHeaderType = headerType => {
  emit('update:modelValue', {
    ...props.modelValue,
    headerType,
    headerText: '',
    media: null,
    uploadFile: null,
  });
};
const upload = event => {
  const file = event.target.files?.[0];
  if (file) emit('upload', file);
  event.target.value = '';
};

const updateBody = body => {
  emit('update:modelValue', { ...props.modelValue, body });
};

const updateButton = (index, title) => {
  const buttons = [...props.modelValue.buttons];
  buttons[index] = title;
  emit('update:modelValue', { ...props.modelValue, buttons });
};

const addButton = () => {
  emit('update:modelValue', {
    ...props.modelValue,
    buttons: [...props.modelValue.buttons, ''],
  });
};

const removeButton = index => {
  emit('update:modelValue', {
    ...props.modelValue,
    buttons: props.modelValue.buttons.filter(
      (_, buttonIndex) => buttonIndex !== index
    ),
  });
};
</script>

<template>
  <section
    class="flex flex-col gap-3 py-3"
    data-testid="whatsapp-interactive-composer"
  >
    <div class="flex items-center justify-between gap-3">
      <div>
        <h3 class="mb-0 text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.TITLE') }}
        </h3>
        <p class="mb-0 text-xs text-n-slate-11">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.DESCRIPTION') }}
        </p>
      </div>
      <Button
        icon="i-ph-x"
        slate
        faded
        xs
        :aria-label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.CLOSE')"
        @click="$emit('close')"
      />
    </div>

    <label for="whatsapp-interactive-header" class="text-sm text-n-slate-12">
      {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER') }}
    </label>
    <select
      id="whatsapp-interactive-header"
      :value="modelValue.headerType || ''"
      class="rounded-lg border border-n-weak bg-n-surface-1 text-sm mb-0"
      @change="updateHeaderType($event.target.value)"
    >
      <option value="">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_NONE') }}
      </option>
      <option v-if="limits.headerTypes?.includes('text')" value="text">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_TEXT') }}
      </option>
      <option v-if="limits.headerTypes?.includes('image')" value="image">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_IMAGE') }}
      </option>
      <option v-if="limits.headerTypes?.includes('video')" value="video">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_VIDEO') }}
      </option>
      <option v-if="limits.headerTypes?.includes('document')" value="document">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_DOCUMENT') }}
      </option>
    </select>
    <Input
      v-if="modelValue.headerType === 'text'"
      id="whatsapp-interactive-header-text"
      :model-value="modelValue.headerText"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_TEXT')"
      :maxlength="limits.headerMaxLength"
      :message="`${modelValue.headerText?.length || 0}/${limits.headerMaxLength}`"
      @update:model-value="
        $emit('update:modelValue', { ...modelValue, headerText: $event })
      "
    />
    <div v-if="mediaHeader" class="flex flex-col gap-2">
      <label for="whatsapp-interactive-upload" class="text-sm text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.UPLOAD') }}
      </label>
      <input
        id="whatsapp-interactive-upload"
        :key="modelValue.headerType"
        type="file"
        :accept="
          modelValue.headerType === 'document'
            ? undefined
            : `${modelValue.headerType}/*`
        "
        class="text-sm text-n-slate-11"
        @change="upload"
      />
      <p v-if="modelValue.media" class="mb-0 text-xs text-n-slate-11">
        {{ modelValue.media.name }}
      </p>
      <Button
        v-if="modelValue.media"
        class="self-start"
        icon="i-ph-trash"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.REMOVE_UPLOAD')"
        slate
        ghost
        xs
        @click="
          $emit('update:modelValue', {
            ...modelValue,
            media: null,
            uploadFile: null,
          })
        "
      />
    </div>

    <TextArea
      id="whatsapp-interactive-body"
      :model-value="modelValue.body"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BODY')"
      :placeholder="
        $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BODY_PLACEHOLDER')
      "
      :max-length="limits.bodyMaxLength"
      show-character-count
      auto-height
      autofocus
      @update:model-value="updateBody"
    />

    <Input
      id="whatsapp-interactive-footer"
      :model-value="modelValue.footer || ''"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.FOOTER')"
      :maxlength="limits.footerMaxLength"
      :message="`${modelValue.footer?.length || 0}/${limits.footerMaxLength}`"
      @update:model-value="
        $emit('update:modelValue', { ...modelValue, footer: $event })
      "
    />

    <div class="flex flex-col gap-2">
      <Input
        v-for="(button, index) in modelValue.buttons"
        :id="`whatsapp-interactive-button-${index}`"
        :key="index"
        :model-value="button"
        :label="
          $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BUTTON_LABEL', {
            number: index + 1,
          })
        "
        :placeholder="
          $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BUTTON_PLACEHOLDER')
        "
        :maxlength="limits.buttonTitleMaxLength"
        :message="`${button.length}/${limits.buttonTitleMaxLength}`"
        @update:model-value="updateButton(index, $event)"
      >
        <template
          v-if="modelValue.buttons.length > limits.buttonMinCount"
          #prefix
        >
          <Button
            class="absolute z-10 ltr:right-1 rtl:left-1 top-7"
            icon="i-ph-trash"
            slate
            ghost
            xs
            :aria-label="
              $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.REMOVE_BUTTON', {
                number: index + 1,
              })
            "
            @click="removeButton(index)"
          />
        </template>
      </Input>
    </div>

    <p v-if="duplicateTitles" role="alert" class="mb-0 text-xs text-n-ruby-9">
      {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.DUPLICATE_LABELS') }}
    </p>

    <Button
      v-if="modelValue.buttons.length < limits.buttonMaxCount"
      class="self-start"
      icon="i-ph-plus"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.ADD_BUTTON')"
      slate
      faded
      sm
      @click="addButton"
    />
    <p class="mb-0 text-xs text-n-slate-11">
      {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.PREVIEW') }}
    </p>
    <WhatsAppInteractivePreview
      class="rounded-lg border border-n-weak p-3"
      :body="modelValue.body"
      :header="
        modelValue.headerType
          ? { type: modelValue.headerType, text: modelValue.headerText }
          : null
      "
      :attachment="modelValue.media"
      :footer="modelValue.footer"
      :buttons="modelValue.buttons.map(title => ({ title }))"
    />
  </section>
</template>
