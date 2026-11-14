# A security backport is a fix copied from a newer gem release for an advisory the installed
# version has no patch for. Each one registers the advisory, the gem and the advisory's patched
# version ranges (as the advisory database writes them, one per release line), and is applied
# only while the installed gem satisfies none of them.
# spec/initializers/monkey_patches/security_backport_spec.rb fails once it satisfies one, so the
# backport and its .bundler-audit.yml entry get deleted instead of a stale copy of the old code
# overriding upstream's fix. Loaded before the other files in this directory by name.
module SecurityBackport
  Entry = Data.define(:advisory, :gem_name, :patched) do
    def installed_version
      Gem.loaded_specs.fetch(gem_name).version
    end

    def needed?(version = installed_version)
      patched.none? { |range| Gem::Requirement.new(range.split(',')).satisfied_by?(version) }
    end
  end

  def self.entries
    @entries ||= []
  end

  # Returns whether the backport still applies, so the caller patches only then.
  def self.register(advisory:, gem_name:, patched:)
    entry = Entry.new(advisory: advisory, gem_name: gem_name, patched: patched)
    entries << entry
    entry.needed?
  end
end
