#!/bin/bash
#
#  algodMon v1.11 - errorMonitor - Node Error Monitor
# 
#  Donate/Register: OBQIVIPTUXZENH2YH3C63RHOGS7SUGGQTNJ52JR6YFHEVFK5BR7BEYKQKI
#
#  Copyright 2021 - Consiglieri-cfi
#

# Initialization
nodeDir=~/node;
sourceDir=$(dirname "$0");
currentDate=$(date +%Y-%m-%d);
currentSecond=$(date +%H:%M:%S);
currentEpoch=$(date +%s);
currentTime=$(echo -e "${currentDate}  ${currentSecond}");
brk=$(printf '=%.0s' {1..120}); brkm=$(printf '=%.0s' {1..70}); brks=$(printf '=%.0s' {1..30});
echo -e "\n\n${brk}\nalgodMon - errorMonitor - Node Error Monitor - Initialization\n${brk}";

# Configuration - Data Directory
if [[ ! -f ${sourceDir}/monitorConfig.cfg ]]; then
        echo -e "\n\n${brks}\nConfiguration - Algorand Data\n${brks}";
        echo -e "\nPlease specify the path to the ALGORAND_DATA directory...\n\nExample: $HOME/node/data\n\n"; read ALGORAND_DATA;
        echo -e "\n\nYou have entered: ${ALGORAND_DATA}\n"
        echo -e "\n${brks}\nSaving Config\n${brks}\n\nWriting config: ${sourceDir}/monitorSync.cfg";
        echo "ALGORAND_DATA=${ALGORAND_DATA}" > ${sourceDir}/monitorConfig.cfg; echo -e "\nDone.\n";
else
source ${sourceDir}/monitorConfig.cfg;
fi;

# Execution Tracker
echo -e "\n\nLast Executed: $(date -r ${sourceDir}/nodeMonitor.log +"%Y-%m-%d %H:%M:%S" 2>/dev/null)\nCurrent Time:  ${currentDate} ${currentSecond}\n"



# Error Monitor - Processing
#
echo -e "\n\n${brk}\nalgodMon - errorMonitor - Node Error Monitor - Processing\n${brk}\n";

# Set File Names
errorReport=${sourceDir}/nodeError.log
warnReport=${sourceDir}/nodeWarn.log

# Find last report
echo -e "Processing:  Finding last error report...";
lastEpochError=$(ls -1tr ${errorReport}-* 2> /dev/null | tail -n 1);
echo -e "Processing:  Finding last warning report...";
lastEpochWarn=$(ls -1tr ${warnReport}-* 2> /dev/null | tail -n 1);

# Node Log - Messages Parsers
echo -e "Processing:  Check 'node.log' for error messages...";
grep -a "err" ${ALGORAND_DATA}/node.log > ${errorReport};
echo -e "Processing:  Check 'node.log' for warning messages...";
grep -a "warn" ${ALGORAND_DATA}/node.log > ${warnReport};

# Node Log - Count Messages
echo -e "Processing:  Count error messages: ${errorReport}";
errorCount=$(wc -l ${errorReport} | awk '{print $1}');
echo -e "Processing:  Count warning messages: ${warnReport}"
warnCount=$(wc -l ${warnReport} | awk '{print $1}');



# Error Monitor - Report
#
echo -e "\n\n${brk}\nalgodMon - errorMonitor - Node Error Monitor - Report\n${brk}";

# errorReport - Errors Detected
mv ${errorReport} ${errorReport}-${currentEpoch};
echo -e "\n${brkm}\nError Report\n${brkm}";
if [[ ! ${errorCount} -gt 0 ]]; then
        echo -e "\nNo errors found in algod node log:  ${ALGORAND_DATA}/node.log\n";
else
echo -e "\nALERT: Errors detected in algod node log:  ${ALGORAND_DATA}/node.log\n\n"
tail ${errorReport}-${currentEpoch};
echo -e "\n\nPlease review messages: ${errorReport}-${currentEpoch}\n"
fi;

