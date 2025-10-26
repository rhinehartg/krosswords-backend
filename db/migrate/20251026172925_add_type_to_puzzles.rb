class AddTypeToPuzzles < ActiveRecord::Migration[8.1]
  def change
    add_column :puzzles, :type, :string
    add_index :puzzles, :type
  end
end
