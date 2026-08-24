# Brief — frictions de runtime observées sur un vrai run grok (2026-08-21)

## D'où vient ce dossier

Ces constats viennent d'un run Orca réel et complet : `run_73627a191505` sur le dépôt
`adamelhirch/candigo`, 5 tâches, 5 PR mergées (#59-#63), 5 dispatches grok lancés via la recette
officielle de `skills/orca-orchestrate/runtimes.md`. **Tout ce qui suit a été mesuré pendant
l'exécution, pas supposé.** C'était le premier run réel sur le host grok ajouté par le commit
`4bc69d3` (« add Grok as a fourth agent host »).

Le run a réussi — mais il a réussi *parce que* le coordinateur a contourné les points ci-dessous
à la main. Un coordinateur qui suit `runtimes.md` à la lettre, sans surveiller, se serait arrêté
au premier worker.

## Constats, du plus grave au plus bénin

### 1. L'invite de confiance de grok bloque le worker, et rien ne la mentionne
Au tout premier lancement dans un dépôt, grok affiche :

```
Do you trust the contents of this directory?
  /Users/.../CandiGO-deploy
  Yes, proceed   y      No, quit   n
```

Il attend indéfiniment. **`--always-approve` ne couvre pas cette invite** — c'est une porte
distincte des permissions d'outils. `runtimes.md` n'en dit rien.

Gravité : un worker bloqué là est *indiscernable* d'un worker en train de travailler. Si le
coordinateur avait lié le dispatch puis attendu, il aurait attendu 60 minutes un worker qui
n'avait jamais lu sa tâche.

Atténuation constatée : la confiance porte sur **le dépôt**, pas sur le worktree. Une seule fois
par repo (vérifié sur 4 lancements suivants, tous sans invite).

### 2. Contradiction interne : `worker-read` ne marche pas par le chemin que `runtimes.md` impose
`runtimes.md` vend grok avec « has a real headless mode » et le guide `orchestration` annonce que
`worker-read` sait rendre « the exact hook-reported ... Grok transcript ».

Mesuré sur les **5** dispatches : `source: "terminal"`, `fallbackReason: "session_not_reported"`,
liste de messages **vide**.

La cause est structurelle : `runtimes.md` impose `terminal create --command "grok --agent worker
--always-approve"` pour sélectionner le profil permissif — mais ce chemin fait du worker un
`external_terminal`, dont la session grok n'est jamais rapportée à Orca. **La recette prescrite
détruit l'avantage annoncé par la même page.**

C'est le point le plus important du dossier : le choix du runtime grok avait été justifié, dans le
plan du run, précisément par cette capacité de lecture de transcript. Elle n'existe pas.

### 3. `orca terminal wait --for tui-idle` n'est pas une garantie de disponibilité
Deux modes de panne observés le même jour :
- `satisfied: false` pendant l'invite de confiance (correct, mais muet sur la cause).
- `satisfied: true` **alors que grok n'avait pas démarré** : l'écran ne montrait que le shell avec
  la commande encore affichée. Lier le dispatch à cet instant injecte la tâche **dans un shell**.

Or `runtimes.md` fait de `tui-idle` l'étape de disponibilité des **trois** recettes supervisées.
Le contournement retenu : lire l'écran et attendre les marqueurs réels du TUI (`always-approve`
dans la barre d'état **et** l'invite `❯`).

### 4. `worker-release` ne termine jamais le ménage sur la recette officielle
Retour systématique : `retained / external_terminal`. Il faut `orca terminal close` à la main.
C'est écrit dans les « hard-won notes » de `orca-orchestrate`, mais ça signifie que la commande
de nettoyage ne nettoie pas dans le cas **nominal** de la recette prescrite. Et l'ordre compte :
fermer le terminal **avant** `worktree rm`, sinon `close` renvoie `ok: false` (le terminal est
déjà parti avec le worktree).

### 5. `gh pr merge --delete-branch` échoue toujours du premier coup
`cannot delete branch 'x' used by worktree at '...'`. L'ordre prescrit par `orca-orchestrate` est
merge → release → `worktree rm`, donc la suppression de branche échoue **à chaque tâche**, par
construction. 5 tâches = 5 échecs cosmétiques qui polluent la sortie et peuvent faire croire à un
problème réel.

### 6. `check --peek` sans Run lié ment silencieusement
Sans Run lié : `{ "messages": [], "count": 0 }` avec `ok: true`.
`gate-list` dans la même situation : erreur explicite `run_required`.

Deux commandes du même sous-système, deux comportements opposés face à la même cause — et c'est
la version *silencieuse* qui est dangereuse. `/orca-resume` demande explicitement de lire la boîte
avec `check --peek` **pendant** l'orientation, donc potentiellement avant toute liaison de Run :
la reprise conclut « 0 mail non lu » alors qu'elle n'a rien lu du tout. Rencontré tel quel au
début de la session.

### 7. `check --wait --types worker_done,escalation,question` se réveille sur les heartbeats
Conforme au guide (« Type filters decide when a waiter wakes; the returned actionable Delivery is
still the oldest full batch »), mais l'effet pratique mérite d'être dit dans le runbook : les
fenêtres d'attente reviennent souvent sans rien d'actionnable, et un coordinateur qui n'a pas lu
cette phrase croit que ses filtres sont cassés.

### 8. `orca orchestration check --json` peut émettre plusieurs objets JSON concaténés
Casse tout `json.load` naïf. Il faut décoder en boucle (`raw_decode`). Soit c'est un défaut du
CLI, soit ça doit être dit aux agents qui parsent.

### 9. `/orca-tasks` étape 5 contredit un marqueur de setup légitime
`/orca-tasks` présente le miroir d'issues comme « required by the tracker choice ». Le marqueur du
projet enregistrait, en toutes lettres et avec un motif documenté, « `github` — suivi par PR
uniquement, **pas de miroir d'issues** ». Aucune règle de précédence n'existe entre les deux : le
coordinateur a dû trancher seul et remonter le conflit à l'utilisateur.

## Ce que j'attends de toi

Tu es orchestrateur sur `adamelhirch/orca-skills`. Traite ce dossier comme une **entrée à
instruire**, pas comme une liste de correctifs à appliquer tels quels — plusieurs points ont
plusieurs solutions défendables (documenter vs corriger ; changer la recette vs changer la
promesse ; toucher au CLI est hors de ce dépôt).

Attendu :
1. Une passe de vérification : reproduis ou infirme ce que tu peux dans ce dépôt (les points 1-5
   touchent `skills/orca-orchestrate/runtimes.md` et `SKILL.md`, le 6 touche `skills/orca-resume`,
   le 9 touche `skills/orca-tasks`). **Ne prends pas mes constats pour argent comptant** :
   ils viennent d'un autre dépôt, sur une seule machine, avec grok 1.0.5.
2. Un plan discuté avec le propriétaire avant toute écriture (`/orca-plan` existe dans ce dépôt).
   Le point 2 est le plus structurant : il faut choisir entre corriger la recette pour préserver
   les transcripts, ou retirer une promesse que la recette ne peut pas tenir.
3. L'exécution ensuite, aux conventions du dépôt : une branche = une PR = une responsabilité, CI
   verte avant merge, `scripts/validate-skills.mjs` doit passer.

Le propriétaire est `adamelhirch`. Commence par lire `README.md`, `docs/COMPAT.md` et
`skills/orca-orchestrate/runtimes.md`, puis viens lui parler avant d'écrire quoi que ce soit.
