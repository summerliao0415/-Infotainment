#!/bin/bash
source ./common_func.sh

sram_info(){
  #before process , it needs to reset sram mirror as none mirror
  temp=$(sudo ./idll-test"$executable" --sram-read 1:0:1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_read)

  #display how many bank
#  bank=$(sudo ./idll-test"$executable" --SOURCE_BANK 0x0 --DEST_BANK 0x1 --ADDRESS 0x0 --LENGTH 0x1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCompareManual | grep -i "sram bank" | sed 's/SRAM Bank\[Number:Size\]\=\[0x//g' | sed 's/:0x[0-9]*]//g' | sed 's/\s//g')
  bank_amount=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Capacity | grep -i "sram bank count" | sed 's/\s//g;s/.*://g')

  #display each bank capacity in hex unit
#  bank_capacity_hex=$(sudo ./idll-test"$executable" --SOURCE_BANK 0x0 --DEST_BANK 0x1 --ADDRESS 0x0 --LENGTH 0x1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCompareManual | grep -i "sram bank" | sed 's/SRAM Bank\[Number:Size\]\=\[0x//g' | sed 's/[0-9]:0x//g' | sed 's/\]//g' | sed 's/\s//g')
  bank_capacity_hex=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Capacity | grep -i "sram bank size" | sed 's/\s//g;s/.*://g' )
  bank_capacity_hex=$(echo "obase=16;$bank_capacity_hex"|bc)
