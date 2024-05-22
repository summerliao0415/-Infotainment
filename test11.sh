#!/bin/bash
COLOR_REST='\e[0m'
COLOR_RED='\e[101m'
COLOR_RED_WD='\e[0;31m'
COLOR_BLUE='\e[104m'
COLOR_RED_WD='\e[0;31m'
COLOR_BLUE_WD='\e[0;34m'
COLOR_YELLOW_WD='\e[93m'
#m=0

#aa=$(sudo ./idll-test -- --EBOARD_TYPE EBOARD_ADi_LEC1 --section Error_String_Message)


#for i in $(seq 0 63); do
#  re=$(sudo ./idll-test --serial-port1 /dev/tty"$i" --serial-port2 /dev/tty"$i" --BAUDRATE 110 --DATABIT 4 --FLOWCTRL 1 --PARITYBIT 1 --STOPBIT 1 --SERIAL_WRITE 5318275781679358691407765605350304812999478327075261097738235411656762136695131351448744798052822084 --READ_LEN 100 --LOOP 1 --READ_INTERVAL 500 -- --EBOARD_TYPE EBOARD_ADi_SA3X --section SerialPort_RW)
##  re=$(sudo ./idll-test --serial-port1 LEC1_COM1 --serial-port2 LEC1_COM1 --BAUDRATE 110 --DATABIT 4 --FLOWCTRL 1 --PARITYBIT 1 --STOPBIT 1 --SERIAL_WRITE 5318275781679358691407765605350304812999478327075261097738235411656762136695131351448744798052822084 --READ_LEN 100 --LOOP 1 --READ_INTERVAL 500 -- --EBOARD_TYPE EBOARD_ADi_LEC1 --section SerialPort_RW)
#  if [[ "$re" =~ "failed" ]]; then
#      echo "i=$i-->fail"
##      echo "$re"
#  else
#    echo "*******************************************************************i=$i**********************************************************************"
##    echo "$re"
#  fi
#
#done

file=$(cat tt.log)
re=$(./idll-test --sram-read 1:0:10 -- --EBOARD_TYPE EBOARD_ADi_SC1X --section SRAM_Manual_read | sed 's/\s//g;s/[0-9]*://g' )
#re=$(./idll-test --sram-read 1:0:1048 -- --EBOARD_TYPE EBOARD_ADi_SC1X --section SRAM_Manual_read | sed 's/\s//g' )
echo "$file"
echo "$re"
if [[ "$re" =~ $file  ]]; then
    echo "pass"
fi