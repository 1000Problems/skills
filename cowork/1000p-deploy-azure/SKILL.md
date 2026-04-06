---
name: 1000p-deploy-azure
description: "Deploy a new 1000Problems sub-project to Azure App Service: scaffold a zero-dependency Node.js app, push to GitHub, deploy to Azure, configure custom subdomain with SSL, and add it to the 1000Problems homepage. Legacy deployment path — use 1000p-deploy-v2 (Vercel) for new projects unless Azure is specifically needed."
---

# 1000Problems Project Deployment (Azure — Legacy)

This is the legacy Azure deployment path. For new projects, prefer `1000p-deploy-v2` (Vercel). Use this only for projects that must run on Azure App Service.

## Why zero dependencies?

Azure App Service + Oryx build system adds 3-5min to deployment and causes container startup timeouts. Zero-dependency Node.js (built-in `http`, `fs`, `path`) deploys in seconds.

## Infrastructure

- **Resource group**: `1000problems-rg` (Central US)
- **App Service plan**: `1000problems-plan` (Linux, Basic)
- **Runtime**: NODE:20-lts
- **GitHub account**: `esotopic` (legacy, older projects)
- **Domain**: GoDaddy (1000problems.com)

## Deployment sequence

1. **Scaffold**: `server.js` (zero deps, serves `public/`, `/api/health`), `package.json`, `public/index.html`
2. **Push to GitHub**: `esotopic/<ProjectName>`
3. **Create App Service**: `az webapp create --name <project>-1000p --runtime "NODE:20-lts"`
4. **Configure**: `SCM_DO_BUILD_DURING_DEPLOYMENT=false`, `DISABLE_ORYX_BUILD=true`, `WEBSITES_PORT=8080`, startup-file `node server.js`
5. **Deploy**: `zip -r deploy.zip . -x ".git/*"` then `az webapp deploy --type zip`
6. **Custom domain + SSL**: CNAME in GoDaddy → `<project>-1000p.azurewebsites.net`, then `az webapp config ssl create` + `ssl bind`
7. **Homepage**: Add to `Pages/Index.cshtml.cs` static list + `Data/ApplicationRepository.cs` DB seeding

## Critical settings

All four are required to avoid container startup timeouts:
- `SCM_DO_BUILD_DURING_DEPLOYMENT=false`
- `DISABLE_ORYX_BUILD=true`
- `WEBSITES_PORT=8080`
- `WEBSITES_CONTAINER_START_TIME_LIMIT=300`
- `startup-file "node server.js"`
