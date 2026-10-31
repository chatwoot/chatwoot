<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ConversationApi from 'dashboard/api/conversations';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversation: { type: Object, required: true },
  name: { type: String, required: true },
});

const store = useStore();
const { t } = useI18n();
const isSaving = ref(false);
const enabled = computed(
  () =>
    props.conversation.additional_attributes?.user_identifier_enabled !== false
);

const toggleIdentifier = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    const { data } = await ConversationApi.update(props.conversation.id, {
      user_identifier_enabled: !enabled.value,
    });
    await store.dispatch('updateConversation', data);
  } catch {
    useAlert(t('CONVERSATION.USER_IDENTIFIER.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex flex-wrap items-center justify-between gap-2 px-4 pt-3">
    <strong v-if="enabled" class="text-sm font-bold text-n-slate-12">
      {{ name }}
    </strong>
    <Button
      v-tooltip="$t('CONVERSATION.USER_IDENTIFIER.HELP')"
      size="sm"
      variant="ghost"
      :color="enabled ? 'blue' : 'slate'"
      :label="
        enabled
          ? $t('CONVERSATION.USER_IDENTIFIER.ON')
          : $t('CONVERSATION.USER_IDENTIFIER.OFF')
      "
      :aria-pressed="enabled"
      :disabled="isSaving"
      :is-loading="isSaving"
      @click="toggleIdentifier"
    />
  </div>
</template>
