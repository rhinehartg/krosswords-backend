class Puzzle < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :difficulty, presence: true, inclusion: { in: %w[Easy Medium Hard] }
  validates :rating, presence: true, inclusion: { in: [1, 2, 3] }
  validates :is_published, inclusion: { in: [true, false] }
  validates :clues, presence: true

  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "difficulty", "id", "is_published", "rating", "title", "updated_at", "is_featured", "challenge_date", "type"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  scope :published, -> { where(is_published: true) }
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :by_rating, ->(stars) { where(rating: stars) }
  
  # Puzzle type scopes
  scope :regular, -> { where(type: nil, is_featured: false) }
  scope :featured, -> { where(is_featured: true) }
  scope :daily_challenges, -> { where(type: 'DailyChallenge') }

  # Helper methods for difficulty
  def easy?
    difficulty == 'Easy'
  end

  def medium?
    difficulty == 'Medium'
  end

  def hard?
    difficulty == 'Hard'
  end

  # Helper methods for rating
  def one_star?
    rating == 1
  end

  def two_star?
    rating == 2
  end

  def three_star?
    rating == 3
  end

  # Helper method to get clues count
  def clues_count
    clues&.length || 0
  end
  
  # Helper methods for puzzle types
  def daily_challenge?
    read_attribute(:type) == 'DailyChallenge'
  end
  
  def featured?
    is_featured?
  end
  
  def regular?
    read_attribute(:type).nil? && !is_featured?
  end
  
  def puzzle_type
    if daily_challenge?
      'Daily Challenge'
    elsif featured?
      'Featured'
    else
      'Regular'
    end
  end
end
