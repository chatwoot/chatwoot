#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to check template structures
# Usage: ruby check_templates.rb

require_relative 'config/environment'

puts '=' * 80
puts 'Template Structure Check'
puts '=' * 80
puts ''

# Get all templates
templates = MessageTemplate.includes(:content_blocks).all

if templates.empty?
  puts '❌ No templates found in database'
  exit
end

# Track templates with issues
templates_with_issues = []

puts "📊 Found #{templates.count} templates\n\n"

# Group by category
templates.group_by(&:category).each do |category, category_templates|
  puts "\n#{'-' * 80}"
  puts "📁 Category: #{category || 'Uncategorized'} (#{category_templates.count} templates)"
  puts '-' * 80

  category_templates.each do |template|
    status_icon = case template.status
                  when 'active' then '✅'
                  when 'draft' then '📝'
                  when 'deprecated' then '🗑️'
                  else '❓'
                  end

    puts "\n#{status_icon} Template: #{template.name}"
    puts "   ID: #{template.id}"
    puts "   Status: #{template.status.upcase}"
    puts "   Channels: #{template.supported_channels.join(', ')}"
    puts "   Content Blocks: #{template.content_blocks.count}"

    # Show content structure
    if template.content_blocks.any?
      puts "\n   📦 Content Blocks:"
      template.content_blocks.order(:order_index).each_with_index do |block, index|
        puts "      #{index + 1}. Type: #{block.block_type}"

        issues = []

        # Show key properties for each block type
        case block.block_type
        when 'quick_reply'
          items = block.properties['items'] || block.properties['replies'] || []
          items = [items] unless items.is_a?(Array)
          puts "         - Items: #{items.size}"
          if items.any?
            puts "         - Sample: #{items.first['title']}"
          else
            issues << 'No items/replies defined'
          end

        when 'time_picker'
          event_title = block.properties['eventTitle'] || block.properties['event_title']
          puts "         - Event Title: #{event_title || 'Not set'}"
          timeslots = block.properties['timeslots'] || []
          timeslots = [timeslots] unless timeslots.is_a?(Array)
          puts "         - Timeslots: #{timeslots.size}"
          images = block.properties['images'] || []
          images = [images] unless images.is_a?(Array)
          puts "         - Images: #{images.size}"
          received_title = block.properties['receivedTitle'] || block.properties['received_title']
          reply_title = block.properties['replyTitle'] || block.properties['reply_title']
          puts "         - Received Title: #{received_title || 'Not set'}"
          puts "         - Reply Title: #{reply_title || 'Not set'}"

          issues << 'No timeslots defined' if timeslots.empty?
          issues << 'Missing received title' unless received_title
          issues << 'Missing reply title' unless reply_title

        when 'list_picker'
          sections = block.properties['sections'] || []
          sections = [sections] unless sections.is_a?(Array)
          puts "         - Sections: #{sections.size}"
          total_items = 0
          if sections.any?
            total_items = sections.sum { |s| (s['items'] || []).size }
            puts "         - Total Items: #{total_items}"
          end
          images = block.properties['images'] || []
          images = [images] unless images.is_a?(Array)
          puts "         - Images: #{images.size}"
          received_title = block.properties['received_title'] || block.properties['receivedTitle']
          reply_title = block.properties['reply_title'] || block.properties['replyTitle']
          puts "         - Received Title: #{received_title || 'Not set'}"
          puts "         - Reply Title: #{reply_title || 'Not set'}"

          issues << 'No sections defined' if sections.empty?
          issues << 'No items in sections' if total_items.zero?
          issues << 'Missing received title' unless received_title
          issues << 'Missing reply title' unless reply_title

        when 'form'
          fields = block.properties['fields'] || []
          fields = [fields] unless fields.is_a?(Array)
          puts "         - Fields: #{fields.size}"
          issues << 'No fields defined' if fields.empty?

        when 'payment'
          merchant = block.properties['merchantName']
          amount = block.properties['amount']
          puts "         - Merchant: #{merchant || 'Not set'}"
          puts "         - Amount: #{amount || 'Not set'}"
          issues << 'Missing merchant name' unless merchant
          issues << 'Missing amount' unless amount

        when 'text'
          content = block.properties['content'] || ''
          preview = content.length > 50 ? "#{content[0..50]}..." : content
          puts "         - Content: #{preview}"
          issues << 'Empty content' if content.empty?
        end

        # Track issues for this template
        next unless issues.any?

        templates_with_issues << {
          template: template,
          block_type: block.block_type,
          block_index: index + 1,
          issues: issues
        }
      end
    elsif template.metadata.present? && template.metadata['apple_message_content'].present?
      # Check metadata for content
      puts "\n   📦 Content (from metadata):"
      content = template.metadata['apple_message_content']

      puts "      Type: #{content['type']}" if content['type']

      if content['items'] || content['replies']
        items = content['items'] || content['replies'] || []
        puts "      Items: #{items.count}"
      end

      puts "      Sections: #{content['sections'].count}" if content['sections']
    end

    puts ''
  end
