// Daily Challenge Generation Modal for Active Admin
function showDailyChallengeModal() {
  const modal = document.createElement('div');
  modal.id = 'daily-challenge-modal';
  modal.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 10000;
  `;
  
  // Get today's date and theme
  const today = new Date();
  const dayOfWeek = today.getDay();
  const themes = [
    "Monday Motivation - inspiring words and positive thinking",
    "Tuesday Trivia - fun facts and knowledge",
    "Wednesday Wisdom - life lessons and quotes",
    "Thursday Thoughts - philosophy and ideas",
    "Friday Fun - entertainment and games",
    "Saturday Science - scientific terms and concepts",
    "Sunday Stories - literature and books"
  ];
  
  const defaultTheme = themes[dayOfWeek];
  const defaultDifficulty = ['Easy', 'Medium', 'Hard'][dayOfWeek % 3];
  
  modal.innerHTML = `
    <div style="
      background: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
      max-width: 500px;
      width: 90%;
      max-height: 80vh;
      overflow-y: auto;
    ">
      <h2 style="margin-top: 0; color: #333;">Generate Daily Challenge</h2>
      
      <form id="daily-challenge-form">
        <div style="margin-bottom: 20px;">
          <label for="challenge_date" style="display: block; margin-bottom: 5px; font-weight: bold;">Challenge Date:</label>
          <input type="date" id="challenge_date" name="challenge_date" required 
            value="${today.toISOString().split('T')[0]}"
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="prompt" style="display: block; margin-bottom: 5px; font-weight: bold;">Theme/Topic:</label>
          <input type="text" id="prompt" name="prompt" required 
            value="${defaultTheme}"
            placeholder="e.g., Monday Motivation, Friday Fun, etc."
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="difficulty" style="display: block; margin-bottom: 5px; font-weight: bold;">Difficulty:</label>
          <select id="difficulty" name="difficulty" required 
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
            <option value="Easy" ${defaultDifficulty === 'Easy' ? 'selected' : ''}>Easy</option>
            <option value="Medium" ${defaultDifficulty === 'Medium' ? 'selected' : ''}>Medium</option>
            <option value="Hard" ${defaultDifficulty === 'Hard' ? 'selected' : ''}>Hard</option>
          </select>
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="word_count" style="display: block; margin-bottom: 5px; font-weight: bold;">Number of Words:</label>
          <input type="number" id="word_count" name="word_count" min="5" max="15" value="10" required
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="title_override" style="display: block; margin-bottom: 5px; font-weight: bold;">Title Override (Optional):</label>
          <input type="text" id="title_override" name="title_override" 
            placeholder="Leave blank for auto-generated title"
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="description_override" style="display: block; margin-bottom: 5px; font-weight: bold;">Description Override (Optional):</label>
          <textarea id="description_override" name="description_override" rows="3"
            placeholder="Leave blank for auto-generated description"
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; resize: vertical;"></textarea>
        </div>
        
        <div style="display: flex; gap: 10px; justify-content: flex-end;">
          <button type="button" onclick="closeDailyChallengeModal()" 
            style="padding: 10px 20px; border: 1px solid #ddd; background: #f8f9fa; border-radius: 5px; cursor: pointer;">
            Cancel
          </button>
          <button type="submit" id="generate-btn"
            style="padding: 10px 20px; background: #ff6b35; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">
            Generate Daily Challenge
          </button>
        </div>
      </form>
      
      <div id="generation-status" style="margin-top: 20px; display: none;">
        <div style="padding: 15px; background: #f8f9fa; border-radius: 5px; border-left: 4px solid #ff6b35;">
          <div id="status-text">Generating daily challenge...</div>
          <div id="status-details" style="font-size: 12px; color: #666; margin-top: 5px;"></div>
        </div>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Handle form submission
  document.getElementById('daily-challenge-form').addEventListener('submit', function(e) {
    e.preventDefault();
    generateDailyChallenge();
  });
}

function closeDailyChallengeModal() {
  const modal = document.getElementById('daily-challenge-modal');
  if (modal) {
    modal.remove();
  }
}

function generateDailyChallenge() {
  const form = document.getElementById('daily-challenge-form');
  const statusDiv = document.getElementById('generation-status');
  const statusText = document.getElementById('status-text');
  const statusDetails = document.getElementById('status-details');
  const generateBtn = document.getElementById('generate-btn');
  
  // Show status
  statusDiv.style.display = 'block';
  statusText.textContent = 'Generating daily challenge...';
  statusDetails.textContent = 'Please wait while AI creates your daily challenge...';
  generateBtn.disabled = true;
  generateBtn.textContent = 'Generating...';
  
  // Prepare form data
  const formData = new FormData(form);
  const data = {
    daily_challenge: {
      challenge_date: formData.get('challenge_date'),
      prompt: formData.get('prompt'),
      difficulty: formData.get('difficulty'),
      word_count: parseInt(formData.get('word_count')),
      title_override: formData.get('title_override') || null,
      description_override: formData.get('description_override') || null
    }
  };
  
  // Make API request
  fetch('/daily_challenges', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify(data)
  })
  .then(response => response.json())
  .then(result => {
    if (result.success) {
      statusText.textContent = '✅ Daily challenge generated successfully!';
      statusDetails.textContent = `Game Type: ${result.daily_challenge.game_type || 'Puzzle'} | Date: ${result.daily_challenge.challenge_date}`;
      generateBtn.textContent = 'Success!';
      generateBtn.style.background = '#28a745';
      
      // Refresh the page after a short delay
      setTimeout(() => {
        window.location.reload();
      }, 2000);
    } else {
      statusText.textContent = '❌ Generation failed';
      statusDetails.textContent = result.error || 'Unknown error occurred';
      generateBtn.textContent = 'Try Again';
      generateBtn.disabled = false;
    }
  })
  .catch(error => {
    statusText.textContent = '❌ Network error';
    statusDetails.textContent = 'Please check your connection and try again';
    generateBtn.textContent = 'Try Again';
    generateBtn.disabled = false;
  });
}

// Close modal when clicking outside
document.addEventListener('click', function(e) {
  if (e.target.id === 'daily-challenge-modal') {
    closeDailyChallengeModal();
  }
});