#  echo "$bank_capacity_hex"

  #incase if the project doesn't support to provide each bank info, it nees manual input info.
  if [[ "$bank_capacity_hex" == "" && "$bank_amount" == "" ]]; then
    echo "looks like some idlls are NOT supported for providing bank info, please input each bank capacity"
    echo "Note: Do NOT input '0x' strings, only number in HEX format (ex. 7ffff):"
    read -p "" capacity
    echo ""
    echo "Please input how many bank is supported: "
    read -p "" amount
    status="true"
    bank_capacity_hex=$capacity
    bank_amount=$amount
    address_dec=$((16#$bank_capacity_hex))
  fi

  #display sram capacity in dec unit
  address=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Capacity | grep -i 'SRAM size' | sed 's/\s//g;s/.*://g')

  #display bank capacity for each bank in dec format
  address_dec=$((16#$bank_capacity_hex))

  bank_address=""
#  echo "bankamount=$bank_amount"
  for (( p = 0; p < bank_amount; p++ )); do
    bank_address[$p]=$((address_dec*p))
  done

  #bank address list for some function usage
#  bank_address=(${bank_address_list[@]})
  echo "Each SRAM bank first address = ${bank_address[*]}"
  #input how many SRAM size
  totalsize=$address

}

sram_info
#organize a data list in random format for further usage
write_data

#===============================================================
#SRAM sync/vsync test
#===============================================================
SramSyncVsync_Repeat(){
  local i
  title b "Auto test sync/vsync date test (repeat 10 times)"
  read -p ""

  for (( i = 0; i < 10; i++ )); do
    title b "Async/sync sram test (repeat 10 times)"
#    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section ASYNC_SRAM"
    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_AutoVerify"
    verify_result "$result"
    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_BankCopy"
    verify_result "$result"
    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_BankCompare"
    verify_result "$result"
    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_CalculateCRC32"
    verify_result "$result"

    if [ "$status" == "fail" ]; then
      break
    fi

  done

}
#===============================================================
#SRAM auto test with random/same pattern data
#===============================================================
SramAutoRandomSame(){
  title b "Auto test with same/random date test (repeat 10 times)"
  read -p "enter key to test..."

  for (( i = 0; i < 10; i++ )); do
    title b "Same/random pattern date test (repeat 10 times)"
    title b "times= $i"

    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Same_Pattern_0xA5"
    verify_result "$result"

    launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Random_Pattern"
    verify_result "$result"

    if [ "$status" == "fail" ]; then
      break
    fi

  done

}
#===============================================================
#SRAM capacity check
#===============================================================
SramCapacity(){
#  sram_info
  title b "SRAM capacity check, while set it sram in mirror 1"
  launch_command "sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Capacity"
#  sram_info
  printcolor y "sram size = $totalsize"
  printcolor y "sram bank amount = $bank_amount"
  printcolor y "sram each bank size = $address_dec"

  if [[ "$result" =~ $totalsize ]]; then
    printf  "\n${COLOR_YELLOW_WD}SRAM capacity PASS ${COLOR_REST}\n"

  else
    printf  "\n${COLOR_RED_WD}SRAM capacity is incorrect as setting SRAM = $sram_size, please check your DUT. ${COLOR_REST}\n"
    read -p ""
  fi
}



#===============================================================
#writing data in wrong address based on mirror mode maximum address to add extra 1 byte
#===============================================================
write_wrong_address(){
  echo ""
  #set up the third bank, because it is used only front 2 banks for mirror mode, no matter how the mirror 1 or 3 is.
  address=${bank_address[2]}
  title b "Now read the address out of the define in mode$1 : $address"
  launch_command "sudo ./idll-test"$executable" --sram-read $1:$address:1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_read"
  compare_result "$result" "failed"

  echo ""
  title b "Now write the address out of the define in mode$1 : $address"
  launch_command "sudo ./idll-test"$executable" --sram-write $1:$address:255 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_write"
  compare_result "$result" "failed"
}
#===============================================================
#sram bank info
#===============================================================
Bank_Info(){
  echo ""
  printcolor b "SRAM bank amount = $bank_amount"
  printcolor b "SRAM bank size = $address_dec"
}

#===============================================================
#new sram mirror test
#===============================================================
Sram_Mirror_Write(){

  local mirror_mode multiple size address file start_address temp
  mirror_mode=$1
  multiple=$2
  size=$3
  address=$4
  file=$5
  echo "totalsize=$totalsize"
  sram_size=$((totalsize/multiple))
  size_mes="SRAM size: $sram_size"
  if [[ "$file" =~ "txt" ]]; then
    launch_command "./idll-test$executable --sram-write $mirror_mode:$address:$file:$size -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_write"
  else
#    clear the data in _file first, preventing previous data storing in memory, start from squire every time.
    _file=""
    for (( i = 0; i < size; i++ )); do
      _file+="$file/"
    done
    launch_command "./idll-test$executable --sram-write $mirror_mode:$address:$_file -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_write"

  fi

  if [[ "$result" =~ $size_mes ]]; then
    title b  "Sram capacity check PASS"
  else
    title r  "Sram capacity check FAIL"
    title r  "Expected size: $size_mes"
#        echo "$result"
    read -p ""
  fi

  compare_result "$result" "mirror mode: $mirror_mode"
}

Sram_Mirror_Read(){
  local read_data size address mode file read_from_sram
  size=$3
  mode=$1
  address=$2
  file=$4

  readarray -n $size readdata < "$file"
  read_data=${readdata[*]}
  read_data=$(echo "$read_data" | sed 's/\s//g;s/[0-9]*://g;/^$/d')

  result=$(./idll-test"$executable" --sram-read $mode:$address:$size -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_read)
  print_command "./idll-test"$executable" --sram-read $mode:$address:$size -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_read"
  read_from_sram=$(echo "$result" | grep -i '[0-9]:' | sed 's/\s//g;s/[0-9]*://g')
  if [[ "$read_data" == "$read_from_sram" ]]; then
    printf "\n"
    printcolor g "================================================================"
    printcolor g "Compare both read/write data : PASS"
    printcolor g "================================================================"
    printf "\n\n\n"
  else
    echo "readfrom file data= $read_data"
    echo "read from sram= $read_from_sram"
    echo "result= $result"
    printf "\n"
    printcolor r "================================================================"
    printcolor r "Compare both read/write data : FAIL"
    printcolor r "================================================================"
    printcolor y "The following info is the data from sram and file data."
    printcolor y "----------------------------------------------------------------"
    printcolor y "Read from file data: \n$read_data"
    printcolor y "----------------------------------------------------------------"
    printcolor y "Read from sram: \n$read_from_sram"
    print_command "./idll-test"$executable" --sram-read $mode:$address:$size -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_read"
    echo "result= $result"
    printf "\n\n\n"
    read -p ""
  fi
  unset -v read_from_sram
  unset -v read_data

#  compare_result "$(echo "$result" | grep -i '[0-9]:' | sed 's/\s//g;s/[0-9]*://g')" "$read_data"
#  echo "$result" | sed 's/\s//g;s/[0-9]*://g'

}

Sram_Bank_Check(){
  local state
  state="true"
  #display how many bank
  bank_amount_02=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Capacity | grep -i "sram bank count" | sed 's/\s//g;s/.*://g')

  #display each bank capacity
  bank_capacity_dec_02=$(sudo ./idll-test"$executable" -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Capacity | grep -i "sram bank size" | sed 's/\s//g;s/.*://g')

  #incase if the project doesn't support to provide each bank info, it needs manual input info.
  if [[ "$bank_capacity_dec_02" == "" || "$bank_amount_02" == "" ]]; then
    return
  fi
  case $1 in
  1)
    if [[ "$bank_amount_02" -ne  "$bank_amount" || "$address_dec" -ne "$bank_capacity_dec_02" ]]; then
      state="false"
    else
      state="true"
    fi
    ;;
  2)
    if [[ "$bank_amount_02" -ne  "$((bank_amount/2))" || "$address_dec" -ne "$bank_capacity_dec_02" ]]; then
      state="false"
    else
      state="true"
    fi
    ;;
  3)
    if [[ "$bank_amount_02" -ne  "$((bank_amount/4))" || "$address_dec" -ne "$bank_capacity_dec_02" ]]; then
      state="false"
    else
      state="true"
    fi
    ;;
  4)
    if [[ "$bank_amount_02" -ne  "$((bank_amount/4))" || "$address_dec" -ne "$bank_capacity_dec_02" ]]; then
      state="false"
    else
      state="true"
    fi
    ;;
  esac
  if [[ "$state" == "false" ]]; then
    printcolor r "The following test result does't follow mirror rule"
    printcolor r "======================================="
    printcolor r "the sram info BEFORE sram mirror=1 test"
    printcolor r "the sram bank =$bank_amount"
    printcolor r "the sram bank size = $address_dec"
    printcolor r "======================================="
    printcolor r "the sram info AFTER sram mirror=$1 test"
    printcolor r "the sram bank =$bank_amount_02"
    printcolor r "the sram bank size = $bank_capacity_dec_02"
    read -p ""
  fi
}
SramRandomSize(){
  local start_address size mirror_mode multiple
  mirror_mode=1
  multiple=1
#  for i in $(seq 0 100);do
#
#  done

  for (( i = 0; i < 3; i++ )); do
    size=$(shuf -i 1-$totalsize -n 1)
#    size=$(shuf -i 1-99 -n 1)
  #  size=100
    differential=$((totalsize-size))

#    start_address=$(shuf -i "$((size-1))"-$((totalsize-1)) -n 1)
    start_address=$(shuf -i 0-$differential -n 1)


    Sram_Mirror_Write "$mirror_mode" "$multiple" "$size" "$start_address" "dummy_write_03.txt"
    Sram_Mirror_Read "$mirror_mode" "$start_address" "$size" "dummy_read_03.txt"
  done
}

