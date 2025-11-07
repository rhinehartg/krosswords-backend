class RemoveTitleFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    remove_index :puzzles, :title if index_exists?(:puzzles, :title)
    remove_column :puzzles, :title, :string
  end
end
