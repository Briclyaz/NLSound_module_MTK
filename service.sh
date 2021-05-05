# Kill audioserver PID if it exists already
(
sleep 3
SERVERPID=$(pidof audioserver)
[ "$SERVERPID" ] && kill $SERVERPID
)&