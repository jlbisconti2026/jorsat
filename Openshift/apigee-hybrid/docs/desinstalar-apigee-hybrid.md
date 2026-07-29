# Desinstalación de ambiente Apigee Hybrid

##1.	Desinstala los recursos del espacio de nombres apigee:
 	
   helm uninstall -n claro-apigee-hybrid-desa \
   vh-desa-test-ar vh-desa-test-py vh-desa-test-uy \
   env-desa-ar env-desa-py env-desa-uy env-test-ar env-test-py env-test-uy \
   ingress-manager \Apigee 
   org \
   apigee-telemetry \
   redis \
   apigee-datastore

3.	Desinstala apigee-operator:
helm uninstall -n claro-apigee-hybrid-desa operator

4.	Elimina los CRDs de Apigee:
oc delete -k  apigee-operator/etc/crds/default/

Opcion 2 :

oc delete crd \
  apigeedatastores.apigee.cloud.google.com \
  apigeedeployments.apigee.cloud.google.com \
  apigeeenvironments.apigee.cloud.google.com \
  apigeeissues.apigee.cloud.google.com \
  apigeeorganizations.apigee.cloud.google.com \
  apigeeredis.apigee.cloud.google.com \
  apigeerouteconfigs.apigee.cloud.google.com \
  apigeeroutes.apigee.cloud.google.com \
  apigeetelemetries.apigee.cloud.google.com \
  cassandradatareplications.apigee.cloud.google.com \
  secretrotations.apigee.cloud.google.com	
4.	Eliminar cert-manager
   oc  delete secret -n claro-apigee-hybrid-desa apigee-ca














