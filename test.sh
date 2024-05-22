#!/bin/bash
#i=0
#while true; do
##   sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_Battery_PICEventByType
##  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiLibInit
##  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_GetPICEvent_and_CheckPICBatteryVoltage
#  ((i++))
#  echo "i=$i"
#
#  result=$(sudo ./idll-test"$executable" --ADDRESS 1319213 --LENGTH 4 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramAsyncCalculateCRC32Manual)
#  if [[ "$result" =~ "Callback data[CRC]" ]]; then
#    printf "===========================================================pass"
#
#  else
#    printf  "$result"
#    printf "not found"
#    read -p ""
#  fi
#done


#for (( i = 0; i < 15; i++ )); do
#  start /B /wait idll-test --PIN_NUM $i --BLINK 5 --DUTY_CYCLE 31 --BRIGHTNESS 63 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_Drive_SetBlink
##  start /B /wait idll-test --PIN_NUM $i --BLINK 5 --DUTY_CYCLE 31 --BRIGHTNESS 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED_Drive_SetBlink
#done

#for (( i = 1; i < 16777215; i++ )); do
#  m=$((16777215%i))
#  if [ "$m" -eq 0 ]; then
#    echo "$i"
#  fi
#
#done

#l="255/"
#for (( k = 0; k < 5592405; k++ )); do
#   l="$l""255/"
#
#done
#
#echo "$l"
#result="0xE5 FE 60 C5 E1 B7 B8 CF 85 94 84 5D 48 B9 6C 4B C1 2B 2D C8 8D F8 07 EC 81 E0 E5 33 2C CA C8 26 "
#result="e5fe60c5e1b7b8cf8594845d48b96c4bc12b2dc88df807ec81e0e5332ccac826  -"
#length=${#result}
#temp=""
#for (( i = 0; i < length; i=i+2 )); do
#  echo "i=$i"
#  temp="$temp${result:i:2} "
#  echo "$temp"
#
#  if [[ "$temp" =~ "  " ]]; then
#    echo "*********"
#    temp="0x${temp^^}"
#    temp
#    echo "$temp"
#    break
#
#  fi
#done


#echo "${result:0:2}"

#a=$(sudo ./idll-test"$executable" --GPIO_PORT_VAL 1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port | grep -i "adiGpioGetPort" |  sed 's/\\n//g' > test.txt)
#a=$(sudo ./idll-test"$executable" --GPIO_PORT_VAL 1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SA3X_4xGPIO_by_Port > test.txt)
#a=$(cat test.txt)
#echo "a=$a"
#b="adiGpioGetPort(0x11)"
##b="(0x11)"
#if [[ "$a" =~ $b ]]; then
#  echo "$a"
#else
#  echo "$a"
#  echo "not find"
#fi

#for (( i = 0; i < 10; i++ )); do
#  temp=$(shuf -i 0-255 -n 1)
#  data=$data/$temp
##  data=${data:1}
#  alldata[i]="$temp"
##  echo "data=$data"
##  echo "${alldata[@]}"
#  length=${#alldata[@]}
#
#done
#m=0
#while true; do
#  for (( i = 0; i < 2 ; i++ )); do
#    echo "====================================test time= $m===================================="
#    echo "**********************************now read 1wire $i**********************************"
#    sudo ./idll-test"$executable" --dallas-eeprom-write $i:0:$data -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_1Wire_EEPROM_Manual_write
#    result=$(sudo ./idll-test"$executable" --dallas-eeprom-read $i:0:$length -- --EBOARD_TYPE EBOARD_ADi_"$board" --section PIC_1Wire_EEPROM_Manual_read)
#    echo "$result"
#
#    echo "**********************************now compare 1wire $i data**********************************"
#    for (( l = 0; l < length; l++ )); do
#
#      if [[ "$result" =~ ${alldata[$l]} ]]; then
#        echo "Good"
#
#      else
#        echo "Fail"
#        read -p ""
#      fi
#
#    done
#
#    ((m++))
#
#  done
#  printf "\n\n\n\n\n\n\n"
#done
#

