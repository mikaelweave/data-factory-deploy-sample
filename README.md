# Data Factory Deployment Sample

Simple sample showcasing how you can deploy Azure Data Factories between environments. This sample is an implementation of (my interpertation of) the recommendations from the [Azure Data Factory Documentation](https://docs.microsoft.com/en-us/azure/data-factory/continuous-integration-deployment). 

This sample will only copy files from one storage container to another (right now). Authentication for the storage accounts is handled via Storage Account Keys to showcase how secrets can be handled between environments.

![Azure Data Factory CI/CD Flow](https://docs.microsoft.com/en-us/azure/data-factory/media/continuous-integration-deployment/continuous-integration-image12.png)
