require 'rails_helper'

# The same question at every fire-and-forget site, asked of the source rather than of a
# checklist: how long may this command hold the session?
#
# A published command has no caller waiting on it, so whatever ceiling its frame declares
# is the only one the connector has for it, and the session's executor runs one command at
# a time -- one parked on a socket write is every send behind it parked too. A new site
# added without a ceiling would reintroduce that with nothing failing.
#
# There are two ceilings and they are not interchangeable. `timeout:` becomes `deadline`,
# an instant, and refuses the command unrun once it passes; `max_runtime:` is counted from
# the moment the work starts and can never drop anything. The teardown takes the second
# alone, which is exactly why it used to take neither: it is published so it can sit
# pending between owners, and a `session.logout` dropped for arriving late leaves a device
# listed on the customer's phone.
RSpec.describe Whatsapp::Session::Backends::Connector::Backend do
  describe 'the ceiling on every fire-and-forget command' do
    let(:source) { Rails.root.join('app/services/whatsapp/session/backends/connector/backend.rb') }
    # [method name, source line] for every `client.publish` call in the backend.
    let(:publish_sites) { sites_calling('client.publish(') }
    # The same question, asked of the other fire-and-forget door. A command written to the
    # control stream has no caller waiting on it either, so nothing else bounds it, and
    # moving a command from one door to the other must not take it out of the sweep.
    let(:control_sites) { sites_calling('client.control(') }

    # The wake, the one command with no ceiling of either kind: the contract applies neither
    # to it. It has an instance adopt a session that may not be running, and nothing here
    # waits on it, so a deadline would drop the very command meant to reach the session.
    # Told apart by the command and not by the method, because two methods send one: the
    # connect, whose RPC bounds what it asks for, and the logout, whose own publish is
    # bounded and must stay under this sweep.
    def wake?(line) = line.include?('SessionWake')

    def sites_calling(call)
      method = nil
      source.readlines.each_with_object([]) do |line, sites|
        method = Regexp.last_match(1) if line =~ /^\s*def ([a-z_0-9?!]+)/
        sites << [method, line] if line.include?(call)
      end
    end

    def bound(line)
      return :deadline if line.include?('timeout:')
      return :runtime if line.include?('max_runtime:')

      :none
    end

    it 'finds every publish site the backend has' do
      # Vacuity guard: a rename or a refactor that hides the calls would leave the sweep
      # passing over nothing at all.
      expect(publish_sites.size).to eq(9)
      expect(publish_sites.map(&:first).uniq)
        .to contain_exactly('disconnect', 'logout', 'delete_session', 'request_pairing_code', 'mark_read',
                            'mark_unread', 'send_chat_presence', 'update_presence', 'subscribe_presence')
    end

    it 'finds every control site the backend has' do
      expect(control_sites.map(&:first)).to contain_exactly('connect', 'logout', 'delete_session')
    end

    it 'declares a ceiling at every site that is not the wake' do
      sites = publish_sites + control_sites
      missing = sites.reject { |_, line| wake?(line) || bound(line) != :none }

      expect(missing.map(&:first)).to be_empty,
                                      "these send a command with no ceiling: #{missing.map(&:first).uniq.join(', ')}. " \
                                      'Nobody waits on a fire-and-forget command, so the frame is the only place a ' \
                                      'limit can come from.'
    end

    it 'gives the teardown the ceiling it can take and withholds the one it cannot' do
      # The distinction is the whole point of having two fields, so it is asserted rather
      # than left to whichever one somebody reaches for next. A deadline here would refuse
      # the teardown that arrives while the session is between owners.
      teardown = (publish_sites + control_sites).filter_map do |method, line|
        bound(line) if %w[disconnect logout delete_session].include?(method) && !wake?(line)
      end

      expect(teardown.size).to eq(4)
      expect(teardown.uniq).to eq([:runtime])
    end

    it 'covers all three kinds' do
      # The fence proves nothing if every site is bounded the same way: it has to be
      # reached by a deadline, by a runtime ceiling, and by the exception.
      by_bound = (publish_sites + control_sites).group_by { |_, line| bound(line) }
                                                .transform_values { |sites| sites.map(&:first).uniq }

      expect(by_bound[:deadline]).to contain_exactly('request_pairing_code', 'mark_read', 'mark_unread',
                                                     'send_chat_presence', 'update_presence', 'subscribe_presence')
      expect(by_bound[:runtime]).to contain_exactly('disconnect', 'logout', 'delete_session')
      expect(by_bound[:none]).to contain_exactly('connect', 'logout')
      expect((publish_sites + control_sites).select { |_, line| bound(line) == :none }).to all(satisfy { |_, line| wake?(line) })
    end
  end
end
