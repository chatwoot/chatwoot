require 'rails_helper'

RSpec.describe Crm::Timezone::Resolver do
  let(:default_tz) { 'America/Sao_Paulo' }

  # Minimal duck-typed doubles: the resolver reads #additional_attributes off the
  # contact (both the 'timezone' and the ISO 'country_code' keys live there — the
  # geocoder populates additional_attributes['country_code']) and
  # #reporting_timezone off the account.
  def contact_with(additional: nil, country_code: nil)
    Struct.new(:additional_attributes).new({ 'timezone' => additional, 'country_code' => country_code })
  end

  def account_with(zone)
    Struct.new(:reporting_timezone).new(zone)
  end

  describe 'precedence: explicit > contact.additional > contact.country > account > default' do
    # Reason: an explicit user-picked tz must win over every inferred source,
    # otherwise a deliberate override is silently ignored.
    it 'prefers the explicit timezone over contact.additional, country and account' do
      resolver = described_class.new(
        explicit: 'America/Sao_Paulo',
        contact: contact_with(additional: 'Europe/Lisbon', country_code: 'FR'),
        account: account_with('UTC')
      )
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    # Reason: a tz explicitly stored on the contact is stronger evidence than a
    # country guess or the account-wide default.
    it 'prefers contact.additional_attributes[timezone] over country and account' do
      resolver = described_class.new(
        contact: contact_with(additional: 'Europe/Lisbon', country_code: 'FR'),
        account: account_with('UTC')
      )
      expect(resolver.name).to eq('Europe/Lisbon')
    end

    # Reason: for a genuinely single-timezone country the contact's local time is
    # unambiguous, so it must pin over the account default (foreigner correctness).
    it 'derives a single-timezone country (FR -> Europe/Paris) over the account timezone' do
      resolver = described_class.new(
        contact: contact_with(country_code: 'FR'),
        account: account_with('UTC')
      )
      expect(resolver.name).to eq('Europe/Paris')
    end

    # Reason: with nothing more specific, the account's reporting timezone is the
    # last resolvable source before the hard-coded default.
    it 'falls back to the account timezone when explicit, contact.additional and country are blank' do
      resolver = described_class.new(account: account_with('America/Sao_Paulo'))
      expect(resolver.name).to eq('America/Sao_Paulo')
    end
  end

  describe 'contact country_code handling' do
    # Reason (foreigner correctness LIMITATION, asserted so it cannot silently
    # change): TZInfo classifies Portugal as THREE zones
    # (Europe/Lisbon, Atlantic/Madeira, Atlantic/Azores), so the exact-single-zone
    # guard treats PT as ambiguous, #name is nil and it falls to the default. A
    # Portuguese lead is therefore only scheduled in Lisbon time via an explicit
    # or contact.additional tz, NOT via country_code alone.
    it 'does NOT derive Portugal (PT is multi-zone in TZInfo) and falls to the default' do
      resolver = described_class.new(contact: contact_with(country_code: 'PT'))

      expect(resolver.name).to be_nil
      expect(resolver.name_or_default).to eq(default_tz)
    end

    # Reason: the reliable way to schedule a Portuguese lead in their own wall time
    # is the stored contact tz; that path must resolve Europe/Lisbon.
    it 'resolves a Portuguese lead to Europe/Lisbon via contact.additional_attributes' do
      resolver = described_class.new(contact: contact_with(additional: 'Europe/Lisbon', country_code: 'PT'))
      expect(resolver.name).to eq('Europe/Lisbon')
    end

    # Reason: Brazil spans 16 zones whose FIRST identifier is America/Noronha;
    # deriving that would schedule leads an hour off, so BR must be treated as
    # ambiguous and fall to the São Paulo default — never Noronha.
    it 'does NOT derive Brazil (multi-zone) and falls to America/Sao_Paulo, not America/Noronha' do
      resolver = described_class.new(contact: contact_with(country_code: 'BR'))

      expect(resolver.name).to be_nil
      expect(resolver.name_or_default).to eq('America/Sao_Paulo')
      expect(resolver.name_or_default).not_to eq('America/Noronha')
    end

    # Reason: a garbage/unknown ISO code must never raise or leak through; it is
    # simply ignored and resolution continues to the next candidate/default.
    it 'ignores an invalid/unknown country_code' do
      resolver = described_class.new(contact: contact_with(country_code: 'ZZ'))

      expect(resolver.name).to be_nil
      expect(resolver.name_or_default).to eq(default_tz)
    end
  end

  describe 'invalid candidates' do
    # Reason: an invalid explicit value must be skipped (not raise, not win) so a
    # valid downstream candidate still resolves.
    it 'skips an invalid explicit timezone and uses the next valid candidate' do
      resolver = described_class.new(explicit: 'Not/AZone', account: account_with('America/Sao_Paulo'))
      expect(resolver.name).to eq('America/Sao_Paulo')
    end

    # Reason: when EVERY candidate is missing/invalid, #name is nil but scheduling
    # must still anchor to a real wall time via the default (never UTC, never raise).
    it 'returns nil from #name but the São Paulo default from #name_or_default when all candidates are invalid' do
      resolver = described_class.new(
        explicit: 'Not/AZone',
        contact: contact_with(additional: nil, country_code: 'XX'),
        account: account_with('also bad')
      )

      expect(resolver.name).to be_nil
      expect(resolver.name_or_default).to eq(default_tz)
    end
  end

  describe 'default (fail-open, configurable, never UTC)' do
    # Reason: the core fix — nothing set resolves to São Paulo wall time instead of
    # silently assuming UTC.
    it 'is nil for #name but America/Sao_Paulo for #name_or_default when nothing is set' do
      resolver = described_class.new

      expect(resolver.name).to be_nil
      expect(resolver.name_or_default).to eq(default_tz)
      expect(resolver.zone_or_default).to eq(ActiveSupport::TimeZone['America/Sao_Paulo'])
    end

    # Reason: operators can move the last-resort default without a deploy via
    # CRM_DEFAULT_TIMEZONE.
    it 'honors a valid CRM_DEFAULT_TIMEZONE override for the fallback' do
      with_modified_env(CRM_DEFAULT_TIMEZONE: 'Europe/Lisbon') do
        expect(described_class.new.name_or_default).to eq('Europe/Lisbon')
      end
    end

    # Reason: a misconfigured ENV must not poison scheduling with an invalid zone;
    # it degrades to the hard-coded São Paulo default.
    it 'falls back to America/Sao_Paulo when CRM_DEFAULT_TIMEZONE is invalid' do
      with_modified_env(CRM_DEFAULT_TIMEZONE: 'Not/AZone') do
        expect(described_class.new.name_or_default).to eq(default_tz)
      end
    end

    # Reason: the ENV default is ONLY a fallback — a resolvable candidate still wins.
    it 'does not let CRM_DEFAULT_TIMEZONE override a resolved candidate' do
      with_modified_env(CRM_DEFAULT_TIMEZONE: 'Europe/Lisbon') do
        expect(described_class.new(explicit: 'America/Sao_Paulo').name).to eq('America/Sao_Paulo')
      end
    end
  end

  describe 'wall-time anchoring (local time, not UTC)' do
    # Reason: 08:00 in São Paulo is 11:00 UTC (UTC-3, no DST). Asserting hour 11
    # proves the resolver anchors LOCAL wall time — the exact bug being fixed.
    it 'anchors 08:00 America/Sao_Paulo to 11:00 UTC (NOT 08:00) via #zone' do
      resolver = described_class.new(explicit: 'America/Sao_Paulo')
      expect(resolver.zone.parse('2026-07-08 08:00:00').utc.hour).to eq(11)
    end

    # Reason: 08:00 in Lisbon in July is 07:00 UTC (WEST, UTC+1) — a DIFFERENT
    # offset than São Paulo, proving the anchor follows the resolved zone.
    it 'anchors 08:00 Europe/Lisbon to 07:00 UTC in summer via #zone' do
      resolver = described_class.new(explicit: 'Europe/Lisbon')
      expect(resolver.zone.parse('2026-07-08 08:00:00').utc.hour).to eq(7)
    end

    # Reason: even with nothing set the defaulted zone must anchor to São Paulo
    # local time (11:00 UTC), never UTC-as-08:00.
    it 'anchors 08:00 to 11:00 UTC through #zone_or_default when unresolved' do
      expect(described_class.new.zone_or_default.parse('2026-07-08 08:00:00').utc.hour).to eq(11)
    end
  end

  describe '#zone' do
    # Reason: #zone is the strict variant — nil when nothing resolves — so callers
    # that need to distinguish "resolved vs defaulted" still can.
    it 'returns nil when unresolvable while #zone_or_default stays present' do
      resolver = described_class.new

      expect(resolver.zone).to be_nil
      expect(resolver.zone_or_default).to be_present
    end
  end
end
