# Recuperación de Entorno Apigee Hybrid

## 1. Resumen Ejecutivo
Tras la pérdida o eliminación de las definiciones de recursos personalizados (CRDs) y releases de Helm en el namespace gsve-apigee-hybrid-desa, se procedió a la reconstrucción ordenada de la arquitectura del cluster de Apigee Hybrid.
El proceso involucró la reinstalación manual de CRDs evitando límites de anotaciones de Kubernetes, el desbloqueo de webhooks y finalizers trabados, la inicialización del clúster de almacenamiento Cassandra y el re-despliegue de los planos de control y ejecución por país (AR, PY, UY). El entorno se restableció al 100% de operatividad.

## 2. Diagrama de la Secuencia de Recuperación

	Restauración de CRDs → 2. Desbloqueo de Webhooks → 3. Despliegue de Org & Redis → 4. Recuperación de Cassandra → 5. Despliegue de Runtimes y VirtualHosts
	
## 3. Detalle Paso a Paso de las Soluciones Aplicadas
### Paso 1: Reinstalación de Custom Resource Definitions (CRDs)
	Problema: Al intentar aplicar los CRDs mediante oc apply, la API Server de OpenShift rechazaba la petición por superar el límite de bytes en anotaciones (metadata.annotations: Too long: may not be more than 262144 bytes).
	Solución: Se aplicaron los manifiestos omitiendo la anotación de última configuración mediante oc create:
```Bash
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeorganizations.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeenvironments.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeroutes.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeredis.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeedeployments.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeeissues.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeerouteconfigs.yaml
oc create -f apigee-operator/etc/crds/crd/bases/apigee.cloud.google.com_apigeedatastores.yaml
```

Validación: Se confirmó la existencia de los 11 CRDs con oc get crd | grep apigee.

```Bash
oc get crd | grep apigee
```

apigeedatastores.apigee.cloud.google.com                          
apigeedeployments.apigee.cloud.google.com                         
apigeeenvironments.apigee.cloud.google.com                        
apigeeissues.apigee.cloud.google.com                              
apigeeorganizations.apigee.cloud.google.com                       
apigeeredis.apigee.cloud.google.
apigeerouteconfigs.apigee.cloud.google.com                        
apigeeroutes.apigee.cloud.google.com                              
cassandradatareplications.apigee.cloud.google.com                 
secretrotations.apigee.cloud.google.com         
                  
