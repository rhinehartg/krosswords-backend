class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Associations
  has_many :ratings, dependent: :destroy
  has_many :rated_puzzles, through: :ratings, source: :puzzle
  has_many :game_sessions, dependent: :destroy
  
  # Allow Active Admin to search and filter these attributes
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "remember_created_at", "reset_password_sent_at", "reset_password_token", "updated_at"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["ratings", "rated_puzzles", "game_sessions"]
  end
  
  # Helper methods
  def rated_puzzle?(puzzle)
    ratings.exists?(puzzle: puzzle)
  end
  
  def rating_for_puzzle(puzzle)
    ratings.find_by(puzzle: puzzle)&.rating
  end

  # Game session helper methods
  def active_session_for_puzzle(puzzle)
    game_sessions.active.find_by(puzzle: puzzle)
  end

  def session_for_puzzle(puzzle)
    game_sessions.find_by(puzzle: puzzle)
  end
end
