<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import ContactAPI from 'dashboard/api/contacts';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import AudienceLabelContacts from './AudienceLabelContacts.vue';

const props = defineProps({
  labels: {
    type: Array,
    default: () => [],
  },
  messagingTier: {
    type: String,
    default: '',
  },
});

const audienceIds = defineModel({ type: Array, default: () => [] });

const WHATSAPP_LIMITS_URL =
  'https://developers.facebook.com/docs/whatsapp/messaging-limits';

const { t } = useI18n();

const contactCounts = ref({});

const labelOptions = computed(() =>
  props.labels.map(label => ({ value: label.id, label: label.title }))
);

const selectedLabels = computed(() =>
  props.labels.filter(label => audienceIds.value.includes(label.id))
);

const totalContacts = computed(() =>
  selectedLabels.value.reduce(
    (total, label) => total + (contactCounts.value[label.id] ?? 0),
    0
  )
);

const removeLabel = labelId => {
  audienceIds.value = audienceIds.value.filter(id => id !== labelId);
};

const fetchContactCount = async label => {
  contactCounts.value[label.id] = null;
  try {
    const { data } = await ContactAPI.get(1, 'name', label.title);
    contactCounts.value[label.id] = data.meta.count;
  } catch {
    contactCounts.value[label.id] = 0;
  }
};

watch(
  selectedLabels,
  labels =>
    labels
      .filter(label => contactCounts.value[label.id] === undefined)
      .forEach(fetchContactCount),
  { immediate: true }
);
</script>

<template>
  <p class="mb-0 text-body-main text-n-slate-11">
    {{
      messagingTier
        ? t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.TIER_DESCRIPTION', {
            tier: messagingTier,
          })
        : t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.TIER_UNKNOWN')
    }}
    <a
      :href="WHATSAPP_LIMITS_URL"
      target="_blank"
      rel="noopener noreferrer"
      class="text-n-blue-11"
    >
      {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.LEARN_MORE') }}
    </a>
  </p>

  <div class="flex flex-col gap-1">
    <label
      for="campaign-audience"
      class="mb-0.5 text-heading-3 text-n-slate-12"
    >
      {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.LABELS.LABEL') }}
    </label>
    <TagMultiSelectComboBox
      id="campaign-audience"
      v-model="audienceIds"
      :options="labelOptions"
      :placeholder="t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.LABELS.PLACEHOLDER')"
    />
  </div>

  <div v-if="selectedLabels.length" class="flex flex-col">
    <span class="mb-3 text-body-main text-n-slate-11">
      {{
        t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.SELECTED_COUNT', {
          count: totalContacts,
        })
      }}
    </span>
    <div
      v-for="label in selectedLabels"
      :key="label.id"
      class="flex items-center h-14 gap-3 border-b border-n-weak last:border-b-0"
    >
      <span
        class="rounded-sm size-2.5 shrink-0"
        :style="{ backgroundColor: label.color }"
      />
      <span class="min-w-0 truncate text-body-main text-n-slate-12">
        {{ label.title }}
      </span>
      <span
        class="flex items-center gap-1.5 shrink-0 text-body-main text-n-slate-11"
      >
        <Icon icon="i-lucide-users" class="size-4" />
        {{ contactCounts[label.id] ?? 0 }}
      </span>
      <div class="flex items-center gap-2 shrink-0 ms-auto">
        <AudienceLabelContacts :label="label" />
        <span class="w-px h-2 ms-1 bg-n-strong" />
        <Button
          variant="ghost"
          color="slate"
          size="sm"
          icon="i-lucide-trash"
          @click="removeLabel(label.id)"
        />
      </div>
    </div>
  </div>
  <p v-else class="mb-0 text-body-main text-n-slate-11">
    {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.EMPTY_STATE') }}
  </p>
</template>
