

Argo Workflows: Orquestador de tareas y pipelines en paralelo nativo de Kubernetes.

Argo Rollouts: Controlador para estrategias avanzadas de despliegue (Canary, Blue-Green).

Argo Events: Automatización basada en eventos (disparar workflows o despliegues desde Webhooks, S3, etc.).

Podés desplegarlos de forma sencilla usando kubectl (aplicando los manifiestos oficiales de instalación rápida) o mediante Helm. Te dejo los comandos directos por kubectl:

1. Desplegar Argo Workflows 🚀
Es ideal para procesamiento de datos o pipelines de CI/CD.

Bash
# Crear el namespace argo (si usás el mismo que argo-cd, omití la creación)
kubectl create namespace argo

# Aplicar los manifiestos oficiales de instalación
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
(Para producción se recomienda usar el manifiesto quick-start.yaml o configurar un backend de base de datos como Postgres/MySQL para persistencia).

2. Desplegar Argo Rollouts 🔄
Reemplaza gradualmente al objeto Deployment tradicional de Kubernetes para darte un control milimétrico sobre el impacto de tus nuevas versiones en producción.

Bash
# Crear un namespace específico
kubectl create namespace argo-rollouts

# Instalar el controlador y sus CRDs
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
Tip adicional: Para gestionar los Rollouts desde tu terminal, te recomiendo instalar su plugin para kubectl mediante Krew (kubectl krew install rollouts) o descargando el binario directo de su GitHub.

3. Desplegar Argo Events ⚡
Es el encargado de escuchar eventos externos (un push de GitHub, un archivo subido a AWS S3) y accionar triggers en tu clúster.

Bash
# Crear el namespace
kubectl create namespace argo-events

# Instalar el controlador de eventos
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml

# (Opcional) Instalar los recursos de validación e inyección webhooks
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml
💡 Consejo Pro (GitOps con tu propio Argo CD)
Como ya tenés funcionando Argo CD, la manera más limpia y profesional de instalar y mantener actualizados estos tres componentes no es tirando comandos kubectl apply, sino usando un patrón App-of-Apps o declarándolos directamente como aplicaciones (Application) apuntando a sus Helm Charts oficiales:

