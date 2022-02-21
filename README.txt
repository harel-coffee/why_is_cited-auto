Description of files: 

1) notebook_v2.ipynb -> Main notebook with models to get results for V1 dataset and also V2. 
			For getting results of  V1 dataset set value of DATASET_VERSION parameter
			to 1, or 2 for results of V2 dataset. For running this notebook 
			the sources data (which are already preprocessed) are in folder inputs. 

2) preprocessing_dataset_v1.ipynb -> Notebook which return preprocessed input data 
				     (the abstracts from CORD-19 dataset) also with citations
				     for results of V1 dataset.
				  
3) preprocessing_dataset_v2.ipynb -> Notebook which return preprocessed input data - abstracts
				     from CORD-19 dataset for results of V2 dataset.  

4) folder extraction_citations_V2_dataset contains notebooks which were be used for downloading citations data for V2 dataset. 
   Extration citations for V1 dataset is in notebook preprocessing_dataset_v1.ipynb. 


The notebooks contains not only code, but also  results and graphs generated at the time 
of upload to this repository. Note that due to changes in the versions of libraries and 
supplementary data sources, the results and graphs do not always exactly match with those 
included in the article.

