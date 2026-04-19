export async function sendTwilioMessage({
  accountSid,
  authToken,
  from,
  to,
  body,
  channelType,
}: {
  accountSid: string
  authToken: string
  from: string
  to: string
  body: string
  channelType: 'WHATSAPP' | 'SMS'
}) {
  const prefix = channelType === 'WHATSAPP' ? 'whatsapp:' : ''
  const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      From: `${prefix}${from}`,
      To: `${prefix}${to}`,
      Body: body,
    }).toString(),
  })

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Twilio error ${res.status}: ${text}`)
  }
  return res.json()
}