Sram_Write_Only(){
  local size address data
  printcolor r "Input what data [0-255] you need to write in SRAM or ENTER to test with data [123]"
  read -p "" data
  data=${data:-123}
  printcolor r "Input how many byte you need to test ,or just ENTER to be 10"
  read -p "" size
  size=${size:-10}
  printcolor r "Input the address you need to write. Or just ENTER to set address = 0"
  read -p "" address
  address=${address:-0}
  Sram_Mirror_Write "1" "1" "$size" "$address" "$data"
}

Sram_Read_Only(){
  local size address
  printcolor r "Input how many byte you need to read, or just ENTER to be 10"
  read -p "" size
  size=${size:-"10"}
  printcolor r "Input the address you need to read. Or just ENTER to set address = 0"
  read -p "" address
  address=${address:-"0"}
  launch_command "./idll-test$executable --sram-read 1:$address:$size -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_read"

}

Sram_Mirror_1_all(){
  local size mirror_mode multiple address
  multiple=$bank_amount
  address=0
  mirror_mode=$1

  printcolor r "Input how many byte you need to test or ENTER to test on all supported size:"
  read -p "" size
  size=${size:-$address_dec}

  #write data to sram
  Sram_Mirror_Write "$mirror_mode" "$multiple" "$size" "$address" "dummy_write_03.txt"

  title b "Mirror=$mirror_mode to check data other banks"
  Sram_Mirror_Read "$mirror_mode" "0" "$size" "dummy_read_03.txt"
  Sram_Bank_Check "$mirror_mode"

  title b "Mirror=1 to check data other banks"
  for addresss in ${bank_address[*]}; do
    if [ "$addresss" -ne 0 ]; then
      Sram_Mirror_Read "1" "$addresss" "$size" "dummy_read_03.txt"
    fi
  done

}