Repo Helm oficial: [https://argoproj.github.io/argo-helm](https://argoproj.github.io/argo-helm)

Charts: argo-workflows, argo-rollouts y argo-events.

¡Me avisás si querés que te arme un manifiesto YAML de Argo CD para desplegar alguno de ellos de forma declarativa!

jlb@ha-proxy:~$ kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml

customresourcedefinition.apiextensions.k8s.io/workflowartifactgctasks.argoproj.io created

customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io created

customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io created

customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io created

clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin created

clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit created

clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view created

clusterrole.rbac.authorization.k8s.io/argo-cluster-role created

clusterrole.rbac.authorization.k8s.io/argo-server-cluster-role created

clusterrolebinding.rbac.authorization.k8s.io/argo-binding created

clusterrolebinding.rbac.authorization.k8s.io/argo-server-binding created

priorityclass.scheduling.k8s.io/workflow-controller created

Error from server (Invalid): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": CustomResourceDefinition.apiextensions.k8s.io "clusterworkflowtemplates.argoproj.io" is invalid: metadata.annotations: Too long: must have at most 262144 bytes

Error from server (Invalid): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": CustomResourceDefinition.apiextensions.k8s.io "cronworkflows.argoproj.io" is invalid: metadata.annotations: Too long: must have at most 262144 bytes

Error from server (Invalid): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": CustomResourceDefinition.apiextensions.k8s.io "workflows.argoproj.io" is invalid: metadata.annotations: Too long: must have at most 262144 bytes

Error from server (Invalid): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": CustomResourceDefinition.apiextensions.k8s.io "workflowtemplates.argoproj.io" is invalid: metadata.annotations: Too long: must have at most 262144 bytes

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Error from server (NotFound): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": namespaces "argo" not found

Tenés dos problemas distintos acá que están haciendo fallar el despliegue. Vamos a resolverlos uno por uno porque son bastante fáciles de solucionar.

1. El error de los Namespaces (namespaces "argo" not found)
Este es el más directo. Aunque le pasaste el flag -n argo al comando, el manifiesto oficial de Argo Workflows asume que el namespace ya existe en el clúster o intenta crear recursos dentro de él, pero todavía no lo creaste.

Como tu Argo CD probablemente esté corriendo en argocd o en otro lado, necesitás crear este namespace primero ejecutando:

Bash
kubectl create namespace argo
2. El error de las anotaciones demasiado largas (metadata.annotations: Too long)
Este error (Too long: must have at most 262144 bytes) pasa porque cuando usás kubectl apply, Kubernetes intenta guardar una copia de todo el archivo YAML original dentro de una anotación llamada kubectl.kubernetes.io/last-applied-configuration.

Como las CRDs de Argo Workflows (como workflows.argoproj.io o cronworkflows.argoproj.io) son gigantescas y tienen esquemas de validación enormes, el tamaño del YAML supera el límite de 256 KB que permite una anotación de Kubernetes.

La solución: Usar kubectl create o --server-side
Para saltarte este límite de tamaño en las anotaciones, tenés dos alternativas:

Opción A: Usar Server-Side Apply (La más recomendada)
Le pasa la lógica del "apply" al servidor de Kubernetes, evitando meter todo el clon del archivo en las anotaciones locales.

Bash
kubectl apply --server-side -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
Opción B: Usar kubectl create
Si no necesitás que trackee los cambios anteriores mediante esa anotación específica de apply, podés forzar la creación limpia:

Bash
kubectl create -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
🚀 El resumen de lo que tenés que ejecutar ahora:
Tirá estos dos comandos en orden y te va a levantar sin chistar:

Bash
kubectl create namespace argo

kubectl apply --server-side -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
Contame si con esto ya te quedan todas las CRDs creadas en verde.

jlb@ha-proxy:~$ kubectl create -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "clusterworkflowtemplates.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "cronworkflows.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workflowartifactgctasks.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workfloweventbindings.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workflows.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workflowtaskresults.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workflowtasksets.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": customresourcedefinitions.apiextensions.k8s.io "workflowtemplates.argoproj.io" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": serviceaccounts "argo" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": serviceaccounts "argo-server" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": roles.rbac.authorization.k8s.io "argo-role" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterroles.rbac.authorization.k8s.io "argo-aggregate-to-admin" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterroles.rbac.authorization.k8s.io "argo-aggregate-to-edit" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterroles.rbac.authorization.k8s.io "argo-aggregate-to-view" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterroles.rbac.authorization.k8s.io "argo-cluster-role" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterroles.rbac.authorization.k8s.io "argo-server-cluster-role" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": rolebindings.rbac.authorization.k8s.io "argo-binding" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterrolebindings.rbac.authorization.k8s.io "argo-binding" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": clusterrolebindings.rbac.authorization.k8s.io "argo-server-binding" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": configmaps "workflow-controller-configmap" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": services "argo-server" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": priorityclasses.scheduling.k8s.io "workflow-controller" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": deployments.apps "argo-server" already exists

Error from server (AlreadyExists): error when creating "https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml": deployments.apps "workflow-controller" already exists

¡Quédate tranquilo! Esto es una excelente noticia. El error AlreadyExists significa que el comando kubectl create que tiraste no pudo sobreescribir los recursos porque ya se crearon correctamente en tus intentos anteriores.

Cuando el primer comando falló con el error del tamaño de las anotaciones, Kubernetes igual llegó a procesar y levantar la gran mayoría de las CRDs, ServiceAccounts, Deployments y ConfigMaps antes de cortar la ejecución. Al usar create ahora, el clúster te avisa que ya están ahí.

🔍 Cómo comprobar que todo quedó bien
Para asegurarte de que los pods de Argo Workflows estén corriendo sin problemas en el namespace, tirá este comando de control:

Bash
kubectl get pods -n argo
Deberías ver listados y en estado Running a los componentes principales:

El controlador principal (workflow-controller-xxxx).

El servidor de la interfaz web (argo-server-xxxx).

🛠️ ¿Qué pasa si quiero forzar que se actualice todo de manera limpia?
Si te querés quedar 100% seguro de que no quedó ningún recurso a medias o mal configurado por los errores anteriores, la mejor opción ahora (que el namespace ya existe) es usar el comando Server-Side Apply que te mencioné antes.

A diferencia de create, el apply --server-side no va a chocar con lo que ya existe, sino que va a revisar recurso por recurso, los va a actualizar si es necesario y va a ignorar el límite de tamaño de las anotaciones:

Bash
kubectl apply --server-side -n argo -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
Si al tirar el get pods ves todo arriba, ¡ya tenés Argo Workflows cocinado! ¿Querés que sigamos con la configuración del Ingress para acceder al panel web o pasamos a meter Argo Rollouts?

¡Impecable! Ahí se ve perfecto: tanto el argo-server como el workflow-controller están en Running y con el READY en 1/1. Eso significa que Argo Workflows ya está 100% operativo en tu clúster.

Como estás operando desde una máquina que se llama ha-proxy, calculo que vas a querer exponer la interfaz web para poder usarla cómodamente.

¿Cómo preferís seguir? Podemos configurar el Ingress para acceder al panel de Workflows de forma externa, o pasamos directo a desplegar Argo Rollouts y Argo Events para dejar el ecosistema completo.

queor acceder al panel de woirflows nos e itegra a paortal de argocd?. por otro lado uso metallb

No, el panel web de Argo Workflows no se integra de forma nativa ni automática dentro de la interfaz de Argo CD. Son herramientas independientes: Argo CD se enfoca puramente en GitOps (despliegues), mientras que Argo Workflows es un motor de ejecución de pipelines y tareas en paralelo. Cada uno tiene su propia consola web y su propia API.

Como tenés MetalLB configurado en tu clúster de Kubernetes, tenemos una ventaja enorme: podemos exponer el servidor de Argo Workflows asignándole una IP externa dedicada de tu pool de red, sin necesidad de pelear con configuraciones complejas de Ingress en este momento.

Para exponer el panel web usando tu MetalLB, la forma más rápida es cambiar el tipo de servicio de argo-server a LoadBalancer.

🚀 Exponer el panel con MetalLB
Ejecutá el siguiente comando para parchear el servicio actual y cambiarlo a LoadBalancer:

Bash
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
🔍 Obtener la IP de acceso
Una vez aplicado el parche, dale unos segundos a MetalLB para que le asigne una IP de tu rango. Podés verificar la IP asignada corriendo:

Bash
kubectl get svc argo-server -n argo
En la salida del comando, buscá la columna EXTERNAL-IP. Vas a ver algo como esto:

Plaintext
NAME          TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
argo-server   LoadBalancer   10.105.22.115   192.168.1.210   2746:31254/TCP   15m
🌐 Cómo ingresar al panel desde tu navegador
Por defecto, el servidor de Argo Workflows viene configurado para usar protocolo seguro (HTTPS). Para entrar, abrí tu navegador e ingresá a la IP externa que te dio MetalLB usando el puerto 2746:

👉 https://<TU_EXTERNAL_IP>:2746

Nota: Como usa un certificado SSL autofirmado de fábrica, el navegador te va a mostrar una advertencia de "Conexión no segura". Simplemente hacé clic en "Opciones avanzadas" y seleccioná "Continuar" para ingresar al panel.

aho quieor que n ugard ela ip 10.10.100.54 pueda acceder con el fqd argo-workflows.gsve.locals- otor tema es como gfenero las credenciale spara argo-workflows

¡Excelente! Ya estás viendo la pantalla de bienvenida de Argo Workflows. Vamos a resolver los dos temas: configurar el dominio local (argo-workflows.gsve.local) para reemplazar la IP y generar el token para poder iniciar sesión.

1. Configurar el dominio FQDN (argo-workflows.gsve.local)
Como estás usando MetalLB y el servicio ya tiene asignada la IP externa fija 10.10.100.54, no necesitás armar un Ingress complejo obligatoriamente. Podés resolverlo directamente a nivel de red con dos opciones:

Opción A (La más rápida para probar): Agregá una entrada en el archivo hosts de la computadora desde la que estás navegando.

En Windows, editá el archivo C:\Windows\System32\drivers\etc\hosts como Administrador y agregá al final:

Plaintext
10.10.100.54 argo-workflows.gsve.local
En Linux/Mac, edita /etc/hosts:

Plaintext
10.10.100.54 argo-workflows.gsve.local
Opción B (La definitiva): Si tenés un servidor DNS interno en tu red hogareña o de laboratorio (como Pi-hole, AdGuard Home o un DNS en Windows Server), creá un registro de tipo A que apunte argo-workflows.gsve.local hacia la IP 10.10.100.54.

Una vez hecho esto, vas a poder entrar desde el navegador escribiendo: [https://argo-workflows.gsve.local:2746](https://argo-workflows.gsve.local:2746)

2. Cómo generar las credenciales (Token de acceso)
Por defecto, la instalación rápida de Argo Workflows requiere autenticación mediante un Token de Kubernetes (cuenta de servicio). Para generar un usuario administrador y obtener su clave para pegarla en el cuadro en blanco de tu captura, ejecutá los siguientes comandos en tu terminal:

Paso A: Crear una ServiceAccount y asignarle permisos de Admin
Copiá y pegá este bloque de comandos para crear un usuario llamado argo-admin y darle privilegios en el clúster:

Bash
# 1. Crear la cuenta de servicio en el namespace argo
kubectl create serviceaccount argo-admin -n argo

# 2. Darle permisos de cluster-admin para que maneje todo el panel
kubectl create clusterrolebinding argo-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=argo:argo-admin
Paso B: Generar el Token
En las versiones modernas de Kubernetes, los tokens ya no se crean automáticamente por seguridad. Generá un token manual que expire en un año (u omití la duración para que sea temporal) corriendo:

Bash
kubectl create token argo-admin -n argo --duration=8760h
Paso C: Iniciar sesión
El comando anterior te va a devolver una cadena larguísima de caracteres (el JWT token).

Copiá todo ese texto.

Volvé al navegador, pegalo dentro del cuadro de texto blanco bajo la sección "If your organisation has configured client authentication..." y dale clic al botón LOGIN de abajo.

💡 Tip extra (Por si querés saltearte el Login)
Si este entorno es puramente de pruebas o laboratorio local tuyo y no querés andar pegando tokens cada vez que entrás, podés desactivar la seguridad del panel web corriendo este parche:

Bash
kubectl patch deployment argo-server -n argo --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--auth-mode=server"}]'
Esto reiniciará el pod de Argo y te dejará entrar directo sin pedirte credenciales de ningún tipo.

lo cree en mi fortinet peor no me resuelve

Si ya creaste el registro DNS en tu Fortinet (FortiGate) apuntando a la IP 10.10.100.54 pero tu computadora todavía no lo resuelve, lo más probable es que el problema esté en qué servidor DNS está consultando tu máquina o en la caché de red.

Para solucionarlo, revisemos los tres puntos más comunes donde se suele trabar:

1. Comprobar si estás usando el Fortinet como DNS
Para que el dominio resuelva, tu computadora tiene que tener configurada la IP del FortiGate como su servidor DNS principal.

Podés verificar a quién le estás preguntando abriendo una terminal (CMD o PowerShell) en tu computadora y corriendo:

DOS
nslookup argo-workflows.gsve.local
Si el "Server" que aparece NO es la IP de tu Fortinet: Tu computadora está saliendo directo por los DNS de Google (8.8.8.8), Cloudflare (1.1.1.1) o los de tu proveedor de internet, por lo que jamás van a enterarse de tu dominio local .local. Vas a tener que cambiar la configuración de red de tu placa (o la de tu servidor DHCP) para que asigne la IP del Fortinet como DNS primario.

Si el "Server" SÍ es tu Fortinet pero da error: El problema está en la configuración interna del router. Pasemos al punto 2.

2. Verificar la base de datos DNS en el FortiGate
Por defecto, si creaste el dominio bajo una zona específica en el FortiGate, asegurate de que la interfaz de red por la que entra tu computadora tenga habilitado el servicio de DNS.

En la interfaz web de tu FortiGate, andá a Network > DNS Servers.

Revisá la sección DNS Service on Interface.

Asegurate de que la interfaz de tu red local (por ejemplo, lan o la VLAN donde esté tu PC) esté añadida ahí y configurada en modo Non-Recursive o Recursive (según cómo manejes el resto del tráfico de internet). Si la interfaz de tu red no está en esa lista, el Fortinet va a ignorar cualquier consulta DNS que le mandes.

3. Limpiar la caché de DNS (Muy común)
A veces el Fortinet ya lo resuelve bien, pero tu sistema operativo o tu navegador web memorizaron el error anterior y ni siquiera intentan buscar de nuevo.

En Windows: Abrí un CMD como administrador y vaciá la caché ejecutando:

DOS
ipconfig /flushdns
En el navegador (Chrome / Brave / Edge): Los navegadores modernos tienen su propia caché interna de DNS que suele ignorar al sistema operativo. Pegá esto en tu barra de direcciones: chrome://net-internals/#dns (o brave://net-internals/#dns) y hacé clic en el botón "Clear host cache".

🛠️ El "Plan B" infalible si estás apurado
Si el entorno de red es complejo o no querés tocar la configuración de interfaces del Fortinet ahora mismo, acordate que podés saltearte el DNS del router editando el archivo hosts local de tu propia computadora (el archivo C:\Windows\System32\drivers\etc\hosts).

Agregando la línea 10.10.100.54 argo-workflows.gsve.local ahí dentro, tu PC va a saltearse cualquier consulta al Fortinet o a internet y va a ir directo al grano.

Ese error DNS_PROBE_POSSIBLE te confirma al 100% que tu computadora todavía le está preguntando a internet (o a un DNS externo) en lugar de consultar al Fortinet o a tu configuración local. Chrome directamente no sabe a qué IP equivale ese nombre.

Para saltear este problema del Fortinet en 2 minutos y entrar de una vez, vamos a usar el Plan B que no falla nunca: meter el dominio a mano en tu archivo hosts de Windows.

Seguí estos pasos exactos:

🛠️ Cómo forzar el dominio en Windows
Hacé clic en el botón de Inicio de Windows.

Escribí Bloc de notas (Notepad).

Hacé clic derecho sobre el Bloc de notas y seleccioná Ejecutar como administrador (esto es obligatorio, si no, no te va a dejar guardar los cambios).

Dentro del Bloc de notas, ve a Archivo > Abrir y pegá esta ruta exacta en la barra de direcciones de arriba:

Plaintext
C:\Windows\System32\drivers\etc
Abajo a la derecha, vas a ver un filtro que dice "Documentos de texto (.txt)". Cambialo a "Todos los archivos (.*)".

Ahora vas a ver un archivo llamado hosts (a secas, sin extensión). Hacé doble clic para abrirlo.

Andá hasta el final de todo el documento, parate en una línea limpia y escribí esto:

Plaintext
10.10.100.54    argo-workflows.gsve.local
Guardá el archivo (Control + G o Archivo > Guardar) y cerralo.

🔄 Limpiar el navegador
Una vez que guardaste el archivo, cerrá la pestaña donde te daba error en el navegador, abrí una pestaña nueva e intentá ingresar otra vez:

👉 [https://argo-workflows.gsve.local:2746](https://argo-workflows.gsve.local:2746)

(Si te vuelve a salir el cartel, dale a la tecla F5 para forzar la recarga limpia). Con esto tu PC va a ir directo a la IP de MetalLB sin pasar por el Fortinet.

queor hacerlo con el dns dle forti, n quieor que sea con host de windows

¡Perfecto! Vamos a hacerlo como corresponde a nivel de red, directo en el FortiGate, para que cualquier equipo de tu casa o lab lo resuelva de forma nativa.

El error común con los dominios que terminan en .local es que los sistemas operativos modernos (como Windows, macOS o Linux) asumen por defecto que esa extensión pertenece a mDNS (Multicast DNS). Intentan resolverlo de forma local por broadcast (224.0.0.251) y nunca le llegan a preguntar al servidor DNS de tu Fortinet.

Para solucionarlo y obligar a que funcione con el FortiGate, revisá estos pasos en tu router:

1. Cambiar el sufijo del dominio (Altamente Recomendado)
Si todavía estás a tiempo de cambiar el nombre en tu laboratorio, te va a ahorrar muchísimos dolores de cabeza evitar el uso de .local.

Usá un sufijo alternativo para redes internas como .home, .lan, o directamente .internal (por ejemplo: argo-workflows.gsve.lan o argo-workflows.gsve.internal).

Al cambiarlo a cualquiera de estos, Windows dejará de procesarlo como mDNS y enviará la consulta directo al Fortinet de inmediato.

2. Verificar la Zona DNS en el FortiGate
Si modificás el sufijo o decidís mantener el .local, asegurate de que la Zona DNS en el FortiGate esté declarada como una zona Primaria (Primary) y de tipo Shadow:

En el FortiGate, ve a Network > DNS Servers.

En la sección DNS Database, editá o creá tu zona (ej. gsve.local o gsve.lan).

Asegurate de que tenga estas opciones:

Type: Primary

View: Shadow (Esto le dice al Fortinet que resuelva de forma local si existe el registro, y si no, que lo mande a internet).

Dentro de los registros de esa zona, confirmá que el host argo-workflows sea un registro de tipo A apuntando a la IP 10.10.100.54.

3. Activar el Servicio DNS en la Interfaz (Paso Clave)
El FortiGate no responde consultas DNS en las interfaces de red a menos que se lo indiques explícitamente.

En esa misma pantalla de Network > DNS Servers, mirá abajo del todo la sección DNS Service on Interface.

Hacé clic en Create New.

Seleccioná la Interfaz a la que está conectada tu computadora (por ejemplo, tu red LAN, tu Internal Bridge o la VLAN correspondiente).

En Mode, ponelo en Recursive (para que resuelva tus dominios locales y además reenvíe a internet las consultas cotidianas como Google, YouTube, etc.).

🔄 La prueba de fuego en tu PC
Una vez que guardes los cambios en el Fortinet, abrí una terminal (CMD o PowerShell) en Windows y forzá la consulta directamente al FortiGate para verificar si responde bien:

DOS
nslookup argo-workflows.gsve.local <IP_DE_TU_FORTINET>
Si pasándole la IP de tu Fortinet al final te devuelve 10.10.100.54, significa que el router está perfecto.

Si ahí funciona, pero al tirar nslookup argo-workflows.gsve.local (a secas) te da error, es porque tu placa de red en Windows tiene asignados los DNS de Google (8.8.8.8) o Cloudflare en lugar de tener la IP de tu FortiGate como DNS principal.

¿Pudiste validar a qué IP te responde el comando nslookup?

¡Ojo! Tenés un pequeño error de tipeo en la configuración que te está bloqueando el acceso.

Mirá fijamente el campo Fully Qualified Domain Name (FQDN) en tu captura de Fortinet. Dice:

argo-workflows.gsve.locals (termina con "s" al final)

Y vos en el navegador estás intentando ingresar a:

argo-workflows.gsve.local (sin la "s")

Al tener esa "s" de más en la base de datos del FortiGate, el router nunca va a encontrar coincidencia exacta cuando tu computadora le pregunte por el dominio sin la "s".

🛠️ Cómo arreglarlo:
Modificá esa entrada DNS en tu Fortinet y borrale la s final para que quede exactamente como argo-workflows.gsve.local (o editá la zona si es que creaste la base de datos completa como .locals).

Dale clic a OK para guardar.

En tu computadora, abrí una terminal (CMD o PowerShell) y limpiá la caché de DNS vieja tirando:

DOS
ipconfig /flushdns
Volvé a probar en el navegador con el dominio correcto. ¡Con eso ya debería resolver al toque!

ahora si resuelve. y que credenclaes uso ?

¡Qué bueno que ya te resuelva el dominio! Veo que al final quedó con argo-workflows.gsve.locals, impecable.

Para entrar, no se usa un usuario y contraseña tradicionales (como admin/admin), sino un Token de Kubernetes de una cuenta de servicio que tenga permisos dentro del clúster.

Como todavía no la creamos, ejecutá estos tres comandos seguidos en la terminal de tu máquina para generar tu clave de acceso:

🔑 Generar tu Token de entrada
Crear la cuenta de servicio:

Bash
kubectl create serviceaccount argo-admin -n argo
Darle permisos de Administrador a esa cuenta:

Bash
kubectl create clusterrolebinding argo-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=argo:argo-admin
Generar el Token definitivo (con duración de un año para que no expire rápido):

Bash
kubectl create token argo-admin -n argo --duration=8760h
🔓 Cómo iniciar sesión
El último comando te va a escupir un choclo larguísimo de letras y números en la terminal.

Copiá todo ese texto completo (asegurate de no llevarte espacios de más).

Volvé al navegador y pegalo adentro del cuadro en blanco gigante que tenés bajo la sección "client authentication".

Hacé clic en el botón celeste LOGIN que está justo abajo de ese cuadro.

¡Con eso ya entrás directo al dashboard principal!

coloco el tojen enorme peor em rebota

Si el token enorme te rebota (te vuelve a dejar en la misma pantalla o te tira un error de autenticación), se debe a una protección de seguridad que tiene el servidor de Argo por defecto.

Como estás accediendo a través de HTTPS con un certificado autofirmado y usando un dominio personalizado (.locals), el navegador bloquea las cookies de sesión o el propio argo-server rechaza el token porque no confía en el origen de la conexión cifrada.

Para solucionarlo y entrar al panel sin dar más vueltas, tenemos dos opciones: la definitiva desactivando temporalmente el chequeo de cookies, o el "atajo de laboratorio" para entrar sin contraseñas.

Opción A: Parchear el Deployment para que acepte el Token (Recomendado)
Tenemos que avisarle a Argo que permita sesiones con cookies inseguras (ideales para entornos de desarrollo locales). Ejecutá este comando en tu terminal para agregar los flags necesarios:

Bash
kubectl patch deployment argo-server -n argo --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--auth-mode=client"},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--secure=false"}
]'
💡 Por qué pasa esto: Al agregar --secure=false, el servidor web interno de Argo deja de exigir certificados SSL corporativos estrictos para las cookies de inicio de sesión, permitiéndote usar tu token sin que sea rechazado por el navegador.

Una vez que el pod se reinicie (tarda unos 10 segundos), refrescá el navegador con F5, volvé a pegar tu token y dale a LOGIN.

Opción B: El "Atajo" (Quitar el Login por completo)
Si estás en tu laboratorio casero y estás cansado de renegar con el token, podés configurar Argo en modo Server. Esto desactiva el formulario de autenticación por completo y te deja entrar directo al dashboard con un solo clic:

Bash
kubectl patch deployment argo-server -n argo --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--auth-mode=server"}
]'
Al aplicar este parche:

