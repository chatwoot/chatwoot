# lib/tasks/lead_follow_up.rake
namespace :lead_follow_up do
  desc 'Enroll existing conversations in active sequences'
  task enroll_existing: :environment do
    puts "🚀 Starting enrollment of existing conversations...\n\n"

    LeadFollowUpSequence.active.find_each do |sequence|
      puts "📋 Processing sequence: #{sequence.name} (ID: #{sequence.id})"
      puts "   Inbox: #{sequence.inbox.name}"

      # Find conversations that match the criteria
      conversations = Conversation
        .joins(:inbox)
        .where(
          account_id: sequence.account_id,
          inbox_id: sequence.inbox_id,
          status: [:open, :pending] # Abiertas o pendientes
        )
        .where.not(id: ConversationFollowUp.select(:conversation_id)) # Sin follow-up existente
        .where('conversations.created_at > ?', 30.days.ago) # Últimos 30 días (ajustable)

      enrolled_count = 0
      skipped_count = 0

      conversations.find_each do |conversation|
        first_step = sequence.enabled_steps.first
        unless first_step
          skipped_count += 1
          next
        end

        next_action_at = if first_step['type'] == 'wait'
                           calculate_wait_time(first_step)
                         else
                           Time.current
                         end

        ConversationFollowUp.create!(
          conversation: conversation,
          lead_follow_up_sequence: sequence,
          current_step: 0,
          next_action_at: next_action_at,
          status: 'active',
          metadata: {
            enrolled_at: Time.current,
            enrolled_via: 'rake_task'
          }
        )

        enrolled_count += 1
        print "." if enrolled_count % 10 == 0
      rescue StandardError => e
        puts "\n  ✗ Failed to enroll conversation #{conversation.id}: #{e.message}"
      end

      puts "\n   ✅ Enrolled: #{enrolled_count} | Skipped: #{skipped_count}\n\n"
    end

    puts "🎉 Done!\n"
  end

  desc 'Enroll conversations for a specific sequence (Usage: rake lead_follow_up:enroll_sequence[SEQUENCE_ID])'
  task :enroll_sequence, [:sequence_id] => :environment do |_t, args|
    unless args[:sequence_id]
      puts "❌ Error: Please provide a sequence_id"
      puts "Usage: rake lead_follow_up:enroll_sequence[1]"
      exit 1
    end

    sequence = LeadFollowUpSequence.find(args[:sequence_id])

    puts "📋 Enrolling conversations for: #{sequence.name}"
    puts "   Status: #{sequence.active? ? '✅ Active' : '⚠️ Inactive'}"

    conversations = Conversation
      .joins(:inbox)
      .where(
        account_id: sequence.account_id,
        inbox_id: sequence.inbox_id,
        status: [:open, :pending]
      )
      .where.not(id: ConversationFollowUp.select(:conversation_id))
      .where('conversations.created_at > ?', 30.days.ago)

    puts "   Found: #{conversations.count} eligible conversations"

    enrolled_count = 0

    conversations.find_each do |conversation|
      first_step = sequence.enabled_steps.first
      next unless first_step

      next_action_at = if first_step['type'] == 'wait'
                         calculate_wait_time(first_step)
                       else
                         Time.current
                       end

      ConversationFollowUp.create!(
        conversation: conversation,
        lead_follow_up_sequence: sequence,
        current_step: 0,
        next_action_at: next_action_at,
        status: 'active',
        metadata: {
          enrolled_at: Time.current,
          enrolled_via: 'rake_task_specific'
        }
      )

      enrolled_count += 1
      print "." if enrolled_count % 10 == 0
    rescue StandardError => e
      puts "\n  ✗ Error enrolling conversation #{conversation.id}: #{e.message}"
    end

    puts "\n✅ Enrolled #{enrolled_count} conversations"
  end

  desc 'Re-enroll failed or cancelled follow-ups'
  task reenroll_failed: :environment do
    puts "🔄 Re-enrolling failed/cancelled follow-ups...\n"

    follow_ups = ConversationFollowUp
      .where(status: ['failed', 'cancelled'])
      .where('updated_at > ?', 7.days.ago)
      .includes(:conversation, :lead_follow_up_sequence)

    puts "Found #{follow_ups.count} follow-ups to process\n"

    re_enrolled_count = 0
    skipped_count = 0

    follow_ups.find_each do |follow_up|
      conversation = follow_up.conversation
      sequence = follow_up.lead_follow_up_sequence

      # Verificar elegibilidad
      unless conversation.open? || conversation.pending?
        skipped_count += 1
        next
      end

      unless sequence.active?
        skipped_count += 1
        next
      end

      # Resetear el follow-up
      first_step = sequence.enabled_steps.first
      unless first_step
        skipped_count += 1
        next
      end

      follow_up.update!(
        status: 'active',
        current_step: 0,
        next_action_at: calculate_wait_time(first_step),
        metadata: {
          re_enrolled_at: Time.current,
          previous_status: follow_up.status,
          previous_error: follow_up.metadata&.dig('last_error')
        }
      )

      re_enrolled_count += 1
      puts "  ✓ Re-enrolled conversation #{conversation.id}"
    end

    puts "\n✅ Re-enrolled: #{re_enrolled_count} | Skipped: #{skipped_count}"
  end

  desc 'Show statistics for all sequences'
  task stats: :environment do
    puts "\n📊 Lead Retargeting Sequences Statistics\n"
    puts "=" * 80

    LeadFollowUpSequence.find_each do |sequence|
      follow_ups = sequence.conversation_follow_ups

      puts "\n#{sequence.active? ? '✅' : '⚠️ '} #{sequence.name} (ID: #{sequence.id})"
      puts "   Inbox: #{sequence.inbox.name}"
      puts "   Status: #{sequence.active? ? 'Active' : 'Inactive'}"
      puts "   Steps: #{sequence.enabled_steps.count}"
      puts "\n   Follow-ups:"
      puts "   - Total: #{follow_ups.count}"
      puts "   - Active: #{follow_ups.where(status: 'active').count}"
      puts "   - Completed: #{follow_ups.where(status: 'completed').count}"
      puts "   - Cancelled: #{follow_ups.where(status: 'cancelled').count}"
      puts "   - Failed: #{follow_ups.where(status: 'failed').count}"

      if follow_ups.any?
        avg_step = follow_ups.average(:current_step).to_f.round(2)
        puts "   - Avg current step: #{avg_step}"
      end
    end

    puts "\n" + "=" * 80
  end

  def calculate_wait_time(step)
    return Time.current unless step['type'] == 'wait'

    config = step['config']
    delay = config['delay_value'].to_i

    case config['delay_type']
    when 'minutes'
      Time.current + delay.minutes
    when 'hours'
      Time.current + delay.hours
    when 'days'
      Time.current + delay.days
    else
      Time.current + delay.hours
    end
  end
end
