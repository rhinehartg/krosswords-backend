class Puzzle < ApplicationRecord
  # Common validations for all puzzle types
  validates :difficulty, presence: true, inclusion: { in: %w[Easy Medium Hard] }
  validates :rating, presence: true, inclusion: { in: [1, 2, 3] }
  validates :is_published, inclusion: { in: [true, false] }
  validates :game_type, inclusion: { in: %w[krossword konundrum krisskross konstructor] }, allow_nil: true
  
  # Validate puzzle_data JSON structure based on game_type
  validate :validate_puzzle_data_structure
  # Validate that krossword puzzles must have challenge_date on Sunday
  validate :validate_krossword_challenge_date

  # Associations
  has_many :ratings, dependent: :destroy
  has_many :rated_by_users, through: :ratings, source: :user
  has_many :game_sessions, dependent: :destroy

  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "difficulty", "id", "is_published", "rating", "updated_at", "challenge_date", "type", "game_type", "puzzle_data"]
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
  scope :konstructors, -> { where(game_type: 'konstructor') }
  
  # Puzzle type scopes (challenge types)
  scope :regular, -> { where(type: nil, challenge_date: nil) }
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

  def konstructor?
    game_type == 'konstructor'
  end
  
  # Helper methods for puzzle types (challenges)
  def daily_challenge?
    read_attribute(:type) == 'DailyChallenge'
  end
  
  def regular?
    read_attribute(:type).nil? && challenge_date.nil?
  end
  
  def puzzle_type
    if daily_challenge?
      'Daily Challenge'
    elsif challenge_date.present?
      'Challenge'
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
    # Return stored letters if present, otherwise generate from seed
    stored_letters = puzzle_data&.dig('letters')
    return stored_letters if stored_letters.present?
    
    # Generate letters from seed if available
    seed_value = seed
    words_array = words
    if seed_value.present? && words_array.present? && words_array.any?
      generate_letters_from_seed(words_array, seed_value)
    else
      []
    end
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

  # For Konstructor: words (array of words to place on grid)
  def konstructor_words
    puzzle_data&.dig('words') || []
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
  
  def generate_letters_from_seed(words, seed_value)
    # Convert seed to integer if it's a string (for backward compatibility)
    seed_int = seed_value.is_a?(String) ? seed_value.hash.abs : seed_value.to_i
    rng = Random.new(seed_int)
    all_letters = words.join('').split('')
    all_letters.shuffle(random: rng)
  end
  
  def validate_puzzle_data_structure
    return unless puzzle_data.present?
    
    case game_type
    when 'krossword'
      validate_krossword_structure
    when 'konundrum'
      validate_konundrum_structure
    when 'krisskross'
      validate_krisskross_structure
    when 'konstructor'
      validate_konstructor_structure
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
    
    # Validate puzzle_clue is present and is a string
    unless puzzle_data['puzzle_clue'].is_a?(String) && puzzle_data['puzzle_clue'].present?
      errors.add(:puzzle_data, "must contain 'puzzle_clue' string for krossword puzzles")
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
    
    # Validate puzzle_clue is present and is a string
    unless puzzle_data['puzzle_clue'].is_a?(String) && puzzle_data['puzzle_clue'].present?
      errors.add(:puzzle_data, "must contain 'puzzle_clue' string for konundrum puzzles")
    end
    
    errors.add(:puzzle_data, "must contain 'words' array") unless puzzle_data['words'].is_a?(Array) && puzzle_data['words'].present?
    
    # Letters are optional if seed is present (letters can be generated from seed)
    unless puzzle_data['letters'].present? || puzzle_data['seed'].present?
      errors.add(:puzzle_data, "must contain either 'letters' array or 'seed' for konundrum puzzles")
    end
    
    # Validate words are strings
    if puzzle_data['words'].is_a?(Array)
      puzzle_data['words'].each_with_index do |word, index|
        unless word.is_a?(String) && word.present?
          errors.add(:puzzle_data, "words[#{index}] must be a non-empty string")
        end
      end
      
      # Validate all words have different lengths
      word_lengths = puzzle_data['words'].map { |w| w.to_s.length }
      if word_lengths.length != word_lengths.uniq.length
        errors.add(:puzzle_data, "all words in konundrum puzzles must have different lengths")
      end
    end
    
    # Validate letters are strings (if present)
    if puzzle_data['letters'].is_a?(Array)
      puzzle_data['letters'].each_with_index do |letter, index|
        unless letter.is_a?(String) && letter.length == 1
          errors.add(:puzzle_data, "letters[#{index}] must be a single character string")
        end
      end
    end
    
    # Seed can be integer or string
    if puzzle_data['seed'].present?
      unless puzzle_data['seed'].is_a?(String) || puzzle_data['seed'].is_a?(Integer) || puzzle_data['seed'].is_a?(Numeric)
        errors.add(:puzzle_data, "seed must be a string or number if provided")
      end
    end
  end
  
  def validate_krisskross_structure
    unless puzzle_data.is_a?(Hash)
      errors.add(:puzzle_data, "must be a hash for krisskross puzzles")
      return
    end
    
    # Validate puzzle_clue is present and is a string
    unless puzzle_data['puzzle_clue'].is_a?(String) && puzzle_data['puzzle_clue'].present?
      errors.add(:puzzle_data, "must contain 'puzzle_clue' string for krisskross puzzles")
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
      
      # Validate all words have different lengths
      word_lengths = puzzle_data['words'].map { |w| w.to_s.length }
      if word_lengths.length != word_lengths.uniq.length
        errors.add(:puzzle_data, "all words in krisskross puzzles must have different lengths")
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

  def validate_konstructor_structure
    unless puzzle_data.is_a?(Hash)
      errors.add(:puzzle_data, "must be a hash for konstructor puzzles")
      return
    end
    
    # Validate puzzle_clue is present and is a string
    unless puzzle_data['puzzle_clue'].is_a?(String) && puzzle_data['puzzle_clue'].present?
      errors.add(:puzzle_data, "must contain 'puzzle_clue' string for konstructor puzzles")
    end
    
    errors.add(:puzzle_data, "must contain 'words' array") unless puzzle_data['words'].is_a?(Array) && puzzle_data['words'].present?
    
    # Validate words are strings
    if puzzle_data['words'].is_a?(Array)
      puzzle_data['words'].each_with_index do |word, index|
        unless word.is_a?(String) && word.present?
          errors.add(:puzzle_data, "words[#{index}] must be a non-empty string")
        end
      end
    end
  end

  def validate_krossword_challenge_date
    # Only validate if this is a krossword puzzle and has a challenge_date
    return unless game_type == 'krossword' && challenge_date.present?
    
    # Sunday is wday == 0 in Ruby (Monday is 1, Sunday is 0)
    unless challenge_date.sunday?
      errors.add(:challenge_date, "must be a Sunday for krossword puzzles")
    end
  end
end
