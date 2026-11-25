require 'rails_helper'

# The waiting queue is a Sidekiq queue, and moving a batch out of it is a list operation on
# the Redis Sidekiq runs on, which MockRedis does not stand in for. Each example uses keys
# of its own.
RSpec.describe Whatsapp::Session::Inbound::ImportSlots, :redis_streams do
  let(:redis) { Redis.new(Redis::Config.app) }
  let(:prefix) { "wactest:import_slots:#{SecureRandom.hex(8)}" }
  let(:waiting) { "#{prefix}:waiting" }
  let(:queue) { "#{prefix}:low" }
  let(:target) { "queue:#{queue}" }

  after do
    redis.del(waiting, target)
    redis.close
    Redis::Alfred.delete(described_class::KEY)
  end

  # Sidekiq pushes on the left and fetches from the right, so the right end of a queue is
  # its head.
  def queued(*names) = redis.lpush(waiting, names)

  it 'wakes as many waiting batches as there are free slots, oldest first, to the head of the queue' do
    queued('first', 'second', 'third')
    redis.lpush(target, 'already-queued')
    described_class.claim(4)
    described_class.claim(4)

    woken = described_class.top_up(into: queue, limit: 4, waiting: waiting)

    expect(woken).to eq(2)
    expect(redis.lrange(waiting, 0, -1)).to eq(['third'])
    expect(redis.lrange(target, -2, -1)).to eq(%w[second first])
  end

  it 'wakes nobody while every slot is taken' do
    queued('first')
    2.times { described_class.claim(2) }

    expect(described_class.top_up(into: queue, limit: 2, waiting: waiting)).to eq(0)
    expect(redis.llen(waiting)).to eq(1)
  end

  it 'stops at an empty waiting queue' do
    queued('only')

    expect(described_class.top_up(into: queue, limit: 4, waiting: waiting)).to eq(1)
    expect(redis.lrange(target, 0, -1)).to eq(['only'])
  end

  # No Sidekiq process may read it, or a waiting batch would run on its own and the cap
  # would be a queue in name only.
  it 'is a queue no Sidekiq process reads' do
    queues = YAML.safe_load(ERB.new(Rails.root.join('config/sidekiq.yml').read).result, permitted_classes: [Symbol])
    names = queues[:queues].map { |entry| Array(entry).first.to_s }

    expect(names).to include(Whatsapp::Baileys::HistoryImportJob.queue_name)
    expect(names).not_to include(described_class::WAITING_QUEUE)
  end
end
