#!/bin/bash
set -e

REPO=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/github/Sean_Li_CutTag_mm39_2026

cd "$REPO/site_src"
make html

cd "$REPO"
rsync -av --delete site_src/build/html/ docs/
touch docs/.nojekyll

git add -A
git commit -m "Update project documentation" || true
git push
