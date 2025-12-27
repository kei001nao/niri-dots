#!/usr/bin/env fish

while true
   set wtr (curl -s "https://wttr.in/?format=%t+(%h),+%C+%c")
   echo -e "《✧  $wtr✧》" > weather.txt 
   echo "refreshed"
   sleep 15
end

echo "script stopped"