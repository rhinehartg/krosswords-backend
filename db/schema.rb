# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_26_173732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "puzzles", force: :cascade do |t|
    t.date "challenge_date"
    t.json "clues", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "difficulty", limit: 10, null: false
    t.boolean "is_featured", default: false, null: false
    t.boolean "is_published", default: false, null: false
    t.integer "rating", limit: 2, null: false
    t.string "title", limit: 255, null: false
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["challenge_date"], name: "index_puzzles_on_challenge_date", unique: true, where: "(challenge_date IS NOT NULL)"
    t.index ["difficulty"], name: "index_puzzles_on_difficulty"
    t.index ["is_featured"], name: "index_puzzles_on_is_featured"
    t.index ["is_published"], name: "index_puzzles_on_is_published"
    t.index ["rating"], name: "index_puzzles_on_rating"
    t.index ["type"], name: "index_puzzles_on_type"
  end

  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "puzzle_id", null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["puzzle_id"], name: "index_ratings_on_puzzle_id"
    t.index ["rating"], name: "index_ratings_on_rating"
    t.index ["user_id", "puzzle_id"], name: "index_ratings_on_user_id_and_puzzle_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 3", name: "rating_range_check"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ratings", "puzzles"
  add_foreign_key "ratings", "users"
end
