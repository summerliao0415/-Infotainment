#!/bin/bash
source ./common_func.sh
#LEC1 SA3X has different hard meter IC, NCV7240 , so it needs to add note for program recognize
exception=("LEC1" "SA3X")

GetSetPin_bsec() {
  title b "Get pin/set pin /get meter sense (BSEC/BACC only)"
  printf "[x] key to exit, or [ENTER] enter key to continue...\n"
  read -p "" input
  m=0
  for ((i = 24; i < 32; i++)); do
    if [ "$input" == "x" ]; then
      break
    fi
    sudo ./idll-test"$executable" --DO_PIN_NUM $i --MSENSE_PIN_NUM $m -- --EBOARD_TYPE EBOARD_ADi_"$board" --section HardMeter_BACC_SetPin
    ((m++))
  done
}

GetSetPort_bsec() {
  title b "Get port/set port /get meter sense (BSEC/BACC only)"
  printf "q key to exit, or enter key to continue...\n"
  read -p "" input

  for i in 1 2 4 8 16 32 64 128 255; do
    if [ "$input" == "q" ]; then
      break
    fi
    sudo ./idll-test"$executable" --PORT_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section HardMeter_BACC_SetPort
  done
}

GetSetPin_SA3() {
  title b "Start counting hard meter by PIN"
  local i

  for ((i = 0; i < 16; i++)); do
    if [[ "$i" == 8 ]]; then
      printcolor r "going to test hard meter (9-16)"
      read -p "enter key to test..."
    fi
    launch_command "sudo ./idll-test$executable --PIN_VAL $i --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPin_NCV7240"
    compare_result "$result" "passed"
  done

}

