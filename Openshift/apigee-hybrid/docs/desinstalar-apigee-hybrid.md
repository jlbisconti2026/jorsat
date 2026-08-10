
# Contenido
1. [Desinstala los recursos del espacio de nombres apigee](#1-desinstala-los-recursos-del-espacio-de-nombres-apigee)
2. [Desinstala apigee-operator](#2-desinstala-apigee-operator)
3. [Elimina los CRDs de Apigee](#3-elimina-los-crds-de-apigee)
4. [Eliminar cert-manager](#4-eliminar-cert-manager)



## 1. Desinstala los recursos del espacio de nombres apigee

```bash
helm uninstall -n claro-apigee-hybrid-desa \
  vh-desa-test-ar vh-desa-test-py vh-desa-test-uy \
  env-desa-ar env-desa-py env-desa-uy env-test-ar env-test-py env-test-uy \
  ingress-manager \
  org \
  apigee-telemetry \
  redis \
  apigee-datastore
```

## 2.	Desinstala apigee-operator:
````
helm uninstall -n claro-apigee-hybrid-desa operator
````

## 3.	Elimina los CRDs de Apigee:
````
oc delete -k  apigee-operator/etc/crds/default/
````

Opcion 2 :

````
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
````

4.	Eliminar cert-manager
   ````
   oc  delete secret -n claro-apigee-hybrid-desa apigee-ca
   ````













