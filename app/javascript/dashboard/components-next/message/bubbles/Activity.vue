<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes, createdAt } = useMessageContext();
const { t, te } = useI18n();

const ACTIVITY_I18N_PREFIX = 'CONVERSATION.ACTIVITY';
const PRIORITY_PARAMS = ['oldPriority', 'newPriority'];

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);

const translateActor = ({ actorType, policyName }) => {
  const actorKey = `${ACTIVITY_I18N_PREFIX}.ACTORS.${actorType.toUpperCase()}`;
  return te(actorKey) ? t(actorKey, { policyName }) : null;
};

// Activity messages store a key and params so the sentence can be built in the
// viewer's locale. Older messages and unmigrated types only have `content`.
const activityText = computed(() => {
  const { key, params = {} } = contentAttributes.value?.activity || {};
  const i18nKey = key
    ? `${ACTIVITY_I18N_PREFIX}.${key
        .split('.')
        .map(part => part.toUpperCase())
        .join('.')}`
    : null;
  if (!i18nKey || !te(i18nKey)) return content.value;

  const translatedParams = { ...params };
  if (params.actorType) {
    translatedParams.userName =
      translateActor(params) ?? translatedParams.userName;
  }
  PRIORITY_PARAMS.forEach(name => {
    if (params[name]) {
      translatedParams[name] = t(
        `CONVERSATION.PRIORITY.OPTIONS.${params[name].toUpperCase()}`
      );
    }
  });

  return t(i18nKey, translatedParams, params.count ?? 1);
});
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="px-3 py-1 !rounded-xl flex min-w-0 items-center gap-2"
    data-bubble-name="activity"
  >
    <span :title="activityText">{{ activityText }}</span>
  </BaseBubble>
</template>
