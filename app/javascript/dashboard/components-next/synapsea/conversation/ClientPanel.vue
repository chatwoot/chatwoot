<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SynCard from '../ui/SynCard.vue';
import SynBadge from '../ui/SynBadge.vue';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const attrs = computed(() => props.contact?.additional_attributes || {});
const tags = computed(
  () => attrs.value.business_tags || props.contact?.labels || []
);
</script>

<template>
  <SynCard :title="$t('CONTACT_PANEL.SYNAPSEA.CRM.TITLE')">
    <dl class="m-0 grid grid-cols-1 gap-2 text-sm">
      <div class="grid grid-cols-2 gap-2">
        <dt class="text-xs text-n-slate-11">
          {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.COMPANY') }}
        </dt>
        <dd class="m-0 text-n-slate-12">
          {{
            attrs.company_name ||
            $t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_COMPANY')
          }}
        </dd>
      </div>
      <div class="grid grid-cols-2 gap-2">
        <dt class="text-xs text-n-slate-11">
          {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.SOURCE') }}
        </dt>
        <dd class="m-0 text-n-slate-12">
          {{ attrs.source || $t('CONTACT_PANEL.SYNAPSEA.CRM.UNKNOWN_SOURCE') }}
        </dd>
      </div>
      <div>
        <dt class="mb-1 text-xs text-n-slate-11">
          {{ $t('CONTACT_PANEL.SYNAPSEA.CRM.BUSINESS_TAGS') }}
        </dt>
        <dd class="m-0 flex flex-wrap gap-1">
          <SynBadge v-for="tag in tags" :key="tag" :label="tag" />
          <span v-if="!tags.length" class="text-xs text-n-slate-10">{{
            t('CONTACT_PANEL.SYNAPSEA.CRM.NO_BUSINESS_TAGS')
          }}</span>
        </dd>
      </div>
    </dl>
  </SynCard>
</template>
