# Dummy: ASP.NET 4.8.1 → IIS (Windows Server Core en AWS) vía GitHub Actions + ngrok

## Qué incluye este scaffold
- `HelloWorldApp/` — Web Application Project (Web Forms) clásico, `TargetFrameworkVersion=v4.8.1`, listo para compilar con MSBuild (no requiere SDK-style ni .NET moderno).
- `.github/workflows/deploy.yml` — pipeline que compila, empaqueta con Web Deploy (msdeploy) y despliega contra tu IIS **sin abrir puertos entrantes en AWS**, usando un túnel ngrok que corre en el propio servidor.

## Por qué esta arquitectura (sin abrir puertos)
El agente `ngrok` se instala **dentro** del Windows Server Core y abre una conexión saliente hacia ngrok.com. Eso expone el puerto 8172 (WMSvc / Web Deploy) como un endpoint público temporal, sin tocar el Security Group de la instancia. El workflow de GitHub Actions consulta la API de ngrok para saber cuál es la URL/puerto vigente en ese momento (cambia si el túnel se reinicia, salvo que reserves una dirección TCP fija).

## Configuración necesaria EN EL SERVIDOR (una sola vez)

1. **Habilitar Web Management Service (WMSvc)** — sí se puede en Server Core, es solo un feature + servicio, sin GUI:
   ```powershell
   Install-WindowsFeature Web-Mgmt-Service
   Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1
   Start-Service WMSVC
   Set-Service WMSVC -StartupType Automatic
   ```
2. **Instalar Web Deploy (Web Deploy 3.6)** en el servidor (necesario para que WMSvc entienda `msdeploy.axd`).
3. **Crear un usuario de despliegue** con permisos de "IIS Manager Permissions" sobre el sitio/aplicación (no hace falta que sea admin del server completo).
4. **Instalar y configurar el agente ngrok como servicio de Windows**:
   ```powershell
   ngrok config add-authtoken <TU_AUTHTOKEN>
   ngrok tcp 8172 --remote-addr <tu-direccion-tcp-reservada>.tcp.ngrok.io:PORT
   # o, como servicio permanente:
   ngrok service install --config "C:\ProgramData\ngrok\ngrok.yml"
   ngrok service start
   ```
   > Con cuenta gratuita, la dirección TCP cambia cada vez que se reinicia el túnel — el workflow ya resuelve la URL vigente automáticamente vía la API de ngrok, así que funciona igual, solo que si quieres una URL estable para depurar a mano conviene una **dirección TCP reservada** (plan pago de ngrok).

## Secrets a crear en GitHub (Settings → Secrets and variables → Actions)

| Secret | Descripción |
|---|---|
| `NGROK_API_KEY` | API key de tu cuenta ngrok (para consultar el túnel activo vía API, no el authtoken del agente) |
| `DEPLOY_USER` | Usuario de IIS Manager / Windows con permisos de deploy sobre el sitio |
| `DEPLOY_PASSWORD` | Password de ese usuario |

## Datos que necesito para dejar el workflow 100% ajustado a tu entorno

1. **Nombre exacto del sitio/aplicación en IIS** (ej. `Default Web Site` o `Default Web Site/HelloWorldApp`) → hoy está como placeholder en `IIS_APP_PATH` dentro de `deploy.yml`.
2. **¿Tu cuenta de ngrok tiene dirección TCP reservada, o vamos a resolverla dinámicamente cada deploy vía API (como está armado ahora)?**
3. **¿El usuario de deploy será una cuenta de IIS Manager (no-admin) o vas a usar una cuenta de Windows local/AD?** (cambia el `authtype` en msdeploy: `Basic` vs `NTLM`).
4. **¿Ya tienes Web Deploy 3.6 y WMSvc instalados en el servidor, o lo armamos juntos con un script?**
5. **Nombre del repo / rama** donde vivirá esto, por si hay que ajustar el trigger (`branches: [ "main" ]`).

Con esas 5 respuestas dejo el `deploy.yml` y el `.pubxml` sin ningún TODO pendiente.
