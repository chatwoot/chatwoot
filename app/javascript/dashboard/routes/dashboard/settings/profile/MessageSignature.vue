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
  azarMessageSignature: {
    type: String,
    default: '',
  },
  monoMessageSignature: {
    type: String,
    default: '',
  },
  gbitsMessageSignature: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['updateSignature']);
const customEditorMenuList = MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS;
const signature = ref(props.messageSignature);
const azarSignature = ref(props.azarMessageSignature);
const monoSignature = ref(props.monoMessageSignature);
const gbitsSignature = ref(props.gbitsMessageSignature);
watch(
  () => props.messageSignature ?? '',
  newValue => {
    signature.value = newValue;
  }
);

watch(
  () => props.azarMessageSignature ?? '',
  newValue => {
    azarSignature.value = newValue;
  }
);

watch(
  () => props.monoMessageSignature ?? '',
  newValue => {
    monoSignature.value = newValue;
  }
);

watch(
  () => props.gbitsMessageSignature ?? '',
  newValue => {
    gbitsSignature.value = newValue;
  }
);

const updateSignature = () => {
  emit(
    'updateSignature',
    signature.value,
    azarSignature.value,
    monoSignature.value,
    gbitsSignature.value
  );
};
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent="updateSignature()">
    <span>{{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER') }}</span>
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
    <hr />
    <span>{{
      $t('PROFILE_SETTINGS.FORM.AZAR_MESSAGE_SIGNATURE.PLACEHOLDER')
    }}</span>
    <WootMessageEditor
      id="message-azar-signature-input"
      v-model="azarSignature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="
        $t('PROFILE_SETTINGS.FORM.AZAR_MESSAGE_SIGNATURE.PLACEHOLDER')
      "
      :enabled-menu-options="customEditorMenuList"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <hr />
    <span>{{
      $t('PROFILE_SETTINGS.FORM.MONO_MESSAGE_SIGNATURE.PLACEHOLDER')
    }}</span>
    <WootMessageEditor
      id="message-mono-signature-input"
      v-model="monoSignature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="
        $t('PROFILE_SETTINGS.FORM.MONO_MESSAGE_SIGNATURE.PLACEHOLDER')
      "
      :enabled-menu-options="customEditorMenuList"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <hr />
    <span>{{
      $t('PROFILE_SETTINGS.FORM.GBITS_MESSAGE_SIGNATURE.PLACEHOLDER')
    }}</span>
    <WootMessageEditor
      id="message-gbits-signature-input"
      v-model="gbitsSignature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="
        $t('PROFILE_SETTINGS.FORM.GBITS_MESSAGE_SIGNATURE.PLACEHOLDER')
      "
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
