#/bin/bash!

echo ####### Comprobar servicio running ########

systemctl status httpd

echo ###### Comprobar si apache esta  activo ####

systemctl is-active httpd

echo ######  Comprobar respuesta con curl ########

curl -I http://localhost:8080/ocp4/
