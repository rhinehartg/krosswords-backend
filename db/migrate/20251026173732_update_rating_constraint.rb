class UpdateRatingConstraint < ActiveRecord::Migration[8.1]
  def change
    # Remove the old constraint
    remove_check_constraint :ratings, name: "rating_range_check"
    
    # Add the new constraint for 1-3 range
    add_check_constraint :ratings, "rating >= 1 AND rating <= 3", name: "rating_range_check"
  end
end
