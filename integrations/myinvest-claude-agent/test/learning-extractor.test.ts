import { describe, expect, it } from 'vitest'
import { extractCandidates, redactSupportText } from '../src/learning/extractor.js'

const manifest = {
  schema_version: 2,
  source_namespace: 'hubspot-conversations-v3',
  export_id: 'export-1',
  tenant_key: 'legacy_academy',
  created_at: '2026-08-16T10:00:00Z',
  knowledge_import: false,
  files: {
    contacts: { path: 'contacts.ndjson', sha256: 'a'.repeat(64), count: 1 },
    conversations: { path: 'conversations.ndjson', sha256: 'b'.repeat(64), count: 1 },
    messages: { path: 'messages.ndjson', sha256: 'c'.repeat(64), count: 2 },
  },
} as const

function message(overrides: Record<string, unknown>) {
  return {
    external_id: 'message-1',
    conversation_external_id: 'conversation-1',
    direction: 'incoming',
    content: 'Wie ändere ich meine Benachrichtigungen?',
    created_at: '2026-08-16T10:00:00Z',
    updated_at: '2026-08-16T10:00:00Z',
    attachments: [],
    metadata: { source: 'hubspot' },
    ...overrides,
  }
}

describe('HubSpot knowledge candidate extraction', () => {
  it('redacts PII deterministically and always quarantines unclassified history', () => {
    const messages = [
      message({
        content: 'Hallo Lucas, bitte antworte an lucas@example.com oder +49 162 12345678.',
      }),
      message({
        external_id: 'message-2',
        direction: 'outgoing',
        content: 'Hallo Lucas, öffne https://example.com/private?token=abc und ändere es dort.',
        created_at: '2026-08-16T10:01:00Z',
        updated_at: '2026-08-16T10:01:00Z',
      }),
    ]
    const first = extractCandidates(manifest, messages)
    const second = extractCandidates(manifest, messages)

    expect(first).toEqual(second)
    expect(first.candidates).toHaveLength(1)
    expect(first.candidates[0]).toMatchObject({
      targetTenant: null,
      status: 'quarantined',
      riskFlags: ['unclassified_hubspot_history'],
      redactionVersion: 3,
    })
    expect(`${first.candidates[0]!.questionRedacted} ${first.candidates[0]!.answerRedacted}`)
      .not.toMatch(/lucas@example|12345678|token=abc/i)
  })

  it('rejects sensitive advice, attachments, and raw secrets instead of learning them', () => {
    const cases = [
      'Welche Anlageberatung bringt die beste Rendite?',
      'Mein Passwort ist secret-api-token-123456789.',
    ]
    for (const content of cases) {
      const result = extractCandidates(manifest, [
        message({ content }),
        message({
          external_id: 'message-2',
          direction: 'outgoing',
          content: 'Das ist eine ausreichend lange Supportantwort.',
          created_at: '2026-08-16T10:01:00Z',
          updated_at: '2026-08-16T10:01:00Z',
        }),
      ])
      expect(result.candidates).toEqual([])
      expect(result.rejectedPairs).toBe(1)
    }
  })

  it('redacts common identifiers without echoing their values', () => {
    const result = redactSupportText(
      'E-Mail name@example.org, IBAN DE02120300000000202051, Ticket-ID ABCDE-12345.',
    )
    expect(result.text).toContain('[E-MAIL/ACCOUNT]')
    expect(result.text).toContain('[IBAN]')
    expect(result.text).toContain('[REFERENZ]')
    expect(result.text).not.toMatch(/example\.org|202051|ABCDE-12345/)
  })

  it('fails closed for every at-token and long separated digit sequence', () => {
    for (const input of [
      '@private_handle',
      'konto@ohne-domain',
      'Telefon 0049 (0) 162 / 12 34 56 78',
      'Referenz 1234-5678-9012-3456',
      'Name: Max Mustermann',
      'Hallo Maximilian ich brauche Hilfe',
      'Mein Name ist Max Mustermann',
      'Mit freundlichen Grüßen Max Mustermann',
      'LG Max',
    ]) {
      const result = redactSupportText(input)
      expect(result.text).not.toContain('@')
      expect(result.text).not.toMatch(/(?:\d[\s()./_+-]*){8,}/)
      expect(result.text).not.toMatch(/Max Mustermann|Maximilian/)
    }
  })
})
