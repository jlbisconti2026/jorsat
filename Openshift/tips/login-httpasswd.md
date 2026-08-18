# Creación de credenciales locales admin OCP/OKD

## Creamos el archivo htpasswd con las credenciales de admin hasheadas

```bash
htpasswd -c -B -b users.htpasswd  admins okd2026!!
```

## Creamos el secret del usuario admin en openshift

```bash
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config 
```

# Borrado de usuario kubeadmin 
Ejecutamos el comando:

```bash
oc delete secret kubeadmin -n kube-system
```

# Borrado user local admin en openshift

```bash
oc delete user <nombre-usuario>
oc delete identity <nombre-idp>:<nombre-usuario>
```
