Sean Li CUT&Tag Analysis Pipeline
=================================

This documentation describes the current maintained CUT&Tag workflow implemented by the scripts in this repository.

The active pipeline uses Bowtie2, filtered mm39 BAM files, CTK4me1 SEACR/CPS peak processing, CTK27ac MACS3 peak processing, profile_bins quantification, edgeR differential enrichment analysis, and edgeR-based PCA QC.

Historical pages from earlier MAnorm2-centered documentation are retained under Appendix or Legacy, but the module pages below reflect the current code.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   how_to_run_full_pipeline

.. toctree::
   :maxdepth: 2
   :caption: Module 1: Preprocessing

   module1_preprocessing/step1_reference
   module1_preprocessing/step2_qc
   module1_preprocessing/step3_alignment
   module1_preprocessing/step4_bam_process

.. toctree::
   :maxdepth: 2
   :caption: Module 2: Peak Calling

   module2_peak_calling/step5_ctk27ac_macs3
   module2_peak_calling/step6_ctk4me1_seacr_cps

.. toctree::
   :maxdepth: 2
   :caption: Module 3: Quantification and Differential Analysis

   module3_quantitative_DE/step7_bam_to_bed
   module3_quantitative_DE/step8_quantification
   module3_quantitative_DE/step9_edger_de

.. toctree::
   :maxdepth: 2
   :caption: Module 4: Downstream

   module4_downstream/step10_summary_organize
   module4_downstream/step11_pca_qc

.. toctree::
   :maxdepth: 2
   :caption: Appendix

   appendix/appendix_index

.. toctree::
   :maxdepth: 1
   :caption: Legacy

   legacy/legacy_index