SetGetPort_SA3() {
  title b "Start counting hard meter by Port (1-8)"
  hex=$((2#1))

  while true; do
    launch_command "sudo ./idll-test$executable --PORT_VAL $hex --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort_NCV7240"
    compare_result "$result" "passed"
    hex=$((hex << 1))

    #    read -p "" continue
    case $hex in
    $((2#100000000)))
      title b "going to test hard meter (9-16)"
      read -p "enter key to test..."
      ;;
    $((2#10000000000000000)))
      title b "going to test hard meter (1-16) set high for 1 mins"
      read -p "enter key to test..."

      #loop 1 min to confirm meter works fine
      after=$(date +%s --date="+1 minute")
      while true; do
        now=$(date +%s)
        launch_command "sudo ./idll-test$executable --PORT_VAL 65535 --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort_NCV7240"
        compare_result "$result" "passed"
        if [[ "$now" > $after ]]; then
          break
        fi
      done

      break
      ;;
    esac
  done
}

GetSetPin_SCXX() {
  title b "Start counting hard meter by PIN"

  hex=$((2#1))
  for ((i = 0; i < 8; i++)); do
    if [[ "${exception[*]}" =~ $board ]]; then
      launch_command "sudo ./idll-test$executable --PIN_VAL $i --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPin_NCV7240"
    else
      launch_command "sudo ./idll-test$executable --PIN_VAL $i --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPin"

    fi

    compare_result "$result" "passed"
  done

}

SetGetPort_SCXX() {
  title b "Start counting hard meter by Port (1-8)"
  hex=$((2#1))

  while true; do
    if [[ "${exception[*]}" =~ $board ]]; then
      launch_command "sudo ./idll-test$executable --PORT_VAL $hex --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort_NCV7240"
    else
      launch_command "sudo ./idll-test$executable --PORT_VAL $hex --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort"
    fi
    compare_result "$result" "passed"
    hex=$((hex << 1))

    if [[ "$hex" == "$((2#100000000))" ]]; then
      break
    fi

  done
  printcolor y "It's going to loop all hard meter by set port for 1 minute, press Enter to continue."
  read -p ""
  after=$(date +%s --date="+1 minute")
  while true; do
    now=$(date +%s)
    if [[ "${exception[*]}" =~ $board ]]; then
      launch_command "sudo ./idll-test$executable --PORT_VAL 255 --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort_NCV7240"
    else
      launch_command "sudo ./idll-test$executable --PORT_VAL 255 --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort"
    fi
    compare_result "$result" "passed"
    if [[ "$now" > $after ]]; then
      break
    fi
  done
}

meter_detection() {
  local l i
  read -p "Input the total supported pin number or Enter for 8 pins hard meter (8 or 16): " pin_number
  pin_number=${pin_number:-8}

  if [ "$pin_number" -eq 16 ]; then
    expected_getport_plug_value="0xFFFF"
    meter_total_pin=9
  else
    expected_getport_plug_value="0xFF"
    meter_total_pin=8
  fi
  #  expected_getport_plug_value="0xFFFF"
  #  meter_total_pin=9
  #  count=0
  for i in "plug" "unplug"; do
    title b "***************Now please make cable in $i status..*************************"
    read -p ""

    case $i in
    "plug")
      while true; do

        for ((l = 0; l < $meter_total_pin; l++)); do
          title b "Now get detection ( PORT ) value"
          launch_command "sudo ./idll-test$executable -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPort"
          compare_result "$result" "$expected_getport_plug_value"

          printf "\n\n"
          title b "Now get detection ( PIN ) value"
          launch_command "sudo ./idll-test$executable --HM_PIN_ID $l -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPin"
          result_check "pin" "true" "$result" "$l"

        done

        read -p "Enter to continue test or press [q] to skip get port function..." input
        if [[ "$input" == "q" ]]; then
          break
        fi

      done
      ;;

    "unplug")
      while true; do

        for ((l = 0; l < $meter_total_pin; l++)); do
          title b "Now get detection ( PORT ) value"
          launch_command "sudo ./idll-test$executable -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPort"
          compare_result "$result" "0x0"

          title b "Now get detection ( PIN ) value"
          launch_command "sudo ./idll-test$executable --HM_PIN_ID $l -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPin"
          result_check "pin" "false" "$result" "$l"
        done

        read -p "enter key continue test or press [q] to skip get port function..." input
        if [[ "$input" == "q" ]]; then
          break
        fi

      done
      ;;
    esac
  done
}

#s1: pin / port
#s2: expected value
#s3: the result of launching command line
#s4: set pin ID
result_check() {

  case $1 in
  'port')
    compare_result "$3" "$2"
    ;;
  'pin')
    if [[ "$3" =~ "Pin ID" ]]; then
      compare_result "$3" "Pin ID: $4  Status: $2"
    elif [[ "$3" =~ "pin:" ]]; then
      compare_result "$3" "pin: $4, status: $2"
    fi
    ;;
  esac
}

meter_detection_loop() {
  read -p "Input the total supported pin number or Enter for 16 pins hard meter (8 or 16): " pin_number
  read -p "input how many minutes your need to test : " set_time
  pin_number=${pin_number:-8}
  set_time=${set_time:-1}
  case $pin_number in
  16)
    meter_total_pin=9
    expected_getport_plug_value="0xFFFF"
    ;;
  8)
    meter_total_pin=8
    expected_getport_plug_value="0xFF"
    ;;
  esac

  for i in "plug" "unplug"; do
    title b "***************Now please make cable in $i status..*************************"
    read -p ""

    case $i in
    "plug")

      after=$(date +%s --date="+$set_time minute")

      while true; do
        now=$(date +%s)

        for ((l = 0; l < $meter_total_pin; l++)); do
          title b "Now get detection ( PORT ) value"
          launch_command "sudo ./idll-test$executable -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPort"
          result_check "port" "$expected_getport_plug_value" "$result"

          printf "\n\n"
          title b "Now get detection ( PIN ) value"
          launch_command "sudo ./idll-test$executable --HM_PIN_ID $l -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPin"
          result_check "pin" "true" "$result" "$l"
          #

        done

        #to get all port/pin status finished first, and will be interrupted if one of them is failed.
        if [[ "$now" > "$after" || "$status" == "fail" ]]; then
          break
        fi

      done
      ;;

    "unplug")

      after=$(date +%s --date="+$set_time minute")

      while true; do
        now=$(date +%s)

        for ((l = 0; l < $meter_total_pin; l++)); do
          title b "Now get detection ( PORT ) value"
          launch_command "sudo ./idll-test$executable -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPort"
          result_check "port" "0x0" "$result"

          title b "Now get detection ( PIN ) value"
          launch_command "sudo ./idll-test$executable --HM_PIN_ID $l -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_Detection_ByPin"
        done

        if [[ "$now" > "$after" || "$status" == "fail" ]]; then
          break
        fi

      done
      ;;
    esac
  done
}

#===============================================================
#Hard Meter Fail / Reset test
#===============================================================
FailGetPort() {
  local re temp
  temp=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiHardMeterFailureGetPort_manu)
  re=$(echo "$temp" | grep '^Failure' | sed "s/\s//g")

  if [ "$1" == "y" ]; then
    print_command "sudo ./idll-test$executable  -- --EBOARD_TYPE EBOARD_ADi_$board --section adiHardMeterFailureGetPort_manu"
    echo "$temp"
  fi
  re=${re:0-$2}
  printcolor b "Fail Get Port=$re"
}

FailGetPin() {
  local re status temp
  local list=()

  for ((i = 0; i < $1; i++)); do
    temp=$(sudo ./idll-test"$executable" --PIN_VAL $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiHardMeterFailureGetPin_manu)

    if [ "$2" == "y" ]; then
      print_command "sudo ./idll-test$executable  --PIN_VAL $i -- --EBOARD_TYPE EBOARD_ADi_$board --section adiHardMeterFailureGetPin_manu "
      echo "$temp"
    fi
    #clear all unneeded string
    re=$(echo "$temp" | grep '^Failure' | sed 's/\s//g ; s/.*://g ; s/,.*//g')
    #if user set more than actual supported pin number, those pins will be set as 0, while it return blank string.
    if [ "$re" == "" ]; then
      re=0
    fi
    list[(($1 - i))]=$re
  done
  status=$(echo "${list[*]}" | sed 's/\s//g')
  printcolor b "Fail Get Pin =$status"
}

FailResetPort() {
  local reset_pin input_list
  for ((i = 0; i < $1; i++)); do
    input_list[i]=1
  done
  total_pin=$(echo "${input_list[*]}" | sed 's/\s//g')
  #  total_pin=$(${input_list[*]}//'\s'//"")
  #  total_pin=$(echo "obase=10;$total_pin"|bc)
  total_pin=$((2#$total_pin))
  printcolor y "Input amount hard meter pins in DEC/HEX format to reset, or press ENTER to reset all port:"
  echo "DEC= xxx (x means digit in DEC format)"
  echo "HEX= 0x (Prefix needs to add '0x' string to recognize it is the HEX format)"
  read -p "Reset Pins= " reset_pin
  reset_pin=${reset_pin:-$total_pin}

  launch_command "sudo ./idll-test$executable --PORT_VAL $reset_pin -- --EBOARD_TYPE EBOARD_ADi_$board --section adiHardMeterOutResetPort_manu"
  compare_result "$result" "passed"
}

FailResetPin() {
  local reset_pin input_list
  printcolor y "Input which hard meter pin in DEC format to reset:"
  echo "DEC= xxx (x means digit in DEC format 0-15)"
  #  echo "HEX= 0x (Prefix needs to add '0x' string to recognize it is the HEX format)"
  read -p "Reset Pins= " reset_pin
  reset_pin=${reset_pin:-"0"}
  launch_command "sudo ./idll-test$executable --PIN_VAL 0x$reset_pin -- --EBOARD_TYPE EBOARD_ADi_$board --section adiHardMeterOutResetPin_manu"
  compare_result "$result" "passed"
}

MeterRotateSelection() {
  local input
  printcolor b "Pressing [y] to set pin to make hard meter count, or [ENTER] to skip."
  read -p "" input

  if [ "$input" == "y" ]; then
    case $board in
    "LEC1")
      GetSetPin_SCXX

      ;;
    "SCXX")
      GetSetPin_SCXX

      ;;
    "SA3X")
      GetSetPin_SA3

      ;;
    "BSEC_BACC")
      GetSetPin_bsec

      ;;
    esac

  fi

}

