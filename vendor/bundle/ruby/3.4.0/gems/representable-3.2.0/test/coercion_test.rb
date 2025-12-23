# frozen_string_literal: true

require 'test_helper'
require 'representable/coercion'

class CoercionTest < MiniTest::Spec
  representer! do
    include Representable::Coercion

    property :title # no coercion.
    property :length, type: Representable::Coercion::Types::Params::Float

    property :band, class: OpenStruct do
      property :founded, type: Representable::Coercion::Types::Params::Integer
    end

    collection :songs, class: OpenStruct do
      property :ok, type: Representable::Coercion::Types::Params::Bool
    end
  end

  let(:album) do
    OpenStruct.new(title: 'Dire Straits', length: 41.34,
                   band: OpenStruct.new(founded: '1977'),
                   songs: [OpenStruct.new(ok: 1), OpenStruct.new(ok: 0)])
  end

  it do
    _(album.extend(representer).to_hash).must_equal({ 'title' => 'Dire Straits',
                                                      'length' => 41.34,
                                                      'band' => { 'founded' => 1977 },
                                                      'songs' => [{ 'ok' => true }, { 'ok' => false }] })
  end

  it {
    album = OpenStruct.new
    album.extend(representer)
    album.from_hash({ 'title' => 'Dire Straits',
                      'length' => '41.34',
                      'band' => { 'founded' => '1977' },
                      'songs' => [{ 'ok' => 1 }, { 'ok' => 0 }] })

    # it
    _(album.length).must_equal 41.34
    _(album.band.founded).must_equal 1977
    _(album.songs[0].ok).must_equal true
  }

  describe 'with user :parse_filter and :render_filter' do
    representer! do
      include Representable::Coercion

      property :length, type: Representable::Coercion::Types::Params::Float,
                        parse_filter: ->(input, _options) { "#{input}.1" }, # happens BEFORE coercer.
                        render_filter: ->(fragment, *) { "#{fragment}.1" }
    end

    # user's :parse_filter(s) are run before coercion.
    it { _(OpenStruct.new.extend(representer).from_hash('length' => '1').length).must_equal 1.1 }
    # user's :render_filter(s) are run before coercion.
    it { _(OpenStruct.new(length: 1).extend(representer).to_hash).must_equal({ 'length' => 1.1 }) }
  end
end
