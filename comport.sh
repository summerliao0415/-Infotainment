#!/bin/bash
source ./common_func.sh

re=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name)
com_amount=$(echo "$re" | grep -i portcount | sed 's/\s//g')
com_amount=${com_amount#adi*:}
for ((i = 0; i < com_amount; i++)); do
  port_name=$(echo "$re" | grep -i "PortIndex = $i,")
  port_name=$(echo "$port_name" | sed 's/\r//g')
  com_list_amount[$i]=${port_name##adi*= }
done

#===============================================================
#com port test on each supported feature
#===============================================================
#randam generate data content for feature usage
number_random() {
  for ((i = 0; i < $1; i++)); do
    re=$(shuf -i 0-9 -n 1)
    #    echo "$re"
    number=$number$re
  done
  echo $number
}

#com_list=("LEC1_COM1" "LEC1_COM2")
if [[ "$os" =~ "Microsoft" ]]; then
  baudrate=("110" "300" "600" "1200" "2400" "4800" "9600" "14400" "19200" "38400" "57600" "115200")
else
  baudrate=("110" "300" "600" "1200" "2400" "4800" "9600" "19200" "38400" "57600" "115200")
fi
#baudrate=("110" "1200" "2400" "4800" "9600" "14400" "19200" "38400" "56000" "57600" "115200")
baudrate_default=115200
databit=("2" "3" "4")
databit_default=4
flowctrl=("1" "2")
flowctrl_default=1
paritybit=("1" "2" "3" "4" "5")
paritybit_default=1
stopbit=("1" "2")
stopbit_default=1
read_interval_default=3000
read_len=("1" "10" "15" "21" "99" "251" "255")
read_len_default=100
data_default=$(number_random read_len_default)

###################################################
#mdb
###################################################
mdb(){
  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name
  local port1 port2
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??'"
  printcolor w "Input com port 1 name you need to test"
  read -p "Port 1 Index = " port1
  printcolor w "Input com port 2 name you need to test"
  read -p "Port 2 Index = " port2

  port1=${port1:-0}
  port1_number=${com_list_amount[$port1]}
  port2=${port2:-1}
  port2_number=${com_list_amount[$port2]}
  printcolor w "Now connect com port:($port1_number) with com port:($port2_number) by null cable."

  for ((i=0;i<10;i++));do
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_MDB_Nullmodem"
    compare_result "$result" "passed"
  done

}


###################################################
#set/get time out
###################################################

Time_out() {
  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??'"
  printcolor w "Input com port 1 name you need to test"
  read -p "Port 1 Index = " port1
  printcolor w "Input com port 2 name you need to test"
  read -p "Port 2 Index = " port2

  printcolor w "Now connect com port:($port1) with com port:($port2) by null cable."

  port1=${port1:-0}
  port1_number=${com_list_amount[$port1]}
  port2=${port2:-1}
  port2_number=${com_list_amount[$port2]}

  write_constant=(5000 500 5 0)
  write_mulplier=(500 50 5 0)
  read_constant=(5000 500 5 0)
  read_mulplier=(500 50 5 0)
  read_interval=(50 0)

  #Normal Test
  ###############################
  for value in ${read_constant[*]}; do
    title b "Read Time Out Constant getting/setting test : $value ms"
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC $value --RTM 0 --WTTC 0 --WTTM 0 -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW "
    compare_result "$result" "All tests passed"
    compare_result "$result" "Get ReadTotalTimeoutConstant setting: $value"
  done

  for value in ${read_mulplier[*]}; do
    title b "Read Time Out Mulplier getting/setting test : $value ms"
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC 0 --RTM $value --WTTC 0 --WTTM 0 -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW"
    compare_result "$result" "All tests passed"
    compare_result "$result" "Get ReadTotalTimeoutMultiplier setting: $value"
  done

  for value in ${read_interval[*]}; do
    title b "Read Time Out Interval getting/setting test : $value ms"
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT $value --RTTC 0 --RTM 0 --WTTC 0 --WTTM 0 -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW"
    compare_result "$result" "All tests passed"
    compare_result "$result" "Get ReadIntervalTimeout setting: $value"
  done

  for value in ${write_constant[*]}; do
    title b "Write Time Out Constant getting/setting test : $value ms"
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC 0 --RTM 0 --WTTC $value --WTTM 0 -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW "
    compare_result "$result" "All tests passed"
    compare_result "$result" "Get WriteTotalTimeoutConstant setting: $value"
  done

  for value in ${write_mulplier[*]}; do
    title b "Write Time Out Mulplier getting/setting test : $value ms"
    launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC 0 --RTM 0 --WTTC 10 --WTTM $value -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW"
    compare_result "$result" "All tests passed"
    compare_result "$result" "Get WriteTotalTimeoutMultiplier setting: $value"
  done

  #Test without cable
  ###############################
  title b "Now will Test w/o null cable, Please remove connection cable."
  title r "Be noted!! If no any message return, after 10 sec. It should be considered as failed."
  read -p "Press enter, when you are ready."

  for mode in "constant" "mulplier"; do

    #    before=$(date '+%s')
    case $mode in
    "constant")
      title b "Read Time Out Constant getting/setting test : ${read_constant[0]} ms"
      launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC ${read_constant[0]} --RTM 0 --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW "
      compare_result "$result" "failed"

      title b "Write Time Out Constant getting/setting test : ${write_constant[0]} ms"
      launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC ${write_constant[0]} --RTM 0 --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW "
      compare_result "$result" "failed"
      ;;
    "mulplier")
      title b "Read Time Out Mulplier getting/setting test : ${read_mulplier[0]} ms"
      launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC 0 --RTM ${read_mulplier[0]} --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      compare_result "$result" "failed"

      title b "Write Time Out Mulplier getting/setting test : ${write_mulplier[0]} ms"
      launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT 0 --RTTC 0 --RTM ${write_mulplier[0]} --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      compare_result "$result" "failed"
      ;;
      #    "interval")
      #        title b "Read Time Out Mulplier getting/setting test : ${read_mulplier[0]} ms"
      #        launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT ${read_interval[0]}  --RTTC 0 --RTM $0 --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      #        compare_result "$result" "failed"
      ##        after=$(date '+%s')
      #      ;;

    esac

    #    amount=$after-$before
    #    if [[ "$amount" -lt 3 || "$amount" -gt 7 ]]; then
    #      title r "Test fail, because the process time is > 7 seconds or < 3 seconds"
    #      read -p ""
    #    fi

  done
  #test with timeout item RIT
  #=========================================================
  title b "Read Time Out Interval getting/setting test : ${read_interval[0]} ms"
  printcolor r "Note: DUT will wait until first byte is received, so it's normal behavior, while DUT has no response."
  printcolor r "Note: So press Ctrl+c to cancel the test, after 10 seconds waiting behavior."
  launch_command "./idll-test$executable --serial-port1 $port1_number --serial-port2 $port2_number --RIT ${read_interval[0]}  --RTTC 0 --RTM $0 --WTTC 0 --WTTM 0  -- --EBOARD_TYPE EBOARD_ADi_$board --section SerialPort_RW"

}

