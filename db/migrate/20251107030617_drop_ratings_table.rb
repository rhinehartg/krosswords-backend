class DropRatingsTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.integer :rating, null: false
      t.timestamps
    end
  end
end
