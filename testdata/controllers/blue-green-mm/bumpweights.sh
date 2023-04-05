echo "kubectl annotate --overwrite isvc wisdom-primary-weight iter8.tools/weight='20'"
echo "kubectl annotate --overwrite isvc wisdom-candidate-weight iter8.tools/weight='80'"
kubectl annotate --overwrite cm wisdom-primary-weight iter8.tools/weight='20'
kubectl annotate --overwrite cm wisdom-candidate-weight iter8.tools/weight='80'