###################################################
#basic info
###################################################
Com_port_info() {
  launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name"
  compare_result "$result" "passed"

}
###################################################
#Testing with all feature
###################################################
Feature() {

  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name
  printcolor w "Now connect each com port with loopback."
  printcolor w "Input com port number you need to test, or Enter to test all"
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??', if you choose to test the single port."
  read -p "PortIndex = " input
  input=${input:-"all"}

  #  board_name=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiLibInit)
  #  if [[ "$board_name" =~ "LEC1"  ]]; then
  #    port1="LEC1_COM""$port1"
  #    port2="LEC1_COM""$port2"
  #  else
  #    port1="COM""$port1"
  #    port2="COM""$port2"
  #  fi

  if [ "$input" != "all" ]; then
    com_list=("${com_list_amount[input]}")
  else
    com_list=("${com_list_amount[*]}")
  fi

  title b "Going to test the com port as below list, please confirm."
  echo "${com_list[@]}"
  read -p ""

  title b "Testing with BAUDRATE"
  for list in ${baudrate[*]}; do
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "Com Port: $com"
        "Baud rate: $list"
        "Data: $data_default"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test$executable --serial-port1 $com --serial-port2 $com --BAUDRATE $list --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "baudrate" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "baudrate=$list"
    done
  done

  #Testing with DATABIT
  ###################################################
  title b "Testing with DATABIT"

  for list in ${databit[*]}; do
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "Com Port: $com"
        "Databit: $list"
        "Data: $data_default"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test$executable --serial-port1 $com --serial-port2 $com --BAUDRATE $baudrate_default --DATABIT $list --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "databit" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "databit=$list"
    done
  done

  #Testing with flowctrl
  ##################################################
  title b "Testing with FLOWCTRL"

  for list in ${flowctrl[*]}; do
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "com port: $com"
        "Flowctrl: $list"
        "Data: $data_default"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test"$executable" --serial-port1 $com --serial-port2 $com --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $list --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "flowctrl" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "flowCtrl=$list"
    done
  done

  #Testing with paritybit
  ###################################################
  title b "Testing with PARITYBIT"

  for list in ${paritybit[*]}; do
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "Com Port: $com"
        "Paritybit: $list"
        "Data: $data_default"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test$executable --serial-port1 $com --serial-port2 $com --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $list --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "parity" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "parity=$list"
    done
  done

  #Testing with stopbit
  ###################################################
  title b "Testing with STOPBIT"

  for list in ${stopbit[*]}; do
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "Com Port: $com"
        "Stopbit: $list"
        "Data: $data_default"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test"$executable" --serial-port1 $com --serial-port2 $com --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $list --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "stopbit" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "stopbit=$list"
    done
  done

  #Testing with different data length
  ###################################################
  title b "Testing with DATA length"

  for list in ${read_len[*]}; do
    data=$(number_random list)
    for com in ${com_list[*]}; do
      printf "Com port Test setting:"
      mesg=(
        "Com Port: $com"
        "Data: $data"
        "Data length:$list"
      )
      title_list b mesg[@]

      launch_command "sudo ./idll-test"$executable" --serial-port1 $com --serial-port2 $com --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data --READ_LEN $list --LOOP 1 --READ_INTERVAL 1000 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      #    result00=$(echo "$result" | grep -i "stopbit" | sed 's/\s//g')
      compare_result "$result" "passed"
      #    compare_result "$result00" "stopbit=$list"
    done
  done
}

