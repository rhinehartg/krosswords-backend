# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin users
if Rails.env.development?
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

  # Create sample puzzles
  puzzles = [
    {
      title: "Animal Kingdom",
      description: "All about our furry and feathered friends",
      difficulty: "Easy",
      rating: 2,
      is_published: true,
      clues: [
        { "clue" => "Man's best friend", "answer" => "DOG" },
        { "clue" => "King of the jungle", "answer" => "LION" },
        { "clue" => "Largest mammal", "answer" => "WHALE" },
        { "clue" => "Flying mammal", "answer" => "BAT" },
        { "clue" => "Fastest land animal", "answer" => "CHEETAH" },
        { "clue" => "Tallest animal", "answer" => "GIRAFFE" }
      ]
    },
    {
      title: "Food & Cooking",
      description: "Delicious puzzles about food",
      difficulty: "Medium",
      rating: 3,
      is_published: true,
      clues: [
        { "clue" => "Italian pasta dish", "answer" => "SPAGHETTI" },
        { "clue" => "Sweet breakfast treat", "answer" => "PANCAKE" },
        { "clue" => "Green leafy vegetable", "answer" => "SPINACH" },
        { "clue" => "Red fruit", "answer" => "TOMATO" },
        { "clue" => "Dairy product", "answer" => "CHEESE" },
        { "clue" => "Grain used for bread", "answer" => "WHEAT" }
      ]
    },
    {
      title: "Outer Space",
      description: "Journey through the cosmos",
      difficulty: "Hard",
      rating: 3,
      is_published: true,
      clues: [
        { "clue" => "Our home planet", "answer" => "EARTH" },
        { "clue" => "Red planet", "answer" => "MARS" },
        { "clue" => "Largest planet", "answer" => "JUPITER" },
        { "clue" => "Ringed planet", "answer" => "SATURN" },
        { "clue" => "Closest star to Earth", "answer" => "SUN" },
        { "clue" => "Natural satellite", "answer" => "MOON" }
      ]
    },
    {
      title: "Weather & Climate",
      description: "All about weather patterns and climate",
      difficulty: "Medium",
      rating: 2,
      is_published: true,
      clues: [
        { "clue" => "Frozen precipitation", "answer" => "SNOW" },
        { "clue" => "Electrical storm", "answer" => "LIGHTNING" },
        { "clue" => "Rotating wind storm", "answer" => "TORNADO" },
        { "clue" => "Water falling from sky", "answer" => "RAIN" },
        { "clue" => "Hot, dry wind", "answer" => "BREEZE" },
        { "clue" => "Visible water vapor", "answer" => "FOG" }
      ]
    },
    {
      title: "Draft Puzzle",
      description: "This puzzle is not yet published",
      difficulty: "Easy",
      rating: 1,
      is_published: false,
      clues: [
        { "clue" => "Test clue", "answer" => "TEST" },
        { "clue" => "Another test", "answer" => "DEMO" }
      ]
    }
  ]

  puzzles.each do |puzzle_data|
    Puzzle.find_or_create_by!(title: puzzle_data[:title]) do |puzzle|
      puzzle.description = puzzle_data[:description]
      puzzle.difficulty = puzzle_data[:difficulty]
      puzzle.rating = puzzle_data[:rating]
      puzzle.is_published = puzzle_data[:is_published]
      puzzle.clues = puzzle_data[:clues]
    end
  end

  puts "✅ Created #{AdminUser.count} admin users"
  puts "✅ Created #{User.count} regular users"
  puts "✅ Created #{Puzzle.count} puzzles"
  puts "✅ Admin login: admin@example.com / password"
  puts "✅ Super admin login: superadmin@example.com / admin123"
end