# B5. Why Parametric Warnings Were Not Automatically Treated as Fit Failure

## Overview

During MAnorm2 parametric mean-variance fitting, warning messages can appear even when the overall fitting procedure ultimately converges successfully. In this project, a key methodological decision was therefore **not** to treat the mere presence of warnings as automatic evidence of model failure.

This section explains why explicit convergence status, rather than warning presence alone, was used as the final criterion for accepting or rejecting the parametric fit.

---

## Why This Became an Important Project-Level Issue

In practice, parametric fitting in MAnorm2 can emit messages such as:

- `glm.fit: algorithm did not converge`
- `NaNs produced`
- `step size truncated due to divergence`

At first glance, these warnings appear severe. It is therefore tempting to conclude that any comparison producing such messages should be discarded from parametric fitting and immediately rerouted to local regression.

However, project-level testing showed that this interpretation was too simplistic.

The key observation was:

> warning messages can arise during intermediate numerical steps even when the overall parametric fitting procedure later reaches a successful final solution.

This meant that the project needed a more careful decision rule.

---

## Why Warning Presence Alone Was Not a Reliable Failure Criterion

### 1. Warnings and final convergence are not the same thing

A warning typically reflects something noteworthy that happened during one iteration or one internal numerical sub-step. It does **not** necessarily mean that the full fitting procedure failed globally.

By contrast, convergence status reflects the behavior of the fitting procedure as a whole.

Thus, warnings and convergence operate at different levels:

- **warnings** describe local numerical difficulty
- **convergence** describes whether the overall fitting process successfully stabilized

Treating them as equivalent would collapse two distinct concepts into one overly aggressive failure rule.

### 2. Parametric fitting sometimes converged despite alarming warnings

In this project, there were comparisons in which parametric fitting emitted multiple warning messages but still ended with explicit successful convergence in the MAnorm2 fit log.

In such cases, replacing the parametric model automatically would have meant discarding a fit that the algorithm itself considered complete.

### 3. Some converged parametric fits were biologically better than the corresponding local alternatives

This was not merely a numerical issue. In several project-relevant comparisons, converged parametric fits produced results that were more biologically convincing than the results from default local regression.

This was especially important at loci where prior biological expectations were strong. Therefore, using “warning present” as an automatic failure rule would not only have been numerically crude, but also biologically counterproductive.

---

## The Decision Rule Used in the Workflow

Because of these observations, the workflow used explicit convergence as the final decision criterion.

A simplified version of the core logic was:

```r
fit_log <- capture.output(
  conds_param <- tryCatch(
    fitMeanVarCurve(
      conds,
      method = "parametric",
      occupy.only = TRUE,
      max.iter = 100,
      init.coef = c(0.1, 10)
    ),
    error = function(e) e
  )
)

param_converged <- any(grepl("Converged\\.", fit_log))
```

The final interpretation was:

- if the model threw a **true error**, fallback was required
- if the model **did not report convergence**, fallback was required
- if the model **did report convergence**, the parametric fit was retained, even if warnings appeared during fitting

This made convergence, not warning presence, the decisive acceptance criterion.

---

## Why This Was More Appropriate Than a Warning-Based Rule

### 1. It respected the actual behavior of the fitting algorithm

The fitting algorithm itself reports whether the process converged. Using that explicit signal is more faithful to the model’s final state than imposing an external warning-based veto rule.

### 2. It avoided unnecessary fallback

If every warning automatically triggered local-regression fallback, then many successfully converged parametric fits would have been discarded unnecessarily.

That would have made the workflow too eager to abandon parametric fitting, even when the final fit was usable and biologically reasonable.

### 3. It preserved continuity with the broader model-comparison logic

This decision was fully consistent with the project’s broader comparison between:

- parametric fitting
- default local regression
- modified local fallback

The project did not assume that local regression was automatically better whenever parametric fitting encountered difficulty. Instead, it treated parametric fitting as acceptable whenever it genuinely converged.

---

## Why This Was Especially Important in This Project

This issue mattered more in this project than it might in a very simple dataset because the comparisons involved:

- limited replicate counts
- heterogeneous variance structures
- strong group differences in some cases
- biologically important loci where model behavior was visibly consequential

Under these conditions, a crude “warnings = fail” rule would have produced too many unnecessary fallback events and could have weakened biologically plausible results.

In other words, the project needed a decision rule that was:

- numerically defensible
- biologically aware
- operationally robust

Using explicit convergence status met those requirements better than a warning-only rule.

---

## Relationship to the Modified Local Fallback

Importantly, the workflow did **not** ignore warnings completely. Rather, it treated warnings as contextual information while reserving fallback for true failure cases.

If the parametric fit:

- threw a real fitting error
- or failed to report convergence

then the workflow switched to the modified local fallback strategy.

This means the project still preserved fault tolerance. It simply did not define fault tolerance in an unnecessarily aggressive way.

---

## Key Take-Home Message

Parametric warnings were not automatically treated as fit failure because warning messages and final convergence are not the same thing. In this project, explicit convergence status was used as the decisive acceptance criterion for the parametric model.

This allowed the workflow to:

- retain successfully converged parametric fits
- avoid unnecessary fallback to local regression
- preserve biologically plausible results in important comparisons
- remain robust by switching to modified local regression only when true failure occurred
