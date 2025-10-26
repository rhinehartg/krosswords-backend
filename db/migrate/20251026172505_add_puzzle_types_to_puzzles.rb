class AddPuzzleTypesToPuzzles < ActiveRecord::Migration[8.1]
  def change
    add_column :puzzles, :challenge_date, :date
    add_column :puzzles, :is_featured, :boolean, default: false, null: false
    
    # Add indexes for better performance
    add_index :puzzles, :is_featured
    
    # Ensure only one daily challenge per date
    add_index :puzzles, [:challenge_date], unique: true, where: "challenge_date IS NOT NULL"
  end
end
