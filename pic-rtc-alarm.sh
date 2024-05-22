#!/bin/bash
source ./common_func.sh
pic_rtc_sync
#===============================================================
#GET PIC EVENT
#===============================================================
PicEvent() {
  while true; do
    print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_GetPICEvent_and_DisplayEventTime"
    sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_GetPICEvent_and_DisplayEventTime

    read -p "[q] to exit, or enter key to loop test PIC event" input
    if [ "$input" == "q" ]; then
      break
    fi

  done
}

#===============================================================
#PIC RTC alarm
#===============================================================

#setting the pic alarm time and compare set and get result, if they are the same
alarm_compare_set_get(){
    # to compare setting alarm time with the result getting value from pic alarm time are correct
    #==============================================================================
    print_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_GET_manual [PIC][RTC][ALARM][MANUAL]"
    pic_alarm_get=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_GET_manual [PIC][RTC][ALARM][MANUAL] )
    echo "$pic_alarm_get"
#    RTC=$(echo "$pic_alarm_get" | grep -i "RTC time" )
    alarm_get_time=$(echo "$pic_alarm_get" | grep -i "rtc alarm")
    alarm_get_time=${alarm_get_time#*Time: }
    alarm_get_time=${alarm_get_time:0:17}
    alarm_set_time=$(echo "$pic_alarm_set" | grep -i 'RTC Alarm set to')
    alarm_set_time=${alarm_set_time#*Time: }
    alarm_set_time=${alarm_set_time:0:17}


    #transfer alarm time/ now pic rtc time to seconds , and then minor both value to confirm the difference if it is the same as setting amount seconds
    #==============================================================================
#    time=$(($(date +%s -d "$Alarm_get_time") - $(date +%s -d "$RTCtime")))

    if [[ "$alarm_set_time" == "$alarm_get_time" ]]; then
      printcolor g "RTC alarm time setting is correct !!"
      msg=(
      "The PIC setting alarm time= $key"
      "The PIC set alarm time=$alarm_set_time"
      "The PIC get alarm time=$alarm_get_time"
      )
      title_list b msg[@]
#      echo "$pic_alarm_get"

    else
      msg=(
      "The PIC setting alarm time= $key"
      "The PIC set alarm time=$alarm_set_time"
      "The PIC get alarm time=$alarm_get_time"
      )
      title_list b msg[@]
      printcolor r "RTC alarm time setting is failed comparing to RTC alarm getting time !!"
      read -p ""
    fi
}

DifferentialTime(){
  time=$key
  if [[ "$key" =~ "/"  ]]; then
    year=$(echo "$time" | sed 's/\/[0-9]\{0,2\}//g')
    month=$(echo "$time" | sed 's/[0-9]\{3,4\}\///g' | sed 's/\/[0-9]*//g')
    day=$(echo "$time" | sed 's/[0-9]\{3,4\}\/[0-9]\{1,2\}\///g' | sed 's/\/[0-9]*//g')
    hour=$(echo "$time" | sed 's/[0-9]\{3,4\}\/[0-9]\{1,2\}\/[0-9]\{1,2\}\///g' | sed 's/\/[0-9]*//g')
    minute=$(echo "$time" | sed 's/[0-9]\{3,4\}\/[0-9]\{1,2\}\/[0-9]\{1,2\}\/[0-9]\{1,2\}\///g' | sed 's/\/[0-9]*//g')
    second=$(echo "$time" | sed 's/[0-9]\{3,4\}\///g' | sed 's/[0-9]\{1,2\}\///g')
#    echo "$year-$month-$day $hour:$minute:$second"
    now=$(date +"%s")
    future=$(date -d "$year-$month-$day $hour:$minute:$second" +"%s")
    echo $((future-now))
  else
    echo "$key"
  fi

}

PicRTCSet(){
  printcolor r "Type [second value] only or the [complete time format] to test alarm trigger"
  printcolor r "e.g. complete time= 2022/02/08/14/35/20 (year/month/day/hour/minute/second)"
  read -p "Setting time =  " key

  printcolor r "Set alarm behavior setting"
  printcolor r "Type 0: only event/ 1: power button trigger"
  read -p "Trigger mode= " input

  if [[ "$key" =~ "/"  ]]; then
    launch_command "./idll-test"$executable" --pic-time $key -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    pic_alarm_set="$result"
  else
    launch_command "sudo ./idll-test"$executable" --pic-alarm_seconds $key -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    pic_alarm_set="$result"

  fi

}

PicRtcAlarm(){
  title b "Setting PIC RTC Alarm"
  confirm_pic_message "rtc_alarm" "newest_unread" "all" ""

  while true; do
    PicRTCSet
#    printcolor r "Type waiting second before alarm trigger"
#    read -p "Seconds=  " key
#
#    printcolor r "Set alarm behavior setting"
#    printcolor r "Type 0: only event/ 1: power button trigger"
#    read -p "Trigger mode= " input
#
#
#    print_command "sudo ./idll-test"$executable" --pic-alarm_seconds $key -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
#    pic_alarm_set=$(sudo ./idll-test"$executable" --pic-alarm_seconds $key -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL])
#    echo "$pic_alarm_set"

    print_command "sudo ./idll-test"$executable" --rtc-alarm-conf $input -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_CONF_SET_manual [PIC][RTC][ALARM][MANUAL]"
    sudo ./idll-test"$executable" --rtc-alarm-conf $input -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_CONF_SET_manual [PIC][RTC][ALARM][MANUAL]

    title b "Confirm if RTC alarm time setting is correct..."
    alarm_compare_set_get

    #confirm the differential between user input time and now time by the function DifferentialTime()
    second=$(DifferentialTime)
    second=$((second+5))
    if [[ "$second" -lt 0 ]]; then
      second=1
    fi
    title b "Now Counting down $second seconds to trigger alarm time..."
    for (( i = 0; i < second; i++ )); do
        sleep 1
        printcolor r "\r$i.."
    done

    #confirm alarm config setting if both setting/getting match
    #==============================================================================
    title b "Get PIC alarm behavior setting"
    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_CONF_GET_manual [PIC][RTC][ALARM][MANUAL]"
    compare_result "$result" "Current RTC Alarm Configuration is '$input'"

    #check if the trigger time match the setting alarm time from pic eventq
    #==============================================================================
    title b "Now will confirm if event exists and date time match the one been setting before."

    #to get how many event related to rtc alarm
    confirm_pic_message "rtc_alarm" "newest_unread" "255" ""

    pic_alarm_get=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_RTC_ALARM_GET_manual [PIC][RTC][ALARM][MANUAL])

    if [[ "$pic_log_filter_amount" -eq 0 ]]; then
      title r "There is no any PIC Alarm event triggered"
      read -p ""
    else
      for (( i = 0; i < pic_log_filter_amount; i++ )); do
        result=$(confirm_pic_message "rtc_alarm" "newest_unread" "0" "")
        printcolor w "$result"
        pic_catch_content=$(echo "$result" | grep "Time")
        picevent_alarmtime=${pic_catch_content:8:17}

        if [[ "$alarm_get_time" == "$picevent_alarmtime" ]]; then
          mesg=(
          "The PIC event time: $picevent_alarmtime"
          "The PIC Alarm expected time: $alarm_get_time"
          )
          title_list b mesg[@]
          printcolor y "Alarm time VS. PIC trigger event match!!!"
        else
          mesg=(
          "The PIC event time: $picevent_alarmtime"
          "The PIC Alarm expected time: $alarm_get_time"
          )
          title_list b mesg[@]

          printcolor b "$pic_alarm_get"
          printcolor b "$result"
          printcolor y "Found alarm event!! But the alarm time getting from PIC can't match the setting alarm time!!"
          read -p "Confirm above list to check what's different..."
        fi
      done
    fi

    read -p "q to exit loop RTC alarm test, or enter to repeat test: " leave
    if [ "$leave" == "q" ]; then
      break
    fi
  done
}