# errorReport - Compare last report
if [[ ! -f ${lastEpochError} ]]; then
echo -e "\nPrevious error report not found.\n";
else
echo -e "\nProcessing:  Comparing last error report...";
diff ${lastEpochError} ${errorReport}-${currentEpoch} > /dev/null 2>&1
diffStatus=$(echo $?)
if [[ ${diffStatus} == 0 ]]; then
echo -e "\nCurrent error report is a duplicate of the previous file.\n\n\tCurrent Report: ${errorReport}-${currentEpoch}\n\tLast Report: ${lastEpochError}\n\n"
echo -e "Removing duplicate report:  ${errorReport}-${currentEpoch}"
rm -f ${errorReport}-${currentEpoch};
dailyError=0;
else
dailyError=1;
fi; fi;


# errorReport - Warning Detected
mv ${warnReport} ${warnReport}-${currentEpoch};
echo -e "\n\n${brkm}\nWarning Report\n${brkm}";
if [[ ! ${warnCount} -gt 0 ]]; then
	echo -e "\nNo warnings found in algod log:  ${ALGORAND_DATA}/node.log\n";
else
echo -e "\nALERT: Warnings detected in algod node log:  ${ALGORAND_DATA}/node.log\n\n"
tail ${warnReport}-${currentEpoch};
echo -e "\n\nPlease review messages: ${warnReport}-${currentEpoch}\n"
fi;

# errorReport - Compare last report
if [[ ! -f ${lastEpochWarn} ]]; then
echo -e "\nPrevious error report not found.\n";
else
echo -e "\nProcessing:  Comparing last warning report...";
diff ${lastEpochWarn} ${warnReport}-${currentEpoch} > /dev/null 2>&1
diffStatus=$(echo $?)
if [[ ${diffStatus} == 0 ]]; then
echo -e "\nCurrent warning report is a duplicate of the previous file.\n\n\tCurrent Report: ${warnReport}-${currentEpoch}\n\tLast Report: ${lastEpochWarn}\n\n"
echo -e "Removing duplicate report:  ${errorReport}-${currentEpoch}"
rm -f ${warnReport}-${currentEpoch};
dailyWarn=0;
else
dailyWarn=1;
fi; fi;


# Error Monitor - Historical
#
echo -e "\n\n${brk}\nalgodMon - errorMonitor - Node Error Monitor - History\n${brk}\n";
errorHistory=${sourceDir}/nodeMonitor.log

# Count - Update
if [ -f ${errorHistory} ]; then
if [ ${dailyError} -gt 0 ]; then
dailyError=$(expr $(grep ${currentDate} ${errorHistory} | awk '{sum+=$3}END{print sum}') + ${errorCount});
echo -e "dailyError=${dailyError}" > ${sourceDir}/lastCountError.src
else
source ${sourceDir}/lastCountError.src 2>/dev/null;
fi;
if [ ${dailyWarn} -gt 0 ]; then
dailyWarn=$(expr $(grep ${currentDate} ${errorHistory} | awk '{sum+=$4}END{print sum}') + ${warnCount});
echo -e "dailyWarn=${dailyWarn}" > ${sourceDir}/lastCountWarn.src
else
source ${sourceDir}/lastCountWarn.src 2>/dev/null;
fi; fi;

# Count - Write
echo -e "${currentTime} \t ${errorCount} \t ${warnCount} \t ${dailyError} \t ${dailyWarn}" >> ${errorHistory};

# Count - Display
echo -e "Date Time Error Warning Err_Total Warn_Total\n$(tail -n 20 ${errorHistory})" | column -t;

# Truncate Node Log
echo -e "\n\nTruncating node log...\n"
sizeOld=$(du -x ${nodeDir}/data/node.log | awk '{print $1}')
truncate -s 0 ${nodeDir}/data/node.log
truncateStatus=${?}
sizeNew=$(du -x ${nodeDir}/data/node.log | awk '{print $1}')
echo -e "\nExit Status: ${truncateStatus}\n"
echo -e "\n\tOld Size: ${sizeOld}\n\tNew Size: ${sizeNew}\n\n"

