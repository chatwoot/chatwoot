# frozen_string_literal: true

require "spec_helper"

describe "Including the deprecated PgSearch module" do
  with_model :SomeModel do
    model do
      ActiveSupport::Deprecation.silence do
        include PgSearch
      end
    end
  end

  with_model :AnotherModel

  it "includes PgSearch::Model" do
    expect(SomeModel.ancestors).to include PgSearch::Model
  end

  it "prints a deprecation message" do
    allow(ActiveSupport::Deprecation).to receive(:warn)

    AnotherModel.include(PgSearch)

    expect(ActiveSupport::Deprecation).to have_received(:warn).with(
      <<~MESSAGE
        Directly including `PgSearch` into an Active Record model is deprecated and will be removed in pg_search 3.0.

        Please replace `include PgSearch` with `include PgSearch::Model`.
      MESSAGE
    )
  end
end
