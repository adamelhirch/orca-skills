# Post-mortem — fiabilité workers & durcissement contrats — 2026-08-24

Run d'observation : ~15 dispatches workers sur CandiGO (orchestrateur Claude Code ; runtimes
opencode + hermes ; modèles deepseek-v4-flash / deepseek-v4-flash-0731 / ox-alpha). Aucune
tâche de ce dossier ne touche le code produit : tout est dans la suite de skills.

## Ce qui a cassé, par catégorie

### Effondrements de modèle (le fait dominant du run)

| Dispatch | Modèle/endpoint | Signature | Coût |
| --- | --- | --- | --- |
| w1-t1, w1-t4, w1-t14 | deepseek-v4-flash (NVIDIA) | boucles littérales (`whatsoever…`, `CEASE-CYCLE`), XML d'appels d'outil émis en texte + `</think>` qui fuit | 3/5 workers, ~35 min, **zéro fichier, zéro commit**, contexte à 3-4 % |
| s-t4 | deepseek-v4-flash-0731 (Deep Infra) | **boucle sémantique** : `Force-push.` ×14 — annonce chaque push, n'en exécute aucun | budget entier brûlé, `interrupted`, contexte 195 K |
| w1-t3 | ox-alpha via Nous Portal | `HTTP 400 — Model is unavailable`, aucun repli configuré | dispatch mort |
| 3× w1 | ox-alpha via OpenRouter | `Empty response (no content or reasoning) after 3 retries`, `response_len=7`, `tool_turns=0` dès le premier tour | 2 redémarrages seuls après ~20 min, 1 mort à 46 min |

Le détecteur maison a raté la boucle sémantique (il cherchait des répétitions *littérales*) et a
produit 2 faux positifs + 1 faux négatif sur les boucles littérales. **Deux fois sur trois,
l'humain a détecté ce que l'outillage a manqué.** Leçon encodée : le screening passe par la
lecture du terminal par le coordinateur, pas par un détecteur naïf.

### Abandons à ~80 % (hermes surtout) — w1-t5/t6/t12/t13

Le worker rend la main avec une liste de « reste à faire » au lieu de settle. Le watchdog
existait mais ne couvrait que « fini sans worker_done ». Corrigé dans `/orca-orchestrate` :
même porte d'entrée, issue différente (pas de finalisation en `succeeded` ; reste découpé en
tâche follow-up qui nomme ce que la branche contient déjà).

### Savoir payé deux fois — w1-t13

Cherche un endpoint que w1-t12 avait documenté dans `windmill/README.md`. Cause racine : aucun
puits de connaissance désigné dans le plan. Corrigé dans `/orca-plan` (**Knowledge sinks**).

### Sorties de sandbox — w1-t1, w1-t4, w1-t6

`brew cleanup` sur l'hôte (~4 Go libérés), `podman machine stop`, skill hermes créée hors
worktree. Trois fois la même cause : le profil permissif nécessaire au run n'a aucune frontière
écrite. Corrigé : section **Sandbox discipline** du contrat worker.

### Violations de contrat — w1-t11, s-t10

Double `worker_done` (« done » sans preuve), tâche déclarée finie sur PR `CONFLICTING` (contrat
qui exigeait « CI verte » mais pas mergeable — défaut du contrat, pas du worker), dérive de spec
déclarée honnêtement (à garder comme comportement à encourager). Corrigé : **Report integrity** +
mergeabilité explicite des deux côtés du gate.

### Conflits de fichiers partagés — windmill/README.md ×4, app/sources/__init__.py ×4

3 rebases au Run 1 ; cible mouvante au Run 2 (merges pendant un rebase → 6 min de marqueurs).
Corrigé : **Shared files** (worker) + **File ownership** et **freeze main mid-rebase**
(plan/orchestrator). La prévention préventive du Run 2 (sérialisation) avait déjà marché :
zéro conflit là où elle était appliquée.

### Erreurs de spec rattrapées par les workers

`db.connect()`→`get_conn()`, `python` vs `python3`, 404 vs 405, `SCHEDULER_INTERNAL`
inexistant, 6 offres/page chez Avature (réfuté : 20). Corrigé : règle **verify spec facts /
mark assumptions** dans `/orca-plan`. Et `plan.md` + `## Merge gate` non versionnés — signalés
par 3 workers avant correction : désormais commit obligatoire avant dispatch (`/orca-setup`,
`/orca-plan`).

### Outillage Orca (hors repo, constaté)

- `agent_prompt_stalled` marqué dispatch+task `failed` chez opencode alors que le prompt est
  livré et l'agent travaille — **5/5 faux positifs**. Contournement : ignorer ce statut tant que
  le terminal montre de l'activité ; à re-probe sur upgrade Orca.
- `--enter` ne soumet pas un prompt long (texte reste en tampon) ; contournement : premier
  caractère non vide + `--enter`.
- `tui-idle` ment (2 terminaux sur 4) — déjà documenté pour grok/hermes, confirmé encore.
- `--ack` attend un `delivery_...`, pas le `msg_...` affiché.

## Correctifs écrits dans cette suite (2026-08-24)

| Fichier | Changement |
| --- | --- |
| `_shared/worker-contract.md` | sections **Report integrity**, **Degenerate-output self-check**, **Sandbox discipline**, **Shared files** ; règle mergeable-or-fail sous `ci: github-actions` |
| `_shared/orchestrator-contract.md` | gate = CI verte **et mergeable** ; freeze de `main` pendant les rebases en vol |
| `orca-orchestrate/runtimes.md` | section **Model reliability and provider fallback** (canary 1 tâche avant fan-out, signatures dégénérées, fallback provider configuré au setup, abandon = signature) |
| `orca-orchestrate/SKILL.md` | screen du modèle avant fan-out ; lecture post-wake des fenêtres `check --wait` ; gate + mergeable ; chemin watchdog abandon ; never-merge-mid-rebase |
| `orca-plan/SKILL.md` | file ownership, knowledge sinks, vérification des faits de spec, modèle nommé si non prouvé, commit du plan approuvé |
| `orca-setup/SKILL.md` | commit du marker (+ plan) avant tout dispatch |
| `orca-freebuff/SKILL.md` | suppression du `gh pr merge --delete-branch` impossible (thread #3 du handoff 2026-08-21) |
| `docs/COMPAT.md` | lignes « Worker models (deepseek family) » et « Supervised-worker contract v3 » |

Non traité ici (défauts CLI Orca, hors repo) : `agent_prompt_stalled` faux positif,
concat JSON de `check --stdout`, `check --peek` silencieux — voir COMPAT et le brief grok.

## À faire ensuite

1. Repasser `install-agents.sh` puis `npx skills add adamelhirch/orca-skills --global --skill '*' -y`
   pour propager les contrats recomposés vers les 4 hôtes (redémarrer les sessions vivantes).
2. Au prochain run : appliquer la règle canary à tout nouveau modèle (1 tâche avant fan-out) et
   noter si les signatures dégénérées sont visibles assez tôt dans le terminal.
3. Le détecteur de dégénérescence reste à réécrire (signatures sémantiques, pas littérales) —
   en attendant, le screening coordonnateur-qui-lit est la défense nominale.
