# Deploy to Hugging Face Spaces from GitHub, automatically

> **Immediate step (pending client approval):** create the branch `hf-deploy-plan` from `main`, commit this plan as `deploy/PLAN.md`, push, and stop there. Don't build anything until the clients approve. Once they do, implement the changes below on that same branch.

## Context
Clients need a free URL to preview the app. The production deploy stays with the client's IT, who pull the repo. Other hosts ruled out: Vercel can't run Shiny, shinyapps.io is being deprecated, Posit Connect Cloud's free plan caps usage at 20 active hours a month, and AWS costs money.

A Hugging Face Docker Space is free (2 vCPU, 16 GB RAM), with no hour cap. The catches: it's public, and it sleeps after about 48 h idle, so the first visit after that takes about a minute to wake.

To keep this low-maintenance, the Space files live in this repo and a GitHub Action keeps the Space in sync. Nobody edits the HF repo by hand. The Space's Dockerfile clones the public GitHub repo at build time, so the app code and data never get pushed to HF. That also avoids HF's Git LFS requirement for the 46–74 MB parquet files.

## Changes (all in this repo)

### 1. `deploy/hf/README.md`: Space settings
```yaml
---
title: Paleotidal
emoji: 🌊
colorFrom: blue
colorTo: green
sdk: docker
app_port: 3838
pinned: false
---
```

### 2. `deploy/hf/Dockerfile`
```dockerfile
# ponytail: geospatial base ships GDAL/GEOS/PROJ/udunits for sf/terra in renv.lock
FROM rocker/geospatial:4.6.1
ENV RENV_CONFIG_REPOS_OVERRIDE=https://packagemanager.posit.co/cran/__linux__/noble/latest \
    RENV_PATHS_LIBRARY=/renv/library
RUN git clone --depth 1 https://github.com/keatonwilson/paleotidal_app /app
WORKDIR /app
# .Rprofile sources renv/activate.R, which sets renv up itself
RUN R -e 'renv::restore()'
# HF runs containers as uid 1000; rocker already has that user (rstudio)
USER rstudio
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
```
If the `4.6.1` tag doesn't exist on Docker Hub yet, use the closest 4.6.x tag.

### 3. `.github/workflows/deploy-hf.yml`
```yaml
name: Deploy to Hugging Face
on:
  push:
    branches: [main]
  workflow_dispatch:
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          sparse-checkout: deploy/hf
      - run: pip install huggingface_hub
      - env:
          HF_TOKEN: ${{ secrets.HF_TOKEN }}
          SPACE: ${{ vars.HF_SPACE }}
        run: |
          python - <<'EOF'
          import os
          from huggingface_hub import HfApi
          api = HfApi(token=os.environ["HF_TOKEN"])
          space = os.environ["SPACE"]
          api.upload_folder(repo_id=space, repo_type="space", folder_path="deploy/hf")
          # factory reboot rebuilds without cache, so the Space clones the latest main
          api.restart_space(space, factory_reboot=True)
          EOF
```

### 4. CLAUDE.md
Add one line under Layout: `deploy/hf/` + `.github/workflows/deploy-hf.yml` publish a public preview to a Hugging Face Space on every push to `main`. IT can ignore both.

### 5. Branch, commit, PR to `main`

## One-time setup (you do this, in the browser)
1. huggingface.co → New Space → SDK **Docker** (blank), visibility Public. Note its id, e.g. `<hf-user>/paleotidal`.
2. HF Settings → Access Tokens → create a token with **write** access.
3. In the GitHub repo's Settings → Secrets and variables → Actions, add the secret `HF_TOKEN` (the token) and the variable `HF_SPACE` (the Space id).
4. Run the workflow once from the Actions tab (`workflow_dispatch`), or merge the PR.

## Verification
1. Run the CLAUDE.md load check (the app code itself doesn't change).
2. Optionally test locally: `docker build -t paleotidal deploy/hf && docker run -p 3838:3838 paleotidal`. Note this clones `main` from GitHub, not your local working tree.
3. The Action goes green, and the Space's build logs show `renv::restore()` finishing (expect roughly 5–15 min).
4. On the Space URL, check that the map loads, layers swap and animate, a cell click shows its time series (that exercises DuckDB), and the Patagonia/PALTIDE2 shelves work.
5. Push a trivial change to `main` and confirm the Space rebuilds and shows it.

Skipped: caching packages between builds (every rebuild reinstalls them). Add a prebuilt GHCR image if the build time starts to hurt.
