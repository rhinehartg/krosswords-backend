class CreatePuzzles < ActiveRecord::Migration[8.1]
  def change
    create_table :puzzles do |t|
      t.string :title, null: false, limit: 255
      t.text :description, null: false, limit: 1000
      t.string :difficulty, null: false, limit: 10  # Easy, Medium, Hard
      t.integer :rating, null: false, limit: 1  # 1-3 star rating
      t.boolean :is_published, default: false, null: false
      t.json :clues, null: false  # Store clue/answer pairs as JSON

      t.timestamps
    end
    
    add_index :puzzles, :difficulty
    add_index :puzzles, :rating
    add_index :puzzles, :is_published
  end
end