end

puts "\n#{'=' * 80}"
puts '📊 Summary by Channel'
puts '=' * 80

channel_stats = templates.flat_map(&:supported_channels).tally
channel_stats.each do |channel, count|
  puts "  #{channel}: #{count} templates"
end

puts "\n#{'=' * 80}"
puts '📊 Summary by Block Type'
puts '=' * 80

block_stats = TemplateContentBlock.group(:block_type).count
if block_stats.any?
  block_stats.each do |block_type, count|
    puts "  #{block_type}: #{count} blocks"
  end
else
  puts '  No content blocks found'
end

# Show templates with issues
if templates_with_issues.any?
  puts "\n#{'=' * 80}"
  puts '⚠️  Templates with Issues'
  puts '=' * 80
  puts ''

  # Group by template and separate by status
  issues_by_template = templates_with_issues.group_by { |issue| issue[:template] }

  # Show active templates with issues first (more critical)
  active_with_issues = issues_by_template.select { |t, _| t.status == 'active' }
  deprecated_with_issues = issues_by_template.select { |t, _| t.status == 'deprecated' }
  draft_with_issues = issues_by_template.select { |t, _| t.status == 'draft' }

  if active_with_issues.any?
    puts "🚨 ACTIVE Templates with Issues (#{active_with_issues.count}):"
    puts ''
    active_with_issues.each do |template, issues|
      puts "  🔴 #{template.name} (ID: #{template.id})"
      issues.each do |issue|
        puts "     Block #{issue[:block_index]} (#{issue[:block_type]}):"
        issue[:issues].each do |problem|
          puts "       - #{problem}"
        end
      end
      puts ''
    end
  end

  if deprecated_with_issues.any?
    puts "🗑️  DEPRECATED Templates with Issues (#{deprecated_with_issues.count}):"
    puts ''
    deprecated_with_issues.each do |template, issues|
      puts "  ⚠️  #{template.name} (ID: #{template.id})"
      issues.each do |issue|
        puts "     Block #{issue[:block_index]} (#{issue[:block_type]}):"
        issue[:issues].each do |problem|
          puts "       - #{problem}"
        end
      end
      puts ''
    end
  end

  if draft_with_issues.any?
    puts "📝 DRAFT Templates with Issues (#{draft_with_issues.count}):"
    puts ''
    draft_with_issues.each do |template, issues|
      puts "  ⚠️  #{template.name} (ID: #{template.id})"
      issues.each do |issue|
        puts "     Block #{issue[:block_index]} (#{issue[:block_type]}):"
        issue[:issues].each do |problem|
          puts "       - #{problem}"
        end
      end
      puts ''
    end
  end
end

puts "\n#{'=' * 80}"
puts '✅ Check Complete'
puts '=' * 80
puts ''
puts '📊 Summary:'
puts "  - Total templates: #{templates.count}"
puts "    • Active: #{templates.active.count}"
puts "    • Draft: #{templates.draft.count}"
puts "    • Deprecated: #{templates.deprecated.count}"
puts ''
puts "  - Templates with issues: #{templates_with_issues.map { |i| i[:template] }.uniq.count}"
active_issues = templates_with_issues.select { |i| i[:template].status == 'active' }.map { |i| i[:template] }.uniq.count
deprecated_issues = templates_with_issues.select { |i| i[:template].status == 'deprecated' }.map { |i| i[:template] }.uniq.count
draft_issues = templates_with_issues.select { |i| i[:template].status == 'draft' }.map { |i| i[:template] }.uniq.count
puts "    • Active with issues: #{active_issues} 🚨" if active_issues > 0
puts "    • Deprecated with issues: #{deprecated_issues}" if deprecated_issues > 0
puts "    • Draft with issues: #{draft_issues}" if draft_issues > 0
puts ''
puts "  - Total issues found: #{templates_with_issues.sum { |i| i[:issues].count }}"
puts ''
puts 'Tips:'
puts '  - Time Picker blocks should have: eventTitle, timeslots, receivedTitle, replyTitle'
puts '  - List Picker blocks should have: sections with items, received_title, reply_title'
puts '  - Quick Reply blocks should have: items or replies array'
puts '  - Form blocks should have: fields array'
puts ''
