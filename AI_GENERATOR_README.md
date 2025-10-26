# AI Generator Service

This service provides AI-powered puzzle generation using Google's Gemini API. It replaces the frontend-based puzzle generation with a robust backend solution.

## Setup

### 1. Configure Gemini API Key

Add your Gemini API key to Rails credentials:

```bash
rails credentials:edit
```

Add the following:

```yaml
gemini_api_key: your_gemini_api_key_here
```

Or set it as an environment variable:

```bash
export GEMINI_API_KEY=your_gemini_api_key_here
```

### 2. Get Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the key and add it to your credentials

## Usage

### API Endpoints

#### Check AI Service Availability
```http
GET /ai_puzzle
```

Response:
```json
{
  "available": true,
  "quotas": {
    "FREE": 0,
    "PRO": 3,
    "PREMIUM": -1
  }
}
```

#### Generate AI Puzzle
```http
POST /ai_puzzle
Content-Type: application/json

{
  "ai_puzzle": {
    "prompt": "animals and nature",
    "difficulty": "Easy",
    "theme": "Nature",
    "word_count": 8
  }
}
```

Response:
```json
{
  "success": true,
  "puzzle": {
    "id": 123,
    "title": "Nature Animals Puzzle",
    "description": "An AI-generated easy puzzle",
    "difficulty": "Easy",
    "rating": 1,
    "clues": [
      {"clue": "King of the jungle", "answer": "LION"},
      {"clue": "Flying mammal", "answer": "BAT"}
    ],
    "is_published": false,
    "created_at": "2025-01-27T10:00:00Z",
    "updated_at": "2025-01-27T10:00:00Z"
  },
  "message": "Puzzle generated successfully!"
}
```

#### Generate Complete Crossword (AI + Layout)
```http
POST /crossword/generate_ai
Content-Type: application/json

{
  "puzzle": {
    "prompt": "space exploration",
    "difficulty": "Medium",
    "theme": "Space",
    "word_count": 10
  }
}
```

Response:
```json
{
  "success": true,
  "puzzle": { /* puzzle data */ },
  "layout": {
    "rows": 15,
    "cols": 15,
    "table": [/* crossword grid */],
    "result": [/* positioned words */]
  },
  "message": "AI puzzle generated successfully!"
}
```

### Rake Tasks

#### Test AI Generation
```bash
rails ai:test_generation
```

#### Check Service Status
```bash
rails ai:check
```

### Service Classes

#### AiGeneratorService

Main service for AI puzzle generation:

```ruby
service = AiGeneratorService.new
result = service.generate_puzzle({
  prompt: "animals and nature",
  difficulty: "Easy",
  theme: "Nature",
  word_count: 8
})

if result[:success]
  puzzle = result[:puzzle]
  puts "Generated: #{puzzle.title}"
else
  puts "Error: #{result[:error]}"
end
```

#### CrosswordGeneratorService

Combines AI generation with crossword layout:

```ruby
service = CrosswordGeneratorService.new
result = service.generate_ai_puzzle({
  prompt: "space exploration",
  difficulty: "Medium",
  word_count: 10
})

if result[:success]
  puzzle = result[:puzzle]
  layout = result[:layout]
  puts "Generated puzzle with #{layout[:rows]}x#{layout[:cols]} grid"
end
```

## Configuration

### Quotas by User Tier

- **FREE**: 0 AI generations per day
- **PRO**: 3 AI generations per day  
- **PREMIUM**: Unlimited AI generations

### AI Model Settings

- **Model**: `gemini-2.5-flash-lite`
- **API URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent`
- **Temperature**: 0.7
- **Max Output Tokens**: 1024
- **Timeout**: 30 seconds
- **Max Retries**: 3

### Implementation Details

The service uses direct HTTP calls to the Gemini API rather than external gems, providing:
- Better control over requests and responses
- More reliable error handling
- No external gem dependencies
- Easier debugging and logging

### Validation Rules

- **Prompt**: Minimum 10 characters
- **Word Count**: 5-15 words
- **Difficulty**: Easy, Medium, or Hard
- **Answer Format**: UPPERCASE letters only (A-Z)
- **Answer Length**: 3-12 characters
- **Clue Length**: 5-50 characters

## Error Handling

The service includes comprehensive error handling for:

- Invalid API keys
- Network timeouts
- Malformed AI responses
- Validation errors
- Quota limits

All errors are logged and returned in a consistent format.

## Testing

Run the test suite:

```bash
rails test
```

Test AI generation specifically:

```bash
rails ai:test_generation
```

## Migration from Frontend

The frontend `GeminiPuzzleService` can now be replaced with API calls to these backend endpoints. The response format is compatible with the existing frontend code structure.
