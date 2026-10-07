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
