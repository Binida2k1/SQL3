#!/bin/bash

echo -e "\n~~~~~ MY SALON ~~~~~\n"

# Định nghĩa biến truy vấn PostgreSQL
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# Hàm hiển thị menu chính
MAIN_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  echo -e "\nWelcome to My Salon, how can I help you?"

  # Hiển thị danh sách dịch vụ
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES" | while IFS=" |" read SERVICE_ID SERVICE_NAME; do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # Nhập lựa chọn
  read SERVICE_ID_SELECTED

  # Kiểm tra dịch vụ có tồn tại không
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  if [[ -z $SERVICE_NAME ]]; then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    BOOK_APPOINTMENT "$SERVICE_ID_SELECTED" "$SERVICE_NAME"
  fi
}

# Hàm đặt lịch hẹn
BOOK_APPOINTMENT() {
  SERVICE_ID_SELECTED=$1
  SERVICE_NAME=$(echo "$2" | sed -E 's/^ *| *$//g')

  # Nhập số điện thoại
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Kiểm tra khách hàng đã tồn tại chưa
  CUSTOMER_INFO=$($PSQL "SELECT customer_id, name FROM customers WHERE phone = '$CUSTOMER_PHONE';")

  if [[ -z $CUSTOMER_INFO ]]; then
    # Nếu chưa có, yêu cầu nhập tên
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # Thêm khách hàng mới
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")

    # Lấy lại thông tin khách hàng
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  else
    # Nếu đã có, lấy thông tin khách hàng
    CUSTOMER_ID=$(echo "$CUSTOMER_INFO" | awk '{print $1}')
    CUSTOMER_NAME=$(echo "$CUSTOMER_INFO" | awk '{$1=""; print $0}' | sed -E 's/^ *| *$//g')
  fi

  # Nhập thời gian hẹn
  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # Thêm cuộc hẹn vào bảng appointments
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

  # Xác nhận đặt lịch thành công
  if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]; then
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

# Gọi menu chính
MAIN_MENU
