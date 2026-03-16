import type { Lead, LeadConversation } from '../types/sdr.types.js';

const leads: Lead[] = [];
const leadConversations: LeadConversation[] = [];

export const inMemorySdrStore = {
  listLeads: () => [...leads],
  getLeadById: (id: string) => leads.find(lead => lead.id === id),
  addLeads: (items: Lead[]) => {
    leads.push(...items);
    return items;
  },
  updateLead: (leadId: string, patch: Partial<Lead>) => {
    const index = leads.findIndex(lead => lead.id === leadId);
    if (index === -1) return undefined;

    leads[index] = { ...leads[index], ...patch };
    return leads[index];
  },
  listConversations: () => [...leadConversations],
  addConversation: (conversation: LeadConversation) => {
    leadConversations.push(conversation);
    return conversation;
  },
  updateConversation: (
    conversationId: string,
    patch: Partial<LeadConversation>
  ) => {
    const index = leadConversations.findIndex(item => item.id === conversationId);
    if (index === -1) return undefined;

    leadConversations[index] = {
      ...leadConversations[index],
      ...patch,
      updatedAt: new Date().toISOString(),
    };

    return leadConversations[index];
  },
};
