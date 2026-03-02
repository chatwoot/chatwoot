import { ref } from 'vue';
import LlmAPI from 'dashboard/api/saas/llm';

/**
 * Composable to generate content for a specific section using AI.
 * Sends the current agent context + section key to the LLM
 * and returns a suggested text for that section.
 */
export function useGenerateSection() {
  const isGenerating = ref(false);
  const generatingSection = ref(null);

  const SECTION_PROMPTS = {
    initial_message:
      'Generate a friendly, professional greeting message that an AI assistant would use to start a conversation with a customer. Keep it to 1-2 sentences.',
    instructions:
      'Generate detailed behavioral instructions for an AI customer service assistant. Include how to handle common queries, tone guidelines, and response format. Be specific and actionable.',
    general_context:
      'Generate a business context section for an AI assistant. Include typical business information like hours, policies, and services. Use placeholder brackets [like this] for specific details the user should fill in.',
    success_criteria:
      'Generate success criteria for an AI assistant conversation. Define what counts as a successful interaction and when the assistant should hand off to a human agent.',
    interruption_rules:
      'Generate escalation/interruption rules for an AI assistant. Define when the assistant should stop and transfer to a human agent. Include triggers like negative sentiment, repeated confusion, or explicit requests.',
    inactivity_message:
      'Generate a short, friendly inactivity message that an AI assistant would send when the customer has been idle. Keep it to 1 sentence.',
    error_message:
      'Generate a short, apologetic fallback error message that an AI assistant would use when it cannot help. Include a suggestion to contact human support. Keep it to 1-2 sentences.',
  };

  /**
   * Generate AI content for a specific section.
   * @param {string} sectionKey - The section to generate for
   * @param {object} context - Current agent state for context
   * @returns {string|null} Generated content or null on error
   */
  const generateSection = async (sectionKey, context = {}) => {
    isGenerating.value = true;
    generatingSection.value = sectionKey;

    try {
      const systemPrompt = `You are a helpful assistant that generates configuration text for AI customer service agents. 
The user's business: ${context.name || 'a business'} - ${context.description || 'no description provided'}.
Respond ONLY with the generated text. No explanations, no markdown formatting, no quotes. Just the raw text content.
Use the user's language if you can detect it from context, otherwise default to Portuguese (Brazil).`;

      const userPrompt =
        SECTION_PROMPTS[sectionKey] ||
        `Generate content for the "${sectionKey}" section of an AI agent configuration.`;

      const response = await LlmAPI.completions({
        model: 'litellm/gpt-4.1-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 500,
        stream: false,
        feature: 'agent_section_gen',
      });

      return (
        response.data?.content ||
        response.data?.choices?.[0]?.message?.content ||
        null
      );
    } catch {
      return null;
    } finally {
      isGenerating.value = false;
      generatingSection.value = null;
    }
  };

  return {
    isGenerating,
    generatingSection,
    generateSection,
  };
}
