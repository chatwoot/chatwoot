export type LeadStatus = 'cold' | 'warm' | 'hot' | 'opportunity' | 'meeting_scheduled';

export type Lead = {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  company?: string;
  segment?: string;
  city?: string;
  role?: string;
  leadScore: number;
  leadStatus: LeadStatus;
  lastMessageAt?: string;
  createdAt: string;
};

export type LeadConversation = {
  id: string;
  leadId: string;
  channel: 'whatsapp' | 'instagram' | 'webchat' | 'email' | 'sms';
  status: 'active' | 'qualified' | 'transferred' | 'closed';
  stage: 'opening' | 'discovery' | 'qualification' | 'interest' | 'scheduling';
  conversationSummary?: string;
  nextAction?: string;
  createdAt: string;
  updatedAt: string;
};

export type SDRMetrics = {
  leadsApproached: number;
  leadsResponded: number;
  leadsQualified: number;
  meetingsScheduled: number;
  conversionRate: number;
};
