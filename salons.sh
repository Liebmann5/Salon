#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~ Salon Appointment Scheduler ~~\n"

MAIN_MENU() {
if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo -e "\nWelcome to the Salon. Here are our services:"

  LIST_OF_SERVICES=$($PSQL "SELECT * FROM services")
  echo "$LIST_OF_SERVICES" | while read SERVICE_ID BAR NAME
  do
    if [[ $SERVICE_ID =~ ^[0-9]+$ ]]
    then
      echo "$SERVICE_ID) $NAME"
    fi
  done
  
  #ask for service
  echo -e "\nWhich service would you like to schedule?"
  read SERVICE_ID_SELECTED

  #if input is not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    #send to main menu
    MAIN_MENU "That is not a valid service."
  else
    #check if input exists
    SERVICE_EXISTS=$($PSQL "select service_id from services where service_id=$SERVICE_ID_SELECTED")

    #if it does not exist
    if [[ -z $SERVICE_EXISTS ]]
    then
      #send to main menu
      MAIN_MENU "That service does not exist."
    else
      #get customer info
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      #You want to RETURN something from the query that either HAS a value or does NOT 
      #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      CUSTOMER_NAME=$($PSQL "SELECT name from customers where phone = '$CUSTOMER_PHONE'")

      #if customer doesn't exist
      if [[ -z $CUSTOMER_NAME ]]
      then
        #get new customer name
        echo -e "\nWhat's your name?"
        read CUSTOMER_NAME

        #insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      fi

      #get service time
      echo -e "\nWhat time would you like to schedule this service for?"
      read SERVICE_TIME

      #get customer_id
      CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$CUSTOMER_PHONE'")

      #insert appointment
      INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID,$SERVICE_ID_SELECTED,'$SERVICE_TIME')")

      #get appointment info
      SERVICE_NAME=$($PSQL "SELECT services.name from appointments INNER JOIN services USING(service_id) where customer_id=$CUSTOMER_ID AND service_id=$SERVICE_ID_SELECTED and time='$SERVICE_TIME'")
      SERVICE_TIME=$($PSQL "SELECT time from appointments where customer_id=$CUSTOMER_ID AND service_id=$SERVICE_ID_SELECTED and time='$SERVICE_TIME'")
      echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $(echo $SERVICE_TIME| sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
      EXIT  
    fi
  fi
}



EXIT() {
  echo -e "\nThank you for stopping in."
}

MAIN_MENU
