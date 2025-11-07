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
    { email: 'john@example.com', password: 'password123', first_name: 'John', last_name: 'Doe' },
    { email: 'jane@example.com', password: 'password123', first_name: 'Jane', last_name: 'Smith' },
    { email: 'bob@example.com', password: 'password123', first_name: 'Bob', last_name: 'Johnson' },
    { email: 'alice@example.com', password: 'password123', first_name: 'Alice', last_name: 'Williams' }
  ]

  users.each do |user_data|
    User.find_or_create_by!(email: user_data[:email]) do |user|
      user.password = user_data[:password]
      user.password_confirmation = user_data[:password]
      user.first_name = user_data[:first_name]
      user.last_name = user_data[:last_name]
    end
  end

  # ==========================================
  # Krossword Puzzles (Traditional)
  # ==========================================
  krossword_puzzles = [
    {
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        puzzle_clue: "Creatures great and small",
        clues: [
          { "clue" => "Man's best friend", "answer" => "DOG" },
          { "clue" => "King of the jungle", "answer" => "LION" },
          { "clue" => "Largest mammal", "answer" => "WHALE" },
          { "clue" => "Flying mammal", "answer" => "BAT" },
          { "clue" => "Fastest land animal", "answer" => "CHEETAH" },
          { "clue" => "Tallest animal", "answer" => "GIRAFFE" }
        ]
      }
    },
    {
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        puzzle_clue: "What's on the menu?",
        clues: [
          { "clue" => "Italian pasta dish", "answer" => "SPAGHETTI" },
          { "clue" => "Sweet breakfast treat", "answer" => "PANCAKE" },
          { "clue" => "Green leafy vegetable", "answer" => "SPINACH" },
          { "clue" => "Red fruit", "answer" => "TOMATO" },
          { "clue" => "Dairy product", "answer" => "CHEESE" },
          { "clue" => "Grain used for bread", "answer" => "WHEAT" }
        ]
      }
    },
    {
      is_published: true,
      game_type: 'krossword',
      puzzle_data: {
        puzzle_clue: "The final frontier",
        clues: [
          { "clue" => "Our home planet", "answer" => "EARTH" },
          { "clue" => "Red planet", "answer" => "MARS" },
          { "clue" => "Largest planet", "answer" => "JUPITER" },
          { "clue" => "Ringed planet", "answer" => "SATURN" },
          { "clue" => "Our star", "answer" => "SUN" },
          { "clue" => "Natural satellite", "answer" => "MOON" }
        ]
      }
    }
  ]

  # ==========================================
  # KrissKross Puzzles (Crossword without clues)
  # ==========================================
  krisskross_puzzles = [
    {
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        puzzle_clue: "Deep blue waters",
        clue: "Ocean",
        words: ["WATER", "WAVE", "TURTLE"],
        layout: {
          rows: 5,
          cols: 6,
          table: [
            ["#", "#", "#", "#", "W", "#"],
            ["T", "U", "R", "T", "L", "E"],
            ["#", "#", "#", "#", "V", "#"],
            ["#", "#", "#", "#", "E", "#"],
            ["W", "A", "T", "E", "R", "#"]
          ],
          result: [
            { clue: "", answer: "WATER", startx: 1, starty: 5, position: 1, orientation: "across" },
            { clue: "", answer: "WAVE", startx: 5, starty: 1, position: 2, orientation: "down" },
            { clue: "", answer: "TURTLE", startx: 1, starty: 2, position: 3, orientation: "across" }
          ]
        }
      }
    },
    {
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        puzzle_clue: "Wild kingdom",
        clue: "Animals",
        words: ["TIGER", "BEAR", "PANTHER"],
        layout: {
          rows: 5,
          cols: 7,
          table: [
            ["#", "#", "#", "#", "B", "#", "#"],
            ["P", "A", "N", "T", "H", "E", "R"],
            ["#", "#", "#", "#", "A", "#", "#"],
            ["T", "I", "G", "E", "R", "#", "#"],
            ["#", "#", "#", "#", "#", "#", "#"]
          ],
          result: [
            { clue: "", answer: "TIGER", startx: 1, starty: 4, position: 1, orientation: "across" },
            { clue: "", answer: "BEAR", startx: 5, starty: 1, position: 2, orientation: "down" },
            { clue: "", answer: "PANTHER", startx: 1, starty: 2, position: 3, orientation: "across" }
          ]
        }
      }
    },
    {
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        puzzle_clue: "Sweet endings",
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
  def generate_letters_from_words(words, seed)
    # Use seed to create deterministic shuffle
    rng = Random.new(seed)
    letters = words.join('').split('')
    # Deterministic shuffle using seeded random
    letters.shuffle(random: rng)
  end

  konundrum_puzzles = [
    {
      is_published: true,
      game_type: 'konundrum',
      puzzle_data: {
        puzzle_clue: "Underwater world",
        words: ['FISH', 'SHARK', 'DOLPHIN'],
        seed: 20241107
      }
    },
    {
      is_published: true,
      game_type: 'konundrum',
      puzzle_data: {
        puzzle_clue: "Sandy shores",
        words: ['WAVE', 'BEACH', 'SHELLS'],
        seed: 20241108
      }
    },
    {
      is_published: true,
      game_type: 'konundrum',
      puzzle_data: {
        puzzle_clue: "Woodland wanderers",
        words: ['FOREST', 'BIRCH', 'DEER'],
        seed: 20241109
      }
    }
  ]

  konundrum_puzzles_data = konundrum_puzzles

  # ==========================================
  # Konstructor Puzzles (Crossword Builder)
  # ==========================================
  konstructor_puzzles = [
    {
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Mother Nature's domain",
        words: ['OCEAN', 'TREE', 'SUN', 'MOUNTAIN', 'FOREST', 'RIVER', 'LAKE', 'STORM', 'CLOUD', 'WIND']
      }
    },
    {
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Fur and feathers",
        words: ['TIGER', 'ELEPHANT', 'LION', 'BEAR', 'EAGLE', 'SHARK', 'WHALE', 'PANDA', 'WOLF', 'DEER']
      }
    },
    {
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Taste sensations",
        words: ['PIZZA', 'COFFEE', 'BREAD', 'SALAD', 'APPLE', 'BANANA', 'ORANGE', 'CHEESE', 'MILK', 'JUICE']
      }
    },
    {
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Digital age essentials",
        words: ['COMPUTER', 'MOUSE', 'KEYBOARD', 'SCREEN', 'PHONE', 'TABLET', 'LAPTOP', 'CAMERA', 'SPEAKER', 'ROUTER']
      }
    },
    {
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Game on!",
        words: ['SOCCER', 'BASKETBALL', 'TENNIS', 'SWIMMING', 'BASEBALL', 'FOOTBALL', 'GOLF', 'HOCKEY', 'VOLLEYBALL', 'RUNNING']
      }
    },
    {
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'konstructor',
      puzzle_data: {
        puzzle_clue: "Harmony and rhythm",
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
        puzzle.is_published = true
        puzzle.game_type = 'krossword'
        puzzle.challenge_date = challenge_date
        puzzle.puzzle_data = krossword_puzzle[:puzzle_data]
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
