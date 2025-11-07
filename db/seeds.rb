# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin users
if Rails.env.development? || Rails.env.staging?
  # Create default admin user
  admin_user = AdminUser.find_or_create_by!(email: 'admin@example.com') do |user|
    user.password = 'password'
    user.password_confirmation = 'password'
  end

  # Create additional admin user
  AdminUser.find_or_create_by!(email: 'superadmin@example.com') do |user|
    user.password = 'admin123'
    user.password_confirmation = 'admin123'
  end

  # Create sample regular users
  users = [
    { email: 'john@example.com', password: 'password123' },
    { email: 'jane@example.com', password: 'password123' },
    { email: 'bob@example.com', password: 'password123' },
    { email: 'alice@example.com', password: 'password123' }
  ]

  users.each do |user_data|
    User.find_or_create_by!(email: user_data[:email]) do |user|
      user.password = user_data[:password]
      user.password_confirmation = user_data[:password]
    end
  end

  # ==========================================
  # Krossword Puzzles (Traditional)
  # ==========================================
  krossword_puzzles = [
    {
      title: "Animal Kingdom",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        clues: [
          { "clue" => "Man's best friend", "answer" => "DOG" },
          { "clue" => "King of the jungle", "answer" => "LION" },
          { "clue" => "Largest mammal", "answer" => "WHALE" },
          { "clue" => "Flying mammal", "answer" => "BAT" },
          { "clue" => "Fastest land animal", "answer" => "CHEETAH" },
          { "clue" => "Tallest animal", "answer" => "GIRAFFE" }
        ],
        description: "All about our furry and feathered friends"
      }
    },
    {
      title: "Food & Cooking",
      difficulty: "Medium",
      rating: 3,
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        clues: [
          { "clue" => "Italian pasta dish", "answer" => "SPAGHETTI" },
          { "clue" => "Sweet breakfast treat", "answer" => "PANCAKE" },
          { "clue" => "Green leafy vegetable", "answer" => "SPINACH" },
          { "clue" => "Red fruit", "answer" => "TOMATO" },
          { "clue" => "Dairy product", "answer" => "CHEESE" },
          { "clue" => "Grain used for bread", "answer" => "WHEAT" }
        ],
        description: "Delicious puzzles about food"
      }
    },
    {
      title: "Outer Space",
      difficulty: "Hard",
      rating: 3,
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        clues: [
          { "clue" => "Our home planet", "answer" => "EARTH" },
          { "clue" => "Red planet", "answer" => "MARS" },
          { "clue" => "Largest planet", "answer" => "JUPITER" },
          { "clue" => "Ringed planet", "answer" => "SATURN" },
          { "clue" => "Closest star to Earth", "answer" => "SUN" },
          { "clue" => "Natural satellite", "answer" => "MOON" }
        ],
        description: "Journey through the cosmos"
      }
    }
  ]

  # ==========================================
  # KrissKross Puzzles (Crossword without clues)
  # ==========================================
  krisskross_puzzles = [
    {
      title: "Ocean Life",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Ocean",
        words: ["WATER", "WAVE", "CORAL"],
        layout: {
          rows: 4,
          cols: 5,
          table: [
            ["#", "#", "#", "W", "#"],
            ["C", "O", "R", "A", "L"],
            ["#", "#", "#", "V", "#"],
            ["W", "A", "T", "E", "R"]
          ],
          result: [
            { clue: "", answer: "WATER", startx: 1, starty: 4, position: 1, orientation: "across" },
            { clue: "", answer: "WAVE", startx: 4, starty: 1, position: 2, orientation: "down" },
            { clue: "", answer: "CORAL", startx: 1, starty: 2, position: 3, orientation: "across" }
          ]
        }
      }
    },
    {
      title: "Animals",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Animals",
        words: ["TIGER", "BEAR", "DEER"],
        layout: {
          rows: 4,
          cols: 5,
          table: [
            ["#", "#", "#", "B", "#"],
            ["T", "I", "G", "E", "R"],
            ["#", "#", "#", "A", "#"],
            ["D", "E", "E", "R", "#"]
          ],
          result: [
            { clue: "", answer: "TIGER", startx: 1, starty: 2, position: 1, orientation: "across" },
            { clue: "", answer: "BEAR", startx: 4, starty: 1, position: 2, orientation: "down" },
            { clue: "", answer: "DEER", startx: 1, starty: 4, position: 3, orientation: "across" }
          ]
        }
      }
    },
    {
      title: "Sweet Treats",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Desserts",
        words: ["CAKE", "COOKIE", "PIE"],
        layout: {
          rows: 5,
          cols: 6,
          table: [
            ["#", "#", "#", "#", "P", "#"],
            ["C", "O", "O", "K", "I", "E"],
            ["A", "#", "#", "#", "E", "#"],
            ["K", "#", "#", "#", "#", "#"],
            ["E", "#", "#", "#", "#", "#"]
          ],
          result: [
            { clue: "", answer: "CAKE", startx: 1, starty: 2, position: 1, orientation: "down" },
            { clue: "", answer: "COOKIE", startx: 1, starty: 2, position: 1, orientation: "across" },
            { clue: "", answer: "PIE", startx: 5, starty: 1, position: 2, orientation: "down" }
          ]
        }
      }
    }
  ]

  # ==========================================
  # Konundrum Puzzles (Multi-word Jumble)
  # ==========================================
  # Generate letters from words (shuffled) - using deterministic approach based on seed
  def generate_letters_from_words(words, seed_string)
    # Use seed to create deterministic shuffle
    seed = seed_string.hash.abs
    rng = Random.new(seed)
    letters = words.join('').split('')
    # Deterministic shuffle using seeded random
    letters.shuffle(random: rng)
  end

  konundrum_puzzles = [
    # Themed puzzles
    { words: ['FISH', 'SHARK', 'DOLPHIN'], theme: 'Ocean Life', difficulty: 'Easy', rating: 2 },
    { words: ['WAVE', 'BEACH', 'SAND'], theme: 'Beach', difficulty: 'Easy', rating: 2 },
    { words: ['FOREST', 'TREE', 'DEER'], theme: 'Forest', difficulty: 'Easy', rating: 2 }
  ]

  konundrum_puzzles_data = konundrum_puzzles.map do |puzzle|
    words = puzzle[:words]
    clue = puzzle[:theme] == 'clueless' ? 'clueless' : puzzle[:theme]
    seed_string = "#{clue}-#{words.join('-')}"
    letters = generate_letters_from_words(words, seed_string)
    
    {
      title: "#{clue == 'clueless' ? 'Themeless' : clue} Challenge",
      difficulty: puzzle[:difficulty],
      rating: puzzle[:rating],
      is_published: true,
      game_type: 'konundrum',
      puzzle_data: {
        clue: clue,
        words: words,
        letters: letters,
        seed: seed_string
      }
    }
  end

  # ==========================================
  # Konstructor Puzzles (Crossword Builder)
  # ==========================================
  konstructor_puzzles = [
    {
      title: "Nature Words",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['OCEAN', 'TREE', 'SUN', 'MOUNTAIN', 'FOREST', 'RIVER', 'LAKE', 'STORM', 'CLOUD', 'WIND']
      }
    },
    {
      title: "Animal Kingdom",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['TIGER', 'ELEPHANT', 'LION', 'BEAR', 'EAGLE', 'SHARK', 'WHALE', 'PANDA', 'WOLF', 'DEER']
      }
    },
    {
      title: "Food & Drinks",
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['PIZZA', 'COFFEE', 'BREAD', 'SALAD', 'APPLE', 'BANANA', 'ORANGE', 'CHEESE', 'MILK', 'JUICE']
      }
    },
    {
      title: "Technology",
      difficulty: "Medium",
      rating: 3,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['COMPUTER', 'MOUSE', 'KEYBOARD', 'SCREEN', 'PHONE', 'TABLET', 'LAPTOP', 'CAMERA', 'SPEAKER', 'ROUTER']
      }
    },
    {
      title: "Sports",
      difficulty: "Hard",
      rating: 3,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['SOCCER', 'BASKETBALL', 'TENNIS', 'SWIMMING', 'BASEBALL', 'FOOTBALL', 'GOLF', 'HOCKEY', 'VOLLEYBALL', 'RUNNING']
      }
    },
    {
      title: "Music",
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        words: ['GUITAR', 'PIANO', 'DRUMS', 'VIOLIN', 'TRUMPET', 'FLUTE', 'SAXOPHONE', 'HARMONICA', 'BANJO', 'CELLO']
      }
    }
  ]

  # ==========================================
  # Create Challenge Puzzles (All puzzles are challenges)
  # ==========================================
  
  today = Date.today
  
  # Generate challenge dates: 14 days in the past, today, and 29 days in the future
  # This gives us past, present, and future puzzles for testing
  past_dates = (-14..-1).map { |i| today + i.days }
  future_dates = (1..29).map { |i| today + i.days }
  challenge_dates = past_dates + [today] + future_dates
  
  # Create challenges for each puzzle type and date
  challenge_dates.each_with_index do |challenge_date, date_index|
    # Konundrum challenge - cycle through puzzles
    konundrum_index = date_index % konundrum_puzzles_data.length
    konundrum_puzzle = konundrum_puzzles_data[konundrum_index]
    Puzzle.find_or_create_by!(
      game_type: 'konundrum',
      challenge_date: challenge_date
    ) do |puzzle|
      puzzle.difficulty = konundrum_puzzle[:difficulty]
      puzzle.rating = konundrum_puzzle[:rating]
      puzzle.is_published = true
      puzzle.game_type = 'konundrum'
      puzzle.challenge_date = challenge_date
      puzzle.puzzle_data = konundrum_puzzle[:puzzle_data]
    end
    
    # KrissKross challenge - cycle through puzzles
    krisskross_index = date_index % krisskross_puzzles.length
    krisskross_puzzle = krisskross_puzzles[krisskross_index]
    Puzzle.find_or_create_by!(
      game_type: 'krisskross',
      challenge_date: challenge_date
    ) do |puzzle|
      puzzle.difficulty = krisskross_puzzle[:difficulty]
      puzzle.rating = krisskross_puzzle[:rating]
      puzzle.is_published = true
      puzzle.game_type = 'krisskross'
      puzzle.challenge_date = challenge_date
      puzzle.puzzle_data = krisskross_puzzle[:puzzle_data]
    end
    
    # Krossword challenge - weekly (only on Sundays)
    if challenge_date.wday == 0 # Sunday
      krossword_index = (date_index / 7) % krossword_puzzles.length
      krossword_puzzle = krossword_puzzles[krossword_index]
      Puzzle.find_or_create_by!(
        game_type: 'krossword',
        challenge_date: challenge_date
      ) do |puzzle|
        puzzle.difficulty = krossword_puzzle[:difficulty]
        puzzle.rating = krossword_puzzle[:rating]
        puzzle.is_published = true
        puzzle.game_type = 'krossword'
        puzzle.challenge_date = challenge_date
        puzzle.puzzle_data = krossword_puzzle[:puzzle_data]
        if krossword_puzzle[:puzzle_data][:description].present?
          puzzle.description = krossword_puzzle[:puzzle_data][:description]
        end
        if krossword_puzzle[:puzzle_data][:clues].present?
          puzzle.clues = krossword_puzzle[:puzzle_data][:clues]
        end
      end
    end
    
    # Konstructor challenge - cycle through puzzles
    konstructor_index = date_index % konstructor_puzzles.length
    konstructor_puzzle = konstructor_puzzles[konstructor_index]
    Puzzle.find_or_create_by!(
      game_type: 'konstructor',
      challenge_date: challenge_date
    ) do |puzzle|
      puzzle.difficulty = konstructor_puzzle[:difficulty]
      puzzle.rating = konstructor_puzzle[:rating]
      puzzle.is_published = true
      puzzle.game_type = 'konstructor'
      puzzle.challenge_date = challenge_date
      puzzle.puzzle_data = konstructor_puzzle[:puzzle_data]
    end
  end

  puts "✅ Created #{AdminUser.count} admin users"
  puts "✅ Created #{User.count} regular users"
  puts "✅ Created #{Puzzle.count} total puzzles"
  puts "   - #{Puzzle.where(game_type: 'krossword').count} Krossword puzzles"
  puts "   - #{Puzzle.where(game_type: 'krisskross').count} KrissKross puzzles"
  puts "   - #{Puzzle.where(game_type: 'konundrum').count} Konundrum puzzles"
  puts "   - #{Puzzle.where(game_type: 'konstructor').count} Konstructor puzzles"
  puts "   - #{Puzzle.where.not(challenge_date: nil).count} Challenge puzzles (daily & weekly)"
  puts "✅ Admin login: admin@example.com / password"
  puts "✅ Super admin login: superadmin@example.com / admin123"
end
