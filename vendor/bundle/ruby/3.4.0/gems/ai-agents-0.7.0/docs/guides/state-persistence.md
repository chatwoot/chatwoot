---
layout: default
title: State Persistence
parent: Guides
nav_order: 3
---

# State Persistence

The AI Agents library provides flexible mechanisms for persisting state between agent interactions and tool executions. This guide covers context serialization, cross-session persistence, and state management patterns.

## Context Serialization

The library's context system is designed to be fully serializable, enabling persistence across process boundaries.

### Basic Serialization

Context objects can be converted to and from JSON:

```ruby
# Run an agent
result = runner.run("Hello, my name is John")

# Serialize context to JSON
context_json = result.context.to_json

# Later, deserialize and continue conversation
restored_context = JSON.parse(context_json, symbolize_names: true)
next_result = runner.run("What's my name?", context: restored_context)
# => "Your name is John"
```

### Database Storage

Store context in your database for long-term persistence:

```ruby
# Store context in database
class ConversationState < ActiveRecord::Base
  def context=(hash)
    self.context_data = hash.to_json
  end
  
  def context
    JSON.parse(context_data, symbolize_names: true)
  end
end

# Usage
conversation = ConversationState.create(
  user_id: user.id,
  context: result.context.to_h
)

# Restore later
restored_context = conversation.context
continued_result = runner.run("Continue conversation", context: restored_context)
```

## Cross-Session Persistence

### Session-Based State

Maintain state across HTTP requests using sessions:

```ruby
class ChatController < ApplicationController
  def send_message
    # Retrieve context from session
    context = session[:agent_context] || {}
    
    # Run agent
    result = agent_runner.run(params[:message], context: context)
    
    # Store updated context in session
    session[:agent_context] = result.context.to_h
    
    render json: { response: result.output }
  end
  
  def reset_conversation
    session[:agent_context] = nil
    render json: { message: "Conversation reset" }
  end
end
```

### File-Based Persistence

For development or simple deployments:

```ruby
class FileContextPersistence
  def initialize(storage_path = "./contexts")
    @storage_path = storage_path
    FileUtils.mkdir_p(@storage_path)
  end
  
  def save_context(user_id, context)
    file_path = context_file_path(user_id)
    File.write(file_path, context.to_json)
  end
  
  def load_context(user_id)
    file_path = context_file_path(user_id)
    return {} unless File.exist?(file_path)
    
    JSON.parse(File.read(file_path), symbolize_names: true)
  end
  
  def delete_context(user_id)
    file_path = context_file_path(user_id)
    File.delete(file_path) if File.exist?(file_path)
  end
  
  private
  
  def context_file_path(user_id)
    File.join(@storage_path, "#{user_id}.json")
  end
end

# Usage
persistence = FileContextPersistence.new
context = persistence.load_context(user.id)

result = runner.run(message, context: context)
persistence.save_context(user.id, result.context.to_h)
```

## State Management Patterns

### Context Layering

Organize context data into logical layers:

```ruby
def build_layered_context(user, conversation_id)
  {
    # User layer - persistent across all conversations
    user: {
      id: user.id,
      name: user.name,
      preferences: user.preferences
    },
    
    # Conversation layer - specific to this conversation
    conversation: {
      id: conversation_id,
      started_at: Time.current,
      topic: nil
    },
    
    # Session layer - temporary data for current session
    session: {
      last_activity: Time.current,
      interaction_count: 0
    }
  }
end
```

### Context Cleanup

Prevent context from growing indefinitely:

```ruby
class ContextCleaner
  MAX_HISTORY_SIZE = 20
  MAX_CONTEXT_KEYS = 50
  
  def self.clean_context(context)
    cleaned = context.deep_dup
    
    # Limit conversation history
    if cleaned[:conversation_history]&.size > MAX_HISTORY_SIZE
      cleaned[:conversation_history] = cleaned[:conversation_history].last(MAX_HISTORY_SIZE)
    end
    
    # Remove old temporary data
    cleaned.delete(:temp_data) if cleaned[:temp_data]
    
    # Limit total context size
    if cleaned.keys.size > MAX_CONTEXT_KEYS
      # Keep essential keys, remove extras
      essential_keys = [:user_id, :current_agent, :conversation_history]
      extra_keys = cleaned.keys - essential_keys
      extra_keys.first(cleaned.keys.size - MAX_CONTEXT_KEYS).each do |key|
        cleaned.delete(key)
      end
    end
    
    cleaned
  end
end

# Use in your service
result = runner.run(message, context: context)
cleaned_context = ContextCleaner.clean_context(result.context.to_h)
save_context(user_id, cleaned_context)
```

## Tool State Management

### Stateless Tool Design

Tools should be stateless and rely on context for all data:

