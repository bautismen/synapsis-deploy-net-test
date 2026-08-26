# Dummy: ASP.NET 4.8.1 → IIS (Windows Server Core en AWS) vía GitHub Actions self-hosted runner

## Arquitectura (sin ngrok, sin VPN, sin puertos abiertos para el deploy)

- **Job `build`** corre en un runner normal de GitHub (`windows-latest`, ya trae MSBuild). Compila el proyecto y publica los archivos como *artifact*.
- **Job `deploy`** corre en un runner **self-hosted instalado dentro de tu propia EC2**. El runner se conecta hacia afuera (outbound) a GitHub, así que nunca necesitas abrir un puerto de entrada para el deploy: descarga el artifact ya compilado y hace un `robocopy` local al folder del sitio en IIS, luego reinicia el App Pool.

No se usa Web Deploy, WMSvc, ngrok, ni credenciales remotas — todo el deploy sucede localmente en la máquina donde ya vive el runner.

## Qué incluye este scaffold

- `HelloWorldApp/` — Web Application Project (Web Forms), `TargetFrameworkVersion=v4.8.1`.
- `.github/workflows/deploy.yml` — build (hosted) + deploy (self-hosted).
- `server-setup/Prepare-IISSite.ps1` — crea el sitio dedicado `HelloWorldApp` en el puerto `8080` dentro de IIS, con los permisos correctos para que el runner (que corre como `NT AUTHORITY\NETWORK SERVICE`) pueda escribir ahí.

## Ya hecho de tu lado ✅

- IIS instalado y `W3SVC` corriendo.
- Runner self-hosted instalado como servicio de Windows en `C:\actions-runner`, en estado `Running`.

## Lo que falta

1. **Correr `Prepare-IISSite.ps1` en el servidor** (por RDP, como Administrador):
   ```powershell
   .\Prepare-IISSite.ps1 -SiteName "HelloWorldApp" -Port 8080 -PhysicalPath "C:\inetpub\HelloWorldApp"
   ```
   Al terminar, prueba localmente sin abrir ningún puerto:
   ```powershell
   Invoke-WebRequest http://localhost:8080 -UseBasicParsing
   ```
   (en este punto va a devolver 403/404 porque la carpeta está vacía — es normal, el primer deploy la llena).

2. **Push del código a tu repo** `bautismen/synapsis-deploy-net-test`, rama `main` (o dispara manualmente con "Run workflow" desde la pestaña Actions, ya que el workflow tiene `workflow_dispatch`).

3. **Verificar el deploy**: en GitHub → Actions, deberías ver los dos jobs (`build` en un runner de GitHub, `deploy` en el tuyo). Al terminar, en el servidor:
   ```powershell
   Invoke-WebRequest http://localhost:8080 -UseBasicParsing
   ```
   ya debería devolver 200 con el HTML de "Hola Mundo".

4. **(Opcional) Ver el sitio desde tu navegador / internet**: eso ya no es parte del deploy, es exponer el *sitio web en sí*. Necesitas abrir el puerto `8080` en el Security Group de la instancia (TCP, restringido a tu IP si es solo para ti). Si prefieres no abrir nada, puedes usar `aws ssm start-session` con port forwarding para verlo sin tocar el Security Group.

## Notas

- El App Pool queda en modo `v4.0` (CLR), correcto para .NET Framework 4.8.1.
- `robocopy /MIR` espeja el contenido — borra en destino lo que no esté en el artifact, así el sitio siempre queda igual al build más reciente.
- Si más adelante quieres reforzar seguridad, puedes registrar el runner con un label específico (`runs-on: [self-hosted, iis-prod]`) y limitar qué repos/workflows pueden apuntarle.
