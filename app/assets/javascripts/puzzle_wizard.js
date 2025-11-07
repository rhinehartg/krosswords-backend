// Puzzle Creation Wizard - Step-by-step modal interface
(function() {
  'use strict';

  const Wizard = {
    currentStep: 0,
    data: {
      game_type: '',
      title: '',
      difficulty: 'Medium',
      rating: 2,
      is_published: false,
      challenge_date: '',
      description: '',
      clues: [],
      puzzle_data: null
    },
    
    steps: [
      { id: 'game-type', title: 'Select Game Type' },
      { id: 'basic-info', title: 'Basic Information' },
      { id: 'content', title: 'Puzzle Content' },
      { id: 'options', title: 'Options & Settings' },
      { id: 'review', title: 'Review & Create' }
    ],

    init: function() {
      // This will be called when the wizard opens
    },

    show: function() {
      this.currentStep = 0;
      this.resetData();
      this.renderModal();
      this.showStep(0);
    },

    resetData: function() {
      this.data = {
        game_type: '',
        difficulty: 'Medium',
        rating: 2,
        is_published: false,
        challenge_date: '',
        description: '',
        clues: [],
        puzzle_data: null
      };
    },

    renderModal: function() {
      // Remove existing modal if present
      const existing = document.getElementById('puzzle-wizard-modal');
      if (existing) existing.remove();

      const modal = document.createElement('div');
      modal.id = 'puzzle-wizard-modal';
      modal.innerHTML = `
        <div class="wizard-overlay"></div>
        <div class="wizard-container">
          <div class="wizard-header">
            <h2>Create New Puzzle</h2>
            <button class="wizard-close" onclick="PuzzleWizard.close()">&times;</button>
          </div>
          
          <div class="wizard-progress">
            ${this.steps.map((step, idx) => `
              <div class="progress-step ${idx === 0 ? 'active' : ''}" data-step="${idx}">
                <div class="step-number">${idx + 1}</div>
                <div class="step-label">${step.title}</div>
              </div>
            `).join('')}
          </div>

          <div class="wizard-content">
            <!-- Steps will be rendered here -->
          </div>

          <div class="wizard-footer">
            <button class="wizard-btn wizard-btn-secondary" id="wizard-prev" onclick="PuzzleWizard.prevStep()" style="display: none;">Previous</button>
            <button class="wizard-btn wizard-btn-secondary" onclick="PuzzleWizard.close()">Cancel</button>
            <button class="wizard-btn wizard-btn-primary" id="wizard-next" onclick="PuzzleWizard.nextStep()">Next</button>
            <button class="wizard-btn wizard-btn-success" id="wizard-submit" onclick="PuzzleWizard.submit()" style="display: none;">Create Puzzle</button>
          </div>
        </div>
      `;

      document.body.appendChild(modal);
      this.addStyles();
      
      // Close on overlay click
      modal.querySelector('.wizard-overlay').addEventListener('click', () => this.close());
      
      // Close on Escape key
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && document.getElementById('puzzle-wizard-modal')) {
          PuzzleWizard.close();
        }
      });
    },

    addStyles: function() {
      if (document.getElementById('puzzle-wizard-styles')) return;

      const style = document.createElement('style');
      style.id = 'puzzle-wizard-styles';
      style.textContent = `
        #puzzle-wizard-modal {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          z-index: 10000;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .wizard-overlay {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0, 0, 0, 0.6);
          backdrop-filter: blur(2px);
        }
        .wizard-container {
          position: relative;
          background: white;
          border-radius: 12px;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          width: 90%;
          max-width: 800px;
          max-height: 90vh;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }
        .wizard-header {
          padding: 24px 32px;
          border-bottom: 1px solid #e5e7eb;
          display: flex;
          justify-content: space-between;
          align-items: center;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .wizard-header h2 {
          margin: 0;
          font-size: 24px;
          font-weight: 600;
        }
        .wizard-close {
          background: rgba(255, 255, 255, 0.2);
          border: none;
          color: white;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          font-size: 20px;
          cursor: pointer;
          transition: all 0.2s;
        }
        .wizard-close:hover {
          background: rgba(255, 255, 255, 0.3);
          transform: scale(1.1);
        }
        .wizard-progress {
          display: flex;
          padding: 20px 32px;
          background: #f9fafb;
          border-bottom: 1px solid #e5e7eb;
          justify-content: space-between;
        }
        .progress-step {
          flex: 1;
          display: flex;
          flex-direction: column;
          align-items: center;
          position: relative;
        }
        .progress-step:not(:last-child)::after {
          content: '';
          position: absolute;
          top: 20px;
          left: calc(50% + 20px);
          width: calc(100% - 40px);
          height: 2px;
          background: #e5e7eb;
          z-index: 0;
        }
        .progress-step.active::after,
        .progress-step.completed::after {
          background: #667eea;
        }
        .step-number {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: #e5e7eb;
          color: #6b7280;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 600;
          margin-bottom: 8px;
          position: relative;
          z-index: 1;
          transition: all 0.3s;
        }
        .progress-step.active .step-number {
          background: #667eea;
          color: white;
          transform: scale(1.1);
        }
        .progress-step.completed .step-number {
          background: #10b981;
          color: white;
        }
        .step-label {
          font-size: 12px;
          color: #6b7280;
          text-align: center;
          font-weight: 500;
        }
        .progress-step.active .step-label {
          color: #667eea;
          font-weight: 600;
        }
        .wizard-content {
          flex: 1;
          padding: 32px;
          overflow-y: auto;
          min-height: 400px;
        }
        .wizard-step {
          display: none;
          animation: fadeIn 0.3s;
        }
        .wizard-step.active {
          display: block;
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .wizard-form-group {
          margin-bottom: 24px;
        }
        .wizard-form-group label {
          display: block;
          margin-bottom: 8px;
          font-weight: 600;
          color: #374151;
          font-size: 14px;
        }
        .wizard-form-group input,
        .wizard-form-group select,
        .wizard-form-group textarea {
          width: 100%;
          padding: 12px;
          border: 2px solid #e5e7eb;
          border-radius: 8px;
          font-size: 14px;
          transition: all 0.2s;
          font-family: inherit;
        }
        .wizard-form-group input:focus,
        .wizard-form-group select:focus,
        .wizard-form-group textarea:focus {
          outline: none;
          border-color: #667eea;
          box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        .wizard-form-group textarea {
          min-height: 120px;
          resize: vertical;
        }
        .wizard-form-group .help-text {
          font-size: 12px;
          color: #6b7280;
          margin-top: 6px;
        }
        .wizard-form-group .error {
          color: #ef4444;
          font-size: 12px;
          margin-top: 6px;
        }
        .wizard-game-type-options {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 16px;
          margin-top: 16px;
        }
        .game-type-card {
          border: 3px solid #e5e7eb;
          border-radius: 12px;
          padding: 24px;
          text-align: center;
          cursor: pointer;
          transition: all 0.2s;
          background: white;
        }
        .game-type-card:hover {
          border-color: #667eea;
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
        }
        .game-type-card.selected {
          border-color: #667eea;
          background: #f0f4ff;
        }
        .game-type-card .icon {
          font-size: 48px;
          margin-bottom: 12px;
        }
        .game-type-card .name {
          font-weight: 600;
          font-size: 16px;
          color: #374151;
          margin-bottom: 8px;
        }
        .game-type-card .desc {
          font-size: 12px;
          color: #6b7280;
        }
        .wizard-footer {
          padding: 20px 32px;
          border-top: 1px solid #e5e7eb;
          display: flex;
          justify-content: space-between;
          gap: 12px;
          background: #f9fafb;
        }
        .wizard-btn {
          padding: 12px 24px;
          border: none;
          border-radius: 8px;
          font-weight: 600;
          font-size: 14px;
          cursor: pointer;
          transition: all 0.2s;
        }
        .wizard-btn-primary {
          background: #667eea;
          color: white;
        }
        .wizard-btn-primary:hover {
          background: #5568d3;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        .wizard-btn-secondary {
          background: #e5e7eb;
          color: #374151;
        }
        .wizard-btn-secondary:hover {
          background: #d1d5db;
        }
        .wizard-btn-success {
          background: #10b981;
          color: white;
        }
        .wizard-btn-success:hover {
          background: #059669;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
        }
        .clue-item {
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 16px;
          margin-bottom: 12px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .clue-item .clue-text {
          flex: 1;
          font-size: 14px;
        }
        .clue-item .clue-answer {
          font-weight: 600;
          color: #667eea;
          margin-left: 16px;
        }
        .clue-item button {
          background: #ef4444;
          color: white;
          border: none;
          padding: 6px 12px;
          border-radius: 6px;
          cursor: pointer;
          font-size: 12px;
        }
        .add-clue-form {
          background: #f0f4ff;
          border: 2px dashed #667eea;
          border-radius: 8px;
          padding: 20px;
          margin-top: 16px;
        }
      `;
      document.head.appendChild(style);
    },

    showStep: function(stepIndex) {
      this.currentStep = stepIndex;
      
      // Update progress indicators
      this.steps.forEach((step, idx) => {
        const stepEl = document.querySelector(`.progress-step[data-step="${idx}"]`);
        if (stepEl) {
          stepEl.classList.remove('active', 'completed');
          if (idx < stepIndex) {
            stepEl.classList.add('completed');
            stepEl.querySelector('.step-number').textContent = '✓';
          } else if (idx === stepIndex) {
            stepEl.classList.add('active');
            stepEl.querySelector('.step-number').textContent = idx + 1;
          } else {
            stepEl.querySelector('.step-number').textContent = idx + 1;
          }
        }
      });

      // Render step content
      const content = document.querySelector('.wizard-content');
      if (content) {
        content.innerHTML = this.renderStepContent(stepIndex);
      }

      // Update footer buttons
      const prevBtn = document.getElementById('wizard-prev');
      const nextBtn = document.getElementById('wizard-next');
      const submitBtn = document.getElementById('wizard-submit');

      if (prevBtn) prevBtn.style.display = stepIndex > 0 ? 'block' : 'none';
      if (nextBtn) nextBtn.style.display = stepIndex < this.steps.length - 1 ? 'block' : 'none';
      if (submitBtn) submitBtn.style.display = stepIndex === this.steps.length - 1 ? 'block' : 'none';
    },

    renderStepContent: function(stepIndex) {
      switch(stepIndex) {
        case 0: return this.renderGameTypeStep();
        case 1: return this.renderBasicInfoStep();
        case 2: return this.renderContentStep();
        case 3: return this.renderOptionsStep();
        case 4: return this.renderReviewStep();
        default: return '';
      }
    },

    renderGameTypeStep: function() {
      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">What type of puzzle are you creating?</h3>
          <div class="wizard-game-type-options">
            <div class="game-type-card ${this.data.game_type === 'krossword' ? 'selected' : ''}" 
                 onclick="PuzzleWizard.selectGameType('krossword')">
              <div class="icon">📝</div>
              <div class="name">Krossword</div>
              <div class="desc">Traditional crossword puzzle with clues and answers</div>
            </div>
            <div class="game-type-card ${this.data.game_type === 'konundrum' ? 'selected' : ''}" 
                 onclick="PuzzleWizard.selectGameType('konundrum')">
              <div class="icon">🔀</div>
              <div class="name">Konundrum</div>
              <div class="desc">Word unscrambling puzzle with shuffled letters</div>
            </div>
            <div class="game-type-card ${this.data.game_type === 'krisskross' ? 'selected' : ''}" 
                 onclick="PuzzleWizard.selectGameType('krisskross')">
              <div class="icon">✖️</div>
              <div class="name">KrissKross</div>
              <div class="desc">Word placement puzzle with intersecting words</div>
            </div>
          </div>
          ${this.data.game_type ? `<div class="help-text" style="margin-top: 20px; text-align: center; color: #10b981;">✓ ${this.data.game_type.charAt(0).toUpperCase() + this.data.game_type.slice(1)} selected</div>` : ''}
        </div>
      `;
    },

    renderBasicInfoStep: function() {
      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">Basic Information</h3>
          <div class="wizard-form-group">
            <label>Difficulty *</label>
            <select id="wizard-difficulty" onchange="PuzzleWizard.data.difficulty = this.value">
              <option value="Easy" ${this.data.difficulty === 'Easy' ? 'selected' : ''}>Easy (Green)</option>
              <option value="Medium" ${this.data.difficulty === 'Medium' ? 'selected' : ''}>Medium (Yellow)</option>
              <option value="Hard" ${this.data.difficulty === 'Hard' ? 'selected' : ''}>Hard (Red)</option>
            </select>
          </div>
          <div class="wizard-form-group">
            <label>Rating *</label>
            <select id="wizard-rating" onchange="PuzzleWizard.data.rating = parseInt(this.value)">
              <option value="1" ${this.data.rating === 1 ? 'selected' : ''}>⭐ 1 Star</option>
              <option value="2" ${this.data.rating === 2 ? 'selected' : ''}>⭐⭐ 2 Stars</option>
              <option value="3" ${this.data.rating === 3 ? 'selected' : ''}>⭐⭐⭐ 3 Stars</option>
            </select>
          </div>
        </div>
      `;
    },

    renderContentStep: function() {
      if (this.data.game_type === 'krossword') {
        return this.renderKrosswordContentStep();
      } else if (this.data.game_type === 'konundrum') {
        return this.renderKonundrumContentStep();
      } else if (this.data.game_type === 'krisskross') {
        return this.renderKrissKrossContentStep();
      }
      return '<div class="wizard-step active">Please select a game type first.</div>';
    },

    renderKrosswordContentStep: function() {
      const cluesHtml = this.data.clues.map((clue, idx) => `
        <div class="clue-item">
          <div class="clue-text">
            <strong>${clue.clue || 'Clue'}</strong> → <span class="clue-answer">${clue.answer || ''}</span>
          </div>
          <button onclick="PuzzleWizard.removeClue(${idx})">Remove</button>
        </div>
      `).join('');

      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">Krossword Content</h3>
          <div class="wizard-form-group">
            <label>Description</label>
            <textarea id="wizard-description" placeholder="Enter a description for this crossword puzzle"
                      onchange="PuzzleWizard.data.description = this.value">${this.data.description || ''}</textarea>
          </div>
          <div class="wizard-form-group">
            <label>Clues * (${this.data.clues.length} added)</label>
            ${cluesHtml}
            <div class="add-clue-form">
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <input type="text" id="new-clue-text" placeholder="Enter clue text">
                <input type="text" id="new-clue-answer" placeholder="Enter answer (UPPERCASE)" style="text-transform: uppercase;">
              </div>
              <button class="wizard-btn wizard-btn-primary" onclick="PuzzleWizard.addClue()" style="width: 100%;">Add Clue</button>
            </div>
            <div class="help-text">Answers should be in UPPERCASE letters. Add at least 5 clues for a good puzzle.</div>
          </div>
        </div>
      `;
    },

    renderKonundrumContentStep: function() {
      // Extract current data
      const clue = this.data.puzzle_data?.clue || '';
      const words = this.data.puzzle_data?.words || [];
      const letters = this.data.puzzle_data?.letters || [];
      const seed = this.data.puzzle_data?.seed || '';
      const lettersText = letters.join('');
      
      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">Konundrum Content</h3>
          
          <div class="wizard-form-group">
            <label>Clue / Theme *</label>
            <input type="text" id="konundrum-clue" value="${clue}" 
                   placeholder="e.g., Ocean Life or 'clueless' for extra difficulty"
                   onchange="PuzzleWizard.updateKonundrumData()">
            <div class="help-text">Enter a theme phrase or 'clueless' for themeless puzzles</div>
          </div>

          <div class="wizard-form-group">
            <label>Words *</label>
            <textarea id="konundrum-words" 
                      placeholder="Enter one word per line:\nOCEAN\nTIGER\nLIGHT"
                      rows="5"
                      onchange="PuzzleWizard.updateKonundrumData()">${words.join('\n')}</textarea>
            <div class="help-text">Enter one word per line (e.g., OCEAN on line 1, TIGER on line 2, LIGHT on line 3). Letters will be automatically shuffled.</div>
          </div>

          <div class="wizard-form-group">
            <label>Seed (Auto-generated)</label>
            <input type="text" id="konundrum-seed" value="${seed}" 
                   placeholder="Auto-generated from timestamp"
                   readonly
                   style="background-color: #f3f4f6; cursor: not-allowed;"
                   onchange="PuzzleWizard.updateKonundrumData()">
            <div class="help-text">Seed is automatically generated from the current timestamp for random shuffling. Letters are generated from words using this seed.</div>
          </div>

          ${lettersText && words.length > 0 && this.data.puzzle_data?.letterGroups ? `
          <div class="wizard-form-group" style="background: #f9fafb; padding: 16px; border-radius: 8px; border: 1px solid #e5e7eb;">
            <label style="margin-bottom: 8px; color: #6b7280;">Preview: Shuffled Letters (Split by Word)</label>
            <div style="font-family: 'Courier New', monospace; font-size: 18px; letter-spacing: 2px; color: #374151; word-break: break-all; display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 12px;">
              ${this.data.puzzle_data.letterGroups.map((group, idx) => `
                <div style="background: white; padding: 12px; border-radius: 6px; border: 2px solid #e5e7eb; flex: 1; min-width: 150px; text-align: center;">
                  <div style="font-size: 11px; color: #6b7280; margin-bottom: 4px; font-weight: 600;">Word ${idx + 1} (${group.length} letters)</div>
                  <div style="font-weight: 600; color: #374151;">${group.join('')}</div>
                </div>
              `).join('')}
            </div>
            <div class="help-text" style="margin-top: 8px; color: #6b7280;">
              Each word's letters have been shuffled separately. Group sizes match the original word lengths (${words.map(w => w.length).join(', ')} letters).
            </div>
          </div>
          ` : ''}
        </div>
      `;
    },

    renderKrissKrossContentStep: function() {
      // Extract current data
      const clue = this.data.puzzle_data?.clue || '';
      const words = this.data.puzzle_data?.words || [];
      const layout = this.data.puzzle_data?.layout || null;
      const isGenerating = this.data._generatingLayout || false;
      
      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">KrissKross Content</h3>
          
          <div class="wizard-form-group">
            <label>Clue / Theme *</label>
            <input type="text" id="krisskross-clue" value="${clue}" 
                   placeholder="e.g., Ocean or 'clueless'"
                   onchange="PuzzleWizard.updateKrissKrossData()"
                   oninput="PuzzleWizard.updateKrissKrossData()">
            <div class="help-text">Enter a theme phrase or 'clueless' for extra difficulty</div>
          </div>

          <div class="wizard-form-group">
            <label>Words *</label>
            <textarea id="krisskross-words" 
                      placeholder="Enter one word per line:\nWATER\nWAVE\nCORAL"
                      rows="5"
                      onchange="PuzzleWizard.updateKrissKrossData()"
                      oninput="PuzzleWizard.updateKrissKrossData()">${words.join('\n')}</textarea>
            <div class="help-text">Enter one word per line (3-5 words total). Each word should be 4-8 letters long.</div>
            <button type="button" 
                    onclick="PuzzleWizard.generateKrissKrossLayout()" 
                    id="krisskross-generate-btn"
                    style="margin-top: 12px; padding: 10px 20px; background-color: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer; font-weight: bold; ${isGenerating ? 'opacity: 0.6; cursor: not-allowed;' : ''}"
                    ${isGenerating ? 'disabled' : ''}>
              ${isGenerating ? '⏳ Generating Layout...' : '🔧 Generate Layout'}
            </button>
            ${layout ? '<div class="help-text" style="color: #10b981; margin-top: 8px;">✓ Layout generated successfully!</div>' : '<div class="help-text" style="color: #6b7280; margin-top: 8px;">Click "Generate Layout" after entering your words.</div>'}
          </div>

          ${layout ? `
          <div class="wizard-form-group" style="background: #f9fafb; padding: 16px; border-radius: 8px; border: 1px solid #e5e7eb;">
            <label style="margin-bottom: 8px; color: #6b7280;">Generated Layout Preview</label>
            <div style="background: white; padding: 12px; border-radius: 4px; font-size: 11px; overflow: auto; max-height: 200px;">
              <div style="margin-bottom: 8px;"><strong>Grid:</strong> ${layout.rows}×${layout.cols}</div>
              <div style="margin-bottom: 8px;"><strong>Words placed:</strong> ${layout.result?.length || 0}</div>
              <details style="margin-top: 8px;">
                <summary style="cursor: pointer; font-weight: 600; color: #667eea;">View Full Layout JSON</summary>
                <pre style="background: #f5f5f5; padding: 8px; border-radius: 4px; margin-top: 8px; font-size: 10px; overflow: auto;">${JSON.stringify(layout, null, 2)}</pre>
              </details>
            </div>
            <div class="help-text" style="margin-top: 8px; color: #10b981;">✓ Layout generated successfully! You can proceed to the next step.</div>
          </div>
          ` : ''}
        </div>
      `;
    },

    renderOptionsStep: function() {
      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">Options & Settings</h3>
          <div class="wizard-form-group">
            <label style="display: flex; align-items: center; cursor: pointer;">
              <input type="checkbox" id="wizard-published" ${this.data.is_published ? 'checked' : ''} 
                     onchange="PuzzleWizard.data.is_published = this.checked"
                     style="width: auto; margin-right: 8px;">
              Publish this puzzle immediately
            </label>
            <div class="help-text">Leave unchecked to save as draft</div>
          </div>
          <div class="wizard-form-group">
            <label>Challenge Date (Optional)</label>
            <input type="date" id="wizard-challenge-date" value="${this.data.challenge_date || ''}"
                   onchange="PuzzleWizard.data.challenge_date = this.value">
            <div class="help-text">Set a date to make this a daily challenge</div>
          </div>
        </div>
      `;
    },

    renderReviewStep: function() {
      let contentPreview = '';
      if (this.data.game_type === 'krossword') {
        contentPreview = `
          <p><strong>Description:</strong> ${this.data.description || 'None'}</p>
          <p><strong>Clues:</strong> ${this.data.clues.length} clues added</p>
          <ul style="margin-top: 12px;">
            ${this.data.clues.slice(0, 5).map(c => `<li>${c.clue} → <strong>${c.answer}</strong></li>`).join('')}
            ${this.data.clues.length > 5 ? `<li>... and ${this.data.clues.length - 5} more</li>` : ''}
          </ul>
        `;
      } else if (this.data.game_type === 'konundrum') {
        const pd = this.data.puzzle_data || {};
        contentPreview = `
          <p><strong>Clue/Theme:</strong> ${pd.clue || 'Not set'}</p>
          <p><strong>Words:</strong> ${pd.words ? pd.words.join(', ') : 'None'} (${pd.words ? pd.words.length : 0} words)</p>
          <p><strong>Letters:</strong> ${pd.letters ? pd.letters.join('') : 'None'} (${pd.letters ? pd.letters.length : 0} letters)</p>
          ${pd.seed ? `<p><strong>Seed:</strong> ${pd.seed}</p>` : ''}
        `;
      } else if (this.data.game_type === 'krisskross') {
        const pd = this.data.puzzle_data || {};
        contentPreview = `
          <p><strong>Clue/Theme:</strong> ${pd.clue || 'Not set'}</p>
          <p><strong>Words:</strong> ${pd.words ? pd.words.join(', ') : 'None'} (${pd.words ? pd.words.length : 0} words)</p>
          <p><strong>Layout:</strong> ${pd.layout ? 'Provided ✓' : 'Not set'}</p>
        `;
      } else {
        contentPreview = `<pre style="background: #f9fafb; padding: 16px; border-radius: 8px; overflow: auto; max-height: 200px;">${JSON.stringify(this.data.puzzle_data, null, 2)}</pre>`;
      }

      return `
        <div class="wizard-step active">
          <h3 style="margin-top: 0; margin-bottom: 24px; color: #374151;">Review Your Puzzle</h3>
          <div style="background: #f9fafb; padding: 24px; border-radius: 8px; margin-bottom: 24px;">
            <h4 style="margin-top: 0;">Basic Info</h4>
            <p><strong>Game Type:</strong> ${this.data.game_type ? this.data.game_type.charAt(0).toUpperCase() + this.data.game_type.slice(1) : 'Not set'}</p>
            <p><strong>Difficulty:</strong> ${this.data.difficulty}</p>
            <p><strong>Rating:</strong> ${'⭐'.repeat(this.data.rating)}</p>
          </div>
          <div style="background: #f9fafb; padding: 24px; border-radius: 8px; margin-bottom: 24px;">
            <h4 style="margin-top: 0;">Content</h4>
            ${contentPreview}
          </div>
          <div style="background: #f9fafb; padding: 24px; border-radius: 8px;">
            <h4 style="margin-top: 0;">Settings</h4>
            <p><strong>Published:</strong> ${this.data.is_published ? 'Yes' : 'No (Draft)'}</p>
            <p><strong>Challenge Date:</strong> ${this.data.challenge_date || 'None'}</p>
          </div>
        </div>
      `;
    },

    selectGameType: function(type) {
      this.data.game_type = type;
      // Re-render the step
      this.showStep(0);
    },

    addClue: function() {
      const clueText = document.getElementById('new-clue-text')?.value.trim();
      const clueAnswer = document.getElementById('new-clue-answer')?.value.trim().toUpperCase();

      if (!clueText || !clueAnswer) {
        alert('Please enter both clue and answer');
        return;
      }

      this.data.clues.push({ clue: clueText, answer: clueAnswer });
      
      // Clear inputs
      const clueInput = document.getElementById('new-clue-text');
      const answerInput = document.getElementById('new-clue-answer');
      if (clueInput) clueInput.value = '';
      if (answerInput) answerInput.value = '';

      // Re-render step
      this.showStep(2);
    },

    removeClue: function(index) {
      this.data.clues.splice(index, 1);
      this.showStep(2);
    },

    updatePuzzleData: function(jsonString) {
      try {
        this.data.puzzle_data = JSON.parse(jsonString);
      return true;
      } catch (e) {
        // Invalid JSON - will be validated on submit
        console.error('Invalid JSON:', e);
        return false;
      }
    },

    updateKonundrumData: function() {
      const clueEl = document.getElementById('konundrum-clue');
      const wordsEl = document.getElementById('konundrum-words');
      const seedInput = document.getElementById('konundrum-seed');
      
      // Get values with fallback to existing data
      const clue = clueEl?.value?.trim() || this.data.puzzle_data?.clue || '';
      const wordsText = wordsEl?.value?.trim() || '';
      
      // Parse words from line-separated (one word per line)
      let words = [];
      if (wordsText) {
        words = wordsText.split('\n').map(w => w.trim().toUpperCase()).filter(w => w);
      } else if (this.data.puzzle_data?.words) {
        // Fallback to existing words if field is empty
        words = this.data.puzzle_data.words;
      }
      
      // Generate or use existing seed (default to timestamp if not set)
      let seed = seedInput?.value?.trim() || this.data.puzzle_data?.seed || '';
      if (!seed && words.length > 0) {
        // Generate seed from current timestamp
        seed = `konundrum-${Date.now()}-${words.join('-')}`;
        if (seedInput) {
          seedInput.value = seed;
        }
      }
      
      // Generate letters from words - shuffle all together, then split by word sizes
      let letters = [];
      let letterGroups = []; // Store groups for display
      if (words.length > 0) {
        // Collect all letters from all words
        const allLetters = words.join('').split('').filter(l => l.match(/[A-Z]/));
        
        // Only shuffle if we have letters and seed
        if (allLetters.length > 0 && seed) {
          // Shuffle all letters together using seed
          letters = this.shuffleWithSeed(allLetters, seed);
          
          // Split shuffled letters into groups based on word sizes
          const wordSizes = words.map(word => word.length);
          let currentIndex = 0;
          letterGroups = wordSizes.map((size) => {
            const group = letters.slice(currentIndex, currentIndex + size);
            currentIndex += size;
            return group;
          });
        } else if (this.data.puzzle_data?.letters) {
          // Use existing letters if available
          letters = this.data.puzzle_data.letters;
          letterGroups = this.data.puzzle_data.letterGroups || [];
        }
      }
      
      // Build puzzle data - preserve existing data if fields are empty
      this.data.puzzle_data = {
        clue: clue || this.data.puzzle_data?.clue || '',
        words: words.length > 0 ? words : (this.data.puzzle_data?.words || []),
        letters: letters.length > 0 ? letters : (this.data.puzzle_data?.letters || []),
        seed: seed || this.data.puzzle_data?.seed || '',
        letterGroups: letterGroups.length > 0 ? letterGroups : (this.data.puzzle_data?.letterGroups || [])
      };
      
      // Re-render to show letters preview (but don't do full re-render, just update if step is already showing)
      // Only re-render if we're on the content step
      if (words.length > 0 && letters.length > 0 && this.currentStep === 2) {
        this.showStep(2);
      }
      
      return this.data.puzzle_data;
    },

    shuffleWithSeed: function(array, seed) {
      // Create a simple seeded random number generator
      let hash = 0;
      for (let i = 0; i < seed.length; i++) {
        const char = seed.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32bit integer
      }
      
      // Simple seeded shuffle (Fisher-Yates with seeded PRNG)
      const shuffled = [...array];
      let seedValue = Math.abs(hash);
      
      for (let i = shuffled.length - 1; i > 0; i--) {
        // Generate pseudo-random index using seed
        seedValue = (seedValue * 9301 + 49297) % 233280;
        const j = Math.floor((seedValue / 233280) * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
      }
      
      return shuffled;
    },

    splitLettersIntoGroups: function(lettersText, groupCount, seed) {
      if (!lettersText || groupCount <= 1) {
        return [lettersText];
      }
      
      // Create seeded RNG for deterministic splitting
      let hash = 0;
      for (let i = 0; i < seed.length; i++) {
        const char = seed.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash;
      }
      
      const totalLetters = lettersText.length;
      const letters = lettersText.split('');
      const groups = [];
      
      // Calculate group sizes (using seed for randomness)
      const sizes = [];
      let seedValue = Math.abs(hash);
      let remaining = totalLetters;
      
      // Distribute letters randomly (but deterministically based on seed)
      for (let i = 0; i < groupCount - 1; i++) {
        seedValue = (seedValue * 9301 + 49297) % 233280;
        // Use a percentage of remaining letters, but ensure at least 1 per group
        const minSize = 1;
        const maxSize = remaining - (groupCount - i - 1); // Ensure we can fill remaining groups
        const sizeRange = maxSize - minSize + 1;
        const groupSize = minSize + Math.floor((seedValue / 233280) * sizeRange);
        sizes.push(groupSize);
        remaining -= groupSize;
      }
      sizes.push(remaining); // Last group gets the rest
      
      // Split letters into groups
      let currentIndex = 0;
      for (let i = 0; i < sizes.length; i++) {
        groups.push(letters.slice(currentIndex, currentIndex + sizes[i]).join(''));
        currentIndex += sizes[i];
      }
      
      return groups;
    },


    generateKrissKrossLayout: function() {
      // Check if already generating
      if (this.data._generatingLayout) {
        return;
      }
      
      const wordsText = document.getElementById('krisskross-words')?.value.trim() || '';
      
      // Parse words from line-separated (one word per line)
      let words = [];
      if (wordsText) {
        words = wordsText.split('\n').map(w => w.trim().toUpperCase()).filter(w => w);
      }
      
      // Need at least 2 words to generate a layout
      if (words.length < 2) {
        alert('Please enter at least 2 words (one per line) to generate a layout');
        return;
      }
      
      // Update words in data immediately
      this.updateKrissKrossData();
      
      // Generate layout asynchronously
      this.generateLayoutFromWords(words);
    },
    
    generateLayoutFromWords: async function(words) {
      // Set generating flag
      this.data._generatingLayout = true;
      this.showStep(this.currentStep); // Re-render to show loading state
      
      try {
        // Convert words to format expected by API
        const wordsForAPI = words.map(word => ({
          clue: '',
          answer: word
        }));
        
        // Call backend API
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
        const response = await fetch('/crossword/generate_layout', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken,
            'Accept': 'application/json'
          },
          body: JSON.stringify({ words: wordsForAPI })
        });
        
        const result = await response.json();
        
        if (result.success && result.layout) {
          // Store layout in puzzle_data
          if (!this.data.puzzle_data) {
            this.data.puzzle_data = {};
          }
          this.data.puzzle_data.layout = result.layout;
          this.data._generatingLayout = false;
          
          // Re-render to show generated layout
          this.showStep(this.currentStep);
        } else {
          throw new Error(result.error || 'Failed to generate layout');
        }
      } catch (error) {
        console.error('Error generating layout:', error);
        this.data._generatingLayout = false;
        alert('Error generating layout: ' + error.message + '\nPlease try again with different words.');
        this.showStep(this.currentStep);
      }
    },
    
    updateKrissKrossData: function() {
      const clueEl = document.getElementById('krisskross-clue');
      const wordsEl = document.getElementById('krisskross-words');
      
      // Get values with fallback to existing data
      const clue = clueEl?.value?.trim() || this.data.puzzle_data?.clue || '';
      const wordsText = wordsEl?.value?.trim() || '';
      
      // Parse words from line-separated (one word per line)
      let words = [];
      if (wordsText) {
        words = wordsText.split('\n').map(w => w.trim().toUpperCase()).filter(w => w);
      } else if (this.data.puzzle_data?.words && this.data.puzzle_data.words.length > 0) {
        // Fallback to existing words if field is empty but data exists
        words = this.data.puzzle_data.words;
      }
      
      // Keep existing layout if present
      const existingLayout = this.data.puzzle_data?.layout || null;
      
      // Initialize puzzle_data if it doesn't exist
      if (!this.data.puzzle_data) {
        this.data.puzzle_data = {};
      }
      
      // Update clue and words, preserve layout
      this.data.puzzle_data.clue = clue;
      this.data.puzzle_data.words = words;
      if (existingLayout) {
        this.data.puzzle_data.layout = existingLayout;
      }
      
      // Return the puzzle data (matching Konundrum pattern)
      return this.data.puzzle_data;
    },

    validateStep: function(stepIndex) {
      switch(stepIndex) {
        case 0:
          if (!this.data.game_type) {
            alert('Please select a game type');
            return false;
          }
          break;
        case 1:
          // Title validation removed - no longer required
          break;
        case 2:
          if (this.data.game_type === 'krossword') {
            if (!this.data.clues || this.data.clues.length === 0) {
              alert('Please add at least one clue');
              return false;
            }
          } else if (this.data.game_type === 'konundrum') {
            // Update data from form first - force read from DOM
            const puzzleData = this.updateKonundrumData();
            
            // Check clue from form directly as well
            const clueEl = document.getElementById('konundrum-clue');
            const clue = clueEl?.value?.trim() || puzzleData?.clue || this.data.puzzle_data?.clue || '';
            
            if (!clue) {
              alert('Please enter a clue/theme');
              // Focus on the clue field
              if (clueEl) clueEl.focus();
              return false;
            }
            
            // Check words from multiple sources
            const wordsEl = document.getElementById('konundrum-words');
            const wordsText = wordsEl?.value?.trim() || '';
            let words = [];
            
            // Parse from form field
            if (wordsText) {
              words = wordsText.split('\n').map(w => w.trim().toUpperCase()).filter(w => w.length > 0);
            }
            
            // Fallback to stored puzzle data if form field is empty but data exists
            if (words.length === 0 && puzzleData?.words && puzzleData.words.length > 0) {
              words = puzzleData.words;
            }
            
            // Also check stored data as final fallback
            if (words.length === 0 && this.data.puzzle_data?.words && this.data.puzzle_data.words.length > 0) {
              words = this.data.puzzle_data.words;
            }
            
            if (words.length === 0) {
              alert('Please enter at least one word (one word per line)');
              if (wordsEl) {
                wordsEl.focus();
                wordsEl.select();
              }
              return false;
            }
            
            // Ensure letters are generated - regenerate if needed
            if (!puzzleData?.letters || puzzleData.letters.length === 0) {
              // Try to regenerate letters if we have words
              if (words.length > 0) {
                this.updateKonundrumData(); // Force regeneration
                const updatedData = this.data.puzzle_data;
                if (!updatedData?.letters || updatedData.letters.length === 0) {
                  alert('Please ensure letters are generated (enter words and they will auto-generate)');
                  return false;
                }
              } else {
                alert('Please ensure letters are generated (enter words and they will auto-generate)');
                return false;
              }
            }
          } else if (this.data.game_type === 'krisskross') {
            // Update data from form first (matching Konundrum pattern)
            const puzzleData = this.updateKrissKrossData();
            
            // Check clue from form directly as well (matching Konundrum pattern)
            const clueEl = document.getElementById('krisskross-clue');
            const clue = clueEl?.value?.trim() || puzzleData?.clue || this.data.puzzle_data?.clue || '';
            
            if (!clue) {
              alert('Please enter a clue/theme');
              // Focus on the clue field
              if (clueEl) {
                clueEl.focus();
                clueEl.select();
              }
              return false;
            }
            
            // Check words from multiple sources (matching Konundrum pattern)
            const wordsEl = document.getElementById('krisskross-words');
            const wordsText = wordsEl?.value?.trim() || '';
            let words = [];
            
            // Parse from form field
            if (wordsText) {
              words = wordsText.split('\n').map(w => w.trim().toUpperCase()).filter(w => w.length > 0);
            }
            
            // Fallback to stored puzzle data if form field is empty but data exists
            if (words.length === 0 && puzzleData?.words && puzzleData.words.length > 0) {
              words = puzzleData.words;
            }
            
            // Also check stored data as final fallback
            if (words.length === 0 && this.data.puzzle_data?.words && this.data.puzzle_data.words.length > 0) {
              words = this.data.puzzle_data.words;
            }
            
            if (words.length < 2) {
              alert('Please enter at least 2 words (one per line)');
              if (wordsEl) {
                wordsEl.focus();
                wordsEl.select();
              }
              return false;
            }
            
            // Check if layout is being generated
            if (this.data._generatingLayout) {
              alert('Please wait for the layout to finish generating');
              return false;
            }
            
            if (!this.data.puzzle_data?.layout) {
              alert('Layout is required. Please wait for the layout to generate after entering words, or try again with different words.');
              // Try to trigger layout generation
              this.generateKrissKrossLayout();
              return false;
            }
          } else {
            if (!this.data.puzzle_data) {
              alert('Please enter puzzle data');
              return false;
            }
          }
          break;
      }
      return true;
    },

    nextStep: function() {
      if (!this.validateStep(this.currentStep)) {
        return;
      }
      if (this.currentStep < this.steps.length - 1) {
        this.showStep(this.currentStep + 1);
      }
    },

    prevStep: function() {
      if (this.currentStep > 0) {
        this.showStep(this.currentStep - 1);
      }
    },

    submit: async function() {
      // Final validation
      if (!this.validateStep(0) || !this.validateStep(1) || !this.validateStep(2)) {
        this.showStep(0);
        return;
      }

      // Final update of puzzle data from forms
      if (this.data.game_type === 'konundrum') {
        this.updateKonundrumData();
      } else if (this.data.game_type === 'krisskross') {
        this.updateKrissKrossData();
      }
      
      // Prepare form data
      const formData = new FormData();
      formData.append('puzzle[game_type]', this.data.game_type);
      formData.append('puzzle[difficulty]', this.data.difficulty);
      formData.append('puzzle[rating]', this.data.rating);
      formData.append('puzzle[is_published]', this.data.is_published ? '1' : '0');
      if (this.data.challenge_date) {
        formData.append('puzzle[challenge_date]', this.data.challenge_date);
      }

      if (this.data.game_type === 'krossword') {
        formData.append('puzzle[description]', this.data.description || '');
        formData.append('puzzle[clues]', JSON.stringify(this.data.clues));
      } else {
        formData.append('puzzle[puzzle_data]', JSON.stringify(this.data.puzzle_data));
      }

      // Show loading state
      const submitBtn = document.getElementById('wizard-submit');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = 'Creating...';
      }

      // Submit to ActiveAdmin
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      fetch('/admin/puzzles', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'text/html'
        },
        body: formData
      })
      .then(response => {
        if (response.ok || response.redirected) {
          // Success - redirect to puzzles list
          window.location.href = '/admin/puzzles';
        } else {
          throw new Error('Failed to create puzzle');
        }
      })
      .catch(error => {
        alert('Error creating puzzle: ' + error.message);
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Create Puzzle';
        }
      });
    },

    close: function() {
      const modal = document.getElementById('puzzle-wizard-modal');
      if (modal) {
        modal.remove();
      }
    }
  };

  // Make wizard globally available
  window.PuzzleWizard = Wizard;

  // Auto-show wizard if we're on the new puzzle page and want to use wizard
  // This can be triggered by a button or URL parameter
  if (window.location.pathname === '/admin/puzzles/new') {
    // Check if we should show wizard (could be triggered by button click instead)
    // For now, we'll add a button to trigger it
  }
})();

