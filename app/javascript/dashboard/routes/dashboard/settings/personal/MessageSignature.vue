<template>
  <div class="flex flex-col gap-6">
    <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
      <woot-message-editor
        id="message-signature-input"
        v-model="signature"
        class="message-editor h-[10rem] !px-3"
        :is-format-mode="true"
        :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
        :enabled-menu-options="customEditorMenuList"
        :enable-suggestions="false"
        :show-image-resize-toolbar="true"
      />
      <form-button
        type="submit"
        color-scheme="primary"
        variant="solid"
        size="large"
      >
        {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
      </form-button>
    </form>
  </div>
</template>
<script setup>
import { defineProps, ref } from 'vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import { MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import FormButton from 'v3/components/Form/Button.vue';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
});

const signature = ref(props.messageSignature);

const customEditorMenuList = MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS;

const emit = defineEmits(['update-signature']);

const updateSignature = () => {
  emit('update-signature', signature.value);
};
</script>
