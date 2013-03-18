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

ActiveRecord::Schema.define(:version => 20130318180703) do

  create_table "comparisons", :force => true do |t|
    t.integer  "chosen_location_id"
    t.integer  "rejected_location_id"
    t.string   "remote_ip"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "locations", :force => true do |t|
    t.integer  "region_id"
    t.float    "lattitude"
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
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "regions", :force => true do |t|
    t.integer  "user_id"
    t.string   "slug"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "studies", :force => true do |t|
    t.string   "user_id"
    t.string   "integer"
    t.string   "slug"
    t.string   "question"
    t.boolean  "public"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "region_set_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
