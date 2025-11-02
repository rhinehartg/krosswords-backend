class CreateGameSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :puzzle, null: false, foreign_key: true
      t.string :status, default: 'active', null: false
      t.jsonb :game_state, default: {}
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    # Ensure only one active session per user per puzzle
    add_index :game_sessions, [:user_id, :puzzle_id], unique: true, name: 'index_game_sessions_on_user_and_puzzle'
    add_index :game_sessions, :status
    add_index :game_sessions, :started_at
  end
end
