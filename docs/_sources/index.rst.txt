Welcome to CUT&Tag Analysis Pipeline!
=====================================

This documentation covers the comprehensive workflow from raw fastq files to differential peak analysis for H3K27ac and H3K4me1.
.. toctree::
   :maxdepth: 2
   :caption: Contents:

   pipeline_index
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
   :caption: Module 2: Peak & Signal

   module2_peak_calling/step5_dual_track_signal
   module2_peak_calling/step6_seacr

.. toctree::
   :maxdepth: 2
   :caption: Module 3: DE Analysis

   module3_quantitative_DE/step7_cps_generation
   module3_quantitative_DE/step8_quantification
   module3_quantitative_DE/step9_manorm2_de

.. toctree::
   :maxdepth: 2
   :caption: Module 4: Downstream

   module4_downstream/step10_annotation
   module4_downstream/step11_summarize_organize
   module4_downstream/step12_PCA

.. toctree::
   :maxdepth: 1
   :caption: Appendix

   appendix/appendix_index
