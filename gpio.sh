#!/bin/bash
source ./common_func.sh

#===============================================================
#Set/Get Port
#===============================================================
set_get_port(){
  for (( i = 0; i < 16; i++ )); do
#    launch_command "sudo ./idll-test"$executable" --GPIO_PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port"
    print_command "sudo ./idll-test"$executable" --GPIO_PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port"
    result00=$(sudo ./idll-test"$executable" --GPIO_PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port)
    result=$(sudo ./idll-test"$executable" --GPIO_PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port | grep -i "adiGpioGetPort" |  sed 's/\\n//g')
    echo "$result00"

    j=$( echo "obase=16;$i"|bc )
    if [ "$i" -gt 0 ]; then
      if [[ "$result" =~ "adiGpioGetPort(0x$j$j)" ]]; then
        printcolor g "Test result is Pass"
        printcolor g "Test result includes adiGpioGetPort(0x$j$j)"
        echo ""

      else

        printcolor r "Test result is Failed"
        printcolor g "Test result doesn't include adiGpioGetPort(0x$j$j)"
        read -p ""
      fi

    else

      if [[ "$result" =~ "adiGpioGetPort(0x$j)" ]]; then
        printcolor g "Test result is Pass"
        printcolor g "Test result doesn't include adiGpioGetPort(0x$j)"
        echo ""

      else

        printcolor r "Test result is Failed"
        printcolor g "Test result doesn't include adiGpioGetPort(0x$j)"
        read -p ""
        echo ""
      fi

    fi

  done

  ################################################################################
  title b "Now will loop 1000 times to check if the set/get port are the same"
  read -p "input [q] to skip or enter to test..." input

  if [ "$input" != "q" ]; then
    for (( i = 0; i < 1000; i++ )); do
      random=$(shuf -i 0-15 -n 1)
      j_random=$( echo "obase=16;$random"|bc )
      launch_command "sudo ./idll-test"$executable" --GPIO_PORT_VAL $random -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port"

      if [ "$random" -gt 0 ]; then
        compare_result "$result" "(0x$j_random$j_random)"
      else
        compare_result "$result" "(0x$j_random)"
      fi

    done
  fi


}