```ruby
class DatabaseTool < Agents::Tool
  name "query_database"
  description "Query the application database"
  param :query, type: "string", desc: "SQL query to execute"
  
  def perform(tool_context, query:)
    # Get database connection from context, not instance variables
    db_config = tool_context.context[:database_config]
    connection = establish_connection(db_config)
    
    # Execute query and return results
    connection.execute(query)
  end
  
  private
  
  def establish_connection(config)
    # Create connection based on config
    ActiveRecord::Base.establish_connection(config)
  end
end
```

### Tool State Persistence

Store tool-specific data in context:

```ruby
class FileProcessorTool < Agents::Tool
  name "process_file"
  description "Process uploaded files"
  param :file_path, type: "string", desc: "Path to file"
  
  def perform(tool_context, file_path:)
    # Initialize tool state in context if needed
    tool_context.context[:file_processor] ||= {
      processed_files: [],
      processing_status: {}
    }
    
    # Process file
    result = process_file(file_path)
    
    # Update tool state in context
    tool_context.context[:file_processor][:processed_files] << file_path
    tool_context.context[:file_processor][:processing_status][file_path] = result[:status]
    
    result
  end
end
```

## Advanced Persistence Patterns

### Context Versioning

Track context changes over time:

```ruby
class VersionedContext
  def initialize(initial_context = {})
    @versions = [initial_context.deep_dup]
    @current_version = 0
  end
  
  def update_context(new_context)
    @versions << new_context.deep_dup
    @current_version = @versions.size - 1
  end
  
  def current_context
    @versions[@current_version]
  end
  
  def rollback(versions = 1)
    target_version = [@current_version - versions, 0].max
    @current_version = target_version
    current_context
  end
  
  def context_history
    @versions.map.with_index do |context, index|
      {
        version: index,
        timestamp: context[:updated_at],
        agent: context[:current_agent]
      }
    end
  end
end
```

### Context Encryption

Encrypt sensitive context data:

```ruby
class EncryptedContextStorage
  def initialize(encryption_key)
    @cipher = OpenSSL::Cipher.new('AES-256-CBC')
    @key = encryption_key
  end
  
  def encrypt_context(context)
    @cipher.encrypt
    @cipher.key = @key
    
    encrypted_data = @cipher.update(context.to_json)
    encrypted_data << @cipher.final
    
    Base64.encode64(encrypted_data)
  end
  
  def decrypt_context(encrypted_data)
    @cipher.decrypt
    @cipher.key = @key
    
    decoded_data = Base64.decode64(encrypted_data)
    decrypted_data = @cipher.update(decoded_data)
    decrypted_data << @cipher.final
    
    JSON.parse(decrypted_data, symbolize_names: true)
  end
end

# Usage
storage = EncryptedContextStorage.new(Rails.application.secret_key_base)

# Encrypt before storing
encrypted_context = storage.encrypt_context(result.context.to_h)
database_record.update(encrypted_context: encrypted_context)

# Decrypt when loading
encrypted_data = database_record.encrypted_context
context = storage.decrypt_context(encrypted_data)
```

### Distributed Context Storage

For multi-server deployments using Redis:

```ruby
class RedisContextStorage
  def initialize(redis_client = Redis.new)
    @redis = redis_client
  end
  
  def save_context(user_id, context, ttl: 1.hour)
    key = context_key(user_id)
    @redis.setex(key, ttl, context.to_json)
  end
  
  def load_context(user_id)
    key = context_key(user_id)
    data = @redis.get(key)
    return {} unless data
    
    JSON.parse(data, symbolize_names: true)
  end
  
  def delete_context(user_id)
    key = context_key(user_id)
    @redis.del(key)
  end
  
  def extend_ttl(user_id, ttl: 1.hour)
    key = context_key(user_id)
    @redis.expire(key, ttl)
  end
  
  private
  
  def context_key(user_id)
    "agent_context:#{user_id}"
  end
end
```

## Context Migration

Handle context format changes across application versions:

```ruby
class ContextMigrator
  CURRENT_VERSION = 2
  
  def self.migrate_context(context)
    version = context[:_version] || 1
    
    case version
    when 1
      migrate_v1_to_v2(context)
    when 2
      context # Already current
    else
      raise "Unknown context version: #{version}"
    end
  end
  
  private
  
  def self.migrate_v1_to_v2(context)
    # V1 -> V2: Rename 'current_agent' to 'current_agent' (no change needed)
    migrated = context.deep_dup
    
    # No migration needed - current_agent is already the correct field name
    
    migrated[:_version] = 2
    migrated
  end
end

# Use in context loading
def load_context(user_id)
  raw_context = storage.load_context(user_id)
  ContextMigrator.migrate_context(raw_context)
end
```

## Best Practices

### Context Size Management
- Regularly clean up old conversation history
- Remove temporary data after use
- Set reasonable size limits for context values

### Security Considerations
- Encrypt sensitive data in persistent storage
- Validate context data when loading from external sources  
- Sanitize context data before serialization

### Performance Optimization
- Use lazy loading for large context objects
- Cache frequently accessed context data
- Consider context compression for large datasets

### Error Handling
- Always validate context structure after deserialization
- Provide fallback default contexts for corrupted data
- Log context-related errors for debugging