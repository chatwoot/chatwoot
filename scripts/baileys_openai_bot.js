const {
  makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
} = require('@adiwajshing/baileys');
const { Configuration, OpenAIApi } = require('openai');
const P = require('pino');

async function askOpenAI(text) {
  const configuration = new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
  });
  const openai = new OpenAIApi(configuration);
  const completion = await openai.createChatCompletion({
    model: 'gpt-3.5-turbo',
    messages: [{ role: 'user', content: text }],
  });
  return completion.data.choices[0].message.content.trim();
}

async function connectToWhatsApp() {
  const { state, saveCreds } = await useMultiFileAuthState('auth_info_baileys');
  const socket = makeWASocket({
    logger: P({ level: 'silent' }),
    auth: state,
    printQRInTerminal: true,
  });

  socket.ev.on('creds.update', saveCreds);

  socket.ev.on('connection.update', ({ connection, lastDisconnect }) => {
    if (connection === 'close') {
      const shouldReconnect =
        lastDisconnect.error?.output?.statusCode !== DisconnectReason.loggedOut;
      if (shouldReconnect) {
        connectToWhatsApp();
      }
    }
  });

  socket.ev.on('messages.upsert', async ({ messages }) => {
    const msg = messages[0];
    if (!msg.message || msg.key.fromMe) return;
    const response = await askOpenAI(msg.message.conversation || '');
    await socket.sendMessage(msg.key.remoteJid, { text: response });
  });
}
connectToWhatsApp();
