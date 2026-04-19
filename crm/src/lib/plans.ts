export type PlanId = 'free' | 'pro'

export const PLANS: Record<PlanId, {
  name: string
  price: number
  description: string
  features: string[]
}> = {
  free: {
    name: 'Free',
    price: 0,
    description: 'Get started at no cost',
    features: [
      'Up to 2 inboxes',
      'Up to 3 agents',
      'Live chat & email channels',
      'Basic reports (30 days)',
      '100 conversations / month',
    ],
  },
  pro: {
    name: 'Pro',
    price: 49,
    description: 'For growing support teams',
    features: [
      'Unlimited inboxes',
      'Unlimited agents',
      'WhatsApp & SMS via Twilio',
      'Automations & macros',
      'Outbound webhook subscriptions',
      'Full reports (90 days)',
      'Unlimited conversations',
      'Priority support',
    ],
  },
}

export function getPlan(plan: string): PlanId {
  return plan === 'pro' ? 'pro' : 'free'
}

export function isPro(plan: string) {
  return plan === 'pro'
}
