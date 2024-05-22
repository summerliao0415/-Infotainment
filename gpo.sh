#!/bin/bash
source ./common_func.sh

#===============================================================
#Blinking function test
#===============================================================
Blink() {
  local period=2000
  local duty_cycle=50
  local result
  if [ "$1" == "scxx" ]; then
    led_amount=31
  elif [ "$1" == "sa3" ]; then
    led_amount=15
  elif [ "$1" == "lec1" ]; then
    led_amount=31
  fi
  period_verify_value=("1" "2" "10" "30" "41" "99" "166" "0" "998" "9999" "10000")
  duty_cycle_value=("1" "0" "2" "3" "19" "20" "49" "50" "80" "99" "100")

  ########################################################################
  #loop all pin test
  title b "Now will loop 100 times to check if the set/get port are the same"
  read -p "input [q] to skip or enter to test..." input

  if [[ "$input" != "q" ]]; then

    repeat_blink
  fi

  ###########################################################################
  #test basic blink / period test
  title b "Reset blinking function...   reset all port to high, before test... "
  for i in $(seq 0 $led_amount); do

    temp=$(sudo ./idll-test"$executable" --PIN_NUM $i --PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin)
    temp=$(sudo ./idll-test"$executable" --LED_NUM $i --BRIGHTNESS 10 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section LEC1_DO_Brightness_with_parameter [ADiDLL][DO][Brightness])
  done


  title b "Change DUTY CYCLE value test"
  for all in $(seq 0 $led_amount); do

    for duty_cyclell in "${duty_cycle_value[@]}"; do
      title r "Note: make sure the brightness should be changed to 100, while blinking/period test."
      printf "${COLOR_BLUE_WD}LED: $all ${COLOR_REST}\n"
      printf "${COLOR_BLUE_WD}Duty cycle:${COLOR_RED_WD} $duty_cyclell ${COLOR_REST}\n"
      printf "${COLOR_BLUE_WD}period (0=disable blinking): $period = $period ms ${COLOR_REST}\n"


      if [ "$duty_cyclell" == 0 ]; then
        printf "${COLOR_RED_WD}Note: Duty =0 should be OFF LED!! \n${COLOR_REST}"
      elif [ "$duty_cyclell" == 100 ]; then
        printf "${COLOR_RED_WD}Note: Duty =100 should be solid on to LED!! \n${COLOR_REST}"

      fi



      read -p "Enter to continue above test..." continue

      launch_command "sudo ./idll-test"$executable" --PIN_NUM $all --PERIOD $period --DUTY_CYCLE $duty_cyclell -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
#      verify_result "$result"
      compare_result "$result" "Duty cycle: $duty_cyclell"
      compare_result "$result" "tests passed"


#      if [[ "$result" =~ "failed" && "$result" =~ "nReadDutyCycle == nDutyCycle" && "$result" =~ "Duty cycle: $duty_cyclell" ]]; then
#        printcolor g "============================================"
#        printcolor g "Result PASS include : Duty cycle: $duty_cyclell"
#        printcolor g "============================================"
#      elif [[ "$result" =~ "Duty cycle: $duty_cyclell" ]]; then
#        printcolor g "============================================"
#        printcolor g "Result PASS include : Duty cycle: $duty_cyclell"
#        printcolor g "============================================"
#      else
#        printcolor r "============================================"
#        printcolor r "Result: FAIL"
#        printcolor r "============================================"
#        read -p ""
#      fi
#      echo ""
#      compare_result "$result" "Duty cycle: $duty_cyclell"
      #read -p "enter key to continue..." continue

      #sleep 1
    done

    #Change PERIOD value
    ######################################################
    title b "Change PERIOD value test"
    read -p "Enter to continue..." continue

    for perioddd in "${period_verify_value[@]}"; do
      title r "Note: make sure the brightness should be changed to 100, while blinking/period test."
      printf "${COLOR_BLUE_WD}LED: $all ${COLOR_REST}\n"
      printf "${COLOR_BLUE_WD}Duty cycle: $duty_cycle ${COLOR_REST}\n"
      printf "${COLOR_BLUE_WD}period( 0,1=disable blinking): ${COLOR_RED_WD}$perioddd  = $perioddd ms ${COLOR_REST}\n"

      if [[ "$perioddd" -eq 0 ]]; then
        printf "${COLOR_RED_WD}Note: period = 0,1 should stop blinking, but doesn't matter it light on/off \n${COLOR_REST}"
      elif [[ "$perioddd" -eq 1 ]]; then
        printf "${COLOR_RED_WD}Note: period = 1 should stop blinking, and light off \n${COLOR_REST}"
      fi



      read -p "Enter to continue above test..." continue


      launch_command "sudo ./idll-test"$executable" --PIN_NUM $all --PERIOD $perioddd --DUTY_CYCLE $duty_cycle -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
      compare_result "$result" "Period: $perioddd"
      verify_result "$result"

    done

    #confirm LED status after disabling blinking
    title b "Start to disable LED blinking function"
    printcolor r "(SCxx/SA3) LED: $all should be back to solid on as it's set port before ..."
    printcolor r "(LEC1) LED: $all won't keep its original state, it on/off randomly ..."
    read -p "Enter to continue..." continue
    print_command "sudo ./idll-test"$executable" --PIN_NUM $all --PERIOD 0 --DUTY_CYCLE 100 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
    sudo ./idll-test"$executable" --PIN_NUM $all --PERIOD 0 --DUTY_CYCLE 100 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink

  done


  title b "All LED should be OFF"
  read -p "enter key to continue..." continue
  sudo ./idll-test"$executable" --PORT_VAL 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort


}