#while true; do
##  sensors
#  lscpu | grep -i 'CPU MHz:'
#  sleep 1
#
#done
#while true; do
#
#  re=$(sudo ./idll-test"$executable" --serial-port1 LEC1_COM1 --serial-port2 LEC1_COM2 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_Nullmodem)
#  if [[ "$re" =~ "failed" ]]; then
#    read -p "got error log"
#  fi
#
#  printf "$re"
#
#done
#i=0
#while true; do
#  ((i++))
#  printf "loop=$i"
#  re1=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section LEC1_DO_Brightness [ADiDLL][DO][Brightness])
#  re2=$(sudo ./idll-test"$executable" --LOOP 1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section GPO_LED)
#  if [[ "$re1" =~ "failed" || "$re2" =~ "failed"  ]]; then
#      printf $re1
#      printf $re2
#  fi
#
#done
#while true;do
#  for i in {0..100};do
#
#    sudo ./idll-test"$executable" --PIN_NUM 0 --PERIOD 1000 --DUTY_CYCLE 50 --BRIGHTNESS $i -- --EBOARD_TYPE EBOARD_ADi_SA3X --section GPO_LED_Drive_SetBlink
#
#  done
#done
#exit



write_data_old() {
  local i
  write_data=""
  for i in $(seq 0 16777216); do
#    data="$data/$i"
#    write_data[$i]=$(shuf -i 0-255 -n 1)
#    echo "${write_data[@]}"

    rand="$(shuf -i 0-255 -n 1)"
    write_data+="$rand/"
#    write_data+=$(echo "$rand" | awk '{printf("%c",$1)}')
    echo "$i:$rand" >> dummy_read_03.txt
#    printf "$(shuf -i 0-255 -n 1)\\" >> dummy.txt
    echo "$i"
  done
  printf "$write_data" > dummy_write_03.txt

}

write_data() {
  local i
  write_data=""
  for i in $(seq 0 8388608); do

#  for i in $(seq 0 1048576); do
#    data="$data/$i"
#    write_data[$i]=$(shuf -i 0-255 -n 1)
#    echo "${write_data[@]}"

#    rand="$(shuf -i 0-255 -n 1)"
    rand=$(shuf -e a b c d e f g h i j h l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z -n 1)
    write_data+=$rand
#    write_data+="$(echo "$rand" | awk '{printf("%c",$1)}')"
#    echo "now i=$rand"
#    echo "now acii=$(echo "$rand" | awk '{printf("%c",$1)}')"
    printf "%d\n" "'$rand" >> dummy_read_03.txt
#    echo "i=$i"
#    printf "%d\n" "'$rand"
#    echo "write data=$write_data"
#    printf "$(shuf -i 0-255 -n 1)\\" >> dummy.txt
    echo "$i"
  done
  printf "$write_data" > dummy_write_03.txt

}

write_data
#read -p "aa" type
#mirror=3
#mirror_mode=${type:-$mirror}
#echo "$type"
#echo "$mirror_mode"

#
#size=100
#number=$((4*size))
#read -n $number data < dummy.txt
#readarray -n $size readdata < read_dummy.txt
#
#rr=${readdata[*]}
#rr=$(echo "$rr" | sed 's/\s//g')
#echo "$data"
#echo "abc=$rr" | sed 's/\r/-/g'
#echo "./idll-test"$executable" --sram-write 1:0:$data -- --EBOARD_TYPE EBOARD_ADi_LEC1 --section SRAM_Manual_write"
#./idll-test"$executable" --sram-write 1:0:$data -- --EBOARD_TYPE EBOARD_ADi_LEC1 --section SRAM_Manual_write
#
#
#aa=$(./idll-test"$executable" --sram-read 1:0:$size -- --EBOARD_TYPE EBOARD_ADi_LEC1 --section SRAM_Manual_read | sed 's/\s//g')
#if [[ "$aa" =~ $rr ]]; then
#  echo "good"
#  read -p ""
#fi
#echo "$aa"