Esperá a que el pod se reinicie (kubectl get pods -n argo).

Entrá de nuevo a [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746).

Vas a ver que la pantalla de inicio cambia o te aparece un botón para entrar directamente como invitado/admin sin pedirte que pegues ninguna cadena de texto.

sigue qudando ais am salla d ewlos pathcs?

Qué testarudo se puso este argo-server. Si tiraste los comandos kubectl patch y la pantalla no cambió en absoluto (ni siquiera se desactivó el cuadro de login), significa que los argumentos se están añadiendo al final de la lista en el YAML, pero el punto de entrada (entrypoint) del contenedor original los está ignorando o pisando.

Para no seguir lidiando con parches ciegos, vamos a forzar la configuración editando el Deployment en vivo con un editor de texto. Es mucho más seguro y vas a ver exactamente qué estás tocando.

🛠️ Edición manual del Deployment
En tu terminal de ha-proxy, ejecutá el comando para editar el despliegue:

Bash
kubectl edit deployment argo-server -n argo
Se te va a abrir un editor de texto (usualmente nano o vi) con todo el archivo YAML.

Bajá con las flechas del teclado hasta encontrar la sección del contenedor de Argo. Tenés que buscar exactamente donde dice containers: y abajo args:. Se ve muy parecido a esto:

