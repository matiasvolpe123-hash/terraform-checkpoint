# Checkpoint de infraestructura base

Infraestructura base en AWS, definida con Terraform, para preparar la plataforma de streaming de datos (Kinesis, Lambda, Flink). Incluye una red privada, roles de IAM con permisos mínimos y estado remoto cifrado con locking.

## Estructura del proyecto

```
.
├── bootstrap/               # Crea el bucket de estado y la tabla de locking (se ejecuta una vez)
├── modules/
│   ├── network/             # VPC, subredes privadas, route tables, S3 Gateway Endpoint
│   └── identity/            # Rol de procesamiento (Lambda/Flink) y rol de auditoría
├── environments/
│   └── dev/                 # Llama a los módulos y configura el backend remoto
├── PLAN_OUTPUT.md           # Evidencia del terraform plan
└── README.md
```

## Recursos que se crean

**Bootstrap** (estado local, se ejecuta una vez)

| Recurso | Descripción |
|---|---|
| `aws_s3_bucket` + versioning | Bucket del estado remoto, con versionado |
| `aws_s3_bucket_server_side_encryption_configuration` | Cifrado SSE (AES256) |
| `aws_s3_bucket_public_access_block` | Bloquea todo acceso público |
| `aws_dynamodb_table` | Tabla de locking (clave `LockID`, pago por uso) |

**Módulo `network`**

| Recurso | Descripción |
|---|---|
| `aws_vpc` | VPC con DNS habilitado |
| `aws_default_security_group` | Security group por defecto sin reglas (todo cerrado) |
| `aws_subnet` (x2 o más) | Subredes privadas, una por zona de disponibilidad, sin IP pública |
| `aws_route_table` + asociaciones | Una route table por subred, sin ruta a internet |
| `aws_vpc_endpoint` (Gateway, S3) | Asociado a todas las route tables privadas |

No se crea Internet Gateway ni NAT Gateway, por lo que no hay acceso directo desde internet a las subredes. Las subredes llegan a S3 a través del Gateway Endpoint.

**Módulo `identity`**

| Recurso | Descripción |
|---|---|
| `aws_iam_role` (processing) | Rol de ejecución para Lambda / Flink |
| `aws_iam_policy` (processing) | Solo `s3:ListBucket`, `s3:GetObject`, `s3:PutObject` sobre un prefijo |
| `aws_iam_role` (audit) | Rol de solo lectura para auditoría del plano de control |
| `SecurityAudit` (política de AWS) | Permisos de lectura de metadatos para auditoría |

## Requisitos previos

- Terraform >= 1.5
- AWS CLI configurado con credenciales que puedan crear los recursos anteriores (`aws configure` o un perfil SSO)
- Verificá con qué identidad vas a trabajar: `aws sts get-caller-identity`
- Un bucket S3 de datos (puede ser uno existente) sobre el que el rol de procesamiento tendrá acceso. Este proyecto no lo crea.

## Cómo inicializar el entorno

### 1. Crear el estado remoto (una sola vez)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Editá terraform.tfvars y poné un nombre de bucket único a nivel global
terraform init
terraform apply
```

### 2. Configurar el backend del entorno

Abrí `environments/dev/backend.tf` y reemplazá el valor de `bucket` por el nombre que usaste en el paso anterior. `region` y `dynamodb_table` deben coincidir también con el bootstrap.

### 3. Desplegar el entorno dev

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Editá terraform.tfvars con el nombre de tu bucket de datos
terraform init
terraform plan
terraform apply
```

Para guardar la evidencia del plan:

```bash
terraform plan -no-color | tee plan_output.txt
```

Pegá el resultado en `PLAN_OUTPUT.md`.

## Cómo verificar el resultado

Que el endpoint de S3 está asociado a las route tables privadas:

```bash
terraform output s3_gateway_endpoint_route_table_ids
terraform output private_route_table_ids
```

Las dos listas tienen que contener los mismos IDs. También se puede comprobar con:

```bash
aws ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids $(terraform output -raw s3_gateway_endpoint_id) \
  --query "VpcEndpoints[0].RouteTableIds"
```

Que no hay salida a internet: en la consola de VPC, ninguna route table privada debe tener una ruta `0.0.0.0/0`.

## Decisiones de seguridad

- Sin permisos `*`: la política del rol de procesamiento enumera exactamente tres acciones y limita los recursos al prefijo indicado. `s3:ListBucket` se restringe con la condición `s3:prefix`.
- El rol de auditoría usa la política administrada `SecurityAudit` y solo puede ser asumido por los principales indicados (por defecto, la cuenta actual).
- Sin Internet Gateway ni NAT; el security group por defecto queda sin reglas.
- El estado está cifrado en S3, versionado, sin acceso público y protegido contra escrituras concurrentes por DynamoDB.

## Reutilizar los módulos en otro entorno (por ejemplo, prod)

Los módulos no tienen valores fijos: todo entra por variables. Para crear prod:

1. Copiá `environments/dev` a `environments/prod`.
2. Cambiá `key` en `backend.tf` (por ejemplo `prod/terraform.tfstate`).
3. Ajustá `environment`, los CIDRs y el bucket de datos en `terraform.tfvars`.

## Limpieza

```bash
cd environments/dev && terraform destroy
```

El bucket de estado tiene `prevent_destroy`. Para eliminarlo hay que vaciarlo (incluyendo versiones) y quitar esa protección en `bootstrap/main.tf` antes de ejecutar `terraform destroy` en `bootstrap/`.

## Nota sobre el locking

Terraform 1.10 y posteriores permiten bloquear el estado directamente en S3 (`use_lockfile`), y el parámetro `dynamodb_table` pasó a estar en desuso. Se usa DynamoDB porque así lo pide la consigna; sigue funcionando.

## Nota sobre la región

Este proyecto se probó en `us-east-2` (Ohio). La cuenta de trabajo pertenece a una organización de AWS con una service control policy que bloquea la creación de recursos en `us-east-1`. Si tu cuenta tiene otras restricciones, ajustá la región en `bootstrap/`, en `environments/dev/backend.tf` y en `environments/dev/terraform.tfvars`.
