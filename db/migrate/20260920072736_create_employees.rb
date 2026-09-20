class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :full_name, null: false
      t.string :job_title, null: false
      t.string :department, null: false
      t.string :country, null: false
      t.decimal :local_salary, precision: 12, scale: 2, null: false
      t.references :exchange_rate, null: false, foreign_key: true
      t.decimal :normalized_usd_salary, precision: 12, scale: 2

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    add_index :employees, :job_title
    add_index :employees, :department
    add_index :employees, :country
    add_index :employees, %i[department job_title]
    add_index :employees, %i[job_title exchange_rate_id]
  end
end
