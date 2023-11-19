#!/bin/bash

LANG=C

#######################
# Переделка скрипта Никиты Калитюка
# для Raspberry Pi (Raspbian)
# с добавлением некоторых параметров
#######################

#directory="/home/rts";
directory=".";
#directory="/root/telemetry";
key="Orangepi-446";
version="2023-06-08";

NEC_PowerRequestedState=$(snmpget -v 1 -c private 192.168.0.10 1.3.6.1.4.1.2699.1.4.1.4.3.0 | cut -d ":" -f2 | xargs);
NEC_sysUpTime=$(snmpget -v 1 -c private 192.168.0.10 1.3.6.1.2.1.1.3.0 | cut -d ")" -f2 | xargs | cut -d "." -f1 | sed "s/ days, /T/");
if [[ "$NEC_PowerRequestedState" == "11" ]]; then 
NEC_powerOnCount=$(snmpget -v 1 -c private 192.168.0.10 1.3.6.1.4.1.2699.1.4.1.2.7.0 | awk '{print $4;}');
NEC_tempSensor=$(snmpget -v 1 -c private 192.168.0.10 1.3.6.1.4.1.2699.1.4.1.10.1.1.4.1 | awk '{print $4;}'); #// echo "315" | cut -c 3 // echo "315" | cut -c-3
NEC_tempSensorL=$(echo $NEC_tempSensor | cut -c -2);
NEC_tempSensorR=$(echo $NEC_tempSensor | cut -c 3);
NEC_tempSensor="${NEC_tempSensorL}.${NEC_tempSensorR}"
fi
#snmpget -v 1 -c public 192.168.0.18 1.3.6.1.2.1.1.3.0 1.3.6.1.4.1.2699.1.4.1.2.7.0 1.3.6.1.4.1.2699.1.4.1.10.1.1.4.0 1.3.6.1.2.1.1.3.0


numcore=$(cat /proc/cpuinfo | grep "processor" | wc -l);

#IP=$(/sbin/ifconfig wlan0 |grep "inet "|awk '{print $2;}');
#MAC=$(/sbin/ifconfig wlan0 |grep "ether"|awk '{print $2;}');
#RSSI=$(/sbin/iwconfig wlan0 |grep "Signal level"|awk '{split($0,m,"=");printf("%d",m[3]);}');
MAC=$(ip a show end0 |grep "ether"|awk '{print $2;}');

vartop=$(top -b -n 1 | grep -e ^% -e ^top -e ^"Tasks:");
#total processes
proc[0]=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<=NF; i++) {if($(i)=="total,") {print ($(i-1));} }}');	#running processes
proc[1]=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<=NF; i++) {if($(i)=="running,") {print ($(i-1));} }}');
#sleeping processes 
proc[2]=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<=NF; i++) {if($(i)=="sleeping,") {print ($(i-1));} }}'); 
#stopped processes
proc[3]=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<=NF; i++) {if($(i)=="stopped,") {print ($(i-1));} }}');
#zombie processes
proc[4]=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<=NF; i++) {if($(i)=="zombie") {print ($(i-1));} }}');

LAvar=$(echo -e "${vartop}" | 
	awk '{for(i=1; i<NF; i++) {if($(i)=="average:" && NR==1) {print ($(i+1), $(i+2), $(i+3))} } }');
LA[0]=$(echo $LAvar | awk '{print $1}');
LA[1]=$(echo $LAvar | awk '{print $2}');
LA[2]=$(echo $LAvar | awk '{print $3}');
for ((i=0; i<3; i++))
do
        LA[$i]=${LA[$i]%","};
done

IDLE=$(echo - e "${vartop}" | awk '{for(i=1; i<=NF; i++) {if($(i)=="id," && NR==3) {print $(i-1)}}}');
IDLE=${IDLE%","};

Users=$(echo - e "${vartop}" | awk '{for(i=1; i<=NF; i++) {if(($(i)=="users," || $(i)=="user,") && NR==1) {print $(i-1)}}}');

varfree=$(free -m | grep -e Mem: -e Swap:);
memtotal=$(echo -e "${varfree}" | awk '{if(NR==1) print $2}');
swaptotal=$(echo -e "${varfree}" | awk '{if(NR==2) print $2}');
memused=$(echo -e "${varfree}" | awk '{if(NR==1) print $3}');
swapused=$(echo -e "${varfree}" | awk '{if(NR==2) print $3}');

cputemp=`cat /sys/class/thermal/thermal_zone0/temp |awk '{printf("%6.2f",$0/1000);}'`

directory="${directory}/hddconf.txt";
openconf=$(cat $directory);
numhdd=$(echo -e "$openconf" | wc -l);
for((i=0; i<$numhdd; i++))
do
        hddname[i]=$(echo -e "$openconf" | head -1);
        vardf[i]=$(df -m | grep "${hddname[i]}");
        hddtotal[i]=$(echo -e "${vardf[i]}" | awk '{print $2}');
        hddused[i]=$(echo -e "${vardf[i]}" | awk '{print $3}');
        openconf="$(echo "$openconf" | sed '1d')";
done

##############################################

jsonvar="{`
`\"orangepi\" : `
	`{\"MAC\" : \"$MAC\", `
	`\"LA1\" : \"${LA[0]}\", `
	`\"LA5\" : \"${LA[1]}\", `
	`\"LA15\" : \"${LA[2]}\", `
	`\"IDLE\" : \"$IDLE\", `
	`\"Users\" : \"$Users\", `
	`\"Num_cores\" : \"$numcore\", `
	`\"Cpu_temp\" : \"$cputemp\", `
	`\"NEC\" : `
		`{\"PowerRequestedState\" : \"${NEC_PowerRequestedState}\", `
		`\"sysUpTime\" : \"${NEC_sysUpTime}\", `
		`\"powerOnCount\" : \"${NEC_powerOnCount}\", `
		`\"tempSensor\" : \"${NEC_tempSensor}\"}, `
	`\"Processes\" : `
                `{\"Total\" : \"${proc[0]}\", `
                `\"Running\" : \"${proc[1]}\", `
		`\"Sleeping\" : \"${proc[2]}\", `
		`\"Stopped\" : \"${proc[3]}\", `
		`\"Zombie\" : \"${proc[4]}\"}, `
	`\"RAM\" : `
		`{\"Total\" : \"$memtotal\", `
		`\"Used\" : \"$memused\"}, `
	`\"SWAP\" : `
		`{\"Total\" : \"$swaptotal\", `
		`\"Used\" : \"$swapused\"}, `
	`\"HDD\" : {";
	for((i=0; i<$numhdd; i++))
	do
		a=`echo ${hddname[i]} | awk '{
				gsub("ubuntu--","");
				print $0;
			}'`
		hddname[$i]=$a;
        	if((i==$numhdd-1))
        	then
                	jsonvar="${jsonvar}\"${hddname[i]}\" : {\"Total\" : \"${hddtotal[i]}\", \"Used\" : \"${hddused[i]}\"}}}}";
        	else
                	jsonvar="${jsonvar}\"${hddname[i]}\" : {\"Total\" : \"${hddtotal[i]}\", \"Used\" : \"${hddused[i]}\"}, ";
        	fi
	done

##############################################

echo -e "${jsonvar}";
#echo -e "${jsonvar}" > telemetry.json
#curl -X POST -H "Content-Type: application/json" -d "$jsonvar" http://188.35.161.31/core/jsonadd.php;

