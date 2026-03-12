# B4. Parametric vs Local Regression in MAnorm2, Including Modified Local Settings

## Overview

A major methodological issue in this project was how to fit the mean-variance relationship in MAnorm2 for differential enrichment analysis. In principle, MAnorm2 supports both parametric and local-regression-based fitting strategies, but in practice these approaches did not behave identically on this dataset.

Because the project included:

- multiple CPS-defined comparison spaces
- limited replicate numbers in many comparisons
- strong biological differences in some contexts
- sex-linked loci with highly asymmetric signal behavior

it was important to compare the available fitting strategies rather than assume that one default option would always be best.

This section summarizes how parametric fitting, default local regression, and modified local regression were compared in this project, and why the final workflow retained parametric fitting as the primary model with modified local regression reserved as a fallback.

---

## Why This Comparison Was Necessary

In MAnorm2, the mean-variance fit directly affects downstream empirical Bayes moderation and therefore influences:

- standard error estimation
- test statistic behavior
- p-values and adjusted p-values
- the apparent significance of biologically important loci

This means that the choice of fitting strategy is not a cosmetic implementation detail. It can materially influence which loci appear significant and how biologically plausible the final differential results look.

Because this project involved several comparisons with uneven variance structure and limited replicate counts, fitting behavior had to be evaluated empirically rather than accepted uncritically.

---

## The Three Fitting Strategies Considered

### 1. Parametric fitting

This was the primary model considered by the workflow.

Representative implementation:

```r
conds_param <- fitMeanVarCurve(
  conds,
  method = "parametric",
  occupy.only = TRUE,
  max.iter = 100,
  init.coef = c(0.1, 10)
)
```

Conceptually, the parametric approach imposes a specific functional form on the mean-variance relationship. When the data behave sufficiently well, this can provide a stable and interpretable fit.

### 2. Default local regression

This was evaluated as a nonparametric alternative.

Representative implementation:

```r
conds_local <- fitMeanVarCurve(
  conds,
  method = "local regression",
  occupy.only = TRUE
)
```

This approach is more flexible and can adapt to irregular mean-variance structure, but it may also behave more conservatively or less stably depending on how the local fit is shaped by the data.

### 3. Modified local regression

The project did not rely only on default local regression. A modified local fallback strategy was also tested:

```r
tmp_conds <- fitMeanVarCurve(
  conds,
  method = "local regression",
  occupy.only = FALSE
)

tmp_conds <- estimatePriorDf(
  tmp_conds,
  occupy.only = TRUE
)
```

This modified local configuration was designed to improve the stability of local regression in difficult comparisons and to provide a more robust fallback than the default local setting alone.

---

## What the Project Observed in Practice

The main conclusion from project-level testing was that these models were **not interchangeable**.

### Parametric fitting often behaved well

In many comparisons, parametric fitting converged successfully and produced results that were:

- stable
- interpretable
- biologically plausible

This was especially important because the project did not want to abandon a working parametric fit merely because a nonparametric option was available.

### Default local regression was not uniformly better

Although local regression is often attractive in principle because of its flexibility, default local regression did not always produce the most convincing results in this dataset. In some contexts, it appeared to behave too conservatively or to weaken signal at loci that were biologically expected to be strong.

### Modified local regression was useful as a fallback

The modified local configuration improved the usefulness of the local-regression family in difficult cases. It gave the workflow a more fault-tolerant nonparametric alternative without making local regression the default for all comparisons.

---

## Why the Comparison Was Biologically Important

This was not only a statistical or numerical question. The fitting strategy affected biologically important loci.

In particular, project-level review showed that some sex-linked loci behaved differently depending on whether parametric or local regression was used. For example, male-specific chrY-associated genes such as **Sry** and **Eif2s3y** could appear much more significant under the parametric fit than under default local regression.

This mattered because:

- these loci had strong biological expectations
- they served as useful sanity checks for model behavior
- the project did not want to adopt a model that systematically weakened obviously plausible biology without strong justification

Thus, model comparison was grounded not only in abstract fit theory but also in locus-level biological interpretability.

---

## Why Parametric Was Retained as the Primary Model

After comparison, the workflow retained parametric fitting as the primary strategy for several reasons.

### 1. It often converged successfully

When the parametric model converged, it usually provided a clean and usable fit.

### 2. It produced biologically sensible results

In several important loci and comparisons, parametric fitting preserved stronger biologically plausible signal than default local regression.

### 3. Local regression was not uniformly superior

The project did not find evidence that local regression should replace parametric fitting as the universal default.

### 4. The workflow already had a robust fallback

Because modified local regression was available as a fallback, the workflow did not need to make local regression the primary strategy just to achieve robustness.

---

## Why Modified Local Was Kept as the Fallback

Even though parametric was retained as primary, the project still needed a strategy for difficult comparisons where parametric fitting genuinely failed.

Modified local regression served this role because it:

- allowed difficult comparisons to complete
- reduced dependence on default local settings alone
- provided a more robust nonparametric alternative when necessary
- preserved pipeline continuity without forcing all comparisons into the same model class

Thus, the project’s final logic was not “parametric only” but rather:

- **parametric by default**
- **modified local when true failure requires fallback**

---

## Relationship to the Warning / Convergence Decision

This section is closely related to the separate question of whether warnings should automatically invalidate the parametric fit.

The workflow’s final logic was:

- compare parametric and local behavior empirically
- keep parametric if it truly converged
- reserve modified local for genuine failure cases

Thus, the parametric vs local comparison and the warning-handling decision were part of the same broader design philosophy.

---

## Key Take-Home Message

In this project, parametric fitting, default local regression, and modified local regression did not behave equivalently. Parametric fitting was retained as the primary MAnorm2 strategy because it often converged successfully and preserved strong biologically plausible signal, including at important sex-linked loci. Modified local regression was kept as a practical fallback for difficult comparisons where parametric fitting genuinely failed, giving the workflow both interpretability and fault tolerance.
