import { createHash } from 'node:crypto'
import { lstat, readFile, realpath } from 'node:fs/promises'
import { basename, dirname, join, resolve } from 'node:path'
import { z } from 'zod'
import { tenantKeySchema, type TenantKey } from '../domain.js'

const fileDescriptorSchema = z
  .object({
    path: z.string(),
    sha256: z.string().regex(/^[0-9a-f]{64}$/),
    count: z.number().int().min(0).max(10_000_000),
  })
  .strict()

const manifestSchema = z
  .object({
    schema_version: z.literal(2),
    source_namespace: z.string().regex(/^hubspot-conversations-v\d+$/),
    export_id: z.string().min(1).max(512),
    tenant_key: tenantKeySchema,
    created_at: z.iso.datetime({ offset: true }),
    knowledge_import: z.literal(false),
    files: z
      .object({
        contacts: fileDescriptorSchema,
        conversations: fileDescriptorSchema,
        messages: fileDescriptorSchema,
      })
      .strict(),
  })
  .strict()

const messageSchema = z
  .object({
    external_id: z.string().min(1).max(512),
    conversation_external_id: z.string().min(1).max(512),
    direction: z.enum(['incoming', 'outgoing', 'note']),
    content: z.string().max(150_000),
    created_at: z.iso.datetime({ offset: true }),
    updated_at: z.iso.datetime({ offset: true }),
    attachments: z.array(z.unknown()).max(100),
    metadata: z.record(z.string(), z.unknown()).optional(),
  })
  .strict()

type BundleMessage = z.infer<typeof messageSchema>

export interface KnowledgeCandidate {
  candidateKey: string
  previousCandidateKeys: string[]
  sourcePairDigest: string
  sourceNamespace: string
  sourceExportId: string
  sourceConversationDigest: string
  targetTenant: TenantKey | null
  questionRedacted: string
  answerRedacted: string
  contentHash: string
  redactionCount: number
  riskFlags: string[]
  status: 'quarantined' | 'pending_review'
  redactionVersion: number
}

export interface CandidateExtraction {
  candidates: KnowledgeCandidate[]
  examinedPairs: number
  rejectedPairs: number
  sourceNamespace: string
  sourceExportId: string
  redactionVersion: number
}

const sensitiveTopic =
  /\b(?:passwort|kennwort|otp|2fa|tan|kreditkarte|iban|konto(?:nummer)?|zahlung|abbuchung|lastschrift|refund|erstattung|anwalt|recht(?:lich|e|er)?|haftung|steuer(?:n|lich|beratung)?|rendite|anlageberatung|kaufempfehlung|verkaufsempfehlung|investmentberatung)\b/iu
const likelySecret = /\b(?:sk|pk|api|access|secret|token)[-_][a-z0-9_-]{12,}\b/iu
const directPersonalization = /\b(?:kundennummer|vertragsnummer|geburtsdatum|anschrift)\b/iu

