---
layout: default
title: Tools
parent: Concepts
nav_order: 2
---

# Tools

**Tools** are the components that allow agents to interact with the outside world. They are the primary way to extend an agent's capabilities beyond what the language model can do on its own. A tool can be anything from a simple calculator to a complex integration with an external API.

In Ruby Agents, tools are designed to be thread-safe and stateless. This is a critical design principle that ensures the stability and reliability of your agent system, especially in concurrent environments.

## Thread-Safe Design

The key to the thread-safe design of tools is that they do not store any execution-specific state in their instance variables. All the data a tool needs to perform its action is passed to it through the `perform` method, which receives a `ToolContext` object.

### The `ToolContext`

The `ToolContext` provides access to the current execution context, including:

*   **Shared context data:** A hash of data that is shared across all tools and agents in a given run.
*   **Usage tracking:** An object that tracks token usage for the current run.
*   **Retry count:** The number of times the current tool execution has been retried.

By passing all the necessary data through the `ToolContext`, we ensure that tool instances can be safely shared across multiple threads without the risk of data corruption.

## Creating a Tool

You create tools by creating a class that inherits from `Agents::Tool` and implements the `perform` method:

```ruby
class WeatherTool < Agents::Tool
  name "get_weather"
  description "Get the current weather for a location."
  param :location, type: "string", desc: "The city and state, e.g., San Francisco, CA"

  def perform(tool_context, location:)
    # Access the API key from the shared context
    api_key = tool_context.context[:weather_api_key]

    # Call the weather API and return the result
    WeatherApi.get(location, api_key)
  end
end
```

The `perform` method receives the `tool_context` and the tool's parameters as arguments. This design ensures that your tools are always thread-safe and easy to test.
