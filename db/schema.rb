# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170304202140) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "foos", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "caption"
    t.integer  "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float    "lng"
    t.float    "lat"
  end

  add_index "images", ["creator_id"], name: "index_images_on_creator_id", using: :btree
  add_index "images", ["lng", "lat"], name: "index_images_on_lng_and_lat", using: :btree

  create_table "roles", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "role_name",  null: false
    t.string   "mname"
    t.integer  "mid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "roles", ["mid"], name: "index_roles_on_mid", using: :btree
  add_index "roles", ["mname", "mid"], name: "index_roles_on_mname_and_mid", using: :btree
  add_index "roles", ["mname"], name: "index_roles_on_mname", using: :btree
  add_index "roles", ["user_id"], name: "index_roles_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thing_images", force: :cascade do |t|
    t.integer  "image_id",               null: false
    t.integer  "thing_id",               null: false
    t.integer  "priority",   default: 5, null: false
    t.integer  "creator_id",             null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "thing_images", ["image_id", "thing_id"], name: "index_thing_images_on_image_id_and_thing_id", unique: true, using: :btree
  add_index "thing_images", ["image_id"], name: "index_thing_images_on_image_id", using: :btree
  add_index "thing_images", ["thing_id"], name: "index_thing_images_on_thing_id", using: :btree

  create_table "thing_tags", force: :cascade do |t|
    t.integer  "thing_id"
    t.integer  "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "thing_tags", ["tag_id"], name: "index_thing_tags_on_tag_id", using: :btree
  add_index "thing_tags", ["thing_id"], name: "index_thing_tags_on_thing_id", using: :btree

  create_table "things", force: :cascade do |t|
    t.string   "name",        null: false
    t.text     "description"
    t.text     "notes"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "things", ["name"], name: "index_things_on_name", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "provider",               default: "email", null: false
    t.string   "uid",                    default: "",      null: false
    t.string   "encrypted_password",     default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "name"
    t.string   "nickname"
    t.string   "image"
    t.string   "email"
    t.json     "tokens"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree

  add_foreign_key "roles", "users"
  add_foreign_key "thing_images", "images"
  add_foreign_key "thing_images", "things"
  add_foreign_key "thing_tags", "tags"
  add_foreign_key "thing_tags", "things"
end