swap(){
  tmp=$input01
  input01=$input02
  input02=$tmp
}

###################################################
#Testing with all MDB feature
###################################################
FeatureMdb() {

  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name
  printcolor w "Now connect each com port with loopback."
  printcolor w "Input 1st com port number you need to test, or Enter to test all"
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??', if you choose to test the single port."
  read -p "PortIndex = " input001
  printcolor w "Input 2nd com port number you need to test, or Enter to test all"
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??', if you choose to test the single port."
  read -p "PortIndex = " input002

  input01=${com_list_amount[input001]:?"You don't choose any port!!"}
  input02=${com_list_amount[input002]:?"You don't choose any port!!"}


  title b "Going to test the com port as below list, please confirm."
  echo "$input01 , $input02"
  read -p ""

  #Testing with Baudrate
  ###################################################
  title b "Testing with BAUDRATE"
  for list in ${baudrate[*]}; do
    printf "Com port Test setting:"
    mesg=(
      "Com Port: $input01 , $input02"
      "Baud rate: $list"
      "Data: $data_default"
    )
    title_list b mesg[@]

    for i in $(seq 2); do
      launch_command "sudo ./idll-test$executable --serial-port1 $input01 --serial-port2 $input02 --BAUDRATE $list --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT 6 --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "baudrate" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "baudrate=$list"
      #swap input01/input02 and then test again
      swap
    done

  done

  #Testing with DATABIT
  ###################################################
  title b "Testing with DATABIT"

  for list in ${databit[*]}; do
    printf "Com port Test setting:"
    mesg=(
      "Com Port: $input01 , $input02"
      "Databit: $list"
      "Data: $data_default"
    )
    title_list b mesg[@]

    for i in $(seq 2); do
      launch_command "sudo ./idll-test$executable --serial-port1 $input01 --serial-port2 $input02 --BAUDRATE $baudrate_default --DATABIT $list --FLOWCTRL $flowctrl_default --PARITYBIT 6 --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "databit" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "databit=$list"
      #swap input01/input02 and then test again
      swap
    done

  done



  #Testing with flowctrl
  ##################################################
  title b "Testing with FLOWCTRL"

  for list in ${flowctrl[*]}; do
    printf "Com port Test setting:"
    mesg=(
      "com port: $input01 , $input02"
      "Flowctrl: $list"
      "Data: $data_default"
    )
    title_list b mesg[@]

    for i in $(seq 2); do
      launch_command "sudo ./idll-test"$executable" --serial-port1 $input01 --serial-port2 $input02 --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $list --PARITYBIT 6 --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "flowctrl" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "flowCtrl=$list"
      #swap input01/input02 and then test again
      swap
    done

  done



  #Testing with stopbit
  ###################################################
  title b "Testing with STOPBIT"

  for list in ${stopbit[*]}; do
    printf "Com port Test setting:"
    mesg=(
      "Com Port: $input01 , $input02"
      "Stopbit: $list"
      "Data: $data_default"
    )
    title_list b mesg[@]

    for i in $(seq 2); do
      launch_command "sudo ./idll-test"$executable" --serial-port1 $input01 --serial-port2 $input02 --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT 6 --STOPBIT $list --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      result00=$(echo "$result" | grep -i "stopbit" | sed 's/\s//g')
      compare_result "$result" "passed"
      compare_result "$result00" "stopbit=$list"
      #swap input01/input02 and then test again
      swap
    done

  done

  #Testing with different data length
  ###################################################
  title b "Testing with DATA length"

  for list in ${read_len[*]}; do
    data=$(number_random list)
    printf "Com port Test setting:"
    mesg=(
      "Com Port: $input01 , $input02"
      "Data: $data"
      "Data length:$list"
    )
    title_list b mesg[@]

    for i in $(seq 2); do
      launch_command "sudo ./idll-test"$executable" --serial-port1 $input01 --serial-port2 $input02 --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT 6 --STOPBIT $stopbit_default --SERIAL_WRITE $data --READ_LEN $list --LOOP 1 --READ_INTERVAL 1000 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
      compare_result "$result" "passed"
      #swap input01/input02 and then test again
      swap
    done

  done
}