Sram_Mirror_2_2(){
  local size mirror_mode multiple
  multiple=2
  mirror_mode=4
  address=("${bank_address[@]}")

  printcolor r "Input how many byte you need to test or ENTER to test on all supported size:"
  read -p "" size
  size=${size:-$address_dec}

  #write data to sram
  Sram_Mirror_Write "$mirror_mode" "$multiple" "$size" "${address[0]}" "dummy_write_03.txt"
  Sram_Mirror_Write "$mirror_mode" "$multiple" "$size" "${address[1]}" "dummy_write_03.txt"

  title b "Mirror=$mirror_mode to check data other banks"
  Sram_Mirror_Read "$mirror_mode" "${address[0]}" "$size" "dummy_read_03.txt"
  Sram_Mirror_Read "$mirror_mode" "${address[1]}" "$size" "dummy_read_03.txt"
  Sram_Bank_Check "$mirror_mode"

  title b "Mirror=1 to check data other banks"
  Sram_Mirror_Read "1" "${bank_address[0]}" "$size" "dummy_read_03.txt"
  Sram_Mirror_Read "1" "${bank_address[1]}" "$size" "dummy_read_03.txt"
  Sram_Mirror_Read "1" "${bank_address[2]}" "$size" "dummy_read_03.txt"
  Sram_Mirror_Read "1" "${bank_address[3]}" "$size" "dummy_read_03.txt"

}

#===============================================================
#SRAM read/write with same/random data function test
#===============================================================
SramManualSramRandom(){
  local size mirror_mode multiple address
  multiple=1
  address=0
  mirror_mode=1

  printcolor r "Input how many byte you need to test or ENTER to test on all supported size:"
  read -p "" size
  size=${size:-$totalsize}

  #write data to sram
  Sram_Mirror_Write "$mirror_mode" "$multiple" "$size" "$address" "dummy_write_03.txt"

  Sram_Mirror_Read "1" "$address" "$size" "dummy_read_03.txt"
}

#-----------------------------------------------------------------------------------------------------
BadParameter(){
  printf  "${COLOR_RED_WD}Now test with bad address  ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}============================== ${COLOR_REST}\n"
  printf "Press enter key to continue.. \n"
  read -p ""

  command_line=(
    "sudo ./idll-test"$executable" --sram-write 1:100000000000:255/255/255 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_write"
    "sudo ./idll-test"$executable" --sram-write 1:10:abcdef@/255/255 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_write"
    "sudo ./idll-test"$executable" --sram-read 1:100000000:3 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_read"
    "sudo ./idll-test"$executable" --sram-read 1:100000000:3 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_read"
    "sudo ./idll-test"$executable" --sram-read 5:1:3 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_read"
    "sudo ./idll-test"$executable" --ADDRESS 4 --LENGTH 5 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramAsyncCalculateCRC32Manual"
    "sudo ./idll-test"$executable" --ADDRESS 5 --LENGTH 4 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramAsyncCalculateCRC32Manual"
    "sudo ./idll-test"$executable" --ADDRESS 4 --LENGTH 5 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramCalculateCRC32Manual"
    "sudo ./idll-test"$executable" --ADDRESS 5 --LENGTH 4 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramCalculateCRC32Manual"
  )

  for command in "${command_line[@]}";do
    launch_command "$(echo "$command")"
    compare_result "$result" "failed" "skip"
  done
}

#===============================================================
#data iterating stack read/write
#===============================================================
sram_write_read_iterate(){
  local size mirror_mode multiple address
  multiple=1
  address=0
  mirror_mode=1
  max_loop=$totalsize

  printcolor r "Input how many byte you need to test or ENTER to test on all supported size:"
  read -p "" size
  size=${size:-$max_loop}

  #loop all first bank address
  for addr in ${bank_address[*]};do
    #loop input size from 1 to final
    for r in $(seq 1 "$size"); do

      title b "Start checking data with different bank"
      mesg=(
      "Mirror Mode: $mirror_mode"
      "Starting address: $addr"
      "Write data size: $r"
      )
      title_list b mesg[@]

      Sram_Mirror_Write "$mirror_mode" "$multiple" "$r" "$addr" "dummy_write_03.txt"
      Sram_Mirror_Read "$mirror_mode" "$addr" "$r" "dummy_read_03.txt"
    done
  done
}


