window.process = {
  env: {
    GROQ_API_KEY: window.groqApiKey || process.env.GROQ_API_KEY,
  },
};
