---
path: "/docs/conversation-continuity"
title: "Configuring Conversation Continuity with Email"
---

### Conversation continuity

Conversation continuity is a de-facto most expected feature for all kind of support platforms. When we support multiple channels and integrations it becomes really difficult to implement this from the start. As for Chatwoot, with Facebook or Twitter channels, the users usually expect you to reach back on the same platform itself. 

When it comes to the Web Widget which is embedded in a website, this is not the case. There are technical limitations for us to maintain this conversation continuity. When an end-user initiates the chat from the Web Widget and an agent is not online, there are questions on how you reach back to that user and how a conversation can progress.

As a first step what we did for this was to capture the email of the user when the chat is initiated. The chat window prompts the user for an email when the user starts a conversation. This is captured in the system as part of the contact's information. The agent can reach back to the user using this given email, but until now the replies used to come back to the agent's email address directly and not Chatwoot.

With a second step that we have done, we are now introducing the capability of conversation continuity directly in Chatwoot Inbox. How this works is, once you have configured all the email settings (which will be discussed shortly in the upcoming sections below), you can send a reply as an email to any of the conversations with a contact having an email and receive the email reply in the conversation thread. This is irrespective of the channel from where the conversation was first initiated. It can be Facebook, Twitter, Web Widget, Twilio, Whatsapp and what not. You conversation always continues seamlessly.


### Configuring inbound reply emails

There are a couple of email infrastructure service providers to handle the incoming emails that we support at the moment. They are 
Sendgrid, Mandrill, Mailgun, Exim, Postfix, Qmail and Postmark.

Step 1 : We have to set the inbound email service used as an environment variable. 

```bash
# Set this to appropriate ingress service for which the options are :
# "relay" for Exim, Postfix, Qmail
# "mailgun" for Mailgun
# "mandrill" for Mandrill
# "postmark" for Postmark
# "sendgrid" for Sendgrid
RAILS_INBOUND_EMAIL_SERVICE=relay
```

This configures the ingress service for the app. Now we have to set the password for the ingress service that we use.

```bash
# Use one of the following based on the email ingress service

# Set this if you are using Sendgrid, Exim, Postfix, Qmail or Postmark
RAILS_INBOUND_EMAIL_PASSWORD=
# Set this if you are Mailgun
MAILGUN_INGRESS_SIGNING_KEY=
# Set this if you are Mandrill
MANDRILL_INGRESS_API_KEY=
```

If you are using Mailgun as your email service, in the Mailgun dashboard configure it to forward your inbound emails to `https://example.com/rails/action_mailbox/mailgun/inbound_emails/mime` if `example.com` is where you have hosted the application.


If you are choosing Sendgrid to be your email service, configure SendGrid Inbound Parse to forward inbound emails to forward your inbound emails to `/rails/action_mailbox/sendgrid/inbound_emails` with the username `actionmailbox` and the password you previously generated. If the deployed application was hosted at `example.com`, you can configure the following URL as the forward route.


```bash
https://actionmailbox:PASSWORD@example.com/rails/action_mailbox/sendgrid/inbound_emails
```


If you are configuring Mandrill as your email service, configure Mandrill to route your inbound emails to `https://example.com/rails/action_mailbox/mandrill/inbound_emails` if `example.com` is where you have hosted the application.

If you want to know more about configuring other services visit [Action Mailbox Basics](https://edgeguides.rubyonrails.org/action_mailbox_basics.html#configuration)


### Enable continuity in the account.

1. Enable `inbound_emails` (Login to rails console and execute the following)

```
account = Account.find(1)
account.enabled_features // This would list enabled features.
account.enable_features('inbound_emails')
account.save!
```

2. Set an inbound domain. This is the domain with which you have set up above.

```
account = Account.find(1)
account.domain='domain.com'
account.save!
```

After executing these steps, the mail sent from Chatwoot will have a `replyto:` in the following format `reply+<random-hex>@<your-domain.com>` and reply to those would get appended to your conversation.
