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

ActiveRecord::Schema[8.1].define(version: 2026_04_10_180000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "impersonation_events", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.string "ip_address"
    t.datetime "started_at", null: false
    t.bigint "target_user_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_user_id"], name: "index_impersonation_events_on_admin_user_id"
    t.index ["target_user_id"], name: "index_impersonation_events_on_target_user_id"
  end

  create_table "investments", force: :cascade do |t|
    t.string "accreditation_status"
    t.string "bank_account_number"
    t.string "bank_name"
    t.string "bank_routing_number"
    t.string "bitcoin_address"
    t.string "cash_flow_import_id"
    t.string "cash_flow_status"
    t.string "company_or_nickname"
    t.datetime "created_at", null: false
    t.string "distribution_method"
    t.decimal "funded_amount", precision: 12, scale: 2
    t.decimal "invested_amount", precision: 12, scale: 2, default: "50000.0", null: false
    t.string "investment_entity_type"
    t.date "investor_since", default: -> { "CURRENT_DATE" }, null: false
    t.string "legacy_offering_name"
    t.text "notes"
    t.bigint "project_id", null: false
    t.string "share_class"
    t.string "tax_identifier"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cash_flow_import_id"], name: "index_investments_on_cash_flow_import_id_unique", unique: true, where: "(cash_flow_import_id IS NOT NULL)"
    t.index ["project_id"], name: "index_investments_on_project_id"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.bigint "project_id", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_sites_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.string "state"
    t.text "street_address"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "impersonation_events", "users", column: "admin_user_id"
  add_foreign_key "impersonation_events", "users", column: "target_user_id"
  add_foreign_key "investments", "projects"
  add_foreign_key "investments", "users"
  add_foreign_key "sites", "projects"
end