disabling_blinking_muti_condition(){
  local period=1000 duty_cycle=50 brightness=50
  #LED multi disabling-blinking test
  printcolor r "How many DO pins is the project supported?"
  read -p "" amount
  amount=${amount:-32}
  title b "Enter to test LED multi disabling-blinking status."
  for led in $(seq 0 $((amount-1))); do
    case $1 in
    "setpin")
      for i in "true" "false" ; do

        launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --PERIOD $period --DUTY_CYCLE $duty_cycle -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"

        case $i in
        "true")
          printcolor y "LED$led is going to set solid ON by set pin."
          printcolor y "Make sure it won't be blinking and should keep solid on."
          printcolor w "Enter to test."
          read -p ""
          launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --PIN_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
          echo "Confirm if the LED stops blinking, and enter to next test"
          read -p ""
        ;;

        "false")
          printcolor y "LED$led is going to set solid OFF by set pin."
          printcolor y "Make sure it won't be blinking and should keep OFF."
          printcolor w "Enter to test."
          read -p ""
          launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --PIN_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
          echo "Confirm if the LED stops blinking, and enter to next test."
          read -p ""
        ;;
        esac
      done
      ;;

    "brightness")
      for i in "true" "false" ; do
        launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --PERIOD $period --DUTY_CYCLE $duty_cycle -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
        title r "If the following script has error, please make sure the project supports BRIGHTNESS function."

        case $i in
        "true")
          printcolor y "LED$led is going to set solid ON by set brightness=100."
          printcolor y "Make sure it won't be blinking and should keep solid on."
          printcolor w "Enter to test."
          read -p ""
          launch_command "sudo ./idll-test"$executable" --LED_NUM $led --BRIGHTNESS 100 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section LEC1_DO_Brightness_with_parameter [ADiDLL][DO][Brightness]"
          echo "Confirm if the LED stops blinking, and enter to next test."
          read -p ""
        ;;

        "false")
          printcolor y "LED$led is going to set solid OFF by set brightness=0."
          printcolor y "Make sure it won't be blinking and should keep OFF."
          printcolor w "Enter to test..."
          read -p ""
          launch_command "sudo ./idll-test"$executable" --LED_NUM $led --BRIGHTNESS 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section LEC1_DO_Brightness_with_parameter [ADiDLL][DO][Brightness]"
          echo "Confirm if the LED stops blinking, and enter to next test."
          read -p ""
        ;;
        esac
      done

      ;;
    esac
  done


}

repeat_blink(){
  for (( i = 0; i < 100; i++ )); do
    random_period=$(shuf -i 0-10000 -n 1)
    random_duty=$(shuf -i 0-100 -n 1)
    random_pin=$(shuf -i 0-$led_amount -n 1)
    launch_command "sudo ./idll-test"$executable" --PIN_NUM $random_pin --PERIOD $random_period --DUTY_CYCLE $random_duty -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
    verify_result "$result"
#    compare_result "$result" "passed"

#    compare_result "$result" "Period: $random_period"
#    compare_result "$result" "Duty cycle: $random_duty"
#    if [[ "$result" =~ "failed" && "$result" =~ "nReadDutyCycle == nDutyCycle"  ]]; then
#      printcolor g "============================================"
#      printcolor g "Result: PASS"
#      printcolor g "============================================"
#    elif [[ "$result" =~ "Period: $random_period" || "$result" =~ "Duty cycle: $random_duty" ]]; then
#      printcolor g "============================================"
#      printcolor g "Result: PASS"
#      printcolor g "============================================"
#    else
#      printcolor r "============================================"
#      printcolor r "Result: FAIL"
#      printcolor r "============================================"
#
#    fi
  done
}

