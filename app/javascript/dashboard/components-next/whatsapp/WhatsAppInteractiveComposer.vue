<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({ body: '', buttons: [''] }),
  },
  limits: {
    type: Object,
    default: () => ({
      bodyMaxLength: 1024,
      buttonTitleMaxLength: 20,
      buttonMinCount: 1,
      buttonMaxCount: 3,
    }),
  },
});

const emit = defineEmits(['update:modelValue', 'close']);

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
  </section>
</template>