#===============================================================
#write with verify
#===============================================================
Write_with_verify(){
  local i m stepping
  sram_info
  stepping=100000

  #############################################################################
  #test sram with verify , est sram with verify
  for m in "SramAsyncWriteWithVerifyManual" "SramWriteWithVerifyManual"; do
    addresss=$address
    length=1

#    title b "Test sram with verify ($m) : Test sram with verify "
#    read -p "enter key to continue..."
#    for i in $(seq 1 $stepping $addresss); do
#
#      result=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $i --SRAM-DATA-FILE="./fakefile.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $m)
#      print_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $i --SRAM-DATA-FILE="./fakefile.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $m"
#      printcolor w "$result"
#      verify_result "$result"
#
#      if [[ "$status" == "fail" ]]; then
#        status=""
#        break
#      fi
#
#    done

    ################################################################################
    #Test sram with verify : address get higher while data length smaller
    title b "Test sram with verify ($m) : address get higher, while data length is smaller "
    read -p "enter key to continue..."
    while true; do

      title b "Test sram with verify ($m) : address get higher while data length smaller "
#      result=$( sudo ./idll-test"$executable" --ADDRESS $((addresss-1)) --LENGTH $length --SRAM-DATA-FILE="./fakefile.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $m )
#      print_command "sudo ./idll-test"$executable" --ADDRESS $((addresss-1)) --LENGTH $length --SRAM-DATA-FILE="./fakefile.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $m"
      launch_command "sudo ./idll-test"$executable" --ADDRESS $((addresss-1)) --LENGTH $length --SRAM-DATA-FILE="./fakefile.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $m"
#      printcolor w "$result"
      verify_result "$result"

      length=$((length+stepping))
      addresss=$((addresss-length))
      if [[ "$addresss" -lt 0 ]]; then
        break
      fi

      if [[ "$status" == "fail" ]]; then
        status=""
        read -p "enter key to continue..."
        break
      fi

    done
  done
}
#===============================================================
#sram bank copy
#===============================================================
bank_copy(){
#  sram_info
  local k i
  echo "abc"
  for k in "SramBankCopyManual" "SramAsyncBankCopyManual"; do

    for (( m = 0; m < bank_amount-1; m++ )); do
      for (( i = 0; i < bank_capacity_hex; i=i+10000 )); do

        title b "Bank copy ($k) : data length setting from small to bigger + all bank compare"
        if [ "$i" -gt 0 ]; then
          launch_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$i --SOURCE_BANK 0x$m --DEST_BANK 0x$((m+1)) -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $k"
  #        print_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$i --SOURCE_BANK 0x$m --DEST_BANK 0x$((m+1)) -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $k"
  #        result=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$i --SOURCE_BANK 0x$m --DEST_BANK 0x$((m+1)) -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $k)
  #        printcolor w "$result"
          verify_result "$result"
          Sram_Bank_Check 1
          if [[ "$status" == "fail" ]]; then
            status=""
            break
          fi
        fi

      done
    done
  done
}

#===============================================================
#sram bank compare
#===============================================================
bank_reset(){
  title b "Now make both banks sync up first."
  if [ "$bank_amount" == "4" ]; then
    temp=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$bank_capacity_hex --SOURCE_BANK 0x0 --DEST_BANK 0x1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCopyManual)
    temp=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$bank_capacity_hex --SOURCE_BANK 0x1 --DEST_BANK 0x2 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCopyManual)
    temp=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$bank_capacity_hex --SOURCE_BANK 0x2 --DEST_BANK 0x3 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCopyManual)
  else
    temp=$(sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x$bank_capacity_hex --SOURCE_BANK 0x0 --DEST_BANK 0x1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCopyManual)
  fi
}

