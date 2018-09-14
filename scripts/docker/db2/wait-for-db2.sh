start_ts=$(date +%s)
while :
do

    #Get the number of instances running in the server
    NUM_PROC=$(docker exec -u db2inst1 db2 ps -eaf|grep -i db2sysc | wc -l)

    if [[ $NUM_PROC -ne "1" ]]; then
          echo "DB2 is not up yet"
    else
          echo "DB2 is up and running"
          end_ts=$(date +%s)
          echo "DB2 is available after $((end_ts - start_ts)) seconds"
          break
    fi

    sleep 1
done
