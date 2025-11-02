class Puzzle < ApplicationRecord
  # Common validations for all puzzle types
  validates :title, presence: true, length: { maximum: 255 }
  validates :difficulty, presence: true, inclusion: { in: %w[Easy Medium Hard] }
  validates :rating, presence: true, inclusion: { in: [1, 2, 3] }
  validates :is_published, inclusion: { in: [true, false] }
  validates :game_type, inclusion: { in: %w[krossword konundrum krisskross] }, allow_nil: true
  
  # Validate puzzle_data JSON structure based on game_type
  validate :validate_puzzle_data_structure

  # Associations
  has_many :ratings, dependent: :destroy
  has_many :rated_by_users, through: :ratings, source: :user
  has_many :game_sessions, dependent: :destroy

  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "difficulty", "id", "is_published", "rating", "title", "updated_at", "is_featured", "challenge_date", "type", "game_type", "puzzle_data"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["ratings", "rated_by_users", "game_sessions"]
  end

  scope :published, -> { where(is_published: true) }
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :by_rating, ->(stars) { where(rating: stars) }
  
  # Game type scopes
  scope :krosswords, -> { where(game_type: 'krossword') }
  scope :konundrums, -> { where(game_type: 'konundrum') }
  scope :krisskross, -> { where(game_type: 'krisskross') }
  
  # Puzzle type scopes (challenge types)
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

  # Helper methods for game types
  def krossword?
    game_type == 'krossword'
  end

  def konundrum?
    game_type == 'konundrum'
  end

  def krisskross?
    game_type == 'krisskross'
  end
  
  # Helper methods for puzzle types (challenges)
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
  
  # Accessors for puzzle_data (JSON-based fields)
  # These provide easy access to type-specific data
  
  # For Krossword: clues, description, layout
  def clues
    # Legacy puzzles use the clues column, new ones use puzzle_data
    if game_type.nil? || (game_type == 'krossword' && puzzle_data.blank?)
      read_attribute(:clues)
    else
      puzzle_data&.dig('clues') || []
    end
  end
  
  def description
    # Legacy puzzles use the description column, new ones use puzzle_data
    if game_type.nil? || (game_type == 'krossword' && puzzle_data.blank?)
      read_attribute(:description)
    else
      puzzle_data&.dig('description')
    end
  end
  
  def layout
    puzzle_data&.dig('layout')
  end
  
  # For Konundrum: clue, words, letters, seed
  def clue
    puzzle_data&.dig('clue')
  end
  
  def words
    puzzle_data&.dig('words') || []
  end
  
  def letters
    puzzle_data&.dig('letters') || []
  end
  
  def seed
    puzzle_data&.dig('seed')
  end
  
  # For KrissKross: clue, words, layout
  def krisskross_words
    puzzle_data&.dig('words') || []
  end
  
  def krisskross_layout
    puzzle_data&.dig('layout')
  end
  
  # Helper method to get clues count
  def clues_count
    if krossword? || game_type.nil?
      clues.is_a?(Array) ? clues.length : 0
    else
      0
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
  
  private
  
  def validate_puzzle_data_structure
    return unless puzzle_data.present?
    
    case game_type
    when 'krossword'
      validate_krossword_structure
    when 'konundrum'
      validate_konundrum_structure
    when 'krisskross'
      validate_krisskross_structure
    when nil
      # Legacy puzzles - validate as krossword
      validate_krossword_structure if puzzle_data.is_a?(Hash)
    end
  end
  
  def validate_krossword_structure
    unless puzzle_data.is_a?(Hash)
      errors.add(:puzzle_data, "must be a hash for krossword puzzles")
      return
    end
    
    # Clues are required for krosswords (unless migrating from old structure)
    if puzzle_data['clues'].blank? && clues.blank?
      errors.add(:puzzle_data, "must contain 'clues' array for krossword puzzles")
    end
    
    # Validate clues format if present
    if puzzle_data['clues'].is_a?(Array)
      puzzle_data['clues'].each_with_index do |clue_item, index|
        unless clue_item.is_a?(Hash) && clue_item['clue'].present? && clue_item['answer'].present?
          errors.add(:puzzle_data, "clues[#{index}] must have 'clue' and 'answer' keys")
        end
      end
    end
    
    # Layout is optional but if present must have correct structure
    if puzzle_data['layout'].present?
      layout = puzzle_data['layout']
      unless layout.is_a?(Hash) && layout['table'].is_a?(Array) && layout['result'].is_a?(Array)
        errors.add(:puzzle_data, "layout must contain 'table' and 'result' arrays")
      end
    end
  end
  
  def validate_konundrum_structure
    unless puzzle_data.is_a?(Hash)
      errors.add(:puzzle_data, "must be a hash for konundrum puzzles")
      return
    end
    
    errors.add(:puzzle_data, "must contain 'clue' string") unless puzzle_data['clue'].is_a?(String) && puzzle_data['clue'].present?
    errors.add(:puzzle_data, "must contain 'words' array") unless puzzle_data['words'].is_a?(Array) && puzzle_data['words'].present?
    errors.add(:puzzle_data, "must contain 'letters' array") unless puzzle_data['letters'].is_a?(Array) && puzzle_data['letters'].present?
    
    # Validate words are strings
    if puzzle_data['words'].is_a?(Array)
      puzzle_data['words'].each_with_index do |word, index|
        unless word.is_a?(String) && word.present?
          errors.add(:puzzle_data, "words[#{index}] must be a non-empty string")
        end
      end
    end
    
    # Validate letters are strings
    if puzzle_data['letters'].is_a?(Array)
      puzzle_data['letters'].each_with_index do |letter, index|
        unless letter.is_a?(String) && letter.length == 1
          errors.add(:puzzle_data, "letters[#{index}] must be a single character string")
        end
      end
    end
    
    # Seed is optional
    if puzzle_data['seed'].present? && !puzzle_data['seed'].is_a?(String)
      errors.add(:puzzle_data, "seed must be a string if provided")
    end
  end
  
  def validate_krisskross_structure
    unless puzzle_data.is_a?(Hash)
      errors.add(:puzzle_data, "must be a hash for krisskross puzzles")
      return
    end
    
    errors.add(:puzzle_data, "must contain 'clue' string") unless puzzle_data['clue'].is_a?(String) && puzzle_data['clue'].present?
    errors.add(:puzzle_data, "must contain 'words' array") unless puzzle_data['words'].is_a?(Array) && puzzle_data['words'].present?
    errors.add(:puzzle_data, "must contain 'layout' hash") unless puzzle_data['layout'].is_a?(Hash) && puzzle_data['layout'].present?
    
    # Validate words
    if puzzle_data['words'].is_a?(Array)
      puzzle_data['words'].each_with_index do |word, index|
        unless word.is_a?(String) && word.present?
          errors.add(:puzzle_data, "words[#{index}] must be a non-empty string")
        end
      end
    end
    
    # Validate layout structure
    if puzzle_data['layout'].is_a?(Hash)
      layout = puzzle_data['layout']
      unless layout['table'].is_a?(Array) && layout['result'].is_a?(Array)
        errors.add(:puzzle_data, "layout must contain 'table' and 'result' arrays")
      end
      
      # Validate result items
      if layout['result'].is_a?(Array)
        layout['result'].each_with_index do |item, index|
          unless item.is_a?(Hash) && item['answer'].present?
            errors.add(:puzzle_data, "layout.result[#{index}] must have 'answer' key")
          end
        end
      end
    end
  end
end
