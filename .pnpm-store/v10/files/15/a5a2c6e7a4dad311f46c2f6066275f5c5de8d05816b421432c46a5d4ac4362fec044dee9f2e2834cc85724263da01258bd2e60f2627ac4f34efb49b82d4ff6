import { Conversation } from './types/conversation';
import { AppliedSla } from './types/sla';
/**
 * Evaluates the SLA status for a given chat and applied SLA.
 * @param {Object} params - The parameters object.
 * @param params.appliedSla - The applied SLA details.
 * @param params.chat - The chat details.
 * @returns An object containing the most urgent SLA status.
 */
export declare const evaluateSLAStatus: ({ appliedSla, chat, }: {
    appliedSla: AppliedSla;
    chat: Conversation;
}) => {
    type: string;
    threshold: string;
    icon: string;
    isSlaMissed: boolean;
};
