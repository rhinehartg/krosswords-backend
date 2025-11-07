class RemoveDifficultyAndRatingFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    # Remove indexes first
    remove_index :puzzles, :difficulty if index_exists?(:puzzles, :difficulty)
    remove_index :puzzles, :rating if index_exists?(:puzzles, :rating)
    
    # Remove columns
    remove_column :puzzles, :difficulty, :string
    remove_column :puzzles, :rating, :integer
  end
end
