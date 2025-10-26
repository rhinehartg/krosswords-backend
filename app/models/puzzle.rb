class Puzzle < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :difficulty, presence: true, inclusion: { in: %w[Easy Medium Hard] }
  validates :rating, presence: true, inclusion: { in: [1, 2, 3] }
  validates :is_published, inclusion: { in: [true, false] }
  validates :clues, presence: true

  # Associations
  has_many :ratings, dependent: :destroy
  has_many :rated_by_users, through: :ratings, source: :user

  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "difficulty", "id", "is_published", "rating", "title", "updated_at", "is_featured", "challenge_date", "type"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["ratings", "rated_by_users"]
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
  
  # Rating methods
  def average_rating
    return 0 if ratings.empty?
    avg = ratings.average(:rating)
    return 0 if avg.nil?
    avg.round(1)
  end
  
  def rating_count
    ratings.count
  end
  
  def update_average_rating!
    avg_rating = average_rating
    # Convert to 1-3 scale for display (round to nearest integer)
    display_rating = case avg_rating
                    when 0..1.5 then 1
                    when 1.5..2.5 then 2
                    when 2.5..3.0 then 3
                    else 2
                    end
    
    update_column(:rating, display_rating)
  end
  
  def user_rating(user)
    ratings.find_by(user: user)&.rating
  end
  
  def rated_by_user?(user)
    ratings.exists?(user: user)
  end
end
