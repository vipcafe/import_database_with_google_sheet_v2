class Api::V1::StudentsController < ApplicationController
  def create
    red = GoogleDrive::Worksheet::Colors::RED
    green = GoogleDrive::Worksheet::Colors::GREEN
    orange = GoogleDrive::Worksheet::Colors::ORANGE
    #connect to google sheets
    config_sheet = AddDataGoogleSheetToDatabase.new.worksheet(params[:sheet_id])

    #check if it can connect to google sheet link if not output 404 message
    if config_sheet.nil?
      return render json: {
                      error: 404,
                      messenge: "please add email : googlesheetapi@connecticapi.iam.gserviceaccount.com  -> add share of the google sheet",
                    }
    end

    #get all data of google_sheet with a command return a array with .rows
    get_sheet = config_sheet.rows
    count_rows = get_sheet.count

    #check blank lines in google sheet and notification error for user
    check_blank = check_blank_data(count_rows, get_sheet)
    if check_blank && check_blank != ""
      return render json: {
                      error: check_blank,
                    }
    end

    count_create = 0
    count_update = 0
    count_already_exist = 0

    #improt data google sheet --> database
    get_sheet.each_with_index do |data, i|
      next if i == 0

      if Student.find_by_student_code(data[1]).nil?
        create_student(data)
        config_sheet[i + 1, 8] = "Create"
        background_color_create(config_sheet, i + 1, 8, red)
        count_create = count_create + 1
      else
        student_update = Student.find_by_student_code(data[1])
        # Date format used for comparison
        date_new = prefix_date(data[5])
        date_old = student_update.date_of_birth.strftime("%d/%m/%Y")

        #check and comparison data . 3 cases : Already exist , update , create
        if student_update.full_name === data[2] && student_update.email === data[3] && student_update.address === data[4] && date_new === date_old && student_update.phone_number === data[6]
          config_sheet[i + 1, 8] = "Already exist"
          background_color_create(config_sheet, i + 1, 8, orange)
          count_already_exist = count_already_exist + 1
        else
          update_student(student_update, data)
          config_sheet[i + 1, 8] = "Update"
          background_color_create(config_sheet, i + 1, 8, green)
          count_update = count_update + 1
        end
      end
    end

    resul_create(config_sheet, count_create, count_update, count_already_exist)
    config_sheet.save

    config_sheet.reload
    return render json: {
                    messenge: "Add data google sheet to database suuccess",
                  }
    render json: {
             status: 404,
             error: "Not found",
           }
  end

  #edit background color of column in google sheet
  def background_color_create(worksheet, row, column, color_add)
    worksheet.set_background_color(row, column, 1, 1, color_add)
    worksheet.set_text_format(
      row, column, 1, 1,
      bold: true,
      italic: true,
      foreground_color: GoogleDrive::Worksheet::Colors::WHITE,
    )
  end

  #funcion check blank line in google sheet
  def check_blank_data(count_rows, get_sheet)
    check_blank = ""
    count_col_blank = 0

    get_sheet.each_with_index do |data, i|
      check = data.first(7).detect { |x| x === "" }
      if check === ""
        check_blank = check_blank + "line #{i + 1} not blank |  "
        count_col_blank = count_col_blank + 1
      else
        count_col_blank = 0
      end

      if count_col_blank === 2
        check_blank = check_blank + ".... | please check bug in line  #{count_rows}"
        return check_blank
        break
      end
    end
    return check_blank
  end

  def create_student(data)
    student_new = Student.new student_code: data[1],
                              full_name: data[2],
                              email: data[3],
                              address: data[4],
                              date_of_birth: data[5],
                              phone_number: data[6]

    student_new.save
  end

  def update_student(student_update, data)
    student_update.update(full_name: data[2],
                          email: data[3],
                          address: data[4],
                          date_of_birth: data[5],
                          phone_number: data[6])
  end

  #Date format
  def prefix_date(date)
    prefix = DateTime.strptime(date, "%d/%m/%Y").strftime("%d/%m/%Y")

    if prefix
      return prefix
    else
      return DateTime.strptime(date, "%d-%m-%Y").strftime("%d/%m/%Y")
    end
  end

  # Notification and prind resul
  def resul_create(config_sheet, create, update, already_exist)
    config_sheet[4, 10] = "Create"
    config_sheet[5, 10] = create
    background_color_create(config_sheet, 4, 10, GoogleDrive::Worksheet::Colors::RED)

    config_sheet[6, 10] = "Update"
    config_sheet[7, 10] = update
    background_color_create(config_sheet, 6, 10, GoogleDrive::Worksheet::Colors::GREEN)

    config_sheet[8, 10] = "Already exist"
    config_sheet[9, 10] = already_exist
    background_color_create(config_sheet, 8, 10, GoogleDrive::Worksheet::Colors::ORANGE)
  end
end
