<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useHubIntegrations } from 'dashboard/composables/useHubIntegrations';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
  conversationId: {
    type: [Number, String],
    default: null,
  },
});

const { actions, loaded, hasAction } = useHubIntegrations();
const { t } = useI18n();

const isCreatingOpportunity = ref(false);
const isEnrichingCnpj = ref(false);

const showIntegrations = computed(() => {
  return loaded.value && actions.value.length > 0;
});

const contactName = computed(() => props.contact?.name || '');
const contactEmail = computed(() => props.contact?.email || '');
const contactPhone = computed(
  () => props.contact?.phone_number || ''
);
const companyName = computed(
  () => props.contact?.additional_attributes?.company_name || ''
);

async function createOpportunity() {
  const action = actions.value.find(a => a.key === 'create_opportunity');
  if (!action) return;

  isCreatingOpportunity.value = true;
  try {
    const payload = {
      contact_name: contactName.value,
      contact_email: contactEmail.value,
      contact_phone: contactPhone.value,
      company_name: companyName.value,
      conversation_id: props.conversationId,
      source: 'nexus',
    };

    const response = await fetch(
      `${action.target_url}${action.endpoint}`,
      {
        method: action.method,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': window.chatwootConfig?.hubApiKey || '',
        },
        body: JSON.stringify(payload),
      }
    );

    if (response.ok) {
      const data = await response.json();
      useAlert(
        t('INTEGRATION_ACTIONS.OPPORTUNITY_CREATED', {
          name: data.name || contactName.value,
        })
      );
    } else {
      useAlert(t('INTEGRATION_ACTIONS.OPPORTUNITY_ERROR'));
    }
  } catch {
    useAlert(t('INTEGRATION_ACTIONS.OPPORTUNITY_ERROR'));
  } finally {
    isCreatingOpportunity.value = false;
  }
}

async function enrichCnpj() {
  const action = actions.value.find(
    a => a.key === 'enrich_contact_cnpj'
  );
  if (!action) return;

  const cnpj =
    props.contact?.custom_attributes?.cnpj ||
    props.contact?.additional_attributes?.cnpj ||
    '';

  if (!cnpj) {
    useAlert(t('INTEGRATION_ACTIONS.NO_CNPJ'));
    return;
  }

  isEnrichingCnpj.value = true;
  try {
    const response = await fetch(
      `${action.target_url}${action.endpoint}`,
      {
        method: action.method,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': window.chatwootConfig?.hubApiKey || '',
        },
        body: JSON.stringify({
          cnpj,
          source: 'nexus',
          source_id: String(props.contact?.id || ''),
        }),
      }
    );

    if (response.ok) {
      useAlert(t('INTEGRATION_ACTIONS.CNPJ_ENRICHED'));
    } else {
      useAlert(t('INTEGRATION_ACTIONS.CNPJ_ERROR'));
    }
  } catch {
    useAlert(t('INTEGRATION_ACTIONS.CNPJ_ERROR'));
  } finally {
    isEnrichingCnpj.value = false;
  }
}
</script>

<template>
  <div v-if="showIntegrations" class="flex flex-wrap items-center gap-1.5">
    <NextButton
      v-if="hasAction('create_opportunity')"
      v-tooltip.top-end="'Criar oportunidade no CRM'"
      icon="i-lucide-briefcase"
      slate
      faded
      sm
      :loading="isCreatingOpportunity"
      @click="createOpportunity"
    />
    <NextButton
      v-if="hasAction('enrich_contact_cnpj')"
      v-tooltip.top-end="'Consultar CNPJ'"
      icon="i-lucide-search"
      slate
      faded
      sm
      :loading="isEnrichingCnpj"
      @click="enrichCnpj"
    />
  </div>
</template>
