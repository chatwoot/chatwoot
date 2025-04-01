import axios from 'axios';

const GROQ_API_URL = 'https://api.groq.com/openai/v1/audio/transcriptions';

export const transcribeAudio = async audioUrl => {
  if (!window.chatwootConfig?.groqApiKey) {
    throw new Error('GROQ_API_KEY não está configurada');
  }

  // Primeiro, baixa o arquivo de áudio
  const audioResponse = await axios.get(audioUrl, {
    responseType: 'blob',
  });

  // Cria um FormData para enviar o arquivo
  const formData = new FormData();
  formData.append('file', audioResponse.data, 'audio.mp3');

  // Adiciona os outros parâmetros
  formData.append('model', 'whisper-large-v3-turbo');
  formData.append('language', 'pt');
  formData.append('response_format', 'text');
  formData.append('temperature', '0');

  const response = await axios.post(GROQ_API_URL, formData, {
    headers: {
      Authorization: `Bearer ${window.chatwootConfig.groqApiKey}`,
      'Content-Type': 'multipart/form-data',
    },
  });

  return response.data;
};
