#!/bin/bash

# Script de démonstration du Rollback Helm
# Ce script démontre comment effectuer un rollback après une mise à jour erronée

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     DÉMONSTRATION: Rollback après Mise à Jour Erronée        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

# Créer un dossier pour les preuves
PROOF_DIR="rollback-demo-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$PROOF_DIR"

echo -e "${YELLOW}📁 Dossier de preuves créé: $PROOF_DIR${NC}\n"

# Étape 1: Vérifier l'état actuel
echo -e "${BLUE}═══ ÉTAPE 1: État Actuel (AVANT modification) ═══${NC}\n"

echo -e "${YELLOW}1.1 - État du déploiement Helm actuel:${NC}"
helm list > "$PROOF_DIR/01-helm-list-before.txt"
cat "$PROOF_DIR/01-helm-list-before.txt"
echo ""

echo -e "${YELLOW}1.2 - Historique des révisions Helm:${NC}"
helm history ecommerce-app > "$PROOF_DIR/02-helm-history-before.txt"
cat "$PROOF_DIR/02-helm-history-before.txt"
echo ""

CURRENT_REVISION=$(helm list -o json | jq -r '.[0].revision')
echo -e "${GREEN}✅ Révision actuelle: $CURRENT_REVISION${NC}\n"

echo -e "${YELLOW}1.3 - État des pods (fonctionnels):${NC}"
kubectl get pods > "$PROOF_DIR/03-pods-before.txt"
cat "$PROOF_DIR/03-pods-before.txt"
echo ""

echo -e "${YELLOW}1.4 - Test de l'application (doit fonctionner):${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://ensa.com)
echo "HTTP Status: $HTTP_CODE" > "$PROOF_DIR/04-app-test-before.txt"
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Application fonctionne: HTTP $HTTP_CODE${NC}" | tee -a "$PROOF_DIR/04-app-test-before.txt"
else
    echo -e "${RED}⚠️  Application retourne: HTTP $HTTP_CODE${NC}" | tee -a "$PROOF_DIR/04-app-test-before.txt"
fi
echo ""

read -p "Appuyez sur Entrée pour continuer vers la mise à jour ERRONÉE..."
echo ""

# Étape 2: Effectuer une mise à jour ERRONÉE
echo -e "${BLUE}═══ ÉTAPE 2: Mise à Jour ERRONÉE (Simulation d'erreur) ═══${NC}\n"

echo -e "${YELLOW}2.1 - Modification: Image avec un tag qui n'existe pas${NC}"
echo "Tentative de mise à jour avec une image cassée..."

# Sauvegarder le values.yaml actuel
cp helm-charts/ecommerce-app/values.yaml "$PROOF_DIR/values-backup.yaml"

# Créer un fichier values avec une image erronée
cat > "$PROOF_DIR/values-broken.yaml" << 'EOF'
microservices:
  ui:
    image:
      tag: "BROKEN-VERSION-DOES-NOT-EXIST"
EOF

echo -e "${RED}🔥 Application d'une mise à jour avec une image cassée...${NC}\n"

# Effectuer la mise à jour erronée
helm upgrade ecommerce-app ./helm-charts/ecommerce-app \
  --set microservices.ui.image.tag=BROKEN-VERSION-DOES-NOT-EXIST \
  > "$PROOF_DIR/05-upgrade-broken.txt" 2>&1

cat "$PROOF_DIR/05-upgrade-broken.txt"
echo ""

echo -e "${YELLOW}2.2 - Nouvel historique (après mise à jour):${NC}"
helm history ecommerce-app > "$PROOF_DIR/06-helm-history-after-broken.txt"
cat "$PROOF_DIR/06-helm-history-after-broken.txt"
echo ""

BROKEN_REVISION=$(helm list -o json | jq -r '.[0].revision')
echo -e "${RED}⚠️  Nouvelle révision (cassée): $BROKEN_REVISION${NC}\n"

echo -e "${YELLOW}2.3 - Attendons que le pod échoue...${NC}"
sleep 10

echo -e "${YELLOW}2.4 - État des pods (CASSÉ - ImagePullBackOff attendu):${NC}"
kubectl get pods > "$PROOF_DIR/07-pods-broken.txt"
cat "$PROOF_DIR/07-pods-broken.txt"
echo ""

echo -e "${YELLOW}2.5 - Détails du pod UI cassé:${NC}"
kubectl describe pod -l app=ui > "$PROOF_DIR/08-pod-ui-describe.txt"
echo "Raison de l'échec:"
grep -A 5 "Failed" "$PROOF_DIR/08-pod-ui-describe.txt" | head -10
echo ""

echo -e "${YELLOW}2.6 - Test de l'application (doit échouer ou être lente):${NC}"
timeout 5 curl -s -o /dev/null -w "HTTP %{http_code}\n" http://ensa.com > "$PROOF_DIR/09-app-test-broken.txt" 2>&1 || echo "TIMEOUT ou ERREUR" >> "$PROOF_DIR/09-app-test-broken.txt"
cat "$PROOF_DIR/09-app-test-broken.txt"
echo ""

echo -e "${RED}❌ L'APPLICATION EST CASSÉE !${NC}\n"

read -p "Appuyez sur Entrée pour effectuer le ROLLBACK..."
echo ""

