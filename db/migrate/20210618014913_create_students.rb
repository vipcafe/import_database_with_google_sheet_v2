class CreateStudents < ActiveRecord::Migration[6.1]
  def change
    create_table :students do |t|
      t.string :student_code
      t.string :full_name
      t.string :email
      t.string :address
      t.date :date_of_birth
      t.string :phone_number

      t.timestamps
    end
  end
end
