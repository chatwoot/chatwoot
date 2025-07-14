export interface Conversation {
  meta: Meta;
  id: number;
  custom_attributes: CustomAttributes;
  first_reply_created_at: number;
  waiting_since: number;
  status: string;
}

export interface Meta {
  assignee: Assignee;
  sender: Sender;
}

export interface Sender {
  id: number;
  email?: string;
  name?: string;
  phone_number?: string;
  custom_attributes?: CustomAttributes;
}

export interface Contact {
  id: number;
  email?: string;
  name?: string;
  phone_number?: string;
  custom_attributes?: CustomAttributes;
}

export interface Assignee {
  id: number;
  email?: string;
  name?: string;
  phone_number?: string;
}

export interface Variables {
  [key: string]: string | number | boolean;
}

export interface CustomAttributes {
  [key: string]: any;
}
