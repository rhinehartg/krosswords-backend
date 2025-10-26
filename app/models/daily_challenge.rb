class DailyChallenge < Puzzle
  validates :challenge_date, presence: true, uniqueness: true
  
  scope :for_date, ->(date) { where(challenge_date: date) }
  scope :current, -> { for_date(Date.current) }
  
  def self.today
    current.first
  end
  
  def self.for_date(date)
    find_by(challenge_date: date)
  end
  
  # Generate a daily challenge for a specific date
  def self.generate_for_date(date, options = {})
    ai_service = AiGeneratorService.new
    
    # Default theme based on day of week
    themes = [
      "Monday Motivation - inspiring words",
      "Tuesday Trivia - fun facts and knowledge",
      "Wednesday Wisdom - life lessons and quotes",
      "Thursday Thoughts - philosophy and ideas",
      "Friday Fun - entertainment and games",
      "Saturday Science - scientific terms and concepts",
      "Sunday Stories - literature and books"
    ]
    
    theme = options[:theme] || themes[date.wday - 1]
    difficulty = options[:difficulty] || select_daily_difficulty(date)
    word_count = options[:word_count] || 8
    
    result = ai_service.generate_puzzle({
      prompt: theme,
      difficulty: difficulty,
      word_count: word_count
    })
    
    if result[:success]
      puzzle = result[:puzzle]
      create!(
        title: puzzle.title,
        description: puzzle.description,
        difficulty: puzzle.difficulty,
        rating: puzzle.rating,
        clues: puzzle.clues,
        is_published: true,
        challenge_date: date
      )
    else
      raise "Failed to generate daily challenge: #{result[:error]}"
    end
  end
  
  private
  
  def self.select_daily_difficulty(date)
    # Rotate difficulty: Easy -> Medium -> Hard -> Easy...
    days_since_epoch = date.to_time.to_i / 1.day
    %w[Easy Medium Hard][days_since_epoch % 3]
  end
end
