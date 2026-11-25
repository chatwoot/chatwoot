require 'rails_helper'
require 'open3'

# The fork ships Enterprise as upstream publishes it: nothing outside enterprise/ reopens or
# patches it. bin/validate_enterprise_isolation reads the source for that; this runs it, and
# adds what only the loaded app can tell, because a prepend aimed at a CE class can still
# land on a method Enterprise put there (Attachment's audio transcription is one).
RSpec.describe 'Enterprise isolation' do # rubocop:disable RSpec/DescribeClass
  it 'finds no overlay, no reopened Enterprise constant and no patch aimed at one' do
    output, status = Open3.capture2e(Rails.root.join('bin/validate_enterprise_isolation').to_s)

    expect(status).to be_success, output
  end

  it 'prepends nothing from CE code over a method Enterprise defines', if: ChatwootApp.enterprise? do
    Rails.application.eager_load!

    expect(EnterpriseIsolationDetector.violations(root: Rails.root.join('enterprise').to_s)).to be_empty
  end

  # The runtime check is only as good as its detector, so it is pointed at a fixture tree here:
  # a class defined in a file under a temporary "Enterprise" root, and modules defined in this
  # file prepended over each kind of method.
  describe EnterpriseIsolationDetector do
    let(:root) { Dir.mktmpdir }
    let(:class_name) { "IsolationProbe#{SecureRandom.hex(4)}" }
    let(:probe) { Object.const_get(class_name) }

    before do
      # Stubbed so RSpec removes it afterwards; the file below reopens it.
      stub_const(class_name, Class.new)
      File.write(File.join(root, 'probe.rb'), <<~RUBY)
        class #{class_name}
          def self.class_level; end
          def instance_level; end

          protected

          def protected_level; end

          private

          def private_level; end
        end
      RUBY
      load File.join(root, 'probe.rb')
    end

    after { FileUtils.remove_entry(root) }

    it 'flags a prepend over an instance, class, protected or private method of the Enterprise tree' do
      probe.prepend(Module.new { def instance_level = :patched })
      probe.singleton_class.prepend(Module.new { def class_level = :patched })
      probe.prepend(Module.new { protected def protected_level = :patched })
      probe.prepend(Module.new { private def private_level = :patched })

      found = described_class.violations(root: root, modules: [probe])

      expect(found.map { |entry| entry[/[#.]\w+/] }).to contain_exactly('#instance_level', '.class_level', '#protected_level', '#private_level')
    end

    it 'leaves alone a prepend over a method defined outside that tree' do
      probe.class_eval { def outside_level; end }
      probe.prepend(Module.new { def outside_level = :patched })

      expect(described_class.violations(root: root, modules: [probe])).to be_empty
    end
  end
end
