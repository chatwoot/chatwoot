import { Conversation, Sender, Variables, Contact } from './types/conversation';
export declare const capitalizeName: (name: string | null) => string;
export declare const getFirstName: ({ user }: {
    user: Sender;
}) => string;
export declare const getLastName: ({ user }: {
    user: Sender;
}) => string;
export declare const getMessageVariables: ({ conversation, contact, }: {
    conversation: Conversation;
    contact?: Contact | undefined;
}) => {
    'contact.name': string;
    'contact.first_name': string;
    'contact.last_name': string;
    'contact.email': string | undefined;
    'contact.phone': string | undefined;
    'contact.id': number;
    'conversation.id': number;
    'agent.name': string;
    'agent.first_name': string;
    'agent.last_name': string;
    'agent.email': string;
};
export declare const replaceVariablesInMessage: ({ message, variables, }: {
    message: string;
    variables: Variables;
}) => string;
export declare const getUndefinedVariablesInMessage: ({ message, variables, }: {
    message: string;
    variables: Variables;
}) => string[];
