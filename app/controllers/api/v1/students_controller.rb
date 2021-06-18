class Api::V1::StudentsController < ApplicationController
  def add_data_to_database
    #gọi class để config tới google_sheet
    get_sheet = AddDataGoogleSheetToDatabase.new.worksheet(params[:sheet_id])

    config_sheet = get_sheet

    red = GoogleDrive::Worksheet::Colors::RED
    green = GoogleDrive::Worksheet::Colors::GREEN
    orange = GoogleDrive::Worksheet::Colors::ORANGE

    #kiểm tra có kết nối đc đến link google sheet hay không nếu không đc báo 403
    if get_sheet.nil?
      return render json: {
                      error: 403,
                      messenge: "please add email : googlesheetapi@connecticapi.iam.gserviceaccount.com  -> add share of the google sheet",
                    }
    end

    #get toàn bộ data của google_sheet và trả về 1 mảng với lệnh .rows
    get_sheet = get_sheet.rows
    count_rows = get_sheet.count

    #check các dòng rỗng không đúng kiểu data
    check_blank = check_blank_data(count_rows, get_sheet)
    if check_blank && check_blank != ""
      return render json: {
                      error: check_blank,
                    }
    end

    student_data = Student.all

    #sữ dụng vòng lặp để truyền data vào database
    count_rows.times do |i|
      puts i
      if i == 0
        next
      end
      if student_data.find_by_student_code(get_sheet[i][1]).nil?
        #tách từng phần tử của mảng truyền vào database
        student_data = Student.new student_code: get_sheet[i][1],
                                   full_name: get_sheet[i][2],
                                   email: get_sheet[i][3],
                                   address: get_sheet[i][4],
                                   date_of_birth: get_sheet[i][5],
                                   phone_number: get_sheet[i][6]
        student_data.save
        config_sheet[i + 1, 8] = "Create"
        background_color_create(config_sheet, i + 1, red)
        config_sheet.save
      else
        student_update = student_data.find_by_student_code(get_sheet[i][1])
        date_new = prefix_date(get_sheet[i][5])
        date_old = student_update.date_of_birth.strftime("%d/%m/%Y")

        if student_update.full_name === get_sheet[i][2] && student_update.email === get_sheet[i][3] && student_update.address === get_sheet[i][4] && date_new === date_old && student_update.phone_number === get_sheet[i][6]
          background_color_create(config_sheet, i + 1, red)
          config_sheet[i + 1, 8] = "Duplicate"
          background_color_create(config_sheet, i + 1, orange)
          config_sheet.save
        else
          student_update.update(full_name: get_sheet[i][2], email: get_sheet[i][3], address: get_sheet[i][4], date_of_birth: get_sheet[i][5], phone_number: get_sheet[i][6])
          config_sheet[i + 1, 8] = "Update"
          background_color_create(config_sheet, i + 1, green)
          config_sheet.save
        end
      end
    end

    config_sheet.reload
    return render json: {
                    messenge: "Add data google sheet to database suuccess",
                  }
    render json: {
             status: 404,
             error: "Not found",
           }
  end

  #chỉnh sữa màu sắc ô status
  def background_color_create(worksheet, col, color_add)
    worksheet.set_background_color(col, 8, 1, 1, color_add)
    worksheet.set_text_format(
      col, 8, 1, 1,
      bold: true,
      italic: true,
      foreground_color: GoogleDrive::Worksheet::Colors::WHITE,
    )
  end

  #check cột rỗng và đưa ra lỗi
  def check_blank_data(count_rows, get_sheet)
    check_blank = ""
    count_col_blank = 0

    count_rows.times do |i|
      7.times do |j|
        if j == 0
          next
        end
        puts get_sheet[i][j]
        if get_sheet[i][j].blank?
          check_blank = check_blank + "line #{i + 1} not blank |  "
          count_col_blank = count_col_blank + 1
          break
        else
          count_col_blank = 0
        end
      end

      if count_col_blank === 2
        check_blank = check_blank + ".... | please check bug in line  #{count_rows}"
        break
      end
    end
    return check_blank
  end

  def prefix_date(date)
    prefix = DateTime.strptime(date, "%d/%m/%Y").strftime("%d/%m/%Y")

    if prefix
      return prefix
    else
      return DateTime.strptime(date, "%d-%m-%Y").strftime("%d/%m/%Y")
    end
  end
end
