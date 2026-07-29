<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  modelValue: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const { checkStatusChange } = useBusinessRulesStatusGuard();
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const inboxes = useMapGetter('inboxes/getInboxes');

const dialogRef = ref(null);
const targetStatus = ref('resolved');
const inboxId = ref(null);
const draftAttrs = reactive({});
const result = ref(null);

const STATUS_OPTIONS = ['open', 'resolved', 'pending', 'snoozed'];

const listAttributes = computed(() =>
  (conversationAttributes.value || []).filter(attr =>
    ['list', 'multi_list', 'text', 'number', 'checkbox'].includes(
      attr.attributeDisplayType || attr.attribute_display_type
    )
  )
);

const attrKey = attr => attr.attributeKey || attr.attribute_key;
const attrType = attr =>
  attr.attributeDisplayType || attr.attribute_display_type;
const isListAttr = attr => ['list', 'multi_list'].includes(attrType(attr));
const attrOptions = attr => attr.attributeValues || attr.attribute_values || [];

watch(
  () => props.modelValue,
  open => {
    if (open) {
      result.value = null;
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);

const runDryRun = () => {
  const customAttributes = {};
  Object.entries(draftAttrs).forEach(([key, value]) => {
    if (value === '' || value == null) return;
    customAttributes[key] = value;
  });

  const draft = {
    status: 'open',
    inbox_id: inboxId.value || undefined,
    custom_attributes: customAttributes,
    labels: [],
    meta: { assignee: null, team: null, sender: { custom_attributes: {} } },
  };

  result.value = checkStatusChange(draft, targetStatus.value);
};

const close = () => {
  emit('update:modelValue', false);
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="lg"
    overflow-y-auto
    :title="t('BUSINESS_RULES.DRY_RUN.TITLE')"
    :confirm-button-label="t('BUSINESS_RULES.DRY_RUN.RUN')"
    :cancel-button-label="t('BUSINESS_RULES.CANCEL')"
    @confirm="runDryRun"
    @close="close"
  >
    <div class="flex flex-col gap-4">
      <p class="m-0 text-sm text-n-slate-11">
        {{ t('BUSINESS_RULES.DRY_RUN.HELP') }}
      </p>

      <label class="flex flex-col gap-1 text-sm text-n-slate-12">
        {{ t('BUSINESS_RULES.DRY_RUN.TARGET_STATUS') }}
        <select v-model="targetStatus" class="m-0 w-full">
          <option
            v-for="status in STATUS_OPTIONS"
            :key="status"
            :value="status"
          >
            {{ t(`BUSINESS_RULES.STATUSES.${status}`) }}
          </option>
        </select>
      </label>

      <label class="flex flex-col gap-1 text-sm text-n-slate-12">
        {{ t('BUSINESS_RULES.DRY_RUN.INBOX') }}
        <select v-model="inboxId" class="m-0 w-full">
          <option :value="null">
            {{ t('BUSINESS_RULES.DRY_RUN.INBOX_ANY') }}
          </option>
          <option
            v-for="inbox in inboxes || []"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
      </label>

      <div
        v-if="listAttributes.length"
        class="flex flex-col gap-2 rounded-lg border border-n-weak p-3"
      >
        <p class="m-0 text-xs font-semibold uppercase text-n-slate-11">
          {{ t('BUSINESS_RULES.DRY_RUN.DRAFT_ATTRS') }}
        </p>
        <label
          v-for="attr in listAttributes.slice(0, 12)"
          :key="attrKey(attr)"
          class="flex flex-col gap-1 text-sm text-n-slate-12"
        >
          {{ attr.attributeDisplayName || attr.attribute_display_name }}
          <select
            v-if="isListAttr(attr)"
            v-model="draftAttrs[attrKey(attr)]"
            class="m-0 w-full"
          >
            <option value="">
              {{ t('BUSINESS_RULES.DRY_RUN.ATTR_EMPTY') }}
            </option>
            <option v-for="opt in attrOptions(attr)" :key="opt" :value="opt">
              {{ opt }}
            </option>
          </select>
          <input
            v-else
            v-model="draftAttrs[attrKey(attr)]"
            type="text"
            class="m-0 w-full"
          />
        </label>
      </div>

      <div
        v-if="result"
        class="flex flex-col gap-2 rounded-lg border border-n-brand/30 bg-n-solid-2 p-3 text-sm"
      >
        <p class="m-0 font-medium text-n-slate-12">
          {{
            result.blocked
              ? t('BUSINESS_RULES.DRY_RUN.WOULD_BLOCK')
              : t('BUSINESS_RULES.DRY_RUN.WOULD_PASS')
          }}
        </p>
        <p
          v-if="result.requiredAttributes?.length"
          class="mb-0 text-n-slate-11"
        >
          {{
            `${t('BUSINESS_RULES.DRY_RUN.REQUIRED')}: ${result.requiredAttributes
              .map(a => a.label || a.value)
              .join(', ')}`
          }}
        </p>
        <p v-if="result.missingAttributes?.length" class="mb-0 text-n-ruby-11">
          {{
            `${t('BUSINESS_RULES.DRY_RUN.MISSING')}: ${result.missingAttributes
              .map(a => a.label || a.value)
              .join(', ')}`
          }}
        </p>
        <p v-if="result.forbiddenLabels?.length" class="mb-0 text-n-ruby-11">
          {{
            `${t('BUSINESS_RULES.DRY_RUN.FORBIDDEN')}: ${result.forbiddenLabels.join(', ')}`
          }}
        </p>
        <p v-if="result.needsAssignee" class="mb-0 text-n-ruby-11">
          {{ t('BUSINESS_RULES.STATUS_ERRORS.missing_assignee') }}
        </p>
      </div>
    </div>
  </Dialog>
</template>
