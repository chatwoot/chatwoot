import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function sendEmail({
  to,
  from,
  fromName,
  subject,
  html,
  text,
  replyTo,
  inReplyTo,
}: {
  to: string
  from: string
  fromName?: string
  subject: string
  html?: string
  text?: string
  replyTo?: string
  inReplyTo?: string
}) {
  const fromAddress = fromName ? `${fromName} <${from}>` : from

  return resend.emails.send({
    from: fromAddress,
    to,
    subject,
    html: html ?? text ?? '',
    text: text,
    replyTo,
    headers: inReplyTo ? { 'In-Reply-To': inReplyTo, References: inReplyTo } : undefined,
  })
}
