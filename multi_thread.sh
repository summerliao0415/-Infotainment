#!/bin/bash
source ./common_func.sh
times=0

loop_time=$(date +%s --date="+12 hour")
file_name="all_tests_auto_EBOARD_ADi_$board.sh"
#file_name="test.txt"
#sed -i 's/"/\\"/g' $file_name

#set start time will make the program pause, until the setting time reach
#input start time format ex. "10/26/21-11" to start setting wait time, or set to 0 to skip the function
#start_time="10/26/21-11"
start_time=0

#to set others=1 will set the other() function launch, if your project support the script
#or just set to =0 to skip the test
others_script=0

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

wait_times() {
  while true; do
    date=$(date '+%D-%k')
    if [[ "$date" =~ $start_time ]]; then
      break
    fi
    sleep 5
    echo $date
    echo 'wait...'

  done
}

act(){
  local ss
  ss=("$@")
  while read line; do
    con=$(echo "$line" | grep -i "idll-test" | grep -v "#\|\"" | sed "s/\r//g")

    if [[ "${#con}" -ne 0 ]]; then
      for script in "${ss[@]}"; do
        # check if the $con include any string in returned array list
        if [[ "$con" =~ $script ]]; then
          echo "$(date +%D-%T)" >> result.log
          launch_command "$con"
          echo "================================================================================================" >> result.log
          echo "$con" >> result.log
          echo "================================================================================================" >> result.log

          if [[ "$result" =~ "failed" ]]; then
            log_to_file
          fi
          echo "$result" >> result.log
        fi
      done
    fi
  done < $file_name

  # check if the array list include the list other_command, and run the function other()
  for scripts in "${ss[@]}"; do
    other_command=("adiWatchdogSetSystemRestart" "adiBatSetLowVoltage" "adiBatSetWarningVoltage" )
    for m in "${other_command[@]}"; do
      if [[ "$scripts" == "$m"  ]]; then
#        echo "ss=${ss[*]}"
#        echo "other=$m"
#        echo "con=$con"
        other "$m"
      fi
    done
  done

}

#====================================================
lEC1_0=("Ext_SPI")
lEC1_1=(" GPO_LED ")
lEC1_2=("HardMeter" "SecMeter")
lEC1_3=("User_LED")
lEC1_4=("HighCurrent_LED")
lEC1_5=("BatteryVoltage" "1Wire" "adiWatchdogSetSystemRestart" "adiBatSetLowVoltage" "adiBatSetWarningVoltage")
lEC1_6=("EEPROM_Auto" )
lEC1_7=("SRAM" )
lEC1_8=("RAWCOM" )
lEC1_9=("RAWCOM" )

SC1X_0=("Ext_SPI")
SC1X_1=("GPO_LED")
SC1X_2=("HardMeter" "SecMeter" "User_LED")
SC1X_3=("Ext_I2C")
SC1X_4=("GPO_LED_Drive")
SC1X_5=("HighCurrent_LED")
SC1X_6=("BatteryVoltage" "1Wire" "adiWatchdogSetSystemRestart" "adiBatSetLowVoltage" "adiBatSetWarningVoltage")
SC1X_7=("EEPROM_Auto" )
SC1X_8=("SRAM" )

if [[ "$start_time" -ne 0 ]]; then
  wait_times
fi

while true; do
  ((times++))
  echo "<<Times=$times>>" >> result.log
  echo "$(date +%D-%T)" >>result.log

  if [[ "$others_script" -ne 0 ]]; then
    other
  fi

  case $board in
  "LEC1")
    act "${lEC1_0[@]}" &
    act "${lEC1_1[@]}" &
    act "${lEC1_2[@]}" &
    act "${lEC1_3[@]}" &
    act "${lEC1_4[@]}" &
    act "${lEC1_5[@]}" &
    act "${lEC1_6[@]}" &
    act "${lEC1_7[@]}" &
    act "${lEC1_8[@]}" &
#    act "${lEC1_9[@]}" &
    wait
    ;;
  "BSEC_BACC")
    .
    ;;
  "SC1X")

    act "${SC1X_0[@]}" &
    act "${SC1X_1[@]}" &
    act "${SC1X_2[@]}" &
    act "${SC1X_3[@]}" &
    act "${SC1X_4[@]}" &
    act "${SC1X_5[@]}" &
    act "${SC1X_6[@]}" &
    act "${SC1X_7[@]}" &
    act "${SC1X_8[@]}" &
    wait
    ;;
  "SA3X")
    .
    ;;
  esac


  if [ "$(date +%s)" -gt "$loop_time" ]; then
    echo "The setting time's up!!"
    echo "The overall test times= $times"
    break
  fi

done