###################################################
#prot to port
###################################################
PortToPort() {
  sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_GetPort_Num_Name
  printcolor r "Please refer above list, input the port index number as listed above as 'PortIndex= ??'"
  printcolor w "Input com port 1 name you need to test"
  read -p "Port 1 Index = " port1_number
  printcolor w "Input com port 2 name you need to test"
  read -p "Port 2 Index = " port2_number
  printcolor w "How many loop you need to test: (at least 10)"
  read -p "" loop

  printcolor w "Now connect com port:($port1) with com port:($port2) by null cable."
  loop=${loop:-10}
  port1_number=${port1_number:-0}
  port2_number=${port2_number:-1}

  port1=${com_list_amount[port1_number]}
  port2=${com_list_amount[port2_number]}

  for ((i = 0; i < loop; i++)); do

    printf "Com Port Test setting:"
    mesg=(
      "Comport 1 : $port1"
      "Comport 2 : $port2"
      "Input Data: $data_default"
      "READ_LEN: $read_len_default"
      "READ_INTERVAL: $read_interval_default"
      "BAUDRATE: $baudrate_default"
      "DATABIT: $databit_default"
      "FLOWCTRL: $flowctrl_default"
      "PARITYBIT: $paritybit_default"
      "STOPBIT: $stopbit_default"
    )
    title_list b mesg[@]
    launch_command "sudo ./idll-test"$executable" --serial-port1 $port1 --serial-port2 $port2 --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
    compare_result "$result" "passed"

  done

  port1=${com_list_amount[port2_number]}
  port2=${com_list_amount[port1_number]}
  for ((i = 0; i < loop; i++)); do

    printf "Com Port Test setting:"
    mesg=(
      "Comport 1 : $port1"
      "Comport 2 : $port2"
      "Input Data: $data_default"
      "READ_LEN: $read_len_default"
      "READ_INTERVAL: $read_interval_default"
      "BAUDRATE: $baudrate_default"
      "DATABIT: $databit_default"
      "FLOWCTRL: $flowctrl_default"
      "PARITYBIT: $paritybit_default"
      "STOPBIT: $stopbit_default"
    )
    title_list b mesg[@]
    launch_command "sudo ./idll-test"$executable" --serial-port1 $port1 --serial-port2 $port2 --BAUDRATE $baudrate_default --DATABIT $databit_default --FLOWCTRL $flowctrl_default --PARITYBIT $paritybit_default --STOPBIT $stopbit_default --SERIAL_WRITE $data_default --READ_LEN $read_len_default --LOOP 1 --READ_INTERVAL $read_interval_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SerialPort_RW"
    compare_result "$result" "passed"

  done
  unset port1 port2 loop
}

