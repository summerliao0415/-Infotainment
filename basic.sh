#!/bin/bash
source ./common_func.sh

#===============================================================
#basic info/initial
#===============================================================
ErrorString() {
  print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section Error_String_Message"
  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section Error_String_Message
}

Initial() {
  while true; do
    #    echo "$board"
    print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section adiLibInit"
    result=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiLibInit)
    echo "$result"
    if [[ "$result" == "" ]]; then
      print_command "sudo ./idll-test"$executable" --ALLOW_INIT_FAIL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section InitBatDetect [ADiDLL][INIT][BAT_DETECT]"
      sudo ./idll-test"$executable" --ALLOW_INIT_FAIL true -- --EBOARD_TYPE EBOARD_ADi_"$board" --section InitBatDetect [ADiDLL][INIT][BAT_DETECT]
    fi

    echo "Input [q] to exit loop.."
    read -p "" input
    if [[ "$input" == "q" ]]; then
      break
    fi
  done
}

SystemInfo() {
  print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SYS_Info"
  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SYS_Info
}

FPGA_FW_SHA256() {
  title b "FPGA FW SHA256 verify"
  read -p "input FPGA F/W 64 char sha256 data: " input

  data=("aa" "12" "@@")
  for i in "${data[@]}"; do
    title b "start to input value: $i"
    print_command "sudo ./idll-test"$executable" --fpga-fw-sha256 $i -- --EBOARD_TYPE EBOARD_ADi_"$board" \"Scenario: adiLibGetFirmwareSHA256\""
    result=$(sudo ./idll-test"$executable" --fpga-fw-sha256 $i -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiLibGetFirmwareSHA256")
    echo "$result"
    compare_result "$result" "failed"

  done
  print_command "sudo ./idll-test"$executable" --fpga-fw-sha256 $input -- --EBOARD_TYPE EBOARD_ADi_"$board" \"Scenario: adiLibGetFirmwareSHA256\""
  sudo ./idll-test"$executable" --fpga-fw-sha256 "$input" -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiLibGetFirmwareSHA256"
}

ConfirmAutoManual() {
  local require file_name auto_item con
  file_name="all_tests_auto_EBOARD_ADi_$board.sh"
  auto_item=('LED' 'Brightness' 'SPI' 'I2C' 'HardMeter' 'SecMeter')
  #skip to set auto/manual at initial time on purpose, so it would be save the auto / manual list without reset at second run this function
#  auto=()
#  manual=()
  m=0
  n=0
  found=0


  printcolor r "So far, the auto script file name: ($file_name)"
  printcolor r "If it is incorrect, input the correct file name, or just [Enter] to test."
  read -p "" file_name2
  file_name=${file_name2:-$file_name}

  echo "Start collecting auto script data...."
  echo "auto=${#auto[*]}"
  if [[ "${#auto[*]}" -gt 0 ]]; then
    return
  fi

  while read line; do
    con=$(echo "$line" | grep -i "idll-test" | grep -v "#" | sed "s/\r//g")
    #loop all auto list to compare with $con to check if they match, if match, then plus 1 in $found
    if [[ "${#con}" -ne 0 ]]; then
      for i in ${auto_item[*]}; do
        if [[ "$con" =~ $i ]]; then
          manual[$m]="$con"
          ((m++))
          ((found++))
        fi
      done

    #if $found is 0, meaning it won't match with auto_item list, so add the $con value to $manual list
      if [ "$found" -eq 0 ]; then
        auto[$n]="$con"
        ((n++))
      fi

    #rest the found value, then repeat again
      found=0

    fi
  done <$file_name
}

AutoManual() {
  ConfirmAutoManual
  for i in "${manual[@]}"; do
    while true; do
      launch_command "$i"
      compare_result "$result" "passed"
      echo "Press [Enter] to test next script, or press [any string] to repeat script."
      read -p "" re
      if [ "$re" == "" ]; then
        break

      fi
    done

  done

}
other() {
#  print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiWatchdogSetSystemRestart" -s"
  local other other_cmd
  other_00=$(./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiWatchdogSetSystemRestart")
  other_00_cmd="./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" \"Scenario: adiWatchdogSetSystemRestart\""
  other_01=$(./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiBatSetLowVoltage")
  other_01_cmd="./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" \"Scenario: adiBatSetLowVoltage\""
  other_02=$(./idll-test"$executable" --BAT-QTY 3 -- --EBOARD_TYPE EBOARD_ADi_"$board" "Scenario: adiBatSetWarningVoltage")
  other_02_cmd="./idll-test"$executable" --BAT-QTY 3 -- --EBOARD_TYPE EBOARD_ADi_"$board" \"Scenario: adiBatSetWarningVoltage\""

  case $1 in
  'adiWatchdogSetSystemRestart')
    other=$other_00
    other_cmd=$other_00_cmd

    ;;
  'adiBatSetLowVoltage')
    other=$other_01
    other_cmd=$other_01_cmd

    ;;
  'adiBatSetWarningVoltage')
    other=$other_02
    other_cmd=$other_02_cmd

    ;;
  esac

  print_command "$other_cmd"
  echo "$other"
  echo "================================================================================================" >> result.log
  echo "$other_cmd" >> result.log
  echo "================================================================================================" >> result.log
  if [[ "$result" =~ "27 == 0" ]]; then
    .
  elif [[ "$result" =~ "failed" ]]; then
    log_to_file
  fi
  echo "$other" >> result.log
}

AutoAuto() {
  ConfirmAutoManual
  done=0
  other_command=("adiWatchdogSetSystemRestart" "adiBatSetLowVoltage" "adiBatSetWarningVoltage" )
  for i in "${auto[@]}"; do
    for m in "${other_command[@]}"; do
      if [[ "$i" =~ $m  ]]; then
        other "$m"
        done=1
      fi

    done
    if [ "$done" -eq 0  ]; then
      launch_command "$i"
      compare_result "$result" "passed"
    fi
    done=0

  done
}

#===============================================================
#MAIN
#===============================================================
while true; do
  printf "\n"
  printf "${COLOR_RED_WD}1. ERROR STRING ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. INITIAL ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. SYSTEM INFO ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}4. FPGA FW SHA256 CONFIRM ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}5. AUTO BATCH FILE TEST AUTOMATICALLY ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}6. AUTO BATCH FILE TEST MANUALLY ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    ErrorString
  elif [ "$input" == 2 ]; then
    Initial
  elif [ "$input" == 3 ]; then
    SystemInfo
  elif [ "$input" == 4 ]; then
    FPGA_FW_SHA256
  elif [ "$input" == 5 ]; then
    AutoAuto
  elif [ "$input" == 6 ]; then
    AutoManual
  fi

done