All_blink(){
  printcolor w "How many led is supported for the project?"
  read -p "" amount

  for (( i = 0; i < amount; i++ )); do
    launch_command "sudo ./idll-test"$executable" --PIN_NUM $i --PERIOD 100 --DUTY_CYCLE 50 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
  done

  while true ; do
    printf "Press 'x' to reset LED / exit the blink loop.. \r"

    read -rsn 1 -t 0.01 input

    if [ "$input" == "x" ]; then
      for (( i = 0; i < amount; i++ )); do
        launch_command "sudo ./idll-test"$executable" --PIN_NUM $i --PERIOD 100 --DUTY_CYCLE 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
      done
      return
    fi

  done


}

#===============================================================
#Brightness for LEC1 A3 32 DO
#===============================================================
## this script need to add correct script
Brightness(){
  brightness=("100" "99" "87" "70" "60" "51" "40" "30" "25" "10" "0")
  local duty_cycle=50 period=1000
  for led in $(seq 0 31);do
    #--------------------------------------------------------
    #test each brightness level with blinking action enabled
    for brightness_value in "${brightness[@]}"; do

      mesg=(
      "LED: $led"
      "Period: 1000 ms"
      "Duty Cycle: 50"
      "Brightness: $brightness_value"
      )
      title_list r mesg[@]

      if [ "$brightness_value" == 0 ]; then
        printcolor r "Note: the LED will stop blinking/ turned LED OFF, while brightness = $brightness_value"
      elif [ "$brightness_value" == 100 ]; then
        printcolor r "Note: the LED will stop blinking/ turned LED SOLID ON, while brightness = $brightness_value"
      fi
      printcolor r "Note: LED should stop blinking, while change the brightness setting."
      printcolor w "Enter to test brightness setting."

      read -p ""
      launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --PERIOD $period --DUTY_CYCLE $duty_cycle -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
#      launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --BLINK 100 --DUTY_CYCLE 50 --BRIGHTNESS $brightness_value -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_Drive_SetBlink"
      launch_command "sudo ./idll-test"$executable" --LED_NUM $led --BRIGHTNESS $brightness_value -- --EBOARD_TYPE EBOARD_ADi_"$board" --section LEC1_DO_Brightness_with_parameter [ADiDLL][DO][Brightness]"
      compare_result "$result" "Brightness: $brightness_value"
    done
  done

}

Brightness_loop(){
  local value led
  for all in $(seq 0 100); do
    value=$(shuf -i 0-10 -n 1)
    led=$(shuf -i 0-31 -n 1)
    launch_command "sudo ./idll-test"$executable" --PIN_NUM $led --BLINK 100 --DUTY_CYCLE 50 --BRIGHTNESS $value -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_Drive_SetBlink"
    compare_result "result" "$value"

  done
}


