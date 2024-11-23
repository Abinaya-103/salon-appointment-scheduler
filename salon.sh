#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {
  # Display an error message if there is one
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Get the list of available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # Check if there are any available services
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    echo "Sorry, we don't have any services available right now."
  else
    # Display the list of available services
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      echo "($SERVICE_ID) $NAME"
    done

    # Prompt user to enter a service ID
    echo -e "\nPlease enter the service ID you want:"
    read SERVICE_ID_SELECTED

    # Validate that the input is a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      MAIN_MENU "That is not a number. Please select a valid service."
    else
      # Check if the service ID exists
      SERVICE_AVAILABLE=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

      if [[ -z $SERVICE_AVAILABLE ]]
      then
        MAIN_MENU "I could not find that service. What would you like today?"
      else
        # Prompt for customer's phone number
        echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE

        # Check if the customer exists in the database
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

        if [[ -z $CUSTOMER_NAME ]]
        then
          # If the customer is not in the database, prompt for their name and add them
          echo -e "\nI don't have a record for that phone number, what's your name?"
          read CUSTOMER_NAME
          INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
        fi

        # Prompt for the appointment time
        echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
        read SERVICE_TIME

        # Get the customer_id from the database
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

        # Insert the appointment into the database
        if [[ $SERVICE_TIME ]]
        then
          INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

          if [[ $INSERT_APPOINTMENT_RESULT ]]
          then
            echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
          fi
        fi
      fi
    fi
  fi
}

# Start the script
MAIN_MENU
