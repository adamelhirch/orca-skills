# Plan — orca-skills: skill `orca-freebuff` pour workers TUI pilotés au terminal

Status: draft — à approuver (spike de faisabilité validé ce jour)

## Objectif

Ajouter à la team de workers Orca des agents **gratuits freebuff** (CLI fourni par
freebuff.com, financé par la pub, modèle DeepSeek V4 Flash 07/31 « unlimited »). Freebuff n'est
pas un agent Orca natif et n'a **aucun mode headless** : la seule voie est de le piloter comme
un TUI dans un terminal de worktree, via `orca terminal send/read/wait`. Livrable : une skill
dédiée `skills/orca-freebuff/SKILL.md` codifiant la recette complète (préflight, dispatch,
launch, injection de tâche, boucle de complétion par marqueur, `worker_done` impersoné, merge,
cleanup) pour qu'un orchestrateur puisse dispatcher une tâche à un worker freebuff sans
improviser.

## Faits vérifiés ce jour (spike réel)

- CLI `freebuff` v0.0.149 installé (`~/.local/bin/freebuff`, npm global ; launcher télécharge
  un binaire Bun dans `~/.config/manicode/freebuff`). Options : `login` (sous-commande),
  `--continue`, `--cwd`. **Aucun mode headless** — `--print`, `-p`, `--json`,
  `--non-interactive`, `--batch`, `--exec`, `--auto`, `--script`, `--prompt` sont tous rejetés
  en `unknown option`.
- Le SDK Codebuff (`@codebuff/sdk`) est une voie **payante** (API key) → hors périmètre
  « gratuit ».
- Spike sur worktree réel `spike-freebuff` (isolé) : freebuff se lance en TUI dans un terminal
  Orca, affiche **DeepSeek V4 Flash 07/31 · unlimited**, aucun login de compte ni pub bloquantes
  (déjà authentifié via `~/.config/manicode/credentials.json` ; pas de sélecteur de modèle).
- L'injection de prompt fonctionne : `orca terminal send --text "<tâche>" --enter` est traité
  par le modèle (phase Thinking visible, réponse rendue).
- **`tui-idle` seul ≠ fin de tâche** : il satisfait pendant les micro-pauses de streaming. La fin
  se détecte par un **marqueur unique demandé dans la réponse + boucle de polling**
  (wait tui-idle → read → grep du marqueur ; répéter), car l'extraction du texte final est
  noyée dans le rendu TUI (ASCII-art + écho du prompt + thinking).
- **Joint d'intégration orchestrateur prouvé** : `worker-start` et `dispatch --inject` refusent
  un terminal non-agent (`agent_unconfigured`). Le chemin qui marche (validé de bout en bout,
  task `completed` avec provenance `reportedBy: <terminal freebuff>`) :
  1. `orca orchestration dispatch --task <id> --run <run_id> --to <worker_handle> --json`
     (sans `--inject`) → crée un dispatch lié au terminal TUI.
  2. Prompt envoyé manuellement via `terminal send` (pas d'injection runtime).
  3. À la complétion (marqueur + idle), le coordinateur envoie depuis **son** cockpit :
     `orca orchestration send --type worker_done --subject succeeded --outcome succeeded
     --task-id <id> --dispatch-id <ctx_id> --from <worker_handle> --run <run_id> --json`
     → lifecycle `action: completed`, task marquée `completed` automatiquement.
- Le worker freebuff n'exécute pas de commandes shell (tout texte envoyé part dans le prompt du
  modèle) → **le `worker_done` est toujours impersoné par le coordinateur** (`--from
  <worker_handle>`) ; c'est le seul écart documenté par rapport au runbook `/orca-orchestrate`,
  où le worker s'annonce lui-même.

## Tâches

### t1 — Écrire `skills/orca-freebuff/SKILL.md` (isolé: no)

Repo sans setup marker, sans tracker ni CI → run non isolé sur le worktree principale
(integration pass), fait par le coordinateur, sans worker (comme la PR #1).

Contenu de la skill :
- Frontmatter calqué sur les skills du repo (`disable-model-invocation: true`, invocation
  `/orca-freebuff`) + row dans le README.
- Préflight : vérifier le CLI (`freebuff --version`), le login (`~/.config/manicode/
  credentials.json`), le worktree personnel, les quotas (sessions premium/jour, fallback Flash).
- Dispatch : run-use → task-create → `worktree create` (name slug) → `terminal create --command
  "freebuff"` → `terminal wait --for tui-idle` (écran d'accueil ignorable) →
  `dispatch --task ... --to <handle>` **sans --inject**.
- Injection : prompt de tâche via `terminal send --text ... --enter`, contenant TOUJOURS le
  contrat de marqueur (finir par `FREEBUFF_TASK_DONE` sur sa propre ligne) + les consignes de
  travail (branche actuelle, ne pas pushé soi-même, rapporter un résumé).
- Boucle de complétion : répéter `wait --for tui-idle` + `terminal read` + grep du marqueur,
  avec bornes (fenêtres 60-120 s, timeout global par tâche) ; ne jamais déclarer fini sur un
  seul idle.
- Clôture : vérifier le travail réel (git status/diff dans le worktree, tests si le plan les
  exige) → `worker_done` impersoné (`--from <worker_handle>`) → settle, merge green
  (coordinateur), `worker-release`, `worktree rm --force`, fermer le terminal TUI.
- Échecs : si le marqueur ne sort jamais dans la fenêtre ou si le modèle dérive (ne suit pas le
  contrat), `terminal send` d'une relance bornée, puis gate au user — jamais de redispatch
  silencieux.
- Section « pourquoi pas headless ni SDK » : les flags rejetés et le SDK payant, pour éviter de
  retenter.

### t2 — Validation réelle de la skill (isolé: no)

Après t1, relire la skill et la suivre littéralement sur un mini-run réel dans un worktree de
test jetable (réutiliser le worktree `spike-freebuff` existant ou en créer un), comme le spike
mais **en suivant la recette écrite** — preuve que les commandes de la skill sont exécutables
telles quelles. Critère de sortie : le mini-run atteint `worker_done succeeded` et la task passe
`completed`, sans éditer `main`. Résultat consigné dans le corps de la PR de t1 (ou commit
suivant).

## Seams / tests

- Pas de code applicatif ni de CI sur ce repo : le gate de t1 = relecture de la skill (lecture
  cohérente de bout en bout, commandes alignées sur le guide `orca-cli` et `orchestration`) +
  validation réelle de t2.
- Le seul risque résiduel déjà acté : `tui-idle` n'est pas un signal de fin fiable — la skill
  l'encode explicitement (marqueur + polling), et la validation t2 l'exerce.