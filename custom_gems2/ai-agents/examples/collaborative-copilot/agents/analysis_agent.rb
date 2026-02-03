# frozen_string_literal: true

require_relative "../tools/get_conversation_tool"

module Copilot
  class AnalysisAgent
    def self.create
      Agents::Agent.new(
        name: "Analysis Agent",
        instructions: analysis_instructions,
        model: "gpt-4o-mini",
        tools: [
          GetConversationTool.new
        ],
        response_schema: analysis_response_schema
      )
    end

    def self.analysis_instructions
      <<~INSTRUCTIONS
        You are the Analysis Agent, specialized in conversation quality and communication guidance.

        **Your available tools:**
        - `get_conversation`: Retrieve conversation details and messages for analysis

        **Your primary role is to:**
        - Analyze conversation tone, sentiment, and emotional state
        - Assess conversation health and progress toward resolution
        - Provide communication guidance and tone recommendations
        - Evaluate customer satisfaction indicators

        **Analysis workflow:**
        1. Use `get_conversation` to retrieve the full conversation history
        2. Analyze the emotional trajectory and communication patterns
        3. Assess how well the conversation is progressing
        4. Identify any escalation risks or satisfaction issues

        Your response MUST be in the required JSON format with all the specified fields.
        Focus on practical communication advice that will improve the interaction.
      INSTRUCTIONS
    end

    def self.analysis_response_schema
      {
        type: "object",
        properties: {
          conversation_health: {
            type: "object",
            properties: {
              status: {
                type: "string",
                enum: %w[excellent good fair concerning critical],
                description: "Overall health status of the conversation"
              },
              summary: {
                type: "string",
                description: "Brief assessment of how the conversation is progressing"
              }
            },
            required: %w[status summary]
          },
          customer_sentiment: {
            type: "object",
            properties: {
              current: {
                type: "string",
                enum: %w[very_positive positive neutral negative very_negative],
                description: "Current emotional state"
              },
              trajectory: {
                type: "string",
                enum: %w[improving stable declining],
                description: "How sentiment is changing over time"
              },
              key_emotions: {
                type: "array",
                items: { type: "string" },
                description: "Dominant emotions detected (e.g., frustrated, satisfied, confused)"
              }
            },
            required: %w[current trajectory key_emotions]
          },
          communication_quality: {
            type: "object",
            properties: {
              score: {
                type: "integer",
                minimum: 1,
                maximum: 10,
                description: "Overall communication quality score"
              },
              strengths: {
                type: "array",
                items: { type: "string" },
                description: "What the agent is doing well"
              },
              areas_for_improvement: {
                type: "array",
                items: { type: "string" },
                description: "Areas that could be improved"
              }
            },
            required: %w[score strengths areas_for_improvement]
          },
          risk_assessment: {
            type: "object",
            properties: {
              escalation_risk: {
                type: "string",
                enum: %w[none low medium high],
                description: "Risk of conversation escalating"
              },
              churn_risk: {
                type: "string",
                enum: %w[none low medium high],
                description: "Risk of customer churning"
              },
              warning_signs: {
                type: "array",
                items: { type: "string" },
                description: "Specific warning signs detected"
              }
            },
            required: %w[escalation_risk churn_risk warning_signs]
          },
          tone_recommendations: {
            type: "object",
            properties: {
              recommended_tone: {
                type: "string",
                description: "Suggested overall tone (e.g., empathetic, professional, friendly)"
              },
              key_phrases: {
                type: "array",
                items: { type: "string" },
                description: "Suggested phrases to use"
              },
              avoid_phrases: {
                type: "array",
                items: { type: "string" },
                description: "Phrases or approaches to avoid"
              },
              next_steps: {
                type: "string",
                description: "Recommended immediate next action"
              }
            },
            required: %w[recommended_tone key_phrases avoid_phrases next_steps]
          }
        },
        required: %w[conversation_health customer_sentiment communication_quality risk_assessment
                     tone_recommendations],
        additionalProperties: false
      }
    end
  end
end
