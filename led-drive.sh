#!/bin/bash
source ./common_func.sh

Period_definition(){
  input=$1
  actual_period="(too hard to calculate)"

  if [[ "$board" == "SC1X" || "$board" == "BSEC_BACC" ]]; then
    case $input in
    0)
      actual_period=0
      ;;

    [1-9]|[1-3][0-9]|4[0-1])
      actual_period=41
      ;;
    4[1-9]|[5-7][0-9]|8[0-3])
      actual_period=83
      ;;
    8[4-9]|9[0-9]|1[0-1][0-9]|12[0-5])
      actual_period=125
      ;;
    12[6-9]|1[3-5][0-9]|16[0-7])
      actual_period=167
      ;;
    9959|99[6-9][0-9]|10000)
      actual_period=10000
      ;;
    esac
  fi

  if [ "$board" == "SA3X" ]; then
    case $input in
    0)
      actual_period=0
      ;;

    [1-9]|[1-9][0-9]|1[0-5][0-9]|16[0-6])
      actual_period=166
      ;;
    16[7-9]|2[0-9][0-9]|3[0-3][0-3])
      actual_period=333
      ;;
    983[4-9]|9[8-9][4-9][0-9]|10000)
      actual_period=10000
      ;;
    esac
  fi

}
#===============================================================
#LED all function
#===============================================================
count_whole_blink_sec(){
  blink_period_=$(($1+1))
#  printf "blink_period_= $blink_period_\n"
  project_period_=$2
  echo "$(echo "scale=2; $blink_period_/$project_period_" | bc)"
}

LED_set_get(){
  title b "To set / get pin and set / get port value for all leds"
  read -p "This test will loop forever, until press CTRL+C..."

  while true; do
    launch_command "sudo ./idll-test$executable --LOOP 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive"
    compare_result "$result" "pass"
  done
}

LedLoop(){
  local period duty pin
  read -p "How many pins does the project support?" pin
  read -p "Press [q] will exit the loop."

  while true; do
    read -rsn 1 -t 0.05 input
    if [[ "$input" == "q" ]]; then
      break
    fi

    for (( i = 0; i < pin; i++ )); do
      period=$(shuf -i 0-10000 -n 1)
      duty=$(shuf -i 0-100 -n 1)
      launch_command "sudo ./idll-test$executable --PIN_NUM $i --PERIOD $period --DUTY_CYCLE $duty --BRIGHTNESS 90 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
      verify_result "$result"
    done

  done
}

