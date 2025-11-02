class GameSession < ApplicationRecord
  belongs_to :user
  belongs_to :puzzle

  # Validations
  validates :status, presence: true, inclusion: { in: %w[active completed abandoned] }
  validate :game_state_is_hash
  validate :unique_active_session_per_user_puzzle

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :abandoned, -> { where(status: 'abandoned') }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_puzzle, ->(puzzle) { where(puzzle: puzzle) }

  # For Active Admin filtering
  def self.ransackable_attributes(auth_object = nil)
    ["id", "status", "started_at", "completed_at", "created_at", "updated_at", "user_id", "puzzle_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "puzzle"]
  end

  # Default values
  before_validation :set_defaults, on: :create

  # Instance methods
  def complete!
    update(status: 'completed', completed_at: Time.current)
  end

  def abandon!
    update(status: 'abandoned')
  end

  def active?
    status == 'active'
  end

  def completed?
    status == 'completed'
  end

  def abandoned?
    status == 'abandoned'
  end

  # Update game state
  def update_game_state(new_state)
    update(game_state: game_state.deep_merge(new_state))
  end

  # Get game state with defaults
  def game_state
    super || {}
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.started_at ||= Time.current
    # Ensure game_state is always a hash, even if empty
    if game_state.nil?
      self.game_state = {}
    elsif !game_state.is_a?(Hash)
      self.game_state = {}
    end
  end

  def game_state_is_hash
    # Ensure game_state is always a hash (can be empty)
    # This runs during validation, so we can set it here if needed
    if game_state.nil?
      self.game_state = {}
    elsif !game_state.is_a?(Hash)
      errors.add(:game_state, 'must be a hash')
      self.game_state = {} # Fix it anyway
    end
  end

  def unique_active_session_per_user_puzzle
    # This validation ensures database-level uniqueness
    # But we also check for active sessions at the application level
    if active? && user && puzzle
      existing = GameSession.where(user: user, puzzle: puzzle, status: 'active')
                            .where.not(id: id)
      if existing.exists?
        errors.add(:base, 'An active session already exists for this user and puzzle')
      end
    end
  end
end

