<script setup>
import { ref, watch } from 'vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import { MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import FormButton from 'v3/components/Form/Button.vue';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['updateSignature']);
const customEditorMenuList = MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS;
const signature = ref(props.messageSignature);
watch(
  () => props.messageSignature ?? '',
  newValue => {
    signature.value = newValue;
  }
);

const updateSignature = () => {
  emit('updateSignature', signature.value);
};
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
    <WootMessageEditor
      id="message-signature-input"
      v-model="signature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
      :enabled-menu-options="customEditorMenuList"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <FormButton
      type="submit"
      color-scheme="primary"
      variant="solid"
      size="large"
    >
      {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
    </FormButton>
  </form>
</template>
