class RemoveIsFeaturedFromPuzzles < ActiveRecord::Migration[8.1]
  def change
    remove_index :puzzles, :is_featured if index_exists?(:puzzles, :is_featured)
    remove_column :puzzles, :is_featured, :boolean
  end
end