LED(){
  brightness=10
  duty_cycle=50
  blink_period=1000
  brightness_verify_value=("100" "99" "70" "50" "30" "10" "1" "0")
  duty_cycle_list=("1" "0" "2" "3" "19" "20" "49" "50" "80" "99" "100")
  blink_period_list=("1" "2" "10" "30" "41" "99" "161" "0" "998" "9999" "10000")
  printcolor w "How many pins does the project support?"
  read -p "" led_amount
  led_amount=${led_amount:-32}
#  if [ "$1" == "scxx" ]; then
#    project_period=24
#    led_amount=23
#  elif [ "$1" == "sa3" ]; then
#    project_period=6
#    led_amount=15
#  fi

#  blink_period_sec=$(count_whole_blink_sec $blink_period $project_period)

#  for all in $(seq 0 $led_amount); do
  for (( all=0; all < led_amount; all++ )); do
    for brightness_ in "${brightness_verify_value[@]}"; do
      printf "\n\n\n"
      printcolor w "LED: $all"
      printcolor r "Setting brightness: $brightness_"
      printcolor w "Blinking period: $blink_period ms"
      printcolor w "Duty cycle: $duty_cycle"
      printcolor w "==============================================="

      if [ "$brightness_" == 0 ]; then
        printcolor r "Note: the LED will STOP blinking/ turned LED OFF, while brightness = 0 "
      elif [ "$brightness_" == 100 ]; then
        printcolor r "Note: the LED will STOP blinking/ turned LED ON, while brightness = 100"
      fi

      read -p "enter to continue above setting..."
      launch_command "sudo ./idll-test$executable --PIN_NUM $all --PERIOD $blink_period --DUTY_CYCLE $duty_cycle --BRIGHTNESS $brightness_ -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
      compare_result "$result" "Brightness: $brightness_"
    done


    for dutycycle in "${duty_cycle_list[@]}"; do
      printf "\n\n\n"
      printcolor w "LED: $all"
      printcolor w "Setting brightness: $brightness"
      printcolor w "Blinking period: $blink_period ms"
      printcolor r "Duty cycle: $dutycycle"
      printcolor w "=============================================== "
      printcolor r 'Note: brightness will NOT be changed, while blink/period item testing'

      case $dutycycle in
      0)
        printcolor r "Note: the LED will stop blinking / turned LED OFF, while duty cycle = 0"
        ;;
      2 | 3)
        if [ "$board" == "SA3X" ]; then
          printcolor y "Note: (SA3X) The duty cycle should have the same behavior, when set duty cycle = 2,3"

        fi

        ;;
      99)
        if [ "$board" == "SA3X" ]; then
          printcolor y "Note: (SA3X) The duty cycle should have the same behavior, when set duty cycle = 99,100"
          printcolor r "Warning: the LED will have slightly blinking (**ALMOST SOLID ON**),while duty cycle = 99"
        fi
        ;;
      100)
        printcolor r "Warning: the LED will have slightly blinking (**ALMOST SOLID ON**), while duty cycle = 100"
        ;;
      esac


      read -p "enter to continue above setting..."
      launch_command "sudo ./idll-test$executable --PIN_NUM $all --PERIOD $blink_period --DUTY_CYCLE $dutycycle --BRIGHTNESS $brightness -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
      compare_result "$result" "Duty cycle: $dutycycle"
    done


    for blink in "${blink_period_list[@]}"; do
      Period_definition "$blink"
      #blink period setting
      printf "\n\n\n"
      printcolor w "LED: $all"
      printcolor w "Setting brightness: $brightness"
      printcolor r "Setting Blinking period: $blink ms"
      printcolor r "Actual Blinking period: $actual_period ms"
      printcolor w "Duty cycle: $duty_cycle"
      printcolor w "==============================================="
      printcolor r 'Note: brightness will NOT be changed, while blink/period item testing'


      if [ "$blink" == 0 ]; then
          printcolor r "Note: the LED will stop blinking/ LED SOLID OFF, while blinking period = 0"
      fi

      if [ "$board" == "SA3X" ]; then

        if [[ "$blink" -gt 0 && "$blink" -lt 167 ]]; then
          printcolor r "SA3xx project period = 1-166 should behave the same blinking frequency "
        fi

      else

        if [[ "$blink" -gt 0 && "$blink" -lt 42 ]]; then
          printcolor r "SA2xx/SA1xx/SCxx project period = 1-41 should behave the same blinking frequency"
        fi

      fi


      read -p "enter to continue above setting..."
      launch_command "sudo ./idll-test$executable --PIN_NUM $all --PERIOD $blink --DUTY_CYCLE $duty_cycle --BRIGHTNESS $brightness -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
      compare_result "$result" "nPeriod: $blink"
    done

    #just disable the led not te be tested.
    read -p "enter to reset LED status..."
    sudo ./idll-test"$executable" --PIN_NUM $all --PERIOD 0 --DUTY_CYCLE 0 --BRIGHTNESS 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_Drive_SetBlink

  done
}

#===============================================================
#parameter
#===============================================================
parameter(){
  title "Check bad parameter... "
  command_line=(
  "sudo ./idll-test$executable --PIN_NUM 25 --PERIOD 23 --DUTY_CYCLE 255 --BRIGHTNESS 255 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
  "sudo ./idll-test$executable --PIN_NUM 23 --PERIOD 256 --DUTY_CYCLE 255 --BRIGHTNESS 255 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
  "sudo ./idll-test$executable --PIN_NUM 23 --PERIOD 23 --DUTY_CYCLE 256 --BRIGHTNESS 255 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
  "sudo ./idll-test$executable --PIN_NUM 23 --PERIOD 23 --DUTY_CYCLE 255 --BRIGHTNESS 256 -- --EBOARD_TYPE EBOARD_ADi_$board --section GPO_LED_Drive_SetBlink"
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
  printf  "\n"
  printf  "${COLOR_RED_WD}1. LED VERIFY ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}2. LED SET / GET PORT/PIN VERIFY ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}3. BAD PARAMETER ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf  "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    LED
  elif [ "$input" == 2 ]; then
    LED_set_get
  elif [ "$input" == 3 ]; then
    parameter
  fi

done