import { createClaudeClient } from './claude.js'
import { loadConfig } from './config.js'

const client = createClaudeClient(loadConfig())
await client.answer({
  tenantKey: 'saas',
  question: 'Welches Wort steht in der freigegebenen Quelle?',
  sources: [
    {
      sourceId: 'provider-check',
      title: 'Provider-Verbindungstest',
      content: 'Das freigegebene Wort lautet VERBUNDEN.',
      metadata: {},
      score: 1,
    },
  ],
})
process.stdout.write('Claude provider check passed.\n')