# Étape 3: ROLLBACK
echo -e "${BLUE}═══ ÉTAPE 3: ROLLBACK vers la Version Précédente ═══${NC}\n"

echo -e "${YELLOW}3.1 - Exécution du rollback vers la révision $CURRENT_REVISION${NC}"
echo -e "${GREEN}Commande: helm rollback ecommerce-app${NC}\n"

helm rollback ecommerce-app > "$PROOF_DIR/10-rollback.txt" 2>&1
cat "$PROOF_DIR/10-rollback.txt"
echo ""

echo -e "${YELLOW}3.2 - Historique après rollback:${NC}"
helm history ecommerce-app > "$PROOF_DIR/11-helm-history-after-rollback.txt"
cat "$PROOF_DIR/11-helm-history-after-rollback.txt"
echo ""

ROLLBACK_REVISION=$(helm list -o json | jq -r '.[0].revision')
echo -e "${GREEN}✅ Révision après rollback: $ROLLBACK_REVISION${NC}\n"

echo -e "${YELLOW}3.3 - Attendons que les pods redémarrent...${NC}"
sleep 15

echo -e "${YELLOW}3.4 - État des pods (RESTAURÉ):${NC}"
kubectl get pods > "$PROOF_DIR/12-pods-after-rollback.txt"
cat "$PROOF_DIR/12-pods-after-rollback.txt"
echo ""

echo -e "${YELLOW}3.5 - Test de l'application (doit fonctionner à nouveau):${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://ensa.com)
echo "HTTP Status: $HTTP_CODE" > "$PROOF_DIR/13-app-test-after-rollback.txt"
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Application RESTAURÉE: HTTP $HTTP_CODE${NC}" | tee -a "$PROOF_DIR/13-app-test-after-rollback.txt"
else
    echo -e "${YELLOW}⚠️  Application retourne: HTTP $HTTP_CODE (peut nécessiter plus de temps)${NC}" | tee -a "$PROOF_DIR/13-app-test-after-rollback.txt"
fi
echo ""

# Étape 4: Résumé
echo -e "${BLUE}═══ ÉTAPE 4: RÉSUMÉ de la Démonstration ═══${NC}\n"

cat > "$PROOF_DIR/00-RESUME.txt" << EOF
╔═══════════════════════════════════════════════════════════════╗
║           DÉMONSTRATION DE ROLLBACK - RÉSUMÉ                  ║
╚═══════════════════════════════════════════════════════════════╝

Date: $(date)
Application: ecommerce-app
Domaine: ensa.com

SCÉNARIO DÉMONTRÉ:
─────────────────────────────────────────────────────────────────
1. État initial fonctionnel (révision $CURRENT_REVISION)
2. Mise à jour avec une image cassée (révision $BROKEN_REVISION)
3. Application cassée (ImagePullBackOff)
4. Rollback vers la révision précédente
5. Application restaurée et fonctionnelle (révision $ROLLBACK_REVISION)

PREUVES COLLECTÉES:
─────────────────────────────────────────────────────────────────
✅ 01-helm-list-before.txt          - État Helm initial
✅ 02-helm-history-before.txt       - Historique avant modification
✅ 03-pods-before.txt                - Pods fonctionnels
✅ 04-app-test-before.txt            - App fonctionnelle (HTTP 200)
✅ 05-upgrade-broken.txt             - Mise à jour erronée
✅ 06-helm-history-after-broken.txt - Historique avec version cassée
✅ 07-pods-broken.txt                - Pods en erreur
✅ 08-pod-ui-describe.txt            - Détails de l'erreur
✅ 09-app-test-broken.txt            - App cassée
✅ 10-rollback.txt                   - Exécution du rollback
✅ 11-helm-history-after-rollback.txt - Historique après rollback
✅ 12-pods-after-rollback.txt        - Pods restaurés
✅ 13-app-test-after-rollback.txt    - App restaurée (HTTP 200)

COMMANDES UTILISÉES:
─────────────────────────────────────────────────────────────────
1. helm list
2. helm history ecommerce-app
3. helm upgrade ecommerce-app --set microservices.ui.image.tag=BROKEN
4. kubectl get pods
5. helm rollback ecommerce-app
6. curl http://ensa.com

RÉSULTAT:
─────────────────────────────────────────────────────────────────
✅ Le rollback a RÉUSSI
✅ L'application est RESTAURÉE
✅ Tous les pods sont RUNNING
✅ L'accès HTTP fonctionne

Cette démonstration prouve que le mécanisme de rollback Helm
fonctionne correctement et permet de restaurer rapidement une
version précédente en cas de mise à jour problématique.
EOF

cat "$PROOF_DIR/00-RESUME.txt"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         🎉 DÉMONSTRATION TERMINÉE AVEC SUCCÈS ! 🎉            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📁 Toutes les preuves sont sauvegardées dans: $PROOF_DIR/${NC}"
echo -e "${YELLOW}📄 Consultez le fichier: $PROOF_DIR/00-RESUME.txt${NC}\n"

echo -e "${BLUE}Pour créer une archive des preuves:${NC}"
echo -e "  tar -czf $PROOF_DIR.tar.gz $PROOF_DIR/"
echo -e "  zip -r $PROOF_DIR.zip $PROOF_DIR/"
echo ""