FailFunction() {
  local amount_pin
  title b "Hard meter Failure get port/pin function test"
  echo "Pressing [y] to export idll output result, or just [ENTER] to skip detailed output:"
  read -p "" export
  echo "Input how many pins are hard meter supported?"
  read -p "Amount supported pins= " amount_pin
  export=${export:-"n"}
  MeterRotateSelection

  while true; do
    printcolor y "Press [x] to exit the loop of fail get port/pin status."
    printcolor y "Press [1] to reset port."
    printcolor y "Press [2] to reset pin."

    echo "Collecting all failure pins status, please wait...."
    FailGetPin "$amount_pin" "$export"
    FailGetPort "$export" "$amount_pin"

    read -rsn 1 -t 0.01 input
    if [[ "$input" == "x" ]]; then
      break
    elif [[ "$input" == "1" ]]; then
      FailResetPort "$amount_pin"
    elif [[ "$input" == "2" ]]; then
      FailResetPin
    fi
  done
}

PerformanceNCV7240(){
  local test_time set_time
  test_time=300
  printcolor b "The default response time = 3000us. if you want to change other response time"
  printcolor b "if you want to change other response time, input the setting time you won't, or just [Enter] to test."
  read -p "" set_time
  set_time=${set_time:-3000}
  launch_command "./idll-test$executable --KEY_VALUE_PAIRS 'adiHardMeterGetPort_threshold=$set_time,adiHardMeterSetPort_threshold=$set_time,adiHardMeterFailureGetPort_threshold=$set_time' --PORT_VAL 0xf0 --HM-Int-Count 1 --LOOP $test_time -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort_NCV7240"
  compare_result "$result" "passed"

}

