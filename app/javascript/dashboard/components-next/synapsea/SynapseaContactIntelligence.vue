<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
  conversation: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const additionalAttributes = computed(
  () => props.contact?.additional_attributes || {}
);

const leadScore = computed(() => {
  let score = 30;
  if (props.contact?.email) score += 20;
  if (props.contact?.phone_number) score += 20;
  if (additionalAttributes.value?.company_name) score += 15;
  if ((props.contact?.labels || []).length) score += 15;
  return Math.min(score, 100);
});

const leadTier = computed(() => {
  if (leadScore.value >= 80) return t('CONTACT_PANEL.SYNAPSEA.LEAD_TIER.HOT');
  if (leadScore.value >= 55)
    return t('CONTACT_PANEL.SYNAPSEA.LEAD_TIER.QUALIFIED');
  return t('CONTACT_PANEL.SYNAPSEA.LEAD_TIER.COLD');
});

const currentIntent = computed(() => {
  if (props.conversation?.priority === 'urgent') {
    return t('CONTACT_PANEL.SYNAPSEA.INTENT.URGENT_SUPPORT');
  }

  if ((props.conversation?.labels || []).length) {
    return t('CONTACT_PANEL.SYNAPSEA.INTENT.GENERAL_FOLLOW_UP');
  }

  return t('CONTACT_PANEL.SYNAPSEA.INTENT.DISCOVERY');
});

const summaryText = computed(() => {
  const contactName = props.contact?.name || t('CONTACT_PANEL.NOT_AVAILABLE');
  const company =
    additionalAttributes.value?.company_name ||
    t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_COMPANY');

  return t('CONTACT_PANEL.SYNAPSEA.AI.AUTO_SUMMARY_VALUE', {
    contactName,
    company,
  });
});

const suggestionText = computed(() =>
  t('CONTACT_PANEL.SYNAPSEA.AI.REPLY_SUGGESTION_VALUE')
);

const businessSource = computed(
  () =>
    additionalAttributes.value?.source ||
    additionalAttributes.value?.origin ||
    t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_SOURCE')
);

const businessStage = computed(
  () =>
    additionalAttributes.value?.stage ||
    additionalAttributes.value?.funnel_stage ||
    t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_STAGE')
);

const businessTags = computed(() => {
  const tags = additionalAttributes.value?.business_tags;
  if (Array.isArray(tags) && tags.length) return tags;

  const labels = props.contact?.labels || [];
  return labels.length
    ? labels
    : [t('CONTACT_PANEL.SYNAPSEA.CRM.NO_BUSINESS_TAGS')];
});

const interactionHistory = computed(() => {
  if (additionalAttributes.value?.last_activity_at) {
    return additionalAttributes.value.last_activity_at;
  }

  return t('CONTACT_PANEL.SYNAPSEA.CRM.NO_INTERACTION_HISTORY');
});
</script>

<template>
 codex/transform-chatwoot-into-synapsea-connect-vkjace
  <div class="grid gap-3">
    <section class="rounded-xl border border-n-weak bg-n-solid-2 p-3">
      <p
        class="mb-2 text-xs font-semibold uppercase tracking-wide text-n-slate-10"
      >

  <div class="grid gap-3 px-2 pb-3">
    <section class="rounded-xl border border-n-weak bg-n-solid-2 p-3">
      <p class="mb-2 text-xs font-medium uppercase tracking-wide text-n-brand">
 develop
        {{ $t('CONTACT_PANEL.SYNAPSEA.AI.TITLE') }}
      </p>
      <dl class="m-0 grid gap-2">
        <div>
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.AI.AUTO_SUMMARY_LABEL') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">{{ summaryText }}</dd>
        </div>
        <div>
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.AI.REPLY_SUGGESTION_LABEL') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">{{ suggestionText }}</dd>
        </div>
        <div class="grid grid-cols-2 gap-2">
 codex/transform-chatwoot-into-synapsea-connect-vkjace
          <div class="rounded-lg border border-n-weak bg-n-slate-2 p-2">

          <div class="rounded-lg bg-n-alpha-2 p-2">
 develop
            <p class="mb-1 text-xs text-n-slate-11">
              {{ $t('CONTACT_PANEL.SYNAPSEA.AI.LEAD_SCORE_LABEL') }}
            </p>
            <p class="mb-0 text-sm font-medium text-n-slate-12">
              {{ leadScore }}
              {{
                $t('CONTACT_PANEL.SYNAPSEA.AI.LEAD_SCORE_SUFFIX', {
                  tier: leadTier,
                })
              }}
            </p>
          </div>
 codex/transform-chatwoot-into-synapsea-connect-vkjace
          <div class="rounded-lg border border-n-weak bg-n-slate-2 p-2">

          <div class="rounded-lg bg-n-alpha-2 p-2">
 develop
            <p class="mb-1 text-xs text-n-slate-11">
              {{ $t('CONTACT_PANEL.SYNAPSEA.AI.INTENT_LABEL') }}
            </p>
            <p class="mb-0 text-sm font-medium text-n-slate-12">
              {{ currentIntent }}
            </p>
          </div>
        </div>
      </dl>
    </section>

    <section class="rounded-xl border border-n-weak bg-n-solid-2 p-3">
 codex/transform-chatwoot-into-synapsea-connect-vkjace
      <p
        class="mb-2 text-xs font-semibold uppercase tracking-wide text-n-slate-10"
      >

      <p class="mb-2 text-xs font-medium uppercase tracking-wide text-n-brand">
 develop
        {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.TITLE') }}
      </p>
      <dl class="m-0 grid grid-cols-1 gap-2">
        <div class="grid grid-cols-2 gap-2">
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.COMPANY') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">
            {{
              additionalAttributes.company_name ||
              $t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_COMPANY')
            }}
          </dd>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.SOURCE') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">{{ businessSource }}</dd>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.STAGE') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">{{ businessStage }}</dd>
        </div>
        <div>
          <dt class="mb-1 text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.BUSINESS_TAGS') }}
          </dt>
          <dd class="m-0 flex flex-wrap gap-1">
            <span
              v-for="tag in businessTags"
              :key="tag"
 codex/transform-chatwoot-into-synapsea-connect-vkjace
              class="inline-flex rounded-full bg-n-slate-3 px-2 py-0.5 text-xs text-n-slate-12"

              class="inline-flex rounded-full bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-12"
 develop
            >
              {{ tag }}
            </span>
          </dd>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <dt class="text-xs text-n-slate-11">
            {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.INTERACTION_HISTORY') }}
          </dt>
          <dd class="m-0 text-sm text-n-slate-12">{{ interactionHistory }}</dd>
        </div>
      </dl>
    </section>
  </div>
</template>
