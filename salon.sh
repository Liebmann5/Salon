#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"
#https://www.postgresql.org/docs/current/app-psql.html
#--tuples-only: Turn off printing of column names and result row count footers, etc. This is equivalent to \t or \pset tuples_only.
#ERASED
#service_id) |      name
#------------+-----------------) 
#     &&
#(4) rows)


echo -e "\n~~~~~ SALON ~~~~~\n"

MAIN_MENU()
{
  #This prints a string in case I call the MAIN_MENU with a string
  #if [[ $1 ]]
  #then
  #  echo -e "\n$1"
  #fi
  
  echo "Hi, what service can I help you get done today?"
  SERVICES
    
}

SERVICES()
{
  AVAILABLE_SERVICES=$($PSQL "SELECT * FROM services")

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "$AVAILABLE_SERVICES" | while read SERVICE_NUM BAR SERVICE_TYPE
  do
    echo "$SERVICE_NUM) $SERVICE_TYPE"
  done
  read SERVICE_ID_SELECTED

  if [[ ! $SERVICE_ID_SELECTED =~ ^[1-4]$ ]]
  then
    SERVICES "That's not a service you sick animal. PLEASE pick a service we offer!"
  else
    AVAILABILITY $SERVICE_ID_SELECTED
  fi
}

AVAILABILITY()
{
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #https://bash.cyberciti.biz/guide/Pass_arguments_into_a_function
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SERVICE_ID_SELECTED=$1
  echo $SERVICE_ID_SELECTED

  #1)echo
  #2)read the users choice
  #3)if [[ ]] check if user's input is correct
  #4)make variable that query's database to print the services available times
  #5)pipe that'll print ^ which lists available times "for the CHOSEN service" only

  #UNAVAILABLE_TIMES=$($PSQL "SELECT name, time FROM appointments FULL JOIN services ON appointments.service_id = services.service_id")
  UNAVAILABLE_TIMES=$($PSQL "SELECT time FROM appointments")
  CHOSEN_SERVICE=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  #Q: Why in the world is this happening? And why is this ok????????
  echo -e "\nThe unavailable times for a$CHOSEN_SERVICE are:"
  echo "$UNAVAILABLE_TIMES" | while read SERVICE_NAME NAME_TWO BAR OCCUPIED_TIME
  do
    echo "You can't have $OCCUPIED_TIME"
  done
  echo $OCCUPIED_TIME
  echo "What time would you like?"
  read SERVICE_TIME
  
  if [[ -z $SERVICE_TIME ]]
  then
    echo "You didn't enter anything doofus! What a fool"
    AVAILABILITY
  else
    #EXPLANATION: WHY TO USE [[ ]] !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #https://stackoverflow.com/questions/13617843/unary-operator-expected-error-in-bash-if-condition
    while [[ $SERVICE_TIME == $OCCUPIED_TIME ]]
    do
      echo "You absolute animal! That time is taken! Let's try this again."
      AVAILABILITY
    done

    CUSTOMER $SERVICE_ID_SELECTED $SERVICE_TIME $CHOSEN_SERVICE
  fi
}

CUSTOMER()
{
  SERVICE_ID_SELECTED=$1
  SERVICE_TIME=$2
  CHOSEN_SERVICE=$3

  echo -e "\nCan I get a phone number for the appointment?"
  read CUSTOMER_PHONE
  #!!!HOW TO CHECK FOR ERRORS WITHOUT HAVING THE CODE CALL THE METHOD AGAIN!!!! {KEEPS CODE STILL}
  #pat="^[0-9]{8}$"
  #while [[ ! $CUSTOMER_PHONE =~ $pat ]]
  #  do
  #  echo "Please enter a phone number as XXXXXXXX: "
  #  read CUSTOMER_PHONE
  #done

  #https://askubuntu.com/questions/697345/script-to-format-phone-numbers
  phonedash=$CUSTOMER_PHONE
  phonenodash="${phonedash//-}"
  phoney=$phonenodash
  echo $phoney
  CUSTOMER_PHONE=$phoney

  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_ID ]]
  then
    echo "There's no record of this phone number can I get a name please?"
    read CUSTOMER_NAME

    if [[ -z $CUSTOMER_NAME ]]
    then
      echo "Way to go Karen! Let's try this again."
      CUSTOMER $SERVICE_ID_SELECTED $SERVICE_TIME
    else
      INSERT_NEW_CUSTOMER=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    fi
    
  fi
  CUSTOMER=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  echo -e "How sexy!\n"
  echo -e "I have put you down for a $CHOSEN_SERVICE at $SERVICE_TIME,$CUSTOMER."
}

MAIN_MENU