bank_compare(){
#  sram_info
  #reset bank data
  bank_reset


  ########################################################################
  #start to test
#  for k in "SramBankCompareManual" "SramAsyncBankCompareManual"; do
#    for (( m = 0; m < $((bank-1)); m++ )); do
#      for (( i = 0; i < bank_capacity_hex; i=i+10000 )); do
#        title b "Bank copy ($k) : Data length setting from small to bigger + all bank compare"
#        result=$(sudo ./idll-test"$executable" --SOURCE_BANK 0x$m --DEST_BANK 0x$((m+1)) --ADDRESS 0x$i --LENGTH 0x$((bank_capacity_hex-i)) -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $k)
#        print_command "sudo ./idll-test"$executable" --SOURCE_BANK 0x$m --DEST_BANK 0x$((m+1)) --ADDRESS 0x$i --LENGTH 0x$((bank_capacity_hex-i)) -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $k"
#        printcolor w "$result"
#        verify_result "$result"
#      done
#    done
#  done

  ########################################################################
  #write the data in bank 0, try to make 2 banks data different
  printf "\n"
  title b "Bank compare : Now try to write data in one of the bank and expect result will be failed."
  read -p "Enter to continue..."
  steppingg=100000
  step_dec=$((16#$steppingg))
  bank_capacity_dec=$((16#$bank_capacity_hex))


  for h in "SramBankCompareManual" "SramAsyncBankCompareManual"; do
    #generate random number to prevent 2 banks have the same data

    for (( i = 0; i < bank_capacity_dec; i=i+step_dec )); do
      title b "$h Test"
      i_hex=$(echo "obase=16;$i"|bc)
      compare_fail_address=$((bank_capacity_dec+i))
      compare_fail_address=$(echo "ibase=10;obase=16;$compare_fail_address"|bc)
      compare_fail_address=${compare_fail_address,,}
      #make all bank sync up first, and then write data to first bank to make banks have different data
      bank_reset

      #write data in bank0
      ran=$(shuf -i 0-255 -n 1)
      title b "Now trying to write data in address: 0x$i_hex"
      launch_command "sudo ./idll-test$executable --sram-write 1:0x$i_hex:$ran -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Manual_write"

      launch_command "sudo ./idll-test$executable --SOURCE_BANK 0x0 --DEST_BANK 0x1 --ADDRESS 0x0 --LENGTH 0x$bank_capacity_hex -- --EBOARD_TYPE EBOARD_ADi_$board --section $h"
      compare_result "$result" "failed" "skip"
      Sram_Bank_Check 1
#      verify_result "$result"

#      if [ "$status" == "fail" ]; then
#        printcolor g "***********The above result is PASSED, while try to make both bank different\n"
#        read -p "enter key to continue..."
#        status=""
#      else
#        printcolor r "***********The above result is FAILED, because both bank data are the same, while try to make both bank different"
#        read -p "Enter to continue..."
#        status=""
#      fi

      title b "Confirm if test result has the the correct returned error address : $compare_fail_address"
      if [[ "$h" =~ "SramAsyncBankCompareManual"  ]]; then
        compare_result "$result" "0x$compare_fail_address]" "skip"
      else
        compare_result "$result" "Error address : 0x$compare_fail_address" "skip"
      fi

    done


  done

  #################################################################
  #make bank data different from above test to prevent both bank data from being the same.
  sudo ./idll-test"$executable" --sram-write 1:0:1/2/3 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SRAM_Manual_write
  sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH 0x"$bank_capacity_hex" --SOURCE_BANK 0x0 --DEST_BANK 0x1 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramBankCopyManual

}

crc_tool(){
  re=$(crc32 temp.txt)
  if [[ "$re" =~ "not found" ]]; then
    title r "Not found CRC32 tool, now try to install it."
    sudo apt install libarchive-zip-perl
  fi
}

#===============================================================
#crc32 caculate
#===============================================================
crc32_caculate(){
#  idll-test --ADDRESS 0x0 --LENGTH 0x800 -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramAsyncCalculateCRC32Manual
  #confirm is CRC32 is install
  crc_tool
  #try to verify with different length
  content_list=('ilovejoe' '1111' '2222222222222220' '2333' 'ioou')

  #size for all list and write in sram / verify the data by crc32
  for l in "SramAsyncCalculateCRC32Manual" "SramCalculateCRC32Manual"; do
    for m in ${content_list[*]};do
      content=$m
      local length crc
      length=${#content}
      #create a txt file to make the content is the same as sram
      while true; do
        start_address=$( shuf -i 0-$totalsize -n 1)
        if [ $((start_address%4)) -eq 0 ]; then
          break
        fi
      done

      differential=$((totalsize-start_address))

      if [[ "$differential" -lt "$length" ]]; then
        start_address=$((start_address-4))
        content=${content:0:4}
#        content=${content:0:$differential}
        length=4
      fi

      printf  "$content" > temp.txt

      #write temp.txt data to sram in specific address
      sudo ./idll-test"$executable" --ADDRESS $start_address --LENGTH $length --SRAM-DATA-FILE=temp.txt -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramWriteWithVerifyManual

      title b "Test sram calculate CRC32 ($l)"
      title b "writing data : $m"
      launch_command "sudo ./idll-test"$executable" --ADDRESS $start_address --LENGTH $length -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $l"
      crc=$(crc32 temp.txt)
      compare_result "$result" "$crc"

    done
  done

  ####################################################################
  #try to write all supported capacity in sram, and try calculate the crc32 for all supported capacity
  for l in "SramAsyncCalculateCRC32Manual" "SramCalculateCRC32Manual"; do
    case $totalsize in
    "67108864")
      crc=$(crc32 fakefile.txt)
      file="fakefile.txt"
      ;;
    "33554432")
      crc=$(crc32 fake32m.txt)
      file="fake32m.txt"
      ;;
    "16777216")
      crc=$(crc32 fake16m.txt)
      file="fake16m.txt"
      ;;
    "8388608")
      crc=$(crc32 fake8m.txt)
      file="fake8m.txt"
      ;;
    "4194304")
      crc=$(crc32 fake4m.txt)
      file="fake4m.txt"
      ;;
    "2097152")
      crc=$(crc32 fake2m.txt)
      file="fake2m.txt"
      ;;
    "1048576")
      crc=$(crc32 fake1m.txt)
      file="fake1m.txt"
    esac

    title b "Try to write all supported capacity in sram, and calculate the all supported capacity crc32"
    launch_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $totalsize --SRAM-DATA-FILE="$file" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramWriteWithVerifyManual"
