class ChangeChallengeDateIndexToAllowMultiplePerDate < ActiveRecord::Migration[8.1]
  def up
    # Remove the old unique constraint on challenge_date alone
    remove_index :puzzles, name: "index_puzzles_on_challenge_date"
    
    # Add new composite unique index on challenge_date and game_type
    # This allows multiple puzzles per date, but only one per game_type per date
    add_index :puzzles, [:challenge_date, :game_type], 
              unique: true, 
              name: "index_puzzles_on_challenge_date_and_game_type",
              where: "challenge_date IS NOT NULL"
  end

  def down
    # Remove the composite index
    remove_index :puzzles, name: "index_puzzles_on_challenge_date_and_game_type"
    
    # Restore the original unique index on challenge_date alone
    add_index :puzzles, [:challenge_date], 
              unique: true, 
              name: "index_puzzles_on_challenge_date",
              where: "challenge_date IS NOT NULL"
  end
end
