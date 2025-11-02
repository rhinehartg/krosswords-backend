class AddGameTypeAndPuzzleDataToPuzzles < ActiveRecord::Migration[8.1]
  def change
    # Add game_type to distinguish puzzle types
    add_column :puzzles, :game_type, :string
    add_index :puzzles, :game_type
    
    # Add puzzle_data JSON column to store all type-specific data
    # This replaces description and clues columns (which we'll migrate later)
    add_column :puzzles, :puzzle_data, :json
    
    # Make description and clues nullable (they'll move into puzzle_data eventually)
    change_column_null :puzzles, :description, true
    change_column_null :puzzles, :clues, true
  end
end
