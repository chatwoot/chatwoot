import { db } from '@/lib/db'
import type { ConversationStatus } from '@/generated/prisma/client'

export type AutomationEvent =
  | 'conversation_created'
  | 'conversation_updated'
  | 'message_created'

interface Condition {
  attribute: string
  operator: string
  value: string
}

export interface AutomationAction {
  type: string
  params: Record<string, string>
}

export async function processEvent(
  accountId: string,
  event: AutomationEvent,
  conversationId: string,
) {
  const automations = await db.automation.findMany({
    where: { accountId, active: true, event },
  })
  if (!automations.length) return

  const conversation = await db.conversation.findUnique({
    where: { id: conversationId },
    include: {
      labels: { include: { label: true } },
      contact: true,
    },
  })
  if (!conversation) return

  for (const automation of automations) {
    const conditions = automation.conditions as Condition[]
    const actions = automation.actions as AutomationAction[]
    if (evaluateConditions(conditions, conversation)) {
      await executeActions(accountId, conversationId, actions)
    }
  }
}

function evaluateConditions(
  conditions: Condition[],
  conversation: {
    status: ConversationStatus
    inboxId: string
    assigneeId: string | null
    labels: { label: { title: string } }[]
    contact: { email: string | null } | null
  },
): boolean {
  if (!conditions.length) return true
  return conditions.every((c) => {
    const val = getAttributeValue(c.attribute, conversation)
    return evaluateCondition(c.operator, val, c.value)
  })
}

function getAttributeValue(
  attribute: string,
  conversation: {
    status: ConversationStatus
    inboxId: string
    assigneeId: string | null
    labels: { label: { title: string } }[]
    contact: { email: string | null } | null
  },
): string {
  switch (attribute) {
    case 'status':
      return conversation.status
    case 'inbox_id':
      return conversation.inboxId
    case 'assignee_id':
      return conversation.assigneeId ?? ''
    case 'label':
      return conversation.labels.map((l) => l.label.title).join(',')
    case 'contact_email':
      return conversation.contact?.email ?? ''
    default:
      return ''
  }
}

function evaluateCondition(operator: string, val: string, target: string): boolean {
  switch (operator) {
    case 'equals':
      return val === target
    case 'not_equals':
      return val !== target
    case 'contains':
      return val.toLowerCase().includes(target.toLowerCase())
    case 'not_contains':
      return !val.toLowerCase().includes(target.toLowerCase())
    case 'is_present':
      return val.trim() !== ''
    case 'is_not_present':
      return val.trim() === ''
    default:
      return false
  }
}

export async function executeActions(
  accountId: string,
  conversationId: string,
  actions: AutomationAction[],
) {
  for (const action of actions) {
    await executeAction(accountId, conversationId, action)
  }
}

async function executeAction(
  accountId: string,
  conversationId: string,
  action: AutomationAction,
) {
  switch (action.type) {
    case 'assign_agent': {
      const agentId = action.params.agentId
      if (!agentId) break
      const member = await db.accountMember.findFirst({
        where: { accountId, userId: agentId },
      })
      if (!member) break
      await db.conversation.update({
        where: { id: conversationId },
        data: { assigneeId: agentId },
      })
      break
    }
    case 'update_status': {
      const status = action.params.status as ConversationStatus
      if (!status) break
      await db.conversation.update({
        where: { id: conversationId },
        data: { status },
      })
      break
    }
    case 'add_label': {
      const labelId = action.params.labelId
      if (!labelId) break
      const label = await db.label.findFirst({ where: { id: labelId, accountId } })
      if (!label) break
      await db.conversationLabel.upsert({
        where: { conversationId_labelId: { conversationId, labelId } },
        create: { conversationId, labelId },
        update: {},
      })
      break
    }
    case 'remove_label': {
      const labelId = action.params.labelId
      if (!labelId) break
      await db.conversationLabel.deleteMany({ where: { conversationId, labelId } })
      break
    }
    case 'send_message': {
      const content = action.params.content
      if (!content) break
      await db.message.create({
        data: { conversationId, content, contentType: 'text', authorType: 'bot' },
      })
      break
    }
    case 'send_webhook': {
      const url = action.params.url
      if (!url) break
      try {
        await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ event: 'automation', conversationId, accountId }),
        })
      } catch {
        // webhook failures are silent
      }
      break
    }
  }
}
