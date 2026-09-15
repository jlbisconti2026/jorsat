for i in {1..200}; do curl -k -s https://apigee-desa-test-ar.apps.oseinfrait01.claro.amx/myproxy-ar > /dev/null; echo "Petición $i enviada"; done
for i in {1..200}; do curl -k -s curl https://apigee-desa-test-uy.apps.oseinfrait01.claro.amx/myproxy-uy -k > /dev/null; echo "Petición $i enviada"; done
for i in {1..200}; do curl -k -s curl https://apigee-desa-test-uy.apps.oseinfrait01.claro.amx/myproxy-py > /dev/null; echo "Petición $i enviada"; done