#    print_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $totalsize --SRAM-DATA-FILE="fake8m.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramWriteWithVerifyManual"
#    sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $totalsize --SRAM-DATA-FILE="fake8m.txt" -- --EBOARD_TYPE EBOARD_ADi_"$board" --section SramWriteWithVerifyManual
    launch_command "sudo ./idll-test"$executable" --ADDRESS 0x0 --LENGTH $totalsize -- --EBOARD_TYPE EBOARD_ADi_"$board" --section $l"
    compare_result "$result" "$crc"
  done

}
Performance(){
  launch_command "sudo ./idll-test$executable -- --EBOARD_TYPE EBOARD_ADi_$board --section SRAM_Performance"
  echo "$result"

}

#
while true; do
  printf  "\n"
  printf  "${COLOR_RED_WD}1. AUTO TEST SRAM SYNC/VSYNC (repeat 10 times) ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}2. AUTO TEST SAME/RANDOM DATA (repeat 10 times) ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}3. SRAM SIZE CHECK ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}4. SRAM MANUAL READ/WRITE SAME/RANDOM ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}5. SRAM MIRROR 1 to ALL (2 BANK)${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}6. SRAM MIRROR 1 to ALL (4 BANK) ${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}7. SRAM MIRROR 2 TO 2${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}8. BAD PARAMETER${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}9. DATA ITERATING READ/WRITE${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}10. SRAM WRITE WITH VERIFY${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}11. SRAM BANK COPY${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}12. SRAM BANK COMPARE${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}13. SRAM CRC32 CALCULATE${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}14. SRAM PERFORMANCE${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}15. SRAM WRITE ONLY${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}16. SRAM READ ONLY${COLOR_REST}\n"
  printf  "${COLOR_RED_WD}======================================${COLOR_REST}\n"
  printf  "CHOOSE ONE TO TEST: "
  read -p "" input

  if [ "$input" == 1 ]; then
    SramSyncVsync_Repeat
  elif [ "$input" == 2 ]; then
    SramAutoRandomSame
  elif [ "$input" == 3 ]; then
    SramCapacity
  elif [ "$input" == 4 ]; then
    SramManualSramRandom
  elif [ "$input" == 5 ]; then
    Sram_Mirror_1_all "2"
  elif [ "$input" == 6 ]; then
    Sram_Mirror_1_all "3"
  elif [ "$input" == 7 ]; then
    Sram_Mirror_2_2
  elif [ "$input" == 8 ]; then
    BadParameter
  elif [ "$input" == 9 ]; then
    sram_write_read_iterate
  elif [ "$input" == 10 ]; then
    Write_with_verify
  elif [ "$input" == 11 ]; then
    bank_copy
  elif [ "$input" == 12 ]; then
    bank_compare
  elif [ "$input" == 13 ]; then
    crc32_caculate
  elif [ "$input" == 14 ]; then
    Performance
  elif [ "$input" == 15 ]; then
    Sram_Write_Only
  elif [ "$input" == 16 ]; then
    Sram_Read_Only
  fi

done