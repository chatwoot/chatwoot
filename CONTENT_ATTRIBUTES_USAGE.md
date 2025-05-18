# Content Attributes Feature Guide

This document explains how to use the new `content_attributes` feature that has been added to the Conversation model in LiveIQ (modified Chatwoot).

## Overview

The Content Attributes feature allows you to store and display structured metadata about a conversation that doesn't fit into the existing conversation model fields. This can be used for a wide range of purposes:

- Storing conversation analysis results
- Tracking conversation metrics and insights
- Adding custom tags or categorization
- Saving AI-generated summaries or sentiment analysis
- Storing workflow stage information

## Technical Implementation

The feature is implemented as a `jsonb` field in the PostgreSQL database, allowing for flexible schema-less storage of any JSON-compatible data.

### Model Changes

The `Conversation` model has been extended with:

```ruby
# Accessor methods
def content_attributes
  self[:content_attributes] || {}
end

def content_attributes=(attributes)
  self[:content_attributes] = attributes
end

# Helper methods
def update_content_attributes(attributes = {})
  update(content_attributes: attributes)
end

def add_content_attribute(key, value)
  attrs = content_attributes
  attrs[key] = value
  update(content_attributes: attrs)
end
```

### UI Integration

A new component `ContentAttributes.vue` has been created to display the content attributes in the conversation sidebar. It formats the attribute keys for better readability and handles different value types appropriately.

## Usage Examples

### Adding Content Attributes to a Conversation

```ruby
# In a Rails controller or service
conversation = Conversation.find(conversation_id)

# Method 1: Replace all content attributes
conversation.update_content_attributes({
  sentiment: 'positive',
  topic_analysis: ['billing', 'feature request'],
  priority_score: 85
})

# Method 2: Add a single attribute
conversation.add_content_attribute('response_time_seconds', 120)
```

### Adding Content Attributes in the UI

Currently this is implemented through the backend only. Future enhancements could include:

1. A UI form to add/edit content attributes
2. Automatic population via AI analysis of conversation content
3. Integration with third-party analytics tools

### Accessing Content Attributes via API

You can access the content attributes via the API in the conversation response:

```javascript
// Example API response (JSON)
{
  "id": 1,
  "inbox_id": 1,
  // ... other conversation fields
  "content_attributes": {
    "sentiment": "positive",
    "topic_analysis": ["billing", "feature request"],
    "priority_score": 85
  }
}
```

## Use Cases

### 1. Conversation Analytics

Store analysis results about the conversation:

```ruby
conversation.update_content_attributes({
  sentiment_analysis: {
    overall: 'positive',
    score: 0.85,
    key_phrases: ['very helpful', 'quick response']
  },
  topics_detected: ['billing', 'account setup'],
  language_detected: 'en',
  complexity_score: 0.4
})
```

### 2. Workflow Tracking

Track the state of a business workflow related to the conversation:

```ruby
conversation.update_content_attributes({
  support_workflow: {
    stage: 'investigation',
    escalated: true,
    needs_engineer_review: true, 
    estimated_resolution_time: '2 hours'
  }
})
```

### 3. Integration with AI Agent

Store AI Agent/Topic responses and context:

```ruby
conversation.update_content_attributes({
  ai_agent: {
    topics_covered: ['account setup', 'billing question'],
    suggested_responses: [
      'Would you like me to help you set up automatic payments?',
      'I can walk you through our different subscription options'
    ],
    confidence_level: 0.92
  }
})
```

## Best Practices

1. **Structure Your Data**: Use a consistent structure for similar types of data
2. **Don't Overuse**: For data that should be searchable or indexed, consider creating proper database fields
3. **Document Your Schemas**: Maintain documentation of the schemas you use for different types of content attributes
4. **Validation**: Add validation for complex content attribute structures in your application code

## Future Enhancements

1. Ability to search conversations by content attributes
2. UI for adding/editing content attributes 
3. Automatic population of content attributes based on conversation content
4. Reporting and analytics based on content attributes 