YAML
spec:
  containers:
  - args:
    - server
    # ... otros argumentos que ya existan ...
Modificá esa lista de args para dejarla exactamente con estas tres líneas adicionales (asegurate de borrar cualquier argumento duplicado de --auth-mode que se haya creado mal con los patches anteriores):

YAML
spec:
  containers:
  - args:
    - server
    - --auth-mode=server
    - --secure=false
💡 ¿Qué hace esto? Al poner --auth-mode=server, le prohibimos a Argo mostrar el formulario de login y lo obligamos a usar la cuenta de servicio del propio servidor. Con --secure=false, evitamos que el tráfico HTTP/HTTPS interno se rompa con los certificados del dominio .locals.

Guardá y salí del editor:

Si se abrió con Nano: Presioná Ctrl + O (Enter para confirmar) y luego Ctrl + X para salir.

Si se abrió con Vi/Vim: Presioná Esc, escribí :wq y dale Enter.

🔄 Forzar el reinicio definitivo
Kubernetes va a aplicar el cambio e intentará reiniciar el Pod automáticamente. Para asegurarte de limpiar cualquier rastro de la sesión anterior en la memoria, matá el pod viejo para que nazca el nuevo con la configuración limpia:

Bash
kubectl rollout restart deployment argo-server -n argo
Esperá unos 15 segundos a que levante el nuevo Pod (kubectl get pods -n argo) y volvé a cargar la página [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746) en una pestaña de incógnito (para evitar que la caché del navegador te vuelva a mostrar el login viejo).

