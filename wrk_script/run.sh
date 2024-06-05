#!/bin/bash
#################################################   Call   #####################################

echo StartTime: "$(date +'%Y-%m-%dT%H:%M:%S')"
for i in $(seq 1 100); do
        (
        sleep $(echo "0.5 * $i" | bc)
        echo StartTime"$i": "$(date +'%Y-%m-%dT%H:%M:%S')" > /home/vt_admin/Github/script_for_test/wrk/res_1_"$i".wrk
        sleep_time=$(echo "(0.5 * (100 - $i) + 600)" | bc)
        sleep_time_int=$(printf "%.0f" "$sleep_time")

        wrk -t 1 -c 100 -d $"${sleep_time_int}s"  --timeout 6s "https://es1-p1-netcdn.tv360.vn/netcdn-live/192/output/192-audio_142800_eng=140800-video=5154400.m3u8"  -s /home/vt_admin/Github/script_for_test/wrk_script/hls.lua >> /home/vt_admin/Github/script_for_test/wrk/res_1_"$i".wrk
        echo EndTime: "$(date +'%Y-%m-%dT%H:%M:%S')" >> /home/vt_admin/Github/script_for_test/wrk/res_1_"$i".wrk
        ) &
done


for i in $(seq 1 100); do
        (
        sleep $(echo "0.5 * $i" | bc)
        echo StartTime"$i": "$(date +'%Y-%m-%dT%H:%M:%S')" > /home/vt_admin/Github/script_for_test/wrk/res_2_"$i".wrk
        sleep_time=$(echo "(0.5 * (100 - $i) + 600)" | bc)
        sleep_time_int=$(printf "%.0f" "$sleep_time")

        wrk -t 1 -c 100 -d $"${sleep_time_int}s"  --timeout 6s "https://es4-p1-netcdn.tv360.vn/netcdn-live/192/output/192-audio_142800_eng=140800-video=5154400.m3u8"  -s /home/vt_admin/Github/script_for_test/wrk_script/hls.lua >> /home/vt_admin/Github/script_for_test/wrk/res_2_"$i".wrk
        echo EndTime: "$(date +'%Y-%m-%dT%H:%M:%S')" >> /home/vt_admin/Github/script_for_test/wrk/res_2_"$i".wrk
        ) &
done

wait

echo EndTime: "$(date +'%Y-%m-%dT%H:%M:%S')"                                               
