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

ActiveRecord::Schema.define(version: 20181217233842) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "classrooms", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "creator_id"
    t.integer  "interviews_per_slot", default: 6, null: false
    t.index ["creator_id"], name: "index_classrooms_on_creator_id", using: :btree
  end

  create_table "companies", force: :cascade do |t|
    t.string   "name"
    t.integer  "slots"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "classroom_id"
    t.index ["classroom_id"], name: "index_companies_on_classroom_id", using: :btree
  end

  create_table "interview_feedbacks", force: :cascade do |t|
    t.string   "interviewer_name",      null: false
    t.integer  "interview_result",      null: false
    t.text     "result_explanation",    null: false
    t.text     "feedback_technical"
    t.text     "feedback_nontechnical"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "interview_id"
    t.index ["interview_id"], name: "index_interview_feedbacks_on_interview_id", using: :btree
  end

  create_table "interviews", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "company_id"
    t.datetime "scheduled_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["company_id"], name: "index_interviews_on_company_id", using: :btree
    t.index ["student_id", "company_id"], name: "index_interviews_on_student_id_and_company_id", unique: true, using: :btree
    t.index ["student_id"], name: "index_interviews_on_student_id", using: :btree
  end

  create_table "pairings", force: :cascade do |t|
    t.integer  "placement_id"
    t.integer  "student_id"
    t.integer  "company_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["company_id"], name: "index_pairings_on_company_id", using: :btree
    t.index ["placement_id"], name: "index_pairings_on_placement_id", using: :btree
    t.index ["student_id"], name: "index_pairings_on_student_id", using: :btree
  end

  create_table "placements", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "classroom_id"
    t.string   "name"
    t.integer  "owner_id"
    t.text     "whiteboard"
    t.index ["classroom_id"], name: "index_placements_on_classroom_id", using: :btree
    t.index ["owner_id"], name: "index_placements_on_owner_id", using: :btree
  end

  create_table "rankings", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "company_id"
    t.integer  "student_preference"
    t.integer  "interview_result"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["company_id"], name: "index_rankings_on_company_id", using: :btree
    t.index ["student_id"], name: "index_rankings_on_student_id", using: :btree
  end

  create_table "students", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "classroom_id"
    t.index ["classroom_id"], name: "index_students_on_classroom_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "oauth_provider"
    t.string   "oauth_uid"
    t.string   "name"
    t.string   "email"
    t.string   "oauth_token"
    t.datetime "token_expires_at"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "refresh_token"
  end

  add_foreign_key "classrooms", "users", column: "creator_id"
  add_foreign_key "companies", "classrooms"
  add_foreign_key "interview_feedbacks", "interviews"
  add_foreign_key "interviews", "companies"
  add_foreign_key "interviews", "students"
  add_foreign_key "placements", "classrooms"
  add_foreign_key "placements", "users", column: "owner_id"
  add_foreign_key "students", "classrooms"
end