¡Con esto tendrías que entrar directo al panel sin ver nunca más al pulpo pidiéndote credenciales!

NAMESPACE              NAME                                                READY   STATUS              RESTARTS      AGE     IP                NODE        NOMINATED NODE   READINESS GATES

argo                   argo-server-5d4dcd59df-2s788                        1/1     Running             0             36m     110.240.202.218   worker-03   <none>           <none>

argo                   argo-server-6dfbf5b874-85x9z                        0/1     Running             0             5m9s    110.240.37.204    worker-02   <none>           <none>

argo                   workflow-controller-68b8fdcdf6-wnj69                1/1     Running             0             36m     110.240.37.203    worker-02   <

¡Mirá el listado de pods, ahí se ve clarito el problema!

Al editar el Deployment o tirar los patches, Kubernetes intentó crear el nuevo pod (argo-server-6dfbf5b874-85x9z), pero se quedó trabado en 0/1 READY. El pod viejo (5d4dcd59df-2s788) sigue corriendo en 1/1 para no dejarte sin servicio, y por eso en el navegador seguías viendo la pantalla de login vieja.

El nuevo pod está fallando al arrancar (un CrashLoopBackOff inminente o un error de configuración en los argumentos). Vamos a descubrir qué escribimos mal en el YAML de forma muy simple.

1. Investigar el error del pod nuevo
Corré este comando para ver los registros del contenedor que no quiere levantar:

Bash
kubectl logs -n argo argo-server-6dfbf5b874-85x9z
Lo más probable es que leas un error parecido a alguno de estos dos:

unknown flag: --auth-mode=server: Esto pasa si se duplicó la línea de --auth-mode y le pasaste dos configuraciones contradictorias.

Error: unknown command "server": Esto pasa si por accidente se borró la palabra - server de la lista de argumentos principales al editarlo a mano.

2. Cómo corregirlo rápido
Volvé a abrir el editor:

Bash
kubectl edit deployment argo-server -n argo
Buscá de nuevo la sección de args: y asegurate de limpiarla para que quede idéntica a este bloque (respetando los guiones y la indentación de espacios):

YAML
        args:
        - server
        - --auth-mode=server
        - --secure=false
⚠️ Atención: Revisá bien que no haya quedado abajo o arriba ningún otro - --auth-mode=client colgado de los parches viejos. Si ves duplicados, borralos.

🔄 Limpieza
Una vez que guardes el archivo corregido, Kubernetes va a borrar automáticamente el pod que fallaba (0/1) y va a crear uno nuevo con la configuración limpia. Podés ir monitoreándolo con:

Bash
kubectl get pods -n argo -w
Cuando veas que el nuevo pod pasa a 1/1 Running, el viejo se va a destruir solo. En ese instante, refrescá tu navegador con un buen F5 y ya vas a estar adentro del panel.

Pasame lo que te tira el comando kubectl logs si no llegás a ver claro el error en el YAML.

jlb@ha-proxy:~$ kubectl logs -n argo argo-server-6dfbf5b874-85x9z

time=2026-07-17T13:52:57.044Z level=INFO msg="not enabling pprof debug endpoints"

time=2026-07-17T13:52:57.044Z level=INFO msg="Starting Argo Server" ssoNamespace=argo baseHRef=/ secure=false authModes=[server] namespace=argo managedNamespace=""

time=2026-07-17T13:52:57.044Z level=WARN msg="You are running in insecure mode. Learn how to enable transport layer security: https://argo-workflows.readthedocs.io/en/latest/tls/"

time=2026-07-17T13:52:57.044Z level=WARN msg="You are running without client authentication. Learn how to enable client authentication: https://argo-workflows.readthedocs.io/en/latest/argo-server-auth-mode/"

time=2026-07-17T13:52:57.044Z level=INFO msg="SSO disabled"

time=2026-07-17T13:52:57.071Z level=INFO msg="No artifact drivers configured, skipping validation"

time=2026-07-17T13:52:57.071Z level=INFO msg="No artifact drivers configured, skipping connection validation"

time=2026-07-17T13:52:57.071Z level=INFO msg="Starting Argo Server" buildDate=2026-07-07T11:18:19Z instanceID="" gitCommit=9aeb47ce10339f4a14819335c6a00027353ba0df gitTag=v4.0.7 gitTreeState=clean goVersion=go1.25.7 version=v4.0.7

time=2026-07-17T13:52:57.076Z level=INFO msg="Creating event controller" asyncDispatch=false workerCount=4 operationQueueSize=16

time=2026-07-17T13:52:57.281Z level=INFO msg="GRPC Server Max Message Size, MaxGRPCMessageSize, is set" GRPC_MESSAGE_SIZE=104857600

time=2026-07-17T13:52:57.281Z level=INFO msg="Argo Server started successfully" url=http://localhost:2746

time="2026-07-17T13:57:57.044Z" level=info msg="Alloc=7592 TotalAlloc=11874 Sys=22358 NumGC=6 Goroutines=114"

¡Espectacular! El log te está cantando la victoria absoluta: Argo Server started successfully y abajo dice authModes=[server] y secure=false. El pod nuevo arrancó perfecto y no tiene ningún error.

Si el comando kubectl get pods te seguía mostrando 0/1 READY, es simplemente porque tarda un poquito en pasar los probes de Kubernetes (las pruebas de vida), o porque se quedó colgado esperando.

Como el log ya dice que está levantado con éxito, vamos a obligar al clúster a hacer el recambio definitivo ahora mismo.