#===============================================================
#LED Set port function test
#===============================================================
SetPort() {
  num=(
    $((2#00000000000000000000000000000001))
    $((2#00000000000000000000000000000010))
    $((2#00000000000000000000000000000100))
    $((2#00000000000000000000000000001000))
    $((2#00000000000000000000000000010000))
    $((2#00000000000000000000000000100000))
    $((2#00000000000000000000000001000000))
    $((2#00000000000000000000000010000000))
    $((2#00000000000000000000000100000000))
    $((2#00000000000000000000001000000000))
    $((2#00000000000000000000010000000000))
    $((2#00000000000000000000100000000000))
    $((2#00000000000000000001000000000000))
    $((2#00000000000000000010000000000000))
    $((2#00000000000000000100000000000000))
    $((2#00000000000000001000000000000000))
    $((2#00000000000000010000000000000000))
    $((2#00000000000000100000000000000000))
    $((2#00000000000001000000000000000000))
    $((2#00000000000010000000000000000000))
    $((2#00000000000100000000000000000000))
    $((2#00000000001000000000000000000000))
    $((2#00000000010000000000000000000000))
    $((2#00000000100000000000000000000000))
    $((2#00000001000000000000000000000000))
    $((2#00000010000000000000000000000000))
    $((2#00000100000000000000000000000000))
    $((2#00001000000000000000000000000000))
    $((2#00010000000000000000000000000000))
    $((2#00100000000000000000000000000000))
    $((2#01000000000000000000000000000000))
    $((2#10000000000000000000000000000000))
    $((2#11111111111111111111111111111111))
    $((2#00000000000000000000000000000000))
    )

  num_sa3=(
    $((2#0000000000000000))
    $((2#1111111111111111))
    )

  if [ "$1" == "scxx" ] || [ "$1" == "lec1" ]; then
      num_actual=("${num[@]}")
#      printf "num_actual=${num_actual[*]}\n"
#      printf "num_actual[0]=${num_actual[0]}\n"
  elif [ "$1" == "sa3" ]; then
    for (( i = 0; i < 18; i++ )); do
        num_actual[$i]=${num[$i]}
        if [ "$i" == 16 ]; then
          num_actual[$i]=${num_sa3[0]}
        elif [ "$i" == 17 ]; then
          num_actual[$i]=${num_sa3[1]}
        fi

#          printf "num_actual=${num_actual[*]}\n"
    done

  fi

  title b "All LED setport test"
  read -p "enter key to continue..." continue

  for i in ${num_actual[*]}; do
    printcolor r $i
    print_command "sudo ./idll-test"$executable" --PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
    launch_command "sudo ./idll-test"$executable" --PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
    compare_result "$result" "Port value: $i"
    sleep 1
  done

  sudo ./idll-test"$executable" --PORT_VAL 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort
  title b "Now will loop 1000 times to check if the set/get port are the same"
  read -p "input [q] to skip or enter to test..." input

  if [ "$input" != "q" ]; then
    for (( i = 0; i < 1000; i++ )); do
      random=$(shuf -i 0-$((${#num_actual[@]}-1)) -n 1)
      printcolor y "random=$random"

      launch_command "sudo ./idll-test"$executable" --PORT_VAL ${num_actual[$random]} -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
      compare_result "$result" "Port value: ${num_actual[$random]}"
    done
    #reset all port to light off
   launch_command "sudo ./idll-test"$executable" --PORT_VAL 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
  fi

}

#===============================================================
#LED Set pin function test
#===============================================================
SetPin() {
  printf "${COLOR_RED_WD}All LED setpin test ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}====================${COLOR_REST}\n"
  read -p "enter key to continue..." continue

  if [ "$1" == "scxx" ] || [ "$1" == "lec1" ]; then
      num_pin=31
  elif [ "$1" == "sa3" ]; then
      num_pin=15
  fi

  for all in $(seq 0 $num_pin); do
    launch_command "sudo ./idll-test"$executable" --PIN_NUM $all --PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
    compare_result "$result" "Pin number: $all, Pin value: 1"
    sleep 1
    launch_command "sudo ./idll-test"$executable" --PIN_NUM $all --PIN_VAL false -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
    compare_result "$result" "Pin number: $all, Pin value: 0"
  done

  title b "Now will loop 1000 times to check if the set/get pin are the same"
  read -p "input [q] to skip or enter to test..." input

  if [ "$input" != "q" ]; then
    for (( i = 0; i < 1000; i++ )); do
      random=$(shuf -i 0-$num_pin -n 1)
      launch_command "sudo ./idll-test"$executable" --PIN_NUM $random --PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
      compare_result "$result" "Pin number: $random, Pin value: 1"
      launch_command "sudo ./idll-test"$executable" --PIN_NUM $random --PIN_VAL false -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
      compare_result "$result" "Pin number: $random, Pin value: 0"
    done
    #reset all port to light off
    launch_command "sudo ./idll-test"$executable" --PORT_VAL 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
  fi
}

#===============================================================
#Bad parameter test
#===============================================================
BadParameter() {
  printf "${COLOR_RED_WD}Bad parameter test ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}===================${COLOR_REST}\n"
  read -p "enter key to continue..."

  command_line=(
  "sudo ./idll-test"$executable" --PIN_NUM 9999999 --PIN_VAL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
  "sudo ./idll-test"$executable" --PIN_NUM 1 --PIN_VAL dd -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPin"
  "sudo ./idll-test"$executable" --PORT_VAL 999999999999999 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetPort"
  "sudo ./idll-test"$executable" --PIN_NUM 0 --PERIOD 65536 --DUTY_CYCLE 99 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
  "sudo ./idll-test"$executable" --PIN_NUM 0 --PERIOD 0 --DUTY_CYCLE 101 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_SetDoLedBlink"
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
  printf "${COLOR_RED_WD}1. (SCXX) BLINK ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. (LEC1) BLINK ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. (SA3X) BLINK ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}4. (SCXX/LEC1/BSEC)SET PORT ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}5. (SCXX/LEC1/BSEC)SET PIN ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}6. (SA3)SET PORT ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}7. (SA3)SET PIN ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}8. BRIGHTNESS ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}9. BLINK LOOP ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}10. BAD PARAMETER ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}11. DISABLE BLINKING BY BRIGHTNESS  ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}12. DISABLE BLINKING BY SETPIN  ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    Blink scxx
  elif [ "$input" == 2 ]; then
    Blink lec1
  elif [ "$input" == 3 ]; then
    Blink sa3
  elif [ "$input" == 4 ]; then
    SetPort scxx
  elif [ "$input" == 5 ]; then
    SetPin scxx
  elif [ "$input" == 6 ]; then
    SetPort sa3
  elif [ "$input" == 7 ]; then
    SetPin sa3
  elif [ "$input" == 8 ]; then
    Brightness
  elif [ "$input" == 9 ]; then
    All_blink
  elif [ "$input" == 10 ]; then
    BadParameter
  elif [ "$input" == 11 ]; then
    disabling_blinking_muti_condition "brightness"
  elif [ "$input" == 12 ]; then
    disabling_blinking_muti_condition "setpin"
  fi

done
