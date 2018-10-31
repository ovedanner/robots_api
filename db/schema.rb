# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_30_160716) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at", null: false
    t.index ["token"], name: "index_access_tokens_on_token"
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "room_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "room_id", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "owner_id", null: false
    t.json "board"
    t.boolean "open", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "firstname", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

end
