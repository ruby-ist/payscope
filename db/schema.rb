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

ActiveRecord::Schema[8.1].define(version: 2026_09_20_072736) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "employees", force: :cascade do |t|
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "department", null: false
    t.string "employee_code", null: false
    t.bigint "exchange_rate_id", null: false
    t.string "full_name", null: false
    t.string "job_title", null: false
    t.decimal "local_salary", precision: 12, scale: 2, null: false
    t.decimal "normalized_usd_salary", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_employees_on_country"
    t.index ["department", "job_title"], name: "index_employees_on_department_and_job_title"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["exchange_rate_id"], name: "index_employees_on_exchange_rate_id"
    t.index ["job_title", "exchange_rate_id"], name: "index_employees_on_job_title_and_exchange_rate_id"
    t.index ["job_title"], name: "index_employees_on_job_title"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.decimal "rate", precision: 12, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_exchange_rates_on_currency", unique: true
  end

  add_foreign_key "employees", "exchange_rates"
end
