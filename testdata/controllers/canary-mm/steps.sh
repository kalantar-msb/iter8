# initialize primary v1
./initialize.sh
# query
./sleep.sh
# in a new terminal
./execintosleep.sh
# inside the sleep pod
cd wisdom
source query.sh

# candidate v2
./v2-candidate.sh

# inside the sleep pod
source query.sh
source test_query.sh

# promote v2
./promote-v2.sh
kubectl delete isvc wisdom-candidate

# clean up
./cleanup.sh