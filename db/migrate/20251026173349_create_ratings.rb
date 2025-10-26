class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.integer :rating, null: false

      t.timestamps
    end
    
    # Add indexes for performance (only if they don't exist)
    add_index :ratings, [:user_id, :puzzle_id], unique: true unless index_exists?(:ratings, [:user_id, :puzzle_id])
    add_index :ratings, :rating unless index_exists?(:ratings, :rating)
    
    # Add check constraint for rating range
    add_check_constraint :ratings, "rating >= 1 AND rating <= 5", name: "rating_range_check"
  end
end
