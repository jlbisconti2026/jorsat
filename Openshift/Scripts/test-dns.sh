#!/bin/bash

##### Prueba de resolucion DNS

echo "Prueba de resolucion directa"
dig api-int.osesapeic01.claro.amx +short
dig api.osesapeic01.claro.amx +short
dig bootstrap.osesapeic01.claro.amx +short
dig master-01.osesapeic01.claro.amx +short
dig master-02.osesapeic01.claro.amx +short
dig master-03.osesapeic01.claro.amx +short
dig infra-01.osesapeic01.claro.amx +short
dig infra-02.osesapeic01.claro.amx +short
dig infra-03.osesapeic01.claro.amx +short
dig worker-01.osesapeic01.claro.amx +short
dig worker-02.osesapeic01.claro.amx +short
dig worker-03.osesapeic01.claro.amx +short


echo "Prueba resolucion reversa DNS"
dig -x 10.92.186.39 +short
dig -x 10.92.186.11 +short
dig -x 10.92.186.12 +short
dig -x 10.92.186.13 +short
dig -x 10.92.186.14 +short
dig -x 10.92.186.15 +short
dig -x 10.92.186.16 +short
dig -x 10.92.186.17 +short
dig -x 10.92.186.18 +short
dig -x 10.92.186.19 +short