PinFeature() {
  printcolor w "Input com port number (1,2):"
  read -p "" port
  port=${port:-1}
  port="LEC1_COM""$port"

  if [[ "$port" =~ "COM1" ]]; then
    mask_default=3
    set_signal_default=3
  else
    mask_default=1
    set_signal_default=1
  fi

  title b "Start setting pin."
  for ((i = 0; i < $((set_signal_default + 1)); i++)); do

    printf "Com port pin test setting:"
    mesg=(
      "Mask: $mask_default"
      "Signal value: $i"
    )

    title_list b mesg[@]
    launch_command "sudo ./idll-test"$executable" --serial-port $port --signal-mask $mask_default --signal-value $i -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiSerialSetSignal [ADiDLL][LEC1][RAWCOM][SIGNAL]"
    compare_result "$result" "signal=0x$i"
    compare_result "$result" "mask=0x$mask_default"

    title b "Confirm each pin status"
    launch_command "sudo ./idll-test"$executable" --serial-port $port -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiSerialGetSignal [ADiDLL][LEC1][RAWCOM][SIGNAL]"

    case $i in
    0)
      compare_result "$result" "RTS: 0"
      compare_result "$result" "CTS: 0"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 0"
        compare_result "$result" "DSR: 0"
        compare_result "$result" "DCD: 0"
        compare_result "$result" "RI : 0"
      fi

      ;;
    1)
      compare_result "$result" "RTS: 1"
      compare_result "$result" "CTS: 1"
      if [[ "$port" =~ "COM1" ]]; then

        compare_result "$result" "DTR: 0"
        compare_result "$result" "DSR: 0"
        compare_result "$result" "DCD: 0"
        compare_result "$result" "RI : 0"
      fi
      ;;
    2)
      compare_result "$result" "RTS: 0"
      compare_result "$result" "CTS: 0"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 1"
        compare_result "$result" "DSR: 1"
        compare_result "$result" "DCD: 1"
        compare_result "$result" "RI : 1"
      fi
      ;;
    3)
      compare_result "$result" "RTS: 1"
      compare_result "$result" "CTS: 1"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 1"
        compare_result "$result" "DSR: 1"
        compare_result "$result" "DCD: 1"
        compare_result "$result" "RI : 1"
      fi
      ;;
    esac
  done

  title b "Start setting MASK value."
  for ((i = 0; i < $((mask_default + 1)); i++)); do

    printf "Com port pin test setting:"
    mesg=(
      "Mask: $i"
      "Signal value: $set_signal_default"
    )
    title_list b mesg[@]

    #reset each pin status before mask task
    sudo ./idll-test"$executable" --serial-port $port --signal-mask $mask_default --signal-value 0 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiSerialSetSignal [ADiDLL][LEC1][RAWCOM][SIGNAL]
    #start to test mask value
    launch_command "sudo ./idll-test"$executable" --serial-port $port --signal-mask $i --signal-value $set_signal_default -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiSerialSetSignal [ADiDLL][LEC1][RAWCOM][SIGNAL]"

    compare_result "$result" "signal=0x$set_signal_default"
    compare_result "$result" "mask=0x$i"

    title b "Confirm each pin status"
    launch_command "sudo ./idll-test"$executable" --serial-port $port -- --EBOARD_TYPE EBOARD_ADi_"$board" --section adiSerialGetSignal [ADiDLL][LEC1][RAWCOM][SIGNAL]"

    case $i in
    0)
      compare_result "$result" "RTS: 0"
      compare_result "$result" "CTS: 0"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 0"
        compare_result "$result" "DSR: 0"
        compare_result "$result" "DCD: 0"
        compare_result "$result" "RI : 0"
      fi

      ;;
    1)
      compare_result "$result" "RTS: 1"
      compare_result "$result" "CTS: 1"
      if [[ "$port" =~ "COM1" ]]; then

        compare_result "$result" "DTR: 0"
        compare_result "$result" "DSR: 0"
        compare_result "$result" "DCD: 0"
        compare_result "$result" "RI : 0"
      fi
      ;;
    2)
      compare_result "$result" "RTS: 0"
      compare_result "$result" "CTS: 0"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 1"
        compare_result "$result" "DSR: 1"
        compare_result "$result" "DCD: 1"
        compare_result "$result" "RI : 1"
      fi
      ;;
    3)
      compare_result "$result" "RTS: 1"
      compare_result "$result" "CTS: 1"
      if [[ "$port" =~ "COM1" ]]; then
        compare_result "$result" "DTR: 1"
        compare_result "$result" "DSR: 1"
        compare_result "$result" "DCD: 1"
        compare_result "$result" "RI : 1"
      fi
      ;;
    esac

  done

}

#===============================================================
#MAIN
#===============================================================
while true; do
  printf "\n"
  printf "${COLOR_RED_WD}1. COM PORT FUNCTION (LOOPBACK) ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}2. PORT TO PORT TEST ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}3. COM PORT / RAW COM FULL PIN TEST (LEC1) ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}4. COM PORT INFO ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}5. COM PORT TIME OUT SETTING ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}6. COM PORT FUNCTION (MDB)(PORT TO PORT) ${COLOR_REST}\n"
  printf "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    Feature
  elif [ "$input" == 2 ]; then
    PortToPort
  elif [ "$input" == 3 ]; then
    PinFeature
  elif [ "$input" == 4 ]; then
    Com_port_info
  elif [ "$input" == 5 ]; then
    Time_out
  elif [ "$input" == 6 ]; then
    FeatureMdb
  fi

done