#===============================================================
#PIC RTC alarm callback
#===============================================================
PicRtcAlarm_Callback() {
  while true; do
    title b "Setting PIC RTC Alarm (callback)"
    printcolor w "Set alarm behavior setting"
    printcolor w "type 0: only event/ 1: power button trigger"
    read -p "trigger mode= " config

    printcolor w "Set alarm time"
    read -p "seconds= " time

    print_command "sudo ./idll-test"$executable" --rtc-alarm-conf $config --pic-alarm_seconds $time -- --EBOARD_TYPE EBOARD_ADi_"$board" --section Callback_PIC_RtcAlarm_Manual [CALLBACK][PIC][MANU]"
    sudo ./idll-test"$executable" --rtc-alarm-conf $config --pic-alarm_seconds $time -- --EBOARD_TYPE EBOARD_ADi_"$board" --section Callback_PIC_RtcAlarm_Manual [CALLBACK][PIC][MANU]

    read -p "[q] to exit loop RTC alarm callback test, or enter key to repeat test " leave

    if [ "$leave" == "q" ]; then
      break
    fi
  done
}

BadParameter(){

  command_line=(
    "./idll-test"$executable" --pic-time 2100/03/31/01/02/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 1999/03/31/01/02/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 2022/a/15/01/02/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 2022/12/b/01/02/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 2022/12/15/c/02/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 2022/12/15/02/d/03 -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
    "./idll-test"$executable" --pic-time 2022/12/15/02/12/e -- --EBOARD_TYPE EBOARD_ADi_$board --section PIC_RTC_ALARM_SET_manual [PIC][RTC][ALARM][MANUAL]"
  )

  for command in "${command_line[@]}";do
    launch_command "$(echo "$command")"
    compare_result "$result" "failed" "skip"
  done
}

#===============================================================
#MAIN
#===============================================================
while true; do
  printf "\n"
  printf "${COLOR_RED_WD}1. GET PIC EVENT${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. PIC RTC ALARM  ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. PIC RTC ALARM CALLBACK ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}4. BAD PARAMETER ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    PicEvent
  elif [ "$input" == 2 ]; then
    PicRtcAlarm
  elif [ "$input" == 3 ]; then
    PicRtcAlarm_Callback
  elif [ "$input" == 4 ]; then
    BadParameter

  fi

done
