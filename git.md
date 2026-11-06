# Git – TP Tiroir

Pour chaque situation : les commandes exactes, dans l'ordre, puis une phrase d'explication.
`<...>` est à remplacer par votre valeur (identifiant GitHub, nom de branche, hash de commit).

---

## 1. Créer le dépôt, premier commit avec le README, relier à GitHub et pousser

```bash
git init -b main
echo "# Tiroir" > README.md
git add README.md
git commit -m "Initial commit : ajout du README"
git remote add origin https://github.com/<utilisateur>/tiroir.git
git push -u origin main
```

`git init -b main` crée le dépôt local avec la branche `main`, `git add` + `git commit` enregistrent le README dans un premier commit, `git remote add` déclare le dépôt GitHub vide sous le nom `origin`, et `git push -u` envoie `main` dessus en mémorisant ce lien pour les prochains `git push` / `git pull`.

---

## 2. Travailler le MCD sur une branche, fusionner dans `main` en gardant la trace, supprimer la branche

```bash
git switch -c mcd
git add mcd.png
git commit -m "Ajout du MCD"
git switch main
git merge --no-ff mcd -m "Merge branch 'mcd'"
git branch -d mcd
```

On travaille sur une branche `mcd` créée avec `git switch -c`, puis on revient sur `main` et `git merge --no-ff` force un commit de fusion, ce qui conserve dans l'historique la trace de l'existence de la branche (même si `main` n'avait pas avancé), et `git branch -d` supprime ensuite la branche devenue inutile. (Si la branche avait été poussée : `git push origin --delete mcd`.)

---

## 3. Conflit dans `README.md` lors d'une fusion

Voir les fichiers en conflit, résoudre et terminer :

```bash
git status
git diff --name-only --diff-filter=U
# ouvrir README.md, choisir le contenu final et supprimer les lignes <<<<<<<, =======, >>>>>>>
git add README.md
git commit --no-edit
```

`git status` et `git diff --name-only --diff-filter=U` listent les fichiers « unmerged » (en conflit), on édite `README.md` pour ne garder que le contenu voulu sans les marqueurs de conflit, `git add` indique à Git que le conflit est résolu, et `git commit --no-edit` termine la fusion avec le message de fusion prérempli.

Tout annuler à la place :

```bash
git merge --abort
```

`git merge --abort` abandonne la fusion en cours et remet le dépôt exactement dans l'état d'avant le `git merge`.

---

## 4. `git push` refusé : un coéquipier a poussé avant moi

```bash
git pull --rebase origin main
git push origin main
```

`git pull --rebase` récupère les commits du coéquipier puis rejoue mes commits locaux par-dessus, ce qui donne un historique linéaire sans commit de fusion, et `git push` peut alors être accepté. (Si un conflit apparaît : le résoudre, `git add <fichier>`, puis `git rebase --continue`.)

---

## 5. Réunir 3 commits « wip » déjà poussés en un seul et mettre à jour GitHub sans écraser le travail d'un autre

```bash
git rebase -i HEAD~3
# dans l'éditeur : laisser "pick" sur la 1re ligne, remplacer "pick" par "squash" (ou "fixup") sur les 2 autres,
# enregistrer, puis écrire le message final du commit unique
git push --force-with-lease origin <ma-branche>
```

`git rebase -i HEAD~3` ouvre la liste des 3 derniers commits pour les fusionner en un seul (`squash` garde les messages à fusionner, `fixup` les jette), et comme l'historique a été réécrit il faut forcer le push avec `--force-with-lease`, qui refuse d'écraser la branche distante si quelqu'un d'autre y a poussé un commit que je n'ai pas encore récupéré, contrairement à `--force`, qui l'écraserait aveuglément.

---

## 6. Corriger la faute dans le message du dernier commit (pas encore poussé)

```bash
git commit --amend -m "Message corrigé sans faute"
```

`git commit --amend -m` remplace le dernier commit par un nouveau commit identique, avec le message corrigé ; c'est sans danger ici puisque le commit n'a pas encore été poussé.

---

## 7. `git reset --hard HEAD~1` tapé par erreur : récupérer le commit perdu

```bash
git reflog
git reset --hard HEAD@{1}
```

`git reflog` affiche le journal de tous les déplacements de `HEAD`, où le commit « perdu » apparaît toujours, et `git reset --hard HEAD@{1}` replace la branche sur l'état juste avant l'erreur (on peut aussi viser directement le commit : `git reset --hard <hash-du-commit>`).

---

## 8. Travail en cours + bug urgent sur `main` : mettre de côté, corriger, revenir

```bash
git stash push -m "travail en cours"
git switch main
# ... corriger le bug, git add, git commit, git push ...
git switch <ma-branche>
git stash pop
```

`git stash push` range les modifications non commitées dans une pile et nettoie le répertoire de travail, ce qui permet de basculer sur `main` pour traiter l'urgence, puis `git stash pop` réapplique les modifications mises de côté sur ma branche et les retire de la pile. (Ajouter `-u` à `git stash push` pour inclure aussi les nouveaux fichiers non suivis.)

---

## 9. Annuler un commit déjà poussé sur `main` sans réécrire l'historique

```bash
git switch main
git revert <hash-du-commit>
git push origin main
```

`git revert` crée un nouveau commit qui applique l'inverse des modifications du commit visé, de sorte que l'historique existant reste intact et que le `git push` se fait normalement, sans force. (Si le commit à annuler est un commit de fusion : `git revert -m 1 <hash>`.)

---

## 10. Copier sur `main` un seul commit d'une autre branche

```bash
git switch main
git log --oneline <autre-branche>
git cherry-pick <hash-du-commit>
```

On se place sur `main`, `git log` sur l'autre branche permet de repérer le hash du commit voulu, et `git cherry-pick` rejoue uniquement ce commit sur `main` en créant un nouveau commit équivalent, sans rapatrier le reste de l'autre branche.
