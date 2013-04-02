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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130402191810) do

  create_table "comparisons", :force => true do |t|
    t.integer  "chosen_location_id"
    t.integer  "rejected_location_id"
    t.string   "remote_ip"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "study_id"
  end

  create_table "locations", :force => true do |t|
    t.integer  "region_id"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "heading"
    t.integer  "pitch"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "region_set_memberships", :force => true do |t|
    t.integer  "region_set_id"
    t.integer  "region_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "region_sets", :force => true do |t|
    t.integer  "user_id"
    t.string   "slug"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "description"
  end

  create_table "regions", :force => true do |t|
    t.integer  "user_id"
    t.string   "slug"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "polygon"
    t.text     "description"
    t.integer  "zoom"
    t.string   "latitude"
    t.string   "longitude"
  end

  add_index "regions", ["slug"], :name => "index_regions_on_slug", :unique => true

  create_table "studies", :force => true do |t|
    t.string   "slug"
    t.string   "question"
    t.boolean  "public"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "region_set_id"
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
  end

  add_index "studies", ["slug"], :name => "index_studies_on_slug", :unique => true

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "provider"
    t.string   "uid"
    t.string   "username"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
