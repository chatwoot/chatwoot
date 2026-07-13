export type ChatwootAssignee = {
  id: number;
  name?: string;
  type?: 'agent_bot' | 'user';
};

export type ChatwootWebhookPayload = {
  event?: string;
  id?: number;
  message_type?: 'incoming' | 'outgoing' | 'activity' | 'template';
  private?: boolean;
  content?: string;
  conversation?: {
    id?: number;
    status?: string;
    meta?: {
      assignee?: ChatwootAssignee | null;
      assignee_type?: 'AgentBot' | 'User' | null;
    };
  };
  sender?: {
    id?: number;
    identifier?: string | null;
    name?: string | null;
    email?: string | null;
    phone_number?: string | null;
    type?: string;
  };
};
