class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :puzzle
  
  validates :rating, presence: true, inclusion: { in: 1..3 }
  validates :user_id, uniqueness: { scope: :puzzle_id, message: "has already rated this puzzle" }
  
  # Callbacks to update puzzle's average rating
  after_save :update_puzzle_rating
  after_destroy :update_puzzle_rating
  
  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "rating", "updated_at", "user_id", "puzzle_id"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["user", "puzzle"]
  end
  
  private
  
  def update_puzzle_rating
    puzzle.update_average_rating!
  end
end
