<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';
import { MESSAGE_TYPES } from './constants';
import { useMessageContext } from './provider.js';
import { useTranslations } from 'dashboard/composables/useTranslations';

const props = defineProps({
  showingOriginal: Boolean,
  icon: { type: Boolean, default: true },
});

defineEmits(['toggle']);

defineOptions({ inheritAttrs: false });

const { t } = useI18n();
const { id, contentAttributes, messageType, contactSide, shouldGroupWithNext } =
  useMessageContext();
const { hasTranslations } = useTranslations(contentAttributes, contactSide);
const autoTranslate = useMapGetter('getAutoTranslate');
const translationState = useMapGetter('getMessageTranslationState');

const state = computed(() => translationState.value(id.value));
// "Already in X" reads once per group, on its last message, like the timestamp.
const visible = computed(() => {
  if (state.value.pending || state.value.failed) return true;
  if (state.value.sameLanguage) return !shouldGroupWithNext.value;
  return hasTranslations.value;
});
const isOutgoing = computed(
  () =>
    !contactSide.value &&
    [MESSAGE_TYPES.OUTGOING, MESSAGE_TYPES.TEMPLATE].includes(messageType.value)
);
// An auto-translated reply is stored in the contact's language, so "original" means the translation there.
const showsTranslation = computed(() =>
  isOutgoing.value && autoTranslate.value.language
    ? props.showingOriginal
    : !props.showingOriginal
);
const toggleLabel = computed(() => {
  const { language, agentLanguage } = autoTranslate.value;
  if (!language) {
    return showsTranslation.value
      ? t('CONVERSATION.VIEW_ORIGINAL')
      : t('CONVERSATION.VIEW_TRANSLATED');
  }
  if (showsTranslation.value) {
    return t('CONVERSATION.VIEW_ORIGINAL_IN', {
      language: isOutgoing.value ? agentLanguage : state.value.sourceLanguage,
    });
  }
  return t('CONVERSATION.VIEW_TRANSLATED_IN', {
    language: isOutgoing.value ? state.value.sourceLanguage : agentLanguage,
  });
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <span
    v-if="visible"
    v-bind="$attrs"
    class="text-xs text-n-slate-11 inline-flex items-center gap-1.5 select-none"
  >
    <Icon
      v-if="state.failed"
      icon="i-lucide-triangle-alert"
      class="size-3 text-n-amber-11"
    />
    <Icon
      v-else-if="icon && autoTranslate.language"
      icon="i-lucide-sparkles"
      class="size-3 text-n-iris-9"
      :class="{ 'animate-twinkle motion-reduce:animate-none': state.pending }"
    />
    <span
      v-if="state.pending"
      class="bg-clip-text text-transparent bg-gradient-to-r from-n-slate-11 from-40% via-n-iris-9 to-n-slate-11 to-60% bg-[length:300%_100%] animate-text-shimmer motion-reduce:animate-none"
    >
      {{
        isOutgoing
          ? $t('CONVERSATION.TRANSLATING_TO', {
              language: autoTranslate.language,
            })
          : $t('CONVERSATION.TRANSLATING')
      }}
    </span>
    <span v-else-if="state.failed" class="text-n-amber-11">
      {{ $t('CONVERSATION.TRANSLATION_FAILED') }}
    </span>
    <span v-else-if="state.sameLanguage">
      {{
        $t('CONVERSATION.ALREADY_IN_LANGUAGE', {
          language: autoTranslate.agentLanguage,
        })
      }}
    </span>
    <span
      v-else
      class="cursor-pointer hover:underline"
      @click="$emit('toggle')"
    >
      {{ toggleLabel }}
    </span>
  </span>
</template>
