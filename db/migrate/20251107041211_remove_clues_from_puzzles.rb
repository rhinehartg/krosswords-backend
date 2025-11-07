class RemoveCluesFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    remove_column :puzzles, :clues, :json
  end
end
