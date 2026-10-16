<<<<<<< HEAD
[root@bastion ocp-bkp-files]# cat chrony-test

echo "#####Nodos master"
ssh -l core master-01.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core master-02.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core master-03.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd

echo "#####Nodos infra"
ssh -l core infra-01.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core infra-02.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core infra-03.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd


echo "#####Nodos worker"
ssh -l core worker-01.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core worker-02.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
ssh -l core worker-03.osesapeic01.claro.amx cat /etc/chrony.conf && systemctl status chronyd
=======
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
>>>>>>> 1408de62a95ebf9fe73effe941ecf5287ac3abbc
