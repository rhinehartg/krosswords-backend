#!/usr/bin/env ruby
# Test script for AI Generator Service
# Run with: rails runner test_ai_generator.rb

puts "🤖 Testing AI Generator Service..."

# Test 1: Check if service is available
puts "\n1. Checking service availability..."
if AiGeneratorService.available?
  puts "✅ AI service is available"
else
  puts "❌ AI service not available - check your Gemini API key"
  puts "   Set your API key with: rails credentials:edit"
  exit 1
end

# Test 2: Test service initialization
puts "\n2. Testing service initialization..."
begin
  service = AiGeneratorService.new
  puts "✅ Service initialized successfully"
rescue AiGeneratorService::Error => e
  puts "❌ Service initialization failed: #{e.message}"
  exit 1
end

# Test 3: Test request validation
puts "\n3. Testing request validation..."
test_params = {
  prompt: "animals and nature",
  difficulty: "Easy",
  theme: "Nature",
  word_count: 8
}

begin
  service.send(:validate_request!, test_params)
  puts "✅ Request validation passed"
rescue AiGeneratorService::Error => e
  puts "❌ Request validation failed: #{e.message}"
  exit 1
end

# Test 4: Test prompt building
puts "\n4. Testing prompt building..."
prompt = service.send(:build_prompt, test_params)
if prompt.include?("animals and nature") && prompt.include?("Easy") && prompt.include?("8")
  puts "✅ Prompt building works correctly"
  puts "   Prompt length: #{prompt.length} characters"
else
  puts "❌ Prompt building failed"
  exit 1
end

puts "\n🎉 All basic tests passed!"
puts "\nTo test actual AI generation, run: rails ai:test_generation"
puts "Make sure you have a valid Gemini API key configured first."
