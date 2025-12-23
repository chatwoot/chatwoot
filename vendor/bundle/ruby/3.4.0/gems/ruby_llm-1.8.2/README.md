<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/docs/assets/images/logotype_dark.svg">
  <img src="/docs/assets/images/logotype.svg" alt="RubyLLM" height="120" width="250">
</picture>

<strong>One *beautiful* Ruby API for GPT, Claude, Gemini, and more.</strong>

Battle tested at [<picture><source media="(prefers-color-scheme: dark)" srcset="https://chatwithwork.com/logotype-dark.svg"><img src="https://chatwithwork.com/logotype.svg" alt="Chat with Work" height="30" align="absmiddle"></picture>](https://chatwithwork.com) — *Claude Code for your documents*

[![Gem Version](https://badge.fury.io/rb/ruby_llm.svg?a=10)](https://badge.fury.io/rb/ruby_llm)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
[![Gem Downloads](https://img.shields.io/gem/dt/ruby_llm)](https://rubygems.org/gems/ruby_llm)
[![codecov](https://codecov.io/gh/crmne/ruby_llm/branch/main/graph/badge.svg?a=2)](https://codecov.io/gh/crmne/ruby_llm)

<a href="https://trendshift.io/repositories/13640" target="_blank"><img src="https://trendshift.io/api/badge/repositories/13640" alt="crmne%2Fruby_llm | Trendshift" style="width: 250px; height: 55px;" width="250" height="55"/></a>
</div>

> [!NOTE]
> Using RubyLLM in production? [Share your story](https://tally.so/r/3Na02p)! Takes 5 minutes.

---

Build chatbots, AI agents, RAG applications. Works with OpenAI, Anthropic, Google, AWS, local models, and any OpenAI-compatible API.

## Why RubyLLM?

Every AI provider ships their own bloated client. Different APIs. Different response formats. Different conventions. It's exhausting.

RubyLLM gives you one beautiful API for all of them. Same interface whether you're using GPT, Claude, or your local Ollama. Just three dependencies: Faraday, Zeitwerk, and Marcel. That's it.

## Show me the code

```ruby
# Just ask questions
chat = RubyLLM.chat
chat.ask "What's the best way to learn Ruby?"
```

```ruby
# Analyze any file type
chat.ask "What's in this image?", with: "ruby_conf.jpg"
chat.ask "What's happening in this video?", with: "video.mp4"
chat.ask "Describe this meeting", with: "meeting.wav"
chat.ask "Summarize this document", with: "contract.pdf"
chat.ask "Explain this code", with: "app.rb"
```

```ruby
# Multiple files at once
chat.ask "Analyze these files", with: ["diagram.png", "report.pdf", "notes.txt"]
```

```ruby
# Stream responses
chat.ask "Tell me a story about Ruby" do |chunk|
  print chunk.content
end
```

```ruby
# Generate images
RubyLLM.paint "a sunset over mountains in watercolor style"
```

```ruby
# Create embeddings
RubyLLM.embed "Ruby is elegant and expressive"
```

```ruby
# Moderate content for safety
RubyLLM.moderate "Check if this text is safe"
```

```ruby
# Let AI use your code
class Weather < RubyLLM::Tool
  description "Get current weather"
  param :latitude
  param :longitude

  def execute(latitude:, longitude:)
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current=temperature_2m,wind_speed_10m"
    JSON.parse(Faraday.get(url).body)
  end
end

chat.with_tool(Weather).ask "What's the weather in Berlin?"
```

```ruby
# Get structured output
class ProductSchema < RubyLLM::Schema
  string :name
  number :price
  array :features do
    string
  end
end

response = chat.with_schema(ProductSchema).ask "Analyze this product", with: "product.txt"
```

## Features

* **Chat:** Conversational AI with `RubyLLM.chat`
* **Vision:** Analyze images and videos
* **Audio:** Transcribe and understand speech
* **Documents:** Extract from PDFs, CSVs, JSON, any file type
* **Image generation:** Create images with `RubyLLM.paint`
* **Embeddings:** Vector search with `RubyLLM.embed`
* **Moderation:** Content safety with `RubyLLM.moderate`
* **Tools:** Let AI call your Ruby methods
* **Structured output:** JSON schemas that just work
* **Streaming:** Real-time responses with blocks
* **Rails:** ActiveRecord integration with `acts_as_chat`
* **Async:** Fiber-based concurrency
* **Model registry:** 500+ models with capability detection and pricing
* **Providers:** OpenAI, Anthropic, Gemini, VertexAI, Bedrock, DeepSeek, Mistral, Ollama, OpenRouter, Perplexity, GPUStack, and any OpenAI-compatible API

## Installation

Add to your Gemfile:
```ruby
gem 'ruby_llm'
```
Then `bundle install`.

Configure your API keys:
```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end
```

## Rails

```bash
# Install Rails Integration
rails generate ruby_llm:install

# Add Chat UI (optional)
rails generate ruby_llm:chat_ui
```

```ruby
class Chat < ApplicationRecord
  acts_as_chat
end

chat = Chat.create! model: "claude-sonnet-4"
chat.ask "What's in this file?", with: "report.pdf"
```

Visit `http://localhost:3000/chats` for a ready-to-use chat interface!

## Documentation

[rubyllm.com](https://rubyllm.com)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the MIT License.
