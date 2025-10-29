# Environment Configuration for Gemini AI

## Setting up your .env file

Create a `.env` file in the root of your backend directory with the following content:

```bash
# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key_here

# Gemini Prompt Template (optional - if not set, uses default template)
# Uncomment and modify the prompt below to customize AI puzzle generation
GEMINI_PROMPT_TEMPLATE="

Requirements:
- Words: 3-12 letters, UPPERCASE letters only (A-Z, no accented characters)
- Words must intersect naturally in a crossword grid
- Use everyday vocabulary appropriate for the theme
- Clues should be clear and engaging (5-50 characters)
- Include a mix of short and medium words for good grid construction

IMPORTANT - Content Guidelines:
- Use only publicly available factual information (general knowledge, public domain facts)
- Do NOT reproduce copyrighted text, dialogue, lyrics, or specific plot details
- For themed puzzles (Disney, Marvel, Star Wars, etc.), use only general public knowledge:
  * Character names (e.g., \"The lion cub in The Lion King\" → SIMBA)
  * General facts, not specific story details
  * Well-known catchphrases in a descriptive way, not direct quotes
- Original clue wording only - do not copy copyrighted material
- If theme involves trademarks, use descriptive clues referencing public knowledge only

Return ONLY this JSON format (no additional text):
{
  \"title\": \"Puzzle Title\",
  \"description\": \"Brief description of the puzzle\",
  \"difficulty\": \"{difficulty}\",
  \"words\": [
    {\"clue\": \"Clue text here\", \"answer\": \"ANSWER\"}
  ]
}
"
```

## How it works

The `AiGeneratorService` class already supports environment variable configuration:

1. **API Key**: Set `GEMINI_API_KEY` with your Gemini API key
2. **Custom Prompt**: Set `GEMINI_PROMPT_TEMPLATE` to override the default prompt template
3. **Fallback**: If `GEMINI_PROMPT_TEMPLATE` is not set, it uses the default template defined in the service

## Usage

1. Copy the content above into a `.env` file in your backend root directory
2. Replace `your_gemini_api_key_here` with your actual Gemini API key
3. Optionally uncomment and modify the `GEMINI_PROMPT_TEMPLATE` to customize the AI behavior
4. Restart your Rails server to pick up the new environment variables

## Current Implementation

The prompt management is handled in `app/services/ai_generator_service.rb`:
- Line 133: `ENV['GEMINI_PROMPT_TEMPLATE'] || DEFAULT_PROMPT_TEMPLATE`
- Line 174: Uses environment variable in `build_prompt` method
- The service already supports both environment variables and Rails credentials
