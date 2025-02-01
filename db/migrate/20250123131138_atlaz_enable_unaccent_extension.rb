class EnableUnaccentExtension < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'unaccent'
  end
end
