namespace :ai do
  desc "Test AI puzzle generation"
  task test_generation: :environment do
    puts "🤖 Testing AI Puzzle Generation..."
    
    unless AiGeneratorService.available?
      puts "❌ AI service not available - check your Gemini API key"
      exit 1
    end
    
    puts "✅ AI service is available"
    
    # Test parameters
    test_params = {
      prompt: "animals and nature",
      difficulty: "Easy",
      theme: "Nature",
      word_count: 8
    }
    
    puts "📝 Generating puzzle with params: #{test_params}"
    
    service = AiGeneratorService.new
    result = service.generate_puzzle(test_params)
    
    if result[:success]
      puzzle = result[:puzzle]
      puts "🎉 Success! Generated puzzle:"
      puts "   Title: #{puzzle.title}"
      puts "   Difficulty: #{puzzle.difficulty}"
      puts "   Words: #{puzzle.clues.length}"
      puts "   ID: #{puzzle.id}"
      puts ""
      puts "📋 Clues:"
      puzzle.clues.each_with_index do |clue_data, index|
        puts "   #{index + 1}. #{clue_data['clue']} -> #{clue_data['answer']}"
      end
    else
      puts "❌ Failed to generate puzzle: #{result[:error]}"
      exit 1
    end
  end
  
  desc "Check AI service availability"
  task check: :environment do
    if AiGeneratorService.available?
      puts "✅ AI service is available"
      puts "   Model: gemini-2.5-flash-lite"
      puts "   Quotas: #{AiGeneratorService::QUOTAS}"
      puts "   Prompt Template: #{AiGeneratorService.using_custom_prompt? ? 'Custom (from ENV)' : 'Default'}"
      if AiGeneratorService.using_custom_prompt?
        puts "   Custom template length: #{AiGeneratorService.current_prompt_template.length} characters"
      end
    else
      puts "❌ AI service not available"
      puts "   Please set your Gemini API key in .env file or Rails credentials"
    end
  end
end
