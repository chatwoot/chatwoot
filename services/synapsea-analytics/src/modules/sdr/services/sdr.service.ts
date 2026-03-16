import { inMemorySdrStore } from '../repositories/inMemorySdrStore.js';
import type { Lead, LeadConversation, LeadStatus, SDRMetrics } from '../types/sdr.types.js';

type LeadImportInput = {
  name: string;
  phone?: string;
  email?: string;
  company?: string;
  segment?: string;
  city?: string;
  role?: string;
};

const deriveStatusFromScore = (score: number): LeadStatus => {
  if (score >= 80) return 'opportunity';
  if (score >= 60) return 'hot';
  if (score >= 35) return 'warm';
  return 'cold';
};

const calculateScore = (lead: LeadImportInput) => {
  let score = 0;

  if (lead.company) score += 15;
  if (lead.segment) score += 10;
  if (lead.phone) score += 15;
  if (lead.email) score += 10;

  const role = String(lead.role || '').toLowerCase();
  if (['ceo', 'founder', 'head', 'diretor', 'gerente'].some(keyword => role.includes(keyword))) {
    score += 20;
  }

  const segment = String(lead.segment || '').toLowerCase();
  if (['imobili', 'constru', 'educa', 'saude', 'finance'].some(keyword => segment.includes(keyword))) {
    score += 20;
  }

  return Math.min(score, 100);
};

const buildOpeningMessage = (lead: Lead) => {
  const name = lead.name.split(' ')[0];
  const segmentText = lead.segment
    ? `Vi que sua empresa atua no segmento ${lead.segment}.`
    : 'Vi que sua operação tem potencial para ganhar eficiência com IA.';

  return `Olá ${name}! ${segmentText} Estamos ajudando times a automatizar prospecção e atendimento no mesmo fluxo. Vocês já usam alguma plataforma hoje?`;
};

export class SDRService {
  importLeads(items: LeadImportInput[]) {
    const now = new Date().toISOString();
    const preparedLeads: Lead[] = items.map(item => {
      const leadScore = calculateScore(item);
      const leadStatus = deriveStatusFromScore(leadScore);

      return {
        id: crypto.randomUUID(),
        name: item.name,
        phone: item.phone,
        email: item.email,
        company: item.company,
        segment: item.segment,
        city: item.city,
        role: item.role,
        leadScore,
        leadStatus,
        createdAt: now,
      };
    });

    inMemorySdrStore.addLeads(preparedLeads);

    return {
      imported: preparedLeads.length,
      hotOrOpportunity: preparedLeads.filter(lead => ['hot', 'opportunity'].includes(lead.leadStatus)).length,
      leads: preparedLeads,
    };
  }

  startProspection(input: { leadId?: string; channel: LeadConversation['channel'] }) {
    const lead = input.leadId
      ? inMemorySdrStore.getLeadById(input.leadId)
      : inMemorySdrStore.listLeads().find(item => !item.lastMessageAt);

    if (!lead) {
      return undefined;
    }

    const now = new Date().toISOString();
    inMemorySdrStore.updateLead(lead.id, { lastMessageAt: now });

    const conversation: LeadConversation = {
      id: crypto.randomUUID(),
      leadId: lead.id,
      channel: input.channel,
      status: lead.leadScore >= 60 ? 'qualified' : 'active',
      stage: lead.leadScore >= 60 ? 'interest' : 'discovery',
      conversationSummary: 'SDR autônomo iniciou conversa e coletou contexto inicial.',
      nextAction:
        lead.leadScore >= 60
          ? 'Agendar reunião com especialista comercial'
          : 'Conduzir perguntas de qualificação (tamanho, canais e urgência)',
      createdAt: now,
      updatedAt: now,
    };

    inMemorySdrStore.addConversation(conversation);

    return {
      conversation,
      openingMessage: buildOpeningMessage(lead),
      lead,
    };
  }

  getQualifiedLeads() {
    return inMemorySdrStore
      .listLeads()
      .filter(lead => ['hot', 'opportunity', 'meeting_scheduled'].includes(lead.leadStatus))
      .sort((a, b) => b.leadScore - a.leadScore);
  }

  getMetrics(): SDRMetrics {
    const leads = inMemorySdrStore.listLeads();
    const conversations = inMemorySdrStore.listConversations();

    const leadsApproached = conversations.length;
    const leadsResponded = conversations.filter(item => item.stage !== 'opening').length;
    const leadsQualified = conversations.filter(item => ['qualified', 'transferred'].includes(item.status)).length;
    const meetingsScheduled = leads.filter(lead => lead.leadStatus === 'meeting_scheduled').length;

    return {
      leadsApproached,
      leadsResponded,
      leadsQualified,
      meetingsScheduled,
      conversionRate: leadsApproached
        ? Number(((leadsQualified / leadsApproached) * 100).toFixed(2))
        : 0,
    };
  }
}
