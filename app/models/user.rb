class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :ratings, dependent: :destroy
  has_many :rated_puzzles, through: :ratings, source: :puzzle
  
  # Allow Active Admin to search and filter these attributes
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "remember_created_at", "reset_password_sent_at", "reset_password_token", "updated_at"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["ratings", "rated_puzzles"]
  end
  
  # Helper methods
  def rated_puzzle?(puzzle)
    ratings.exists?(puzzle: puzzle)
  end
  
  def rating_for_puzzle(puzzle)
    ratings.find_by(puzzle: puzzle)&.rating
  end
end
