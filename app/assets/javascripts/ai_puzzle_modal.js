// AI Puzzle Generation Modal for Active Admin
function showAIPuzzleModal() {
  const modal = document.createElement('div');
  modal.id = 'ai-puzzle-modal';
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
      <h2 style="margin-top: 0; color: #333;">Generate AI Puzzle</h2>
      
      <form id="ai-puzzle-form">
        <div style="margin-bottom: 20px;">
          <label for="prompt" style="display: block; margin-bottom: 5px; font-weight: bold;">Describe theme/topic</label>
          <input type="text" id="prompt" name="prompt" required 
            placeholder="Describe the puzzle theme (e.g., space exploration, kitchen staples)"
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="difficulty" style="display: block; margin-bottom: 5px; font-weight: bold;">Difficulty:</label>
          <select id="difficulty" name="difficulty" required 
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
            <option value="Easy">Easy</option>
            <option value="Medium" selected>Medium</option>
            <option value="Hard">Hard</option>
          </select>
        </div>
        
        <div style="margin-bottom: 20px;">
          <label for="word_count" style="display: block; margin-bottom: 5px; font-weight: bold;">Number of words</label>
          <input type="number" id="word_count" name="word_count" min="5" max="15" value="8" required
            style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px;">
        </div>
        
        
        
        <div style="display: flex; gap: 10px; justify-content: flex-end;">
          <button type="button" onclick="closeAIPuzzleModal()" 
            style="padding: 10px 20px; border: 1px solid #ddd; background: #f8f9fa; border-radius: 5px; cursor: pointer;">
            Cancel
          </button>
          <button type="submit" id="generate-btn"
            style="padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold;">
            Generate Puzzle
          </button>
        </div>
      </form>
      
      <div id="generation-status" style="margin-top: 20px; display: none;">
        <div style="padding: 15px; background: #f8f9fa; border-radius: 5px; border-left: 4px solid #007bff;">
          <div id="status-text">Generating puzzle...</div>
          <div id="status-details" style="font-size: 12px; color: #666; margin-top: 5px;"></div>
        </div>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Handle form submission
  document.getElementById('ai-puzzle-form').addEventListener('submit', function(e) {
    e.preventDefault();
    generateAIPuzzle();
  });
}

function closeAIPuzzleModal() {
  const modal = document.getElementById('ai-puzzle-modal');
  if (modal) {
    modal.remove();
  }
}

function generateAIPuzzle() {
  const form = document.getElementById('ai-puzzle-form');
  const statusDiv = document.getElementById('generation-status');
  const statusText = document.getElementById('status-text');
  const statusDetails = document.getElementById('status-details');
  const generateBtn = document.getElementById('generate-btn');
  
  // Show status
  statusDiv.style.display = 'block';
  statusText.textContent = 'Generating puzzle...';
  statusDetails.textContent = 'Please wait while AI creates your puzzle...';
  generateBtn.disabled = true;
  generateBtn.textContent = 'Generating...';
  
  // Prepare form data
  const formData = new FormData(form);
  const data = {
    ai_puzzle: {
      prompt: formData.get('prompt'),
      difficulty: formData.get('difficulty'),
      word_count: parseInt(formData.get('word_count'))
    }
  };
  
  // Make API request
  fetch('/ai_puzzle', {
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
      statusText.textContent = '✅ Puzzle generated successfully!';
      statusDetails.textContent = `Title: ${result.puzzle.title} | Words: ${result.puzzle.clues.length}`;
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
  if (e.target.id === 'ai-puzzle-modal') {
    closeAIPuzzleModal();
  }
});