PerformanceOther(){
  local test_time set_time
  test_time=300
  printcolor b "The default response time = 3000us. if you want to change other response time"
  printcolor b "if you want to change other response time, input the setting time you won't, or just [Enter] to test."
  read -p "" set_time
  set_time=${set_time:-3000}
  launch_command "./idll-test$executable --KEY_VALUE_PAIRS 'adiHardMeterGetPort_threshold=$set_time,adiHardMeterSetPort_threshold=$set_time,adiHardMeterFailureGetPort_threshold=$set_time' --PORT_VAL 0xf0 --HM-Int-Count 1 --LOOP $test_time -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort"
  compare_result "$result" "passed"

}

PerformanceOther_old(){
  local test_time set_time
  test_time=300
  printcolor b "The default response time = 3000us. if you want to change other response time"
  printcolor b "if you want to change other response time, input the setting time you won't, or just [Enter] to test."
  read -p "" set_time
  set_time=${set_time:-3000}
  for (( i = 0; i < $test_time; i++ )); do
    # to get specific strings from result Max=
    launch_command "./idll-test$executable --PORT_VAL 0xFF --HM-Int-Count 1 -- --EBOARD_TYPE EBOARD_ADi_$board --section HardMeter_ByPort"
    getport_time=$(echo "$result"  | grep -i adihardmetergetport | grep -o "Max=[0-9]*" | sed 's/Max=//g' )
    setport_time=$(echo "$result"  | grep -i adihardmetersetport | grep -o "Max=[0-9]*" | sed 's/Max=//g' )
    senseport_time=$(echo "$result"  | grep -i adihardmetergetsenseport | grep -o "Max=[0-9]*" | sed 's/Max=//g' )
    if [[ "$getport_time" -gt 3000 || "$setport_time" -gt 3000 || "$senseport_time" -gt 3000  ]]; then
      log_to_file
      printcolor r "Some the of the hardmeter response time are large than 3000us as below list."
      printcolor r "============================================================================"
      printcolor w "Getport_time=$getport_time us"
      printcolor w "Setport_time=$setport_time us"
      printcolor w "Senseport_time=$senseport_time us"
      read -p ""
    fi

  done
#  compare_result "$result" "passed"
}


#========================================================================================================

while true; do
  printf "${COLOR_RED_WD}1. GET PIN / SET PIN / GET METER SENSE (BSEC/BACC only)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. Get PORT / SET PORT /GET METER SENSE (BSEC/BACC only)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. Get PORT / SET PORT /GET METER SENSE (SA3)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}4. GET PIN / SET PIN / GET METER SENSE (SA3)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}5. Get PORT / SET PORT /GET METER SENSE ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}6. GET PIN / SET PIN / GET METER SENSE ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}7. METER DETECTION PIN/PORT ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}8. METER DETECTION PIN/PORT LOOP${COLOR_REST}\n"
  printf "${COLOR_RED_WD}9. METER FAILURE / RESET${COLOR_REST}\n"
  printf "${COLOR_RED_WD}10. METER PERFORMANCE (SA3X/LEC1)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}11. METER PERFORMANCE (SA2X/SCxx)${COLOR_REST}\n"
  printf "${COLOR_RED_WD}=========================================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    GetSetPin_bsec
  elif [ "$input" == 2 ]; then
    GetSetPort_bsec
  elif [ "$input" == 3 ]; then
    SetGetPort_SA3
  elif [ "$input" == 4 ]; then
    GetSetPin_SA3
  elif [ "$input" == 5 ]; then
    SetGetPort_SCXX
  elif [ "$input" == 6 ]; then
    GetSetPin_SCXX
  elif [ "$input" == 7 ]; then
    meter_detection
  elif [ "$input" == 8 ]; then
    meter_detection_loop
  elif [ "$input" == 9 ]; then
    FailFunction
  elif [ "$input" == 10 ]; then
    PerformanceNCV7240
  elif [ "$input" == 11 ]; then
    PerformanceOther
  fi

done
