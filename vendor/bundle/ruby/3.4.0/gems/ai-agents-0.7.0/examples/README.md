# Examples

This directory contains examples demonstrating how to use the Ruby Agents SDK.

## Prerequisites

1. **Set up your API key:**
   ```bash
   export OPENAI_API_KEY=your_api_key_here
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

## Running Examples

### Basic Usage
```bash
ruby examples/basic_usage.rb
```

This example demonstrates:
- Configuring the Agents gem
- Creating a simple tool with parameters
- Creating an agent that uses the tool
- Testing both tool and agent functionality
- Viewing conversation history

### Expected Output

The example will show:
- ✅ Configuration success message
- 🔧 Direct tool testing with different greeting styles
- 🤖 Agent conversations using the tool
- 📝 Conversation history with timestamps

## What You'll Learn

- How to configure the gem with `Agents.configure`
- How to create tools that extend `Agents::Tool`
- How to create agents that extend `Agents::Agent`
- How to use tools within agents
- How tools and agents integrate with RubyLLM

## Troubleshooting

### "No API keys configured" Error
Make sure you've set the `OPENAI_API_KEY` environment variable:
```bash
export OPENAI_API_KEY=sk-your-key-here
```

### Connection Errors
- Check your internet connection
- Verify your API key is valid
- Ensure you have sufficient API credits

### Ruby Version
Make sure you're using Ruby 3.1 or later:
```bash
ruby --version
```