<script setup>
import { ref, computed, watch } from 'vue';
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

const { actions, loaded, hasAction, getAction } = useHubIntegrations();

const leads = ref([]);
const loadingLeads = ref(false);
const leadsFetched = ref(false);
const isCreating = ref(false);

const contactPhone = computed(() => props.contact?.phone_number || '');
const contactEmail = computed(() => props.contact?.email || '');
const contactName = computed(() => props.contact?.name || '');
const companyName = computed(
  () => props.contact?.additional_attributes?.company_name || ''
);

const showPanel = computed(() => {
  return loaded.value && (hasAction('create_opportunity') || hasAction('advance_opportunity'));
});

const amplexBaseUrl = computed(() => {
  const action = getAction('create_opportunity') || getAction('advance_opportunity');
  return action?.target_url || '';
});

async function searchLeads() {
  if (!amplexBaseUrl.value || loadingLeads.value) return;
  if (!contactPhone.value && !contactEmail.value) return;

  loadingLeads.value = true;
  try {
    const params = new URLSearchParams();
    if (contactPhone.value) params.set('phone', contactPhone.value);
    if (contactEmail.value) params.set('email', contactEmail.value);

    const response = await fetch(
      `${amplexBaseUrl.value}/amplex/api/crm/integrations/search-lead?${params}`,
      {
        headers: {
          'X-Api-Key': window.chatwootConfig?.hubApiKey || '',
        },
      }
    );

    if (response.ok) {
      const data = await response.json();
      leads.value = data.leads || [];
    }
  } catch (e) {
    // silent fail
  } finally {
    loadingLeads.value = false;
    leadsFetched.value = true;
  }
}

async function createOpportunity() {
  const action = getAction('create_opportunity');
  if (!action) return;

  isCreating.value = true;
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
      useAlert('Oportunidade criada no CRM');
      // Refresh leads list
      await searchLeads();
    } else {
      useAlert('Erro ao criar oportunidade');
    }
  } catch {
    useAlert('Erro ao criar oportunidade');
  } finally {
    isCreating.value = false;
  }
}

function openInCrm(leadId) {
  if (amplexBaseUrl.value) {
    window.open(`${amplexBaseUrl.value}/leads/${leadId}`, '_blank');
  }
}

function formatCurrency(value) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value || 0);
}

// Search leads when contact changes
watch(
  () => props.contact?.id,
  () => {
    if (showPanel.value && (contactPhone.value || contactEmail.value)) {
      searchLeads();
    }
  },
  { immediate: true }
);
</script>

<template>
  <div v-if="showPanel" class="px-1">
    <!-- Loading -->
    <div v-if="loadingLeads" class="text-xs text-n-slate-11 text-center py-3">
      Buscando oportunidades...
    </div>

    <!-- Leads found -->
    <div v-else-if="leads.length > 0" class="flex flex-col gap-2">
      <div
        v-for="lead in leads"
        :key="lead.id"
        class="rounded-lg border border-n-weak bg-n-alpha-1 p-2.5 cursor-pointer hover:bg-n-alpha-2 transition-colors"
        @click="openInCrm(lead.id)"
      >
        <div class="flex items-center justify-between mb-1">
          <span class="text-xs font-semibold text-n-slate-12 truncate">
            {{ lead.name }}
          </span>
          <span class="text-[10px] px-1.5 py-0.5 rounded-full bg-n-brand-alpha-1 text-n-brand-11 font-medium">
            {{ lead.stage_name }}
          </span>
        </div>
        <div class="flex items-center justify-between text-[11px] text-n-slate-11">
          <span>{{ lead.contact_name || lead.email }}</span>
          <span v-if="lead.expected_revenue" class="font-medium text-n-slate-12">
            {{ formatCurrency(lead.expected_revenue) }}
          </span>
        </div>
        <div class="text-[10px] text-n-slate-10 mt-1">
          {{ lead.user_name ? `Resp: ${lead.user_name}` : '' }}
        </div>
      </div>

      <!-- Create another opportunity button -->
      <NextButton
        v-if="hasAction('create_opportunity')"
        icon="i-lucide-plus"
        label="Nova oportunidade"
        slate
        faded
        xs
        :loading="isCreating"
        @click="createOpportunity"
      />
    </div>

    <!-- No leads found -->
    <div v-else-if="leadsFetched" class="text-center py-2">
      <p class="text-xs text-n-slate-11 mb-2">
        Nenhuma oportunidade encontrada
      </p>
      <NextButton
        v-if="hasAction('create_opportunity')"
        icon="i-lucide-briefcase"
        label="Criar oportunidade"
        slate
        faded
        sm
        :loading="isCreating"
        @click="createOpportunity"
      />
    </div>

    <!-- No contact info to search -->
    <div v-else class="text-xs text-n-slate-11 text-center py-2">
      Sem telefone/email para buscar no CRM
    </div>
  </div>
</template>
