<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import Label from 'dashboard/components-next/label/Label.vue';
import CardStatusIcon from 'dashboard/components-next/Conversation/ConversationCard/CardStatusIcon.vue';

const props = defineProps({
  value: { type: [String, Number, Boolean, Array], default: null },
  column: { type: Object, required: true },
  row: { type: Object, required: true },
});
const route = useRoute();
const { t, locale } = useI18n();
const TIMESTAMP_FIELDS = new Set([
  'created_at',
  'updated_at',
  'last_activity_at',
  'snoozed_until',
]);
const ISO_TIMESTAMP =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/;
const isDatetime = computed(
  () =>
    props.column.type === 'datetime' ||
    (props.column.type === 'text' &&
      TIMESTAMP_FIELDS.has(props.column.key) &&
      typeof props.value === 'string' &&
      ISO_TIMESTAMP.test(props.value) &&
      Number.isFinite(Date.parse(props.value)))
);
const link = computed(() => {
  const id = props.row[props.column.id_key];
  if (id == null) return null;
  const accountId = route.params.accountId;
  if (props.column.type === 'conversation') {
    return frontendURL(conversationUrl({ accountId, id }));
  }
  if (props.column.type === 'contact') {
    return frontendURL(`accounts/${accountId}/contacts/${id}`);
  }
  return null;
});
const formatted = computed(() => {
  const { value } = props;
  if (value === null) return t('CAPTAIN_ASK.TRACE.NOT_SET');
  if (value === true) return t('CAPTAIN_ASK.TRACE.YES');
  if (value === false) return t('CAPTAIN_ASK.TRACE.NO');
  if (value === '') return t('CAPTAIN_ASK.TRACE.EMPTY');
  if (props.column.type === 'number')
    return new Intl.NumberFormat(locale.value).format(value);
  if (isDatetime.value) {
    return new Intl.DateTimeFormat(locale.value, {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(new Date(value));
  }
  return String(value);
});
</script>

<template>
  <div
    v-if="column.type === 'tags' && value !== null"
    class="flex flex-nowrap gap-1 max-w-[20rem] overflow-x-auto"
    tabindex="0"
    role="region"
    :aria-label="column.label || column.key"
  >
    <Label v-for="(tag, index) in value" :key="index" :label="tag" compact />
    <span v-if="!value.length" class="text-n-slate-11">{{
      t('CAPTAIN_ASK.TRACE.EMPTY')
    }}</span>
  </div>
  <Label
    v-else-if="column.type === 'status' && value !== null"
    :label="value"
    compact
  >
    <template #icon><CardStatusIcon :status="value" /></template>
  </Label>
  <RouterLink
    v-else-if="link && value !== null"
    :to="link"
    class="text-n-blue-11 hover:underline whitespace-nowrap"
  >
    {{ formatted }}
  </RouterLink>
  <span
    v-else
    :title="isDatetime ? value : undefined"
    class="text-n-slate-12 tabular-nums whitespace-nowrap"
  >
    {{ formatted }}
  </span>
</template>