test(){
  launch_command "sudo ./idll-test"$executable" --GPIO_PIN_ID 0x0 --GPIO_PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Pin"
  echo "$result" > templog.txt
  readarray readdata < "templog.txt"

  before=$(echo "${readdata[5]}")
  before=${before#*: 0x}
  before=$(echo $before | sed 's/\s//g')
  before=$(echo "ibase=16;obase=2;$before"|bc)
  before=$(printf %08d $before)

  after=$(echo "${readdata[9]}")
  after=${after#*: 0x}
  after=$(echo $after | sed 's/\s//g')
  after=$(echo "ibase=16;obase=2;$after"|bc)
  after=$(printf %08d $after)
  m=1
  for (( i = 0; i < 8; i++ )); do
    if [[ "$m" -eq $i || "$((m+4))" -eq $i ]]; then
      echo "$m"
      echo "$i"
      echo "skip test"
    else
      if [[ "${before[$i]}" -eq "${after[$i]}"  ]]; then
        echo "$i"
        echo 'compare pass'
      else
        echo "$i"
        echo 'compare fail'
      fi
    fi

  done


#  for i in ${readdata[*]}; do
#    echo "----------------"
#    echo $i
#  done


}


set_get_pin(){

  for (( i = 0; i < 4; i++ )); do
    for state in "true" "false"; do
      launch_command "sudo ./idll-test$executable --GPIO_PIN_ID 0x$i --GPIO_PIN_VAL $state -- --EBOARD_TYPE EBOARD_ADi_$board --section SA3X_4xGPIO_by_Pin"

      echo "$result" > templog.txt
      readarray readdata < "templog.txt"
      #get the before changing gpio action result
      before=$(echo "${readdata[5]}")
      before=${before#*: 0x}
      before=$(echo "$before" | sed 's/\s//g')
      before=${before^^}
      before=$(echo "ibase=16;obase=2;$before"|bc)
      #add more 8 digit, when the result length is not enough
      before=$(printf %08d "$before")


      #get the after changing gpio action result
      after=$(echo "${readdata[9]}")
      after=${after#*: 0x}
      after=$(echo "$after" | sed 's/\s//g')
      after=${after^^}
      after=$(echo "ibase=16;obase=2;$after"|bc)
      #add more 8 digit, when the result length is not enough
      after=$(printf %08d "$after")

      compare_result "${readdata[8]}" "Read back pin value: $state"
      title b "Compare both the setting GPO bit=$i and received GPI bit=$((4+i)) pin status"
      title b "Read back Get Port=$after"
      compare_result "${after:$((7-i)):1}" "${after:$((7-4-i)):1}"

      #start to compare each byte value between after/before except the setting pin
      for (( l = 0; l < 8; l++ )); do
        echo "positon=$l"
        #skip the $i setting pin result compareation
        if [[ "$i" -eq $l || "$((i+4))" -eq $l ]]; then
          echo "skip test"

        #compare the rest of the gpio pins if they are the same
        else
          #use 7-l meaning the string starting from position is opposite from what we need
          if [[ "${before:$((7-l)):1}" -eq "${after:$((7-l)):1}" ]]; then

            re=(
            "the before value=$before"
            "the after value =$after"
            "the before byte=${before:$((7-l)):1}"
            "the after byte=${after:$((7-l)):1}"
            )

            for rere in "${re[@]}";do
              printcolor b "$rere"
            done
            title b 'compare pass'

          else
            re=(
            "The before/after byte=$l is not the same"
            "the before value=$before"
            "the after value=$after"
            "the before byte=${before:$((7-l)):1}"
            "the after byte=${after:$((7-l)):1}"
            )

            for rere in "${re[@]}";do
              printcolor r "$rere"
            done
            title r 'compare fail'
            read -p ""
          fi
        fi

#      launch_command "sudo ./idll-test"$executable" --GPIO_PIN_ID 0x$((i+4)) --GPIO_PIN_VAL $state -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Pin"
#      compare_result "$result" "Read back pin value: $state"
      done
    done

  done

##################################################################################
  title b "Now will loop 1000 times to check if the set/get port are the same"
  read -p "input [q] to skip or enter to test..." input

  if [ "$input" != "q" ]; then
    for (( i = 0; i < 1000; i++ )); do
      random=$(shuf -i 0-3 -n 1)

      for state in "true" "false"; do
        launch_command "sudo ./idll-test"$executable" --GPIO_PIN_ID 0x$random --GPIO_PIN_VAL $state -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Pin"
        echo "$result" > templog.txt
        readarray readdata < "templog.txt"

        compare_result "${readdata[8]}" "Read back pin value: $state"
#        launch_command "sudo ./idll-test"$executable" --GPIO_PIN_ID 0x$((random+4)) --GPIO_PIN_VAL $state -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Pin"
#        compare_result "$result" "Read back pin value: $state"
      done

    done
  fi



}

#===============================================================
#Bad parameter test
#===============================================================
BadParameter() {
  printf "${COLOR_RED_WD}Bad parameter test ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}===================${COLOR_REST}\n"
  read -p "enter key to continue..." continue

  command_line=(
  "sudo ./idll-test"$executable" --GPIO_PIN_ID 0x99 --GPIO_PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Pin"
  "sudo ./idll-test"$executable" --GPIO_PORT_VAL 65535 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port"
  )

  for command in "${command_line[@]}";do
    launch_command "$command"
    compare_result "$result" "failed" "skip"
  done

}

#===============================================================
#MAIN
#===============================================================
while true; do
  printf "\n"
  printf "${COLOR_RED_WD}1. SET PORT ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. SET PIN ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. BAD PARAMETER ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    set_get_port
  elif [ "$input" == 2 ]; then
    set_get_pin
  elif [ "$input" == 3 ]; then
    BadParameter
  fi

done
