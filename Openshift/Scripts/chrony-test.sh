echo "#####Nodos master"
echo "####Config cronyd presente en master-01"
ssh -l core master-01.osesapeic01.claro.amx cat /etc/chrony.conf
echo "###Estado de servicio chronyd en nodo master-01"
ssh -l core master-01.osesapeic01.claro.amx systemctl is-active chronyd
echo "###Config cronyd presente en master-02"
ssh -l core master-02.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo master-02"
ssh -l core master-02.osesapeic01.claro.amx  systemctl is-active chronyd
echo "###Config cronyd presente en master-03"
ssh -l core master-03.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo master-03"
ssh -l core master-03.osesapeic01.claro.amx systemctl is-active chronyd

echo "#####Nodos infra"
echo "###Config cronyd presente en infra-01"
ssh -l core infra-01.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo infra-01"
ssh -l core infra-01.osesapeic01.claro.amx systemctl is-active chronyd
echo "###Config cronyd presente en infra-02"
ssh -l core infra-02.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en  nodo infra-02"
ssh -l core infra-02.osesapeic01.claro.amx systemctl is-active chronyd
echo "###Config cronyd presente en infra-03"
ssh -l core infra-03.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo infra-03"
ssh -l core infra-03.osesapeic01.claro.amx systemctl is-active chronyd


echo "#####Nodos worker"
echo "###Config cronyd presente en worker-01"
ssh -l core worker-01.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo worker-01"
ssh -l core worker-01.osesapeic01.claro.amx  systemctl is-active chronyd
echo "###Config cronyd presente en worker-02"
ssh -l core worker-02.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo worker-02"
ssh -l core worker-02.osesapeic01.claro.amx  systemctl is-active chronyd
echo "###Config cronyd presente en worker-03"
ssh -l core worker-03.osesapeic01.claro.amx cat /etc/chrony.conf
echo "Estado de servicio chronyd en nodo worker-03"
ssh -l core worker-03.osesapeic01.claro.amx  systemctl is-active chronyd
