---
layout: default
title: Structured Output
parent: Guides
nav_order: 5
---

# Structured Output

Structured output ensures AI agents return responses in a predictable JSON format that conforms to a specified schema. This is useful for building reliable integrations, data extraction workflows, and applications that need consistent response formats.

## Basic Usage

Add a `response_schema` when creating an agent to enforce structured responses:

```ruby
# JSON Schema approach
extraction_agent = Agents::Agent.new(
  name: "DataExtractor",
  instructions: "Extract key information from user messages",
  response_schema: {
    type: 'object',
    properties: {
      entities: { type: 'array', items: { type: 'string' } },
      sentiment: { type: 'string', enum: ['positive', 'negative', 'neutral'] },
      summary: { type: 'string' }
    },
    required: ['entities', 'sentiment'],
    additionalProperties: false
  }
)

runner = Agents::Runner.with_agents(extraction_agent)
result = runner.run("I love the new product features, especially the API and dashboard!")

# Response will be valid JSON matching the schema:
# {
#   "entities": ["API", "dashboard"],
#   "sentiment": "positive",
#   "summary": "User expresses enthusiasm for new product features"
# }
```

## RubyLLM::Schema (Recommended)

For more complex schemas, use `RubyLLM::Schema` which provides a cleaner Ruby DSL:

```ruby
class ContactSchema < RubyLLM::Schema
  string :name, description: "Full name of the person"
  string :email, description: "Email address"
  string :phone, description: "Phone number", required: false
  string :company, description: "Company name", required: false
  array :interests, description: "List of interests or topics mentioned" do
    string description: "Individual interest or topic"
  end
end

contact_agent = Agents::Agent.new(
  name: "ContactExtractor",
  instructions: "Extract contact information from business communications",
  response_schema: ContactSchema
)

runner = Agents::Runner.with_agents(contact_agent)
result = runner.run("Hi, I'm Sarah Johnson from TechCorp. You can reach me at sarah@techcorp.com or 555-0123. I'm interested in AI and automation solutions.")

# Returns structured contact data:
# {
#   "name": "Sarah Johnson",
#   "email": "sarah@techcorp.com",
#   "phone": "555-0123",
#   "company": "TechCorp",
#   "interests": ["AI", "automation solutions"]
# }
```
