---
path: "/docs/customizations/email-notifications"
title: "Customize email notifications in Chatwoot"
---

Chatwoot allows customization of email notifications in self hosted installations.

To customize the email notifications, follow the instructions below. Inorder to update the content, you have to add a new template in the Database, here is how you can do it.

### 1. Login into the rails console.

For Heroku installation, login to your account, go to the app. Click on "More", select "Run Console" from the dropdown menu. Enter the following command and hit run

```rb
heroku run rails console
```

For Linux VM installations, go to directory where Chatwoot code is available. If you have used the installation script, the default path is `/home/chatwoot/chatwoot`. Run the following command.

```rb
RAILS_ENV=production bundle exec rails console
```

### 2. Create a new template for the emails. Execute the following commands.

```rb
email_template = EmailTemplate.new
email_template.name = 'conversation_assignment' # Accepts conversation_assignment, conversation_creation
email_template.body = '// Enter your content'
email_template.save!
```

#### Variables

Template would receive 3 variable

1. `user` - Use `{{ user.name }}` to get the username.
2. `conversation` - Use `{{ conversation.display_id }}` to get the conversation ID
3. `action_url` - This is the URL of the conversation.

### Default content 

Default content of the above template is as shown below

#### 1. Conversation Assignment

```html
<p>Hi {{user.available_name}},</p>
<p>Time to save the world. A new conversation has been assigned to you</p>
<p> Click <a href="{{action_url}}">here</a> to get cracking.</p>
```

#### 2. Conversation Creation

```html
<p>Hi {{user.available_name}}</p>

<p>Time to save the world. A new conversation has been created in {{ inbox.name }}</p>
<p>
Click <a href="{{ action_url }}">here</a> to get cracking.
</p>
```

We use [Liquid templating engine](https://shopify.github.io/liquid/) internally, so all valid operators can be used here.


