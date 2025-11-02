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
    },
    {
      title: "Draft Puzzle",
      difficulty: "Easy",
      rating: 1,
      is_published: false,
      game_type: 'krossword',
      puzzle_data: {
        clues: [
          { "clue" => "Test clue", "answer" => "TEST" },
          { "clue" => "Another test", "answer" => "DEMO" }
        ],
        description: "This puzzle is not yet published"
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
    },
    {
      title: "Sports",
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Sports",
        words: ["SOCCER", "BALL", "GOAL", "TEAM"],
        layout: {
          rows: 4,
          cols: 7,
          table: [
            ["#", "#", "G", "#", "#", "T", "#"],
            ["#", "S", "O", "C", "C", "E", "R"],
            ["#", "#", "A", "#", "#", "A", "#"],
            ["B", "A", "L", "L", "#", "M", "#"]
          ],
          result: [
            { clue: "", answer: "SOCCER", startx: 2, starty: 2, position: 1, orientation: "across" },
            { clue: "", answer: "BALL", startx: 1, starty: 4, position: 2, orientation: "across" },
            { clue: "", answer: "GOAL", startx: 3, starty: 1, position: 3, orientation: "down" },
            { clue: "", answer: "TEAM", startx: 6, starty: 1, position: 4, orientation: "down" }
          ]
        }
      }
    },
    {
      title: "Colors",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Colors",
        words: ["RED", "BLUE", "YELLOW"],
        layout: {
          rows: 4,
          cols: 6,
          table: [
            ["#", "R", "#", "B", "#", "#"],
            ["Y", "E", "L", "L", "O", "W"],
            ["#", "D", "#", "U", "#", "#"],
            ["#", "#", "#", "E", "#", "#"]
          ],
          result: [
            { clue: "", answer: "RED", startx: 2, starty: 1, position: 1, orientation: "down" },
            { clue: "", answer: "BLUE", startx: 4, starty: 1, position: 2, orientation: "down" },
            { clue: "", answer: "YELLOW", startx: 1, starty: 2, position: 3, orientation: "across" }
          ]
        }
      }
    },
    {
      title: "Music",
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      game_type: 'krisskross',
      puzzle_data: {
        clue: "Music",
        words: ["PIANO", "SONG", "MUSIC"],
        layout: {
          rows: 5,
          cols: 5,
          table: [
            ["#", "M", "#", "#", "#"],
            ["#", "U", "#", "S", "#"],
            ["#", "S", "#", "O", "#"],
            ["P", "I", "A", "N", "O"],
            ["#", "C", "#", "G", "#"]
          ],
          result: [
            { clue: "", answer: "PIANO", startx: 1, starty: 4, position: 1, orientation: "across" },
            { clue: "", answer: "SONG", startx: 4, starty: 2, position: 2, orientation: "down" },
            { clue: "", answer: "MUSIC", startx: 2, starty: 1, position: 3, orientation: "down" }
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
    { words: ['OCEAN', 'SHARK', 'WHALE'], theme: 'Ocean Life', difficulty: 'Easy', rating: 2 },
    { words: ['WAVE', 'BEACH', 'SAND'], theme: 'Beach', difficulty: 'Easy', rating: 2 },
    { words: ['FOREST', 'TREE', 'DEER'], theme: 'Forest', difficulty: 'Easy', rating: 2 },
    { words: ['PANDA', 'BEAR', 'TIGER'], theme: 'Wild Animals', difficulty: 'Easy', rating: 2 },
    { words: ['PIZZA', 'PASTA', 'RISOTTO'], theme: 'Italian Food', difficulty: 'Medium', rating: 2 },
    { words: ['GUITAR', 'VIOLIN', 'CELLO'], theme: 'String Instruments', difficulty: 'Medium', rating: 2 },
    { words: ['PLANET', 'STAR', 'COMET'], theme: 'Space', difficulty: 'Easy', rating: 2 },
    { words: ['SNOW', 'RAIN', 'WIND'], theme: 'Weather', difficulty: 'Easy', rating: 2 },
    { words: ['WIZARD', 'DRAGON', 'MAGIC'], theme: 'Fantasy', difficulty: 'Easy', rating: 2 },
    # Themeless puzzles (clueless)
    { words: ['OCEAN', 'TIGER', 'LIGHT'], theme: 'clueless', difficulty: 'Hard', rating: 2 },
    { words: ['PIZZA', 'PLANET', 'GHOST'], theme: 'clueless', difficulty: 'Hard', rating: 2 },
    { words: ['WIZARD', 'BURGER', 'RIVER'], theme: 'clueless', difficulty: 'Hard', rating: 2 }
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
  # Create all puzzles
  # ==========================================
  
  # Create Krossword puzzles
  krossword_puzzles.each do |puzzle_data|
    Puzzle.find_or_create_by!(title: puzzle_data[:title]) do |puzzle|
      puzzle.difficulty = puzzle_data[:difficulty]
      puzzle.rating = puzzle_data[:rating]
      puzzle.is_published = puzzle_data[:is_published]
      puzzle.game_type = puzzle_data[:game_type]
      puzzle.puzzle_data = puzzle_data[:puzzle_data]
      # For backward compatibility, also set description and clues on legacy columns
      if puzzle_data[:puzzle_data][:description].present?
        puzzle.description = puzzle_data[:puzzle_data][:description]
      end
      if puzzle_data[:puzzle_data][:clues].present?
        puzzle.clues = puzzle_data[:puzzle_data][:clues]
      end
    end
  end

  # Create KrissKross puzzles
  krisskross_puzzles.each do |puzzle_data|
    Puzzle.find_or_create_by!(title: puzzle_data[:title]) do |puzzle|
      puzzle.difficulty = puzzle_data[:difficulty]
      puzzle.rating = puzzle_data[:rating]
      puzzle.is_published = puzzle_data[:is_published]
      puzzle.game_type = puzzle_data[:game_type]
      puzzle.puzzle_data = puzzle_data[:puzzle_data]
    end
  end

  # Create Konundrum puzzles
  konundrum_puzzles_data.each do |puzzle_data|
    Puzzle.find_or_create_by!(title: puzzle_data[:title]) do |puzzle|
      puzzle.difficulty = puzzle_data[:difficulty]
      puzzle.rating = puzzle_data[:rating]
      puzzle.is_published = puzzle_data[:is_published]
      puzzle.game_type = puzzle_data[:game_type]
      puzzle.puzzle_data = puzzle_data[:puzzle_data]
    end
  end

  puts "✅ Created #{AdminUser.count} admin users"
  puts "✅ Created #{User.count} regular users"
  puts "✅ Created #{Puzzle.count} total puzzles"
  puts "   - #{Puzzle.krosswords.count} Krossword puzzles"
  puts "   - #{Puzzle.krisskross.count} KrissKross puzzles"
  puts "   - #{Puzzle.konundrums.count} Konundrum puzzles"
  puts "✅ Admin login: admin@example.com / password"
  puts "✅ Super admin login: superadmin@example.com / admin123"
end
