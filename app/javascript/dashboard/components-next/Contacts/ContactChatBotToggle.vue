<script setup>
import { computed, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();
const store = useStore();
const isUpdating = ref(false);

const contactId = computed(() => props.contact?.id);
const resolvedContact = useFunctionGetter('contacts/getContactById', contactId);

const resolveChatBot = () => {
  const value =
    resolvedContact.value?.chatBot ??
    resolvedContact.value?.chat_bot ??
    props.contact?.chat_bot ??
    props.contact?.chatBot;
  return value !== false;
};

const switchValue = ref(resolveChatBot());

watch(
  [resolvedContact, () => props.contact],
  () => {
    switchValue.value = resolveChatBot();
  },
  { deep: true }
);

const handleChange = async () => {
  if (isUpdating.value || props.disabled) {
    switchValue.value = resolveChatBot();
    return;
  }

  const nextValue = switchValue.value;
  if (nextValue === resolveChatBot()) return;

  isUpdating.value = true;
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      chatBot: nextValue,
    });
    emit('update', { chatBot: nextValue });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.UPDATE_SUCCESS'));
  } catch {
    switchValue.value = resolveChatBot();
    useAlert(t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.UPDATE_ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <OutlinedAttributeField
    :label="t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.LABEL')"
    :description="t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.DESCRIPTION')"
    filled
  >
    <div class="flex items-center justify-between gap-2 min-h-8 w-full px-1">
      <span class="text-sm text-n-slate-11 truncate">
        {{
          switchValue
            ? t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.ON')
            : t('CONTACTS_LAYOUT.DETAILS.CHAT_BOT.OFF')
        }}
      </span>
      <Switch v-model="switchValue" @change="handleChange" />
    </div>
  </OutlinedAttributeField>
</template>
