// The Vapi voices an inbox can pick for Captain on calls, matching
// Voice::Captain::AssistantConfig::VOICES. Previews are Vapi's own samples.
export const DEFAULT_CAPTAIN_VOICE = 'Elliot';

export const CAPTAIN_VOICES = [
  { id: 'Elliot', descriptionKey: 'MALE_CANADIAN' },
  { id: 'Savannah', descriptionKey: 'FEMALE_AMERICAN' },
  { id: 'Naina', descriptionKey: 'FEMALE_INDIAN' },
  { id: 'Sagar', descriptionKey: 'MALE_INDIAN' },
];

export const captainVoicePreviewUrl = voiceId =>
  `https://voice-previews.vapi.ai/${voiceId.toLowerCase()}.wav`;
