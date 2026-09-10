
# Indice

[Ver logs de las colas activas en redis](#ver-logs-de-las-colas-activas-en-redis)
[Pruebas de carga hacia Redis](#pruebas-de-carga-hacia-redis)
[Ver instancias N8N registradas en  Redis](#ver-instancias-n8n-registradas-en--redis)
[Inspeccionar los detalles de las instancias](#inspeccionar-los-detalles-de-las-instancias)
[Consultar tamaño de db postgres](#consultar-tamaño-de-db-postgres)
[Ver detalle de tamaño de las tablas en el pod de postgre](#ver-detalle-de-tamaño-de-las-tablas-en-el-pod-de-postgres)
[Ver fechas en que se escribieron registos en la DB POSTGRES](#ver-fechas-en-que-se-escribieron-registos-en-la-db-postgres)
[Query para determinar a saber a qué nombre de workflow corresponde el ID](#query-para-determinar-a-saber-a-qué-nombre-de-workflow-corresponde-el-id)
[Query para ver el detalle de los registros con error. en este caso 1 y 2](#query-para-ver-el-detalle-de-los-registros-con-error-en-este-caso-1-y-2)

## Ver logs de las colas activas en redis

Con este comando podes ver la ejecución de los workflows en tiempo real:

```bash
oc exec -it redis-976f88598-f6l7f -n arquitectura -- redis-cli KEYS "bull:*"
```

## Pruebas de carga hacia Redis

2.2. Lanzar peticiones concurrentes desde el Bastion:OpenShift CLI.Abre tu terminal en el bastion y ejecuta el siguiente bucle en Bash para disparar 30 peticiones simultáneas en paralelo contra la ruta de tu Route de n8n:Bashdone

```bash
ROUTE=$(oc get route n8nmain -n arquitectura -o jsonpath='{.spec.host}')
for i in {1..30}; do
  curl -s -X POST "https://${ROUTE}/webhook/test-carga" -d "{\"id\": $i}" &
done
wait
```

### Ver instancias N8N registradas en  Redis

```bash
oc exec -it redis-976f88598-f6l7f -n arquitectura -- redis-cli KEYS "n8n:{instance:}*"
```

Resultado:

1) "n8n:{instance:}80e7422c-fbe6-4f8c-88d3-419d82701fd8"
2) "n8n:{instance:}state"
3) "n8n:{instance:}514abd65-b678-4d28-9209-bc3854b4077f"
4) "n8n:{instance:}56169a77-f809-4e58-adbc-0a5dd22e4fbe"
5) "n8n:{instance:}members"

## Inspeccionar los detalles de las instancias  

```bash
oc exec -it redis-976f88598-f6l7f -n arquitectura -- redis-cli GET "n8n:{instance:}514abd65-b678-4d28-9209-bc3854b4077f"
```

Resultado:

"{\"schemaVersion\":1,\"instanceKey\":\"514abd65-b678-4d28-9209-bc3854b4077f\",\"hostId\":\"main-n8nmain-7b798854b-p2zq6\",\"instanceType\":\"main\",\"instanceRole\":\"leader\",\"version\":\"2.30.8\",\"registeredAt\":1789046494202,\"lastSeen\":1789051774295}"

## Consultar tamaño de db postgres  

ej:
oc exec -it <nombre-pod-postgres> -n arquitectura -- psql -U <usuario> -c "SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;"

comando real:

```bash
 oc exec -it postgres-6d857ccd88-7cdq7 -n arquitectura -- psql -U n8n -c "SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;"
```

 db_size
---------
 14 MB
(1 row)

## Ver detalle de tamaño de las tablas en el pod de postgres  

```bash
oc exec -it postgres-6d857ccd88-7cdq7 -n arquitectura -- psql -U n8n -c "SELECT relname AS table_name, pg_size_pretty(pg_total_relation_size(C.oid)) AS total_size FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname = 'public' AND C.relkind = 'r' ORDER BY pg_total_relation_size(C.oid) DESC;"
```

Resultado:

             table_name              | total_size
--------------------------------------+------------
 execution_data                       | 160 kB
 role_scope                           | 152 kB
 mcp_registry_server                  | 120 kB
 deployment_key                       | 112 kB
 execution_entity                     | 112 kB
 project_relation                     | 96 kB
 workflow_dependency                  | 96 kB
 migrations                           | 72 kB
 workflow_entity                      | 72 kB
 user_api_keys                        | 64 kB
 scope                                | 64 kB
 user                                 | 64 kB
 agents_memory_entry_sources          | 48 kB
 workflow_history                     | 48 kB
 shared_workflow                      | 48 kB
 scheduled_task                       | 48 kB
 agents_memory_entries                | 48 kB
 agents_observations                  | 48 kB
 role                                 | 48 kB
 agent_files                          | 40 kB
 workflow_statistics                  | 40 kB
 instance_ai_pending_confirmations    | 40 kB
 instance_ai_checkpoints              | 40 kB
 agent_execution_threads              | 40 kB
 test_run                             | 40 kB
 scheduled_job                        | 40 kB
 instance_ai_observations             | 40 kB
 variables                            | 32 kB
 credential_dependency                | 32 kB
 dynamic_credential_entry             | 32 kB
 agents_messages                      | 32 kB
 instance_ai_threads                  | 32 kB
 project                              | 32 kB
 role_mapping_rule                    | 32 kB
 instance_ai_observational_memory     | 32 kB
 agents                               | 32 kB
 instance_ai_run_snapshots            | 32 kB
 evaluation_config                    | 32 kB
 dynamic_credential_user_entry        | 32 kB
 instance_ai_messages                 | 32 kB
 credentials_entity                   | 32 kB
 evaluation_collection                | 32 kB
 settings                             | 32 kB
 user_favorites                       | 32 kB
 workflow_statistics_delta            | 24 kB
 webhook_entity                       | 24 kB
 tag_entity                           | 24 kB
 execution_metadata                   | 24 kB
 execution_annotations                | 24 kB
 execution_annotation_tags            | 24 kB
 test_case_execution                  | 24 kB
 chat_hub_messages                    | 24 kB
 chat_hub_sessions                    | 24 kB
 oauth_user_consents                  | 24 kB
 dynamic_credential_resolver          | 24 kB
 binary_data                          | 24 kB
 secrets_provider_connection          | 24 kB
 chat_hub_tools                       | 24 kB
 workflow_builder_session             | 24 kB
 instance_version_history             | 24 kB
 instance_ai_workflow_snapshots       | 24 kB
 instance_ai_iteration_logs           | 24 kB
 agent_checkpoints                    | 24 kB
 agents_threads                       | 24 kB
 agent_execution                      | 24 kB
 agent_history                        | 24 kB
 agent_task_definition                | 24 kB
 instance_ai_mcp_registry_connections | 24 kB
 workflow_publication_outbox          | 24 kB
 instance_ai_thread_grants            | 24 kB
 trusted_key_source                   | 16 kB
 agent_task_snapshot                  | 16 kB
 trusted_key                          | 16 kB
 agents_memory_entry_cursors          | 16 kB
 shared_credentials                   | 16 kB
 agent_chat_subscriptions             | 16 kB
 auth_provider_sync_history           | 16 kB
 workflow_publish_history             | 16 kB
 role_mapping_rule_project            | 16 kB
 oauth_refresh_tokens                 | 16 kB
 workflow_publication_trigger_status  | 16 kB
 oauth_authorization_codes            | 16 kB
 instance_ai_resources                | 16 kB
 oauth_access_tokens                  | 16 kB
 chat_hub_agents                      | 16 kB
 oauth_clients                        | 16 kB
 ai_builder_temporary_workflow        | 16 kB
 agents_resources                     | 16 kB
 data_table_column                    | 16 kB
 insights_by_period                   | 16 kB
 insights_raw                         | 16 kB
 event_destinations                   | 16 kB
 data_table                           | 16 kB
 installed_nodes                      | 16 kB
 insights_metadata                    | 16 kB
 workflows_tags                       | 16 kB
 folder                               | 16 kB
 processed_data                       | 16 kB
 agents_observation_cursors           | 16 kB
 agents_observation_locks             | 16 kB
 annotation_tag_entity                | 16 kB
 agents_memory_entry_locks            | 16 kB
 invalid_auth_token                   | 16 kB
 agent_task_run_lock                  | 8192 bytes
 token_exchange_jti                   | 8192 bytes
 auth_identity                        | 8192 bytes
 chat_hub_session_tools               | 8192 bytes
 project_secrets_provider_access      | 8192 bytes
 folder_tag                           | 8192 bytes
 chat_hub_agent_tools                 | 8192 bytes
 workflow_published_version           | 8192 bytes
 installed_packages                   | 8192 bytes
 instance_ai_observation_cursors      | 8192 bytes
 instance_ai_observation_locks        | 8192 bytes
(114 rows)

## Ver fechas en que se escribieron registos en la DB POSTGRES:

```bash
 oc exec -it postgres-6d857ccd88-7cdq7  -n arquitectura -- psql -U n8n -d n8n
```

una vez dentro del pod de posgres correr la query:

```bash
SELECT
    id,
    "workflowId",
    status,
    "startedAt" AS fecha_inicio,
    "stoppedAt" AS fecha_fin
FROM execution_entity
ORDER BY "startedAt" DESC
LIMIT 20;
```

Resultado:

id |    workflowId    | status  |        fecha_inicio        |          fecha_fin         
---+------------------+---------+----------------------------+----------------------------
20 | ClmFcWsKWjfgW1jP | success | 2026-09-10 17:05:49.444+00 | 2026-09-10 17:05:49.458+00
19 | ClmFcWsKWjfgW1jP | success | 2026-09-10 17:05:47.046+00 | 2026-09-10 17:05:47.063+00
18 | ClmFcWsKWjfgW1jP | success | 2026-09-10 17:05:42.021+00 | 2026-09-10 17:05:42.036+00
17 | ClmFcWsKWjfgW1jP | success | 2026-09-10 17:05:09.956+00 | 2026-09-10 17:05:09.972+00
16 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:38:09.517+00 | 2026-09-10 14:38:09.53+00
15 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:35:35.824+00 | 2026-09-10 14:35:35.841+00
14 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:32:44.686+00 | 2026-09-10 14:32:44.706+00
13 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:31:32.753+00 | 2026-09-10 14:31:32.767+00
12 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:21:01.856+00 | 2026-09-10 14:21:01.872+00
11 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:03:25.072+00 | 2026-09-10 14:03:25.089+00
10 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:03:00.391+00 | 2026-09-10 14:03:00.407+00
 9 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:02:52.541+00 | 2026-09-10 14:02:52.56+00
 8 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:02:16.187+00 | 2026-09-10 14:02:16.203+00
 7 | ClmFcWsKWjfgW1jP | success | 2026-09-10 14:00:16.876+00 | 2026-09-10 14:00:16.89+00
 6 | ClmFcWsKWjfgW1jP | success | 2026-09-10 13:59:00.456+00 | 2026-09-10 13:59:00.47+00
 5 | ClmFcWsKWjfgW1jP | success | 2026-09-10 13:58:15.797+00 | 2026-09-10 13:58:15.812+00
 4 | ClmFcWsKWjfgW1jP | success | 2026-09-10 13:58:08.328+00 | 2026-09-10 13:58:08.344+00
 3 | ClmFcWsKWjfgW1jP | success | 2026-09-10 13:57:52.941+00 | 2026-09-10 13:57:52.962+00
 2 | ClmFcWsKWjfgW1jP | error   | 2026-09-10 13:56:44.206+00 | 2026-09-10 13:56:44.221+00
 1 | ClmFcWsKWjfgW1jP | error   | 2026-09-10 13:56:11.315+00 | 2026-09-10 13:56:11.38+00
 
## Query para determinar a saber a qué nombre de workflow corresponde el ID

n8n=> SELECT id, name
FROM workflow_entity
WHERE id = 'ClmFcWsKWjfgW1jP';

## Query para ver el detalle de los registros con error. en este caso 1 y 2

n8n=> SELECT *
FROM execution_data
WHERE "executionId" IN (1,2);