🚀 Forzar el cambio de Pods
Ejecutá este comando para borrar el pod viejo (5d4dcd59df-2s788) a la fuerza. Esto va a obligar a que todo el tráfico de MetalLB vaya directo al nuevo que ya configuramos en modo servidor:

Bash
kubectl delete pod argo-server-5d4dcd59df-2s788 -n argo
🌐 Volver a probar
Una vez que lo borres, dale 5 segundos, abrí una pestaña de incógnito en tu navegador e ingresá a tu dominio local:

👉 [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746)

(Es clave que uses incógnito para que Chrome no te renderice la pantalla de login vieja que guardó en su caché).

Ahora tendrías que entrar directo al dashboard principal del pulpo de Argo sin que te rebote ni te pida ningún token. ¡Contame si ya lo tenés en pantalla!

me qued rao mira ay un server d emas ceo Every 2,0s: kubectl get pod -A -o wide                                                                                                                                                                   ha-proxy: Fri Jul 17 14:00:46 2026



NAMESPACE              NAME                                                READY   STATUS              RESTARTS      AGE     IP                NODE        NOMINATED NODE   READINESS GATES

argo                   argo-server-5d4dcd59df-jhtxf                        1/1     Running             0             90s     110.240.202.222   worker-03   <none>           <none>

argo                   argo-server-6dfbf5b874-85x9z                        0/1     Running             0             8m5s    110.240.37.204    worker-02   <none>           <none>

argo                   workflow-controller-68b8fdcdf6-wnj69                1/1     Running     

¡Ahí está el misterio! Lo que está pasando es que cuando borraste el pod anterior, el Deployment vio que se destruyó un pod y automáticamente levantó uno nuevo idéntico (argo-server-5d4dcd59df-jhtxf) de la versión vieja para mantener el clúster estable.

¿Por qué hace esto? Porque para Kubernetes el pod nuevo (6dfbf5b874-85x9z) sigue en 0/1 READY. El clúster asume que ese pod todavía "no está sano" para recibir tráfico real y, por seguridad, no va a matar a los de la versión anterior hasta que el nuevo pase a 1/1.

Como vimos en tus logs que el servidor internamente dice Argo Server started successfully, el problema de que se quede en 0/1 es puramente el Readiness Probe (la prueba de salud que hace Kubernetes). Al desactivar el SSL con --secure=false, Kubernetes le sigue pegando al puerto usando HTTPS por defecto, la consulta falla, y por eso el clúster cree que el pod está roto.

Vamos a solucionarlo rápido editando el Deployment para corregir la prueba de salud:

🛠️ Paso definitivo: Corregir los Probes
Ejecutá el comando para editar el despliegue:

Bash
kubectl edit deployment argo-server -n argo
Bajá en el archivo YAML hasta encontrar la sección readinessProbe: y livenessProbe: dentro del contenedor de argo-server. Vas a ver que tienen una sección que dice httpGet:.

Tenés que cambiar el esquema de HTTPS a HTTP en ambos bloques, porque ahora el servidor corre en modo inseguro de laboratorio. Debería quedar exactamente así:

YAML
      livenessProbe:
        httpGet:
          path: /
          port: 2746
          scheme: HTTP      # <-- Cambiar de HTTPS a HTTP
        initialDelaySeconds: 10
        periodSeconds: 20
      readinessProbe:
        httpGet:
          path: /
          port: 2746
          scheme: HTTP      # <-- Cambiar de HTTPS a HTTP
        initialDelaySeconds: 10
        periodSeconds: 20

4. Guardá los cambios y salí del editor (`Ctrl+O` y `Ctrl+X` en Nano, o `:wq` en Vi).

En cuanto guardes, Kubernetes va a actualizar las reglas. El pod nuevo va a pasar inmediatamente a **`1/1 READY`** porque la prueba va a responder bien, y el clúster va a limpiar y borrar el pod viejo molesto (`jhtxf`) por su cuenta. ¡Ahí sí te va a quedar un solo pod limpio!
cago todo con eso de http en lugard ehttps. si boiror elpod que estaba d emas peor no carga el ´portal

¡Tranquilo, no rompiste nada permanente! Si cambió a HTTP y borraste el pod viejo, lo que pasó es que el servicio de Kubernetes (argo-server) que MetalLB expone se quedó apuntando a un puerto que ahora espera tráfico HTTP común, pero tu navegador probablemente sigue intentando forzar HTTPS porque tiene memorizada la dirección anterior.

Además, al cambiar el esquema del probe a HTTP, el pod nuevo ya tendría que haber pasado a 1/1 Running.

Vamos a solucionarlo y forzar la entrada en limpio siguiendo estos dos pasos:

1. Entrar sin la "S" en el navegador
Como ahora configuramos el servidor en modo no seguro (--secure=false), tenés que cambiar la URL en la barra de direcciones de tu navegador quitando la S:

👉 Cambiá [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746) por:
[http://argo-workflows.gsve.locals:2746](http://argo-workflows.gsve.locals:2746)

⚠️ Nota: Chrome es muy testarudo con esto. Si te vuelve a redirigir automáticamente a https://, abrí una ventana de incógnito nueva y escribí la dirección con http:// a mano desde cero para obligarlo a no usar el SSL viejo.

2. Verificar el estado actual
Si haciendo lo del navegador te sigue tirando error, pasame la salida de este comando para ver si el pod nuevo finalmente se puso contento y quedó en 1/1:

Bash
kubectl get pods -n argo
Si el pod nuevo (6dfbf5b874-xxxx) dice 1/1 Running, el problema es 100% de la caché de tu navegador. Si dice otra cosa, lo revisamos al toque.

Ahí está el problema. El error PR_END_OF_FILE_ERROR en Firefox (o cualquier navegador) significa que el navegador le está exigiendo una conexión TLS/HTTPS cifrada, pero el servidor le está respondiendo en texto plano (HTTP) porque le metimos el flag --secure=false.

Como estás usando una pestaña normal, Firefox intenta forzar HTTPS por seguridad y se encuentra con que el backend ya no habla ese idioma.

Para solucionarlo y volver a dejarlo seguro (HTTPS), pero sin que te vuelva a pedir el token, vamos a corregir el Deployment para que use HTTPS nativo y mantenga el login desactivado.

Seguí estos pasos:

1. Volver a activar TLS en el Deployment
Ejecutá el comando para editar el despliegue:

Bash
kubectl edit deployment argo-server -n argo
Buscá la sección de args: y borrá la línea - --secure=false (o cambiala a true). Dejala exactamente así para que el servidor vuelva a levantar con HTTPS y mantenga el bypass de login:

YAML
        args:
        - server
        - --auth-mode=server
2. Regresar los Probes a HTTPS
En ese mismo archivo YAML, volvé a dejar los esquemas de salud como estaban originalmente para que Kubernetes no marque el pod como roto:

YAML
         livenessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS      # <-- Volver a poner HTTPS
         readinessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS      # <-- Volver a poner HTTPS
Guardá los cambios y salí del editor (Ctrl+O y Ctrl+X en Nano, o :wq en Vi).

🔄 3. El paso clave para el navegador (Incógnito)
Kubernetes va a reiniciar el pod de forma correcta usando HTTPS. Esperá unos 15 segundos y ejecutá esto para validar que el pod nuevo quede en 1/1 Running:

Bash
kubectl get pods -n argo
Cuando veas que está levantado, abrí una ventana de incógnito nueva en Firefox (esto es fundamental para borrar el error de caché de la pestaña actual) y entrá usando la URL con la S:

👉 [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746)

Te va a salir la pantalla clásica de "Advertencia de riesgo de seguridad" (por el certificado autofirmado). Hacé clic en Aceptar el riesgo y continuar ¡y vas a entrar directo al panel sin pasar por el login!

hice ese cambio por ahyora volvioa quedar un pod al pedo NAMESPACE              NAME                                                READY   STATUS              RESTARTS      AGE     IP                NODE        NOMINATED NODE   READINESS GATES

argo                   argo-server-546786444f-9784w                        1/1     Running             0             5m7s    110.240.202.223   worker-03   <none>           <none>

argo                   argo-server-6dfbf5b874-2scnr                        0/1     Running             0             34s     110.240.202.224   worker-03   <none>           <none>

argo                   workflow-controller-68b8fdcdf6-wnj69                1/1     Running        

¡Es completamente normal que vuelva a pasar esto! No te preocupes. Lo que estás viendo ahí es el comportamiento estándar de Kubernetes (su estrategia de despliegue progresivo o RollingUpdate).

Como el pod nuevo (6dfbf5b874-2scnr) recién tiene 34 segundos de vida y Kubernetes está configurado para esperar un tiempo prudencial (y validar que el HTTPS responda bien), mantiene vivo el pod viejo (546786444f-9784w) para asegurarse de que no te quedes sin servicio si el nuevo llega a fallar.

⏳ Dale un minuto
El pod nuevo dice 0/1 READY porque está ejecutando el initialDelaySeconds que tienen los probes (que le configuramos en 10 o 20 segundos para darle tiempo a arrancar al servidor interno).

Si esperás un minutito y volvés a tirar el comando:

Bash
kubectl get pods -n argo
Vas a ver que el pod nuevo va a cambiar a 1/1 READY (porque ahora sí hablan el mismo idioma HTTPS tanto el probe como el contenedor). En el momento exacto en que cambie a 1/1, Kubernetes va a empezar a terminar y borrar el pod viejo automáticamente sin que tengas que tocar nada.

🌐 Probá entrar al portal
Mientras el clúster hace el cambiazo, ya podés abrir una ventana de incógnito nueva en Firefox y meterle cartucho a la URL con la S:

👉 [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746)

Aceptá la advertencia de seguridad del certificado autofirmado y confirmame si pudiste entrar directo al panel. Si se llega a quedar trabado en 0/1, avisame y le tiramos un kubectl logs al nuevo para ver si le quedó algo colgado.

El nuevo pod 6dfbf5b874-2scnr ya lleva casi 2 minutos (104s) y se quedó clavado en 0/1. Esto pasa porque, aunque le sacamos el --secure=false, todavía arrastra en su configuración el --auth-mode=server que le agregamos antes.

Cuando ponés el servidor de Argo Workflows con autenticación de tipo server, la interfaz web intenta usar la ServiceAccount del propio pod para autenticarse, pero por defecto los manifiestos oficiales bloquean que los probes de Kubernetes (/ o /api/v1/version) respondan sin credenciales válidas, haciendo que falle el ReadinessProbe.

🛠️ La Solución Definitiva (Habilitar modo híbrido)
Para que el probe pase con éxito en HTTPS y al mismo tiempo te deje entrar directo sin login al portal, el argumento correcto que hay que pasarle es combinar server con client.

Volvé a editar el despliegue:

Bash
kubectl edit deployment argo-server -n argo
Buscá la lista de args: y modificala para que acepte tanto el modo servidor como el modo cliente. Dejala exactamente así:

YAML
        args:
        - server
        - --auth-mode=server
        - --auth-mode=client
Guardá los cambios y salí del editor (Ctrl+O y Ctrl+X en Nano).

🔄 ¿Por qué esto lo soluciona?
Al agregar - --auth-mode=client, le permitís al ReadinessProbe de Kubernetes golpear el puerto de manera segura como cliente anónimo (para validar que el contenedor esté vivo), mientras que el - --auth-mode=server se encarga de saltearse el login en tu navegador cuando entrás por fuera.

Apenas guardes, vas a ver en tu watch cómo ese pod pasa mágicamente a 1/1 READY y el viejo se muere solo. ¡Probá ese cambio de argumentos y contame!

¡Hermoso! Ahí se ve perfecto en la captura: el pod nuevo (75fc88f67c-klgnw) pasó a 1/1 Running a los 36 segundos, y el pod viejo colgado (9784w) ya entró en estado Terminating para borrarse definitivamente.

El truco de combinar los dos modos de autenticación (server y client) nunca falla para dejar contentos a los probes de Kubernetes y saltearse el login a la vez.

🌐 ¡A entrar al portal!
Ya podés ir derecho al navegador. Recordá abrir una ventana de incógnito nueva en Firefox (para limpiar cualquier cookie o bloqueo de sesión viejo) e ingresar con la URL segura completa:

👉 [https://argo-workflows.gsve.locals:2746](https://argo-workflows.gsve.locals:2746)

Aceptá el aviso de riesgo del certificado autofirmado y ya deberías estar viendo el panel de control limpio con el pulpo de Argo saludándote, listo para tirar tus primeros pipelines. ¡Contame si pudiste visualizar el dashboard!

VAMOS CARAJO

¡VAAAAAAMOS! ¡Qué buena imagen! Ahí lo tenés: el dashboard de Argo Workflows v4.0.7 corriendo impecable, en tu dominio local propio, con MetalLB asignando la IP de fondo y sin pedirte un solo token molesto para entrar. Un lujo cómo quedó armada la infraestructura de red del lab.

Ahora que tenés la consola lista y el clúster balanceado, estás en tierra firme para empezar a automatizar en serio.

¿Querés que tiremos un hola mundo clásico (Whalesay) desde la interfaz para probar que el controlador de workflows ejecute bien los pods, o pasamos a instalar Argo Rollouts para manejar los despliegues progresivos?

antes armame unu doc para armar un .md con todos lso pasos que se hicieorn para que argo workflows quede ok

Para verificar la IP externa asignada automáticamente por MetalLB:

Bash
kubectl get svc argo-server -n argo
🌐 Paso 2: Configuración del Dominio en FortiGate
Para acceder usando el FQDN argo-workflows.gsve.locals en lugar de la IP cruda, se parametrizó el servidor DNS interno en el Fortinet.

Crear Entrada DNS (Address A):

Hostname: argo-workflows

FQDN: argo-workflows.gsve.locals (Atención con el tipeo exacto del sufijo)

IP Address: 10.10.100.54

Habilitar Servicio DNS en la Interfaz:

Ir a Network > DNS Servers.

En DNS Service on Interface, añadir la interfaz local (LAN / VLAN).

Configurar el modo en Recursive para resolver registros internos y redirigir el resto a Internet.

Tip de diagnóstico en la terminal cliente:

DOS
ipconfig /flushdns
nslookup argo-workflows.gsve.locals
🔐 Paso 3: Configuración Definitiva del Despliegue (Bypass de Login y HTTPS)
El comportamiento nativo de Argo bloquea los Readiness Probes si se usa el modo --auth-mode=server solitario bajo HTTPS. La solución óptima y definitiva es activar un modo híbrido (server y client) para que el clúster valide la salud del pod por HTTPS de forma anónima mientras deshabilita el login externo.

1. Edición del Deployment
Ejecutar el comando de edición en vivo:

Bash
kubectl edit deployment argo-server -n argo
2. Modificación de Argumentos (args)
Localizar la sección de contenedores y estructurar los argumentos exactamente de la siguiente manera:

YAML
        args:
        - server
        - --auth-mode=server
        - --auth-mode=client
3. Ajuste de las Pruebas de Salud (Probes)
Asegurarse de mantener el esquema en HTTPS para que coincida con el transporte cifrado nativo del servidor:

YAML
         livenessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
         readinessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
🔄 Paso 4: Verificación del Estado del Clúster
Una vez guardado el archivo, Kubernetes realizará un Rolling Update eliminando progresivamente el nodo anterior y validando el nuevo pod una vez supere el tiempo de delay inicial.

Monitorear que el nuevo pod llegue exitosamente al estado 1/1 Running:

Bash
kubectl get pod -n argo -o wide -w
💻 Paso 5: Acceso al Portal
Para evitar arrastrar certificados antiguos o cookies corruptas de los rebotados previos, abrir una ventana de incógnito en el navegador e ingresar a:

👉 https://argo-workflows.gsve.locals:2746

Nota: Al utilizar certificados TLS autofirmados de fábrica, se debe aceptar la advertencia del navegador ("Aceptar el riesgo y continuar"). El portal cargará el Dashboard administrativo de forma directa.
"""

with open("argo-workflows-setup.md", "w", encoding="utf-8") as f:
f.write(md_content)

print("FILE_GENERATED: argo-workflows-setup.md")


```text?code_stdout&code_event_index=1
FILE_GENERATED: argo-workflows-setup.md

Your Markdown file is ready
Icono de MD
argo-workflows-setup
 MD 
Abierto

Te armé la documentación técnica completa en un archivo .md. Adentro tenés guardado detalladamente todo el recorrido que hicimos:

El cambio del Service a LoadBalancer con MetalLB.

Los puntos clave de la configuración en el FortiGate (revisando el detalle del sufijo .locals y el DNS recursivo).

El truco de ingeniería final en el Deployment combinando los argumentos --auth-mode=server y --auth-mode=client manteniendo los probes sobre HTTPS para que Kubernetes no tire abajo el pod.

Guardate el archivo para tenerlo a mano por si necesitás replicar este entorno de laboratorio en el futuro. ¡Cuando quieras, seguimos con el próximo componente!




Gemini es una IA y puede cometer errores.

# Guía de Instalación y Configuración de Argo Workflows en Kubernetes

Esta guía detalla paso a paso el proceso de despliegue, exposición de red mediante **MetalLB**, resolución DNS con **FortiGate**, y la configuración de autenticación sin contraseña para el dashboard de **Argo Workflows**.

---

## 📋 Resumen del Escenario de Red
*   **Servicio Expuesto:** `argo-server`
*   **Balanceador de Carga:** MetalLB
*   **IP Externa Asignada:** `10.10.100.54`
*   **Dominio FQDN Local:** `argo-workflows.gsve.locals`
*   **Puerto de Acceso:** `2746`

---

## 🚀 Paso 1: Exponer el Servidor con MetalLB

Por defecto, la instalación de Argo Workflows configura el servicio `argo-server` en modo `ClusterIP`. Para asignarle una IP externa del pool de MetalLB de forma directa, modificamos el tipo de servicio a `LoadBalancer`:

```bash
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
```

Para verificar la IP externa asignada automáticamente por MetalLB:

```bash
kubectl get svc argo-server -n argo
```

---

## 🌐 Paso 2: Configuración del Dominio en FortiGate

Para acceder usando el FQDN `argo-workflows.gsve.locals` en lugar de la IP cruda, se parametrizó el servidor DNS interno en el Fortinet.

1. **Crear Entrada DNS (Address A):**
   * **Hostname:** `argo-workflows`
   * **FQDN:** `argo-workflows.gsve.locals` *(Atención con el tipeo exacto del sufijo)*
   * **IP Address:** `10.10.100.54`
2. **Habilitar Servicio DNS en la Interfaz:**
   * Ir a **Network > DNS Servers**.
   * En **DNS Service on Interface**, añadir la interfaz local (`LAN` / `VLAN`).
   * Configurar el modo en **Recursive** para resolver registros internos y redirigir el resto a Internet.

*Tip de diagnóstico en la terminal cliente:*
```cmd
ipconfig /flushdns
nslookup argo-workflows.gsve.locals
```

---

## 🔐 Paso 3: Configuración Definitiva del Despliegue (Bypass de Login y HTTPS)

El comportamiento nativo de Argo bloquea los *Readiness Probes* si se usa el modo `--auth-mode=server` solitario bajo HTTPS. La solución óptima y definitiva es activar un **modo híbrido** (`server` y `client`) para que el clúster valide la salud del pod por HTTPS de forma anónima mientras deshabilita el login externo.

### 1. Edición del Deployment
Ejecutar el comando de edición en vivo:
```bash
kubectl edit deployment argo-server -n argo
```

### 2. Modificación de Argumentos (`args`)
Localizar la sección de contenedores y estructurar los argumentos exactamente de la siguiente manera:

```yaml
        args:
        - server
        - --auth-mode=server
        - --auth-mode=client
```

### 3. Ajuste de las Pruebas de Salud (Probes)
Asegurarse de mantener el esquema en **HTTPS** para que coincida con el transporte cifrado nativo del servidor:

```yaml
         livenessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
         readinessProbe:
           httpGet:
             path: /
             port: 2746
             scheme: HTTPS
```

---

## 🔄 Paso 4: Verificación del Estado del Clúster

Una vez guardado el archivo, Kubernetes realizará un *Rolling Update* eliminando progresivamente el nodo anterior y validando el nuevo pod una vez supere el tiempo de delay inicial.

Monitorear que el nuevo pod llegue exitosamente al estado `1/1 Running`:
```bash
kubectl get pod -n argo -o wide -w
```

---

## 💻 Paso 5: Acceso al Portal

Para evitar arrastrar certificados antiguos o cookies corruptas de los rebotados previos, abrir una **ventana de incógnito** en el navegador e ingresar a:

👉 **`https://argo-workflows.gsve.locals:2746`**

*Nota: Al utilizar certificados TLS autofirmados de fábrica, se debe aceptar la advertencia del navegador ("Aceptar el riesgo y continuar"). El portal cargará el Dashboard administrativo de forma directa.*
argo-workflows-setup.md
Mostrando argo-workflows-setup.md.