const legacyRedactions: Array<[RegExp, string]> = [
  [/[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+/giu, '[E-MAIL]'],
  [/\bDE\d{20}\b/giu, '[IBAN]'],
  [/\b(?:https?:\/\/|www\.)\S+/giu, '[LINK]'],
  [/(?:^|(?<=\s))\+?\d(?:[\s()./-]*\d){7,14}(?=$|[\s,.;!?])/gu, '[TELEFON]'],
  [/\b(?:kunden|vertrags|ticket|vorgangs|rechnungs)?(?:nummer|nr\.?|id)\s*[:#-]?\s*[a-z0-9-]{5,}\b/giu, '[REFERENZ]'],
  [/\b(?:hallo|hi|guten tag|liebe?r?)\s+[\p{L}][\p{L}'-]{1,40}(?:\s+[\p{L}][\p{L}'-]{1,40})?(?=[,!])/giu, 'Hallo [NAME]'],
  [/\b(?:viele|beste|freundliche|liebe)\s+grüße[,]?\s+[\p{L}][\p{L}'-]{1,40}(?:\s+[\p{L}][\p{L}'-]{1,40})?/giu, 'Viele Grüße [NAME]'],
  [/\b[\p{L}][\p{L}'-]{1,40}(?:straße|str\.|weg|allee|platz)\s+\d{1,4}[a-z]?\b/giu, '[ADRESSE]'],
]

const strictRedactions: Array<[RegExp, string]> = [
  [/[^\s@]*@[^\s@]*/gu, '[E-MAIL/ACCOUNT]'],
  [/\bDE\d{20}\b/giu, '[IBAN]'],
  [/(?:\+?\d[\s()./_-]*){8,}/gu, '[TELEFON/NUMMER]'],
  [/\b(?:vorname|nachname|name|ansprechpartner(?:in)?|kundenname)\s*[:=-]\s*[\p{L}][\p{L}'-]{1,40}(?:\s+[\p{L}][\p{L}'-]{1,40})?/giu, '[NAME]'],
  [/\b(?:mein(?: vollständiger)? name ist|ich heiße|ich heisse)\s+[\p{L}][\p{L}'-]{1,40}(?:\s+[\p{L}][\p{L}'-]{1,40})?/giu, 'Mein Name ist [NAME]'],
  [/\b(?:hallo|hi|guten tag|liebe?r?)\s+[\p{L}][\p{L}'-]{1,40}/giu, 'Hallo [NAME]'],
  [/\b(?:mit freundlichen grüßen|freundliche grüße|beste grüße|viele grüße|liebe grüße|lg|vg|gruß|gruss|grüße|gruesse)\s*[,;:-]?\s+(?:dein(?:e)?|euer|ihr(?:e)?|von)?\s*[\p{L}][\p{L}'-]{1,40}(?:\s+[\p{L}][\p{L}'-]{1,40}){0,2}/giu, 'Viele Grüße [NAME]'],
  ...legacyRedactions,
  [/\b(?:mein(?: vollständiger)? name ist|ich heiße|ich heisse)\b[^.!?]*(?:[.!?]|$)/giu, 'Mein Name ist [NAME].'],
  [/\b(?:mit freundlichen grüßen|freundliche grüße|beste grüße|viele grüße|liebe grüße|lg|vg|gruß|gruss|grüße|gruesse)(?=\s|[,;:!.-]|$)[\s\S]*$/iu, 'Viele Grüße [SIGNATUR ENTFERNT]'],
]

function redactWithRules(
  input: string,
  rules: Array<[RegExp, string]>,
): { text: string; redactionCount: number } {
  let text = input
    .normalize('NFKC')
    .replace(/<[^>]+>/g, ' ')
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  let redactionCount = 0
  for (const [pattern, replacement] of rules) {
    text = text.replace(pattern, () => {
      redactionCount += 1
      return replacement
    })
  }
  return { text, redactionCount }
}

export function redactSupportText(input: string): { text: string; redactionCount: number } {
  return redactWithRules(input, strictRedactions)
}

function legacyRedactSupportText(input: string): { text: string; redactionCount: number } {
  return redactWithRules(input, legacyRedactions)
}

function containsResidualPersonalData(value: string): boolean {
  return (
    /@/u.test(value) ||
    /(?:\d[\s()./_+-]*){8,}/u.test(value) ||
    /\bDE\d{20}\b/iu.test(value) ||
    /\b(?:mein(?: vollständiger)? name ist|ich heiße|ich heisse)\s+\p{L}/iu.test(value) ||
    /\b(?:mit freundlichen grüßen|freundliche grüße|beste grüße|viele grüße|liebe grüße|lg|vg|gruß|gruss|grüße|gruesse)\s*[,;:-]?\s+\p{L}/iu.test(value)
  )
}

function candidateFromPair(
  manifest: z.infer<typeof manifestSchema>,
  questionMessage: BundleMessage,
  answerMessage: BundleMessage,
): KnowledgeCandidate | null {
  if (questionMessage.attachments.length > 0 || answerMessage.attachments.length > 0) return null
  const question = redactSupportText(questionMessage.content)
  const answer = redactSupportText(answerMessage.content)
  if (containsResidualPersonalData(`${question.text} ${answer.text}`)) return null
  if (question.text.length < 10 || answer.text.length < 10) return null
  if (question.text.length > 1_000 || answer.text.length > 2_500) return null
  if (
    sensitiveTopic.test(`${question.text} ${answer.text}`) ||
    likelySecret.test(`${question.text} ${answer.text}`) ||
    directPersonalization.test(`${question.text} ${answer.text}`)
  ) {
    return null
  }
  const contentHash = createHash('sha256')
    .update(`${question.text}\0${answer.text}`)
    .digest('hex')
  const conversationDigest = createHash('sha256')
    .update(questionMessage.conversation_external_id)
    .digest('hex')
  const sourcePairDigest = createHash('sha256')
    .update(`${questionMessage.external_id}\0${answerMessage.external_id}`)
    .digest('hex')
  const candidateKey = createHash('sha256')
    .update(`${manifest.source_namespace}\0${sourcePairDigest}`)
    .digest('hex')
  const legacyQuestion = legacyRedactSupportText(questionMessage.content).text
  const legacyAnswer = legacyRedactSupportText(answerMessage.content).text
  const legacyContentHash = createHash('sha256')
    .update(`${legacyQuestion}\0${legacyAnswer}`)
    .digest('hex')
  const previousCandidateKey = createHash('sha256')
    .update(`${manifest.source_namespace}\0${conversationDigest}\0${legacyContentHash}`)
    .digest('hex')
  return {
    candidateKey,
    previousCandidateKeys: previousCandidateKey === candidateKey ? [] : [previousCandidateKey],
    sourcePairDigest,
    sourceNamespace: manifest.source_namespace,
    sourceExportId: manifest.export_id,
    sourceConversationDigest: conversationDigest,
    targetTenant: null,
    questionRedacted: question.text,
    answerRedacted: answer.text,
    contentHash,
    redactionCount: question.redactionCount + answer.redactionCount,
    riskFlags: ['unclassified_hubspot_history'],
    status: 'quarantined',
    redactionVersion: 3,
  }
}

export function extractCandidates(
  manifestInput: unknown,
  messageInputs: unknown[],
): CandidateExtraction {
  const manifest = manifestSchema.parse(manifestInput)
  const messages = messageInputs.map((input) => messageSchema.parse(input))
  const conversations = new Map<string, BundleMessage[]>()
  for (const message of messages) {
    const conversation = conversations.get(message.conversation_external_id) ?? []
    conversation.push(message)
    conversations.set(message.conversation_external_id, conversation)
  }
  const candidates: KnowledgeCandidate[] = []
  let examinedPairs = 0
  let rejectedPairs = 0

  for (const conversationMessages of conversations.values()) {
    const sorted = [...conversationMessages].sort((left, right) =>
      left.created_at.localeCompare(right.created_at) || left.external_id.localeCompare(right.external_id),
    )
    let question: BundleMessage | undefined
    for (const message of sorted) {
      if (message.direction === 'incoming') {
        question = message
      } else if (message.direction === 'outgoing' && question) {
        examinedPairs += 1
        const candidate = candidateFromPair(manifest, question, message)
        if (candidate) candidates.push(candidate)
        else rejectedPairs += 1
        question = undefined
      }
    }
  }

  return {
    candidates: [...candidates].sort((left, right) => left.candidateKey.localeCompare(right.candidateKey)),
    examinedPairs,
    rejectedPairs,
    sourceNamespace: manifest.source_namespace,
    sourceExportId: manifest.export_id,
    redactionVersion: 3,
  }
}

async function readPrivateBundleFile(root: string, filename: string, maxBytes: number): Promise<Buffer> {
  if (basename(filename) !== filename) throw new Error('Unsafe bundle path')
  const path = join(root, filename)
  const stat = await lstat(path)
  const resolvedRoot = await realpath(root)
  const resolvedPath = await realpath(path)
  if (!stat.isFile() || stat.isSymbolicLink() || dirname(resolvedPath) !== resolvedRoot) {
    throw new Error('Unsafe bundle file')
  }
  if (stat.size > maxBytes) throw new Error('Bundle file exceeds size limit')
  return readFile(path)
}

export async function extractCandidatesFromBundle(rootInput: string): Promise<CandidateExtraction> {
  const root = resolve(rootInput)
  const manifestBytes = await readPrivateBundleFile(root, 'manifest.json', 1_048_576)
  const manifest = manifestSchema.parse(JSON.parse(manifestBytes.toString('utf8')))
  if (
    manifest.files.contacts.path !== 'contacts.ndjson' ||
    manifest.files.conversations.path !== 'conversations.ndjson' ||
    manifest.files.messages.path !== 'messages.ndjson'
  ) {
    throw new Error('Unexpected bundle paths')
  }
  const messagesBytes = await readPrivateBundleFile(root, manifest.files.messages.path, 268_435_456)
  const digest = createHash('sha256').update(messagesBytes).digest('hex')
  if (digest !== manifest.files.messages.sha256) throw new Error('Messages digest mismatch')
  const text = new TextDecoder('utf-8', { fatal: true }).decode(messagesBytes)
  const lines = messagesBytes.length === 0 ? [] : text.split('\n')
  if (lines.at(-1) === '') lines.pop()
  if (lines.some((line) => line.length === 0)) throw new Error('Blank NDJSON line')
  if (lines.length !== manifest.files.messages.count) throw new Error('Messages count mismatch')
  return extractCandidates(manifest, lines.map((line) => JSON.parse(line)))
}
