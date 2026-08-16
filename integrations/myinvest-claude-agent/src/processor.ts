import type { ChatwootPort } from './chatwoot-client.js'
import type { ClaudePort } from './claude.js'
import type { TenantConfig } from './config.js'
import type { ChatwootWebhookPayload, KnowledgeHit } from './domain.js'
import type { KnowledgeRepository } from './knowledge/repository.js'
import type { AgentState } from './state.js'

const explicitHuman =
  /\b(menschen?|mitarbeiter(?:in)?|support[- ]?team|echte person|berater(?:in)?)\b/i
const sensitiveAdvice =
  /\b(rechnung|bezahlen|zahlung|abbuchung|lastschrift|kreditkarte|refund|erstattung|preis|kosten|recht(?:lich|e|er)?|anwalt|vertrag|klausel|haftung|widerruf|kündigung|steuer(?:n|lich|beratung)?|rendite|anlageberatung|kaufempfehlung|verkaufsempfehlung|investmentberatung)\b/i
export class MessageProcessor {
  constructor(
    private readonly dependencies: {
      knowledge: KnowledgeRepository
      claude: ClaudePort
      chatwoot: ChatwootPort
      state: AgentState
      minRetrievalScore: number
      maxSources: number
    },
  ) {}

  async process(input: {
    tenant: TenantConfig
    payload: ChatwootWebhookPayload
  }): Promise<void> {
    const { tenant, payload } = input
    const conversationId = payload.conversation.id
    if (await this.dependencies.state.isHandedOff(tenant.key, conversationId)) return

    const delivery = await this.dependencies.state.beginDelivery(
      tenant.key,
      payload.id,
      conversationId,
    )
    if (!delivery.acquired) {
      if (delivery.status === 'processing' || delivery.status === 'sending') {
        await this.dependencies.chatwoot.handoff(tenant, conversationId)
        await this.dependencies.state.markHandedOff(tenant.key, conversationId)
        await this.dependencies.state.completeDelivery(tenant.key, payload.id, 'handed_off')
      }
      return
    }

    const handoff = async () => {
      await this.dependencies.chatwoot.handoff(tenant, conversationId)
      await this.dependencies.state.markHandedOff(tenant.key, conversationId)
      await this.dependencies.state.completeDelivery(tenant.key, payload.id, 'handed_off')
    }

    const question = payload.content.trim()
    if (!question || explicitHuman.test(question) || sensitiveAdvice.test(question)) {
      await handoff()
      return
    }

    try {
      const sources = await this.dependencies.knowledge.search(
        tenant.key,
        question,
        this.dependencies.maxSources,
      )
      if (!sources[0] || sources[0].score < this.dependencies.minRetrievalScore) {
        await handoff()
        return
      }
      const answer = await this.dependencies.claude.answer({
        tenantKey: tenant.key,
        question,
        sources,
      })
      const sourceList = sources
        .map((source) => sourceReference(source))
        .filter((value, index, all) => all.indexOf(value) === index)
        .join(', ')
      await this.dependencies.state.markSending(tenant.key, payload.id)
      await this.dependencies.chatwoot.sendMessage(
        tenant,
        conversationId,
        `${answer}\n\nQuellen: ${sourceList}`,
        payload.id,
      )
      await this.dependencies.state.completeDelivery(tenant.key, payload.id, 'replied')
    } catch {
      await handoff()
    }
  }
}

function sourceReference(source: KnowledgeHit): string {
  const url = source.metadata.url
  return typeof url === 'string' && /^https:\/\//.test(url)
    ? `${source.title} (${url})`
    : `${source.title} [${source.sourceId}]`
}