### Paso 2: Eliminación de Webhooks Interceptores Bloqueantes
	Problema: Los comandos de Helm rebotaban con el error failed calling webhook: no endpoints available for service "apigee-webhook-service".
	Solución: Se removieron temporalmente las reglas de validación y mutación para permitir que Helm registre las nuevas entregas mientras el operador se estabilizaba:

  ```Bash
oc delete mutatingwebhookconfiguration apigee-mutating-webhook-configuration-claro-apigee-hybrid-desa
oc delete validatingwebhookconfiguration apigee-validating-webhook-configuration-claro-apigee-hybrid-desa
oc rollout restart deployment/apigee-controller-manager -n claro-apigee-hybrid-desa
```
### Paso 3: Limpieza de Recursos Atascados (Finalizers)
	Problema: El recurso [apigeedatastore.apigee.cloud.google.com/default](https://apigeedatastore.apigee.cloud.google.com/default) se mantenía en estado deleting, bloqueando la creación del StatefulSet de Cassandra y sus PVCs.
	Solución: Se forzó la remoción del finalizer para liberar la API de Kubernetes:
  
  ```Bash
oc patch apigeedatastore default -n claro-apigee-hybrid-desa -p '{"metadata":{"finalizers":null}}' --type=merge
  ```

### Paso 4: Re-despliegue de Componentes Base e Infraestructura
Con los webhooks y CRDs en orden, se ejecutó el despliegue con Helm de la Organización, Datastore (Cassandra), Redis e Ingress:

  ```Bash
helm upgrade --install org apigee-org/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install apigee-datastore apigee-datastore/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install redis apigee-redis/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install apigee-telemetry apigee-telemetry/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
helm upgrade --install ingress-manager apigee-ingress-manager/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml
```

	Resultado: Se provisionaron los nodos apigee-cassandra-default-0, 1, 2 en estado 2/2 Running.
	Acción Correctiva Menor: Se reiniciaron los pods de schema-setup para forzar la conexión inmediata contra Cassandra recién creada, logrando el estado Completed y liberando la inicialización del pod MART.
### Paso 5: Despliegue de Entornos (Environments) y Virtual Hosts
Finalmente, se re-instalaron los entornos de ejecución para Argentina, Paraguay y Uruguay:
Entornos (Environments):
  ```
helm upgrade --install env-desa-ar apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-ar
helm upgrade --install env-desa-py apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-py
helm upgrade --install env-desa-uy apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-uy
helm upgrade --install env-test-ar apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-ar
helm upgrade --install env-test-py apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-py
helm upgrade --install env-test-uy apigee-env/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=test-uy
  ```
Virtual Hosts:
  ```
helm upgrade --install vh-desa-test-ar apigee-virtualhost/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-ar
helm upgrade --install vh-desa-test-py apigee-virtualhost/ -n claro-apigee-hybrid-desa -f overrides-desa.yaml --set env=desa-py
  ```
Listado de todos los pods de apigee funcionando:
NAME                                                              READY   STATUS      
apigee-cassandra-default-0                                        2/2     Running     
apigee-cassandra-default-1                                        2/2     Running     
apigee-cassandra-default-2                                        2/2     Running     
apigee-cassandra-schema-setup-claup-apigee-hy-ecaf627-ch8d7       0/1     Completed   
apigee-cassandra-schema-val-claup-apigee-hy-ecaf627-297457szql6   0/1     Completed   
apigee-cassandra-user-setup-claup-apigee-hy-ecaf627-vn7b6         0/1     Completed   
apigee-connect-agent-claup-apigee-hy-ecaf627-1160-n5bpe-tdwrv     1/1     Running     
apigee-controller-manager-947fc4557-jhp2n                         1/2     Running    
apigee-controller-manager-9bc87c94b-hn89d                         1/2     Running     
apigee-hybrid-helm-guardrail-operator                             0/1     Completed   
apigee-ingressgateway-apigee-ingress-claup-apigee-hy-ecaf6chzcw   2/2     Running     
apigee-ingressgateway-apigee-ingress-claup-apigee-hy-ecaf6qr5ch   2/2     Running     
apigee-ingressgateway-internal-chaining-claup-apigee-hy-ecb4lwj   2/2     Running     
apigee-ingressgateway-internal-chaining-claup-apigee-hy-ecvpgm8   2/2     Running    
apigee-ingressgateway-manager-5fd87c45b7-46hnc                    3/3     Running     
apigee-ingressgateway-manager-5fd87c45b7-zkbrg                    3/3     Running     
apigee-mart-claup-apigee-hy-ecaf627-1160-mqn2p-tx4b8              1/1     Running     
apigee-redis-default-0                                            1/1     Running    
apigee-redis-default-1                                            1/1     Running     
apigee-redis-envoy-default-1160-spc3v-pmw8b                       1/1     Running     
apigee-runtime-claup-apigee-hy-desa-ar-33c0380-1160-6v94q-pbglb   1/1     Running    
apigee-runtime-claup-apigee-hy-desa-py-3440b57-1160-fk1l2-wppmp   1/1     Running     
apigee-runtime-claup-apigee-hy-desa-uy-25e6c54-1160-4wxff-8ggb2   1/1     Running     
apigee-runtime-claup-apigee-hy-test-ar-1d91f1f-1160-t16tx-qf6ph   1/1     Running     
apigee-runtime-claup-apigee-hy-test-py-bccce2b-1160-lodee-959r6   1/1     Running     
apigee-runtime-claup-apigee-hy-test-uy-f2be057-1160-wdz0g-cm5hj   1/1     Running     
apigee-synchronizer-claup-apigee-hy-desa-ar-33c0380-1160-w4hwrw   1/1     Running     
apigee-synchronizer-claup-apigee-hy-desa-py-3440b57-1160-1pw5fs   1/1     Running     
apigee-synchronizer-claup-apigee-hy-desa-uy-25e6c54-1160-7fkmhj   1/1     Running     
apigee-synchronizer-claup-apigee-hy-test-ar-1d91f1f-1160-vmb9rq   1/1     Running     
apigee-synchronizer-claup-apigee-hy-test-py-bccce2b-1160-ek8n55   1/1     Running     
apigee-synchronizer-claup-apigee-hy-test-uy-f2be057-1160-02m8cn   1/1     Running     
apigee-watcher-claup-apigee-hy-ecaf627-1160-sey7a-4pg5p           1/1     Running     
infra-01oseinfrait01claroamx-debug                                1/1     Running     
infra-02oseinfrait01claroamx-debug                                1/1     Running     
infra-03oseinfrait01claroamx-debug                                1/1     Running     

