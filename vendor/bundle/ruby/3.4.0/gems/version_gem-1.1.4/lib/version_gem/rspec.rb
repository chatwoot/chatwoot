# frozen_string_literal: true

RSpec::Matchers.define(:have_version_constant) do
  match do |version_mod|
    version_mod.const_defined?(:VERSION, false)
  end
end

RSpec::Matchers.define(:have_version_as_string) do
  match do |version_mod|
    !version_mod::VERSION.nil? && version_mod::VERSION.is_a?(String)
  end
end

RSpec::Matchers.define(:have_major_as_integer) do
  match do |version_mod|
    version_mod.major.is_a?(Integer)
  end
end

RSpec::Matchers.define(:have_minor_as_integer) do
  match do |version_mod|
    version_mod.minor.is_a?(Integer)
  end
end

RSpec::Matchers.define(:have_patch_as_integer) do
  match do |version_mod|
    version_mod.patch.is_a?(Integer)
  end
end

RSpec::Matchers.define(:have_pre_as_nil_or_string) do
  match do |version_mod|
    version_mod.pre.nil? || version_mod.pre.is_a?(String)
  end
end

RSpec.shared_examples_for("a Version module") do |version_mod|
  it "is introspectable" do
    aggregate_failures "introspectable api" do
      expect(version_mod).is_a?(Module)
      expect(version_mod).to(have_version_constant)
      expect(version_mod).to(have_version_as_string)
      expect(version_mod.to_s).to(be_a(String))
      expect(version_mod).to(have_major_as_integer)
      expect(version_mod).to(have_minor_as_integer)
      expect(version_mod).to(have_patch_as_integer)
      expect(version_mod).to(have_pre_as_nil_or_string)
      expect(version_mod.to_h.keys).to(match_array(%i[major minor patch pre]))
      expect(version_mod.to_a).to(be_a(Array))
    end
  end
